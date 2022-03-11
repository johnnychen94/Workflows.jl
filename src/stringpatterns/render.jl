# Examples of valid placeholder pattern:
#   - ${{ a }}
#   - ${{ a.b }}
#   - ${{ a.b[1] }}
#   - ${{ a.b[1].c.d[1] }}
#   - ${{ a.b | join(" ") }} # TODO
#   - ${{ a.b | join(" ") | default("fallback") }} # TODO
#   - ${{ a.b | join(${{ sep }}) }} # TODO
# Examples of invalid placeholder pattern:
#   - ${{ .b }}
#   - ${{ a. }}

re_placeholder = r"\${{\s*(?<value>\w(\[\d+\])?[(\w(\[\d+\])?)\.]*)\s*}}"

"""
    render(template, config::Dict) -> new

Recursively render strings in `template` by substituting `config` for every occurence of `\${{ PLACEHOLDER }}`.

# Examples

```julia
using Workflows.Dialects: render

config = Dict(
    "tasks" => Dict(
        "args" => Dict(
            "script" => "main.jl",
            "flags" => [
                "--startup=no",
                "--color=yes"
            ],
            "length" => 100
        )
    ),
)

# "julia --startup=no --color=yes main.jl 100"
template = "julia \${{ tasks.args.flags | join(" ") }} \${{ tasks.args.script }} \${{ tasks.args.length }}"
render(template, config)
```
"""
function render end

render(template::AbstractDict, config) = Dict(k=>render(t, config) for (k, t) in template)
render(template::AbstractVector, config) = [render(v, config) for v in template]
render(x::Any, config) = x # silently skip it for unsupported type

# TODO(johnnychen94): rewrite this to get better performance and/or to support filter syntax
function render(template::AbstractString, config::AbstractDict)
    # Note that this doesn't find nested placeholders such as "${{ x | join(${{ sep }}) }}"
    indices = findall(re_placeholder, template)

    value_lookup = _build_value_lookup(config)

    parts = Union{SubString,String}[]
    i = 1
    for r in indices
        i < r[1] && push!(parts, @view template[i:r[1]-1])
        r[1] <= r[end] && push!(parts, _render(@view(template[r]), value_lookup))
        i = r[end]+1
    end
    i <= length(template) && push!(parts, @view template[i:end])
    return join(parts, "")
end

function _render(template::AbstractString, value_lookup)
    # TODO(johnnychen94): support filter syntax
    name = match(re_placeholder, template)[:value]
    return _to_string(value_lookup[name])
end

# TODO(johnnychen94): ideally, we would like to support filter syntax `${{ values | join(" ") }}`
_to_string(v::AbstractVector) = mapreduce(string, (l,r)->"$l $r", v)
_to_string(v) = string(v)

function _build_value_lookup(config::AbstractDict)
    patterns = Dict{String,Any}()
    return _build_value_lookup!(patterns, config; prefix="")
end

function _build_value_lookup!(patterns, config::AbstractDict; prefix)
    for (k, v) in config
        occursin(".", k) && error("key \"$k\" should not contain dot.")
        pname = isempty(prefix) ? string(k) : "$prefix.$k"
        _build_value_lookup!(patterns, v; prefix=pname)
    end
    return patterns
end

function _build_value_lookup!(patterns, config::AbstractVector; prefix)
    @assert !isempty(prefix)
    for (i, x) in enumerate(config)
        _build_value_lookup!(patterns, x; prefix="$prefix[$i]")
    end
    patterns["$prefix"] = config
    return patterns
end

function _build_value_lookup!(patterns, config::Any; prefix)
    patterns["$prefix"] = config
    return patterns
end
