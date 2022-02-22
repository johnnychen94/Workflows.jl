@option struct LoopTask <: AbstractTask
    name::String
    id::String
    runner::String
    groups::Vector{String} = String[]
    deps::Vector{String} = String[]
    requires::Vector{String} = String[]
    outs::Vector{String} = String[]
    matrix::Dict{String} = Dict{String,Any}()
    run::Dict{String, Any} = Dict{String, Any}()
end

task_id(t::LoopTask) = t.id
task_name(t::LoopTask) = t.name
task_groups(t::LoopTask) = t.groups
task_deps(t::LoopTask) = t.deps
task_requires(t::LoopTask) = t.requires
task_outs(t::LoopTask) = t.outs
runner_type(t::LoopTask) = t.runner
runner_info(::LoopTask) = error("LoopTask must be unrolled first to get runner information")

function Base.show(io::IO, t::LoopTask)
    print(io, "LoopTask(name=\"", task_name(t), "\", id=\"", task_id(t), "\")")
end

function Base.collect(t::LoopTask)
    special_names = ("includes", "excludes")
    matrix_keys = [k for k in keys(t.matrix) if !in(k, special_names)]
    excludes = get(t.matrix, "excludes", Dict{String,Any}[])
    excludes = Dict{String,String}[Dict("matrix.$k"=>string(v) for (k, v) in patterns) for patterns in excludes]
    unique!(excludes)
    includes = get(t.matrix, "includes", Dict{String,Any}[])
    includes = Dict{String,String}[Dict("matrix.$k"=>string(v) for (k, v) in patterns) for patterns in includes]
    unique!(includes)
    special_common = intersect(includes, excludes)
    isempty(special_common) || error("Ambiguous \"matrix\" configuration: $special_common are listed in both \"includes\" and \"excludes\".")

    function _build_task(t, patterns; count::Int)
        config = Dict{String,Any}()
        config["name"] = t.name
        config["runner"] = t.runner
        config["groups"] = t.groups
        config["requires"] = t.requires
        config["deps"] = t.deps
        config["outs"] = t.outs
        config["id"] = t.id * "@$count"
        config["run"] = render(t.run, patterns)
        return from_dict(SimpleTask, config)
    end

    items = SimpleTask[]
    patterns = Dict{String, String}()
    id_count = 1
    seen = Dict{String,String}[]
    for v in Base.Iterators.product(getindex.(Ref(t.matrix), matrix_keys)...)
        length(matrix_keys) == 0 && continue
        for (i, k) in enumerate(matrix_keys)
            patterns["matrix.$k"] = string(v[i])
        end
        patterns in excludes && continue
        push!(items, _build_task(t, patterns; count=id_count))
        isempty(includes) || push!(seen, copy(patterns))
        id_count += 1
    end
    for patterns in includes
        patterns in seen && continue
        push!(items, _build_task(t, patterns; count=id_count))
        id_count += 1
    end

    return items
end

"""
    render(old, patterns::Dict) -> new

Recursively render strings in `old` by substituting `patterns`.

```jldoctest; setup=:(using Workflows.Dialects: render)
julia> render("echo \${{ greet }}, \${{ name }}", Dict("greet"=>"hello", "name"=>"world"))
"echo hello, world"

julia> render("echo \${{ values }}", Dict("values" => "[1, 2, 3]"))
"echo [1, 2, 3]"
```
"""
function render(config::Dict{String}, patterns::Dict)
    out = Dict{String,Any}()
    for (k, old) in config
        out[k] = render(old, patterns)
    end
    return out
end
render(contents::Vector{String}, patterns) = map(v->render(v, patterns), contents)

function render(content::String, patterns::Dict)
    build_regex(name, value) = r"\${{\s*" * name * r"\s*}}" => value

    # TODO(johnnychen94): tweak the performance of `replace`
    out = _replace(content, (build_regex(k, v) for (k, v) in patterns)...)
    return out
end
render(x::Number, patterns) = x

@static if VERSION < v"1.7"
    # slooooow version
    _replace(s, pat1, pat2...; kwargs...) = _replace(_replace(s, pat1; kwargs...), pat2...; kwargs...)
    _replace(s, pat1; kwargs...) = replace(s, pat1; kwargs...)
else
    _replace(s, pat...; kwargs...) = replace(s, pat...; kwargs...)
end
