"""
    load_config(filename::AbstractString)

Load workflow configuration from `filename`.
"""
function load_config(filename::AbstractString)
    name, ext = splitext(basename(filename))
    config = if ext == ".toml"
        # https://toml.io/en/v1.0.0#filename-extension
        # TOML files should use the extension `.toml`
        TOML.parsefile(filename)
    elseif ext in (".yml", ".yaml")
        YAML.load_file(filename; dicttype=Dict{String, Any})
    else
        throw(ArgumentError("unsupported file extension: \"$ext\"."))
    end
    dialect = config["dialect"] # required
    ver = config["version"] # required
    check_version(dialect, VersionNumber(ver))

    # runtime dispatch to custom dialect implementation
    return load_config(Val(Symbol(dialect)), config)
end
load_config(::Val{d}, config) where d = error("unsupported workflow dialect \"$d\".")

"""
    save_config(filename::AbstractString, workflow)

Save workflow configuration into `filename`.
"""
function save_config(filename::AbstractString, workflow::AbstractWorkflow)
    name, ext = splitext(basename(filename))
    if ext == ".toml"
        config = to_dict(workflow, TOMLStyle)
        config["version"] = string(spec_versions[workflow.dialect])
        open(filename, "w") do io
            TOML.print(convert_to_builtin, io, config)
        end
    else
        throw(ArgumentError("unsupported file extension: \"$ext\"."))
    end
    return
end

# some custom types need to be converted to built in types before serialization
convert_to_builtin(v::VersionNumber) = string(v)
convert_to_builtin(v) = v

# TOML support
function Configurations.to_toml(io::IO, x::AbstractWorkflow; kwargs...)
    to_toml(convert_to_builtin, io, x; kwargs...)
end
function Configurations.to_toml(filename::String, x::AbstractWorkflow; kwargs...)
    to_toml(convert_to_builtin, filename, x; kwargs...)
end

# VersionNumber support
from_dict(::Type{T}, ::Type{VersionNumber}, ver::AbstractString) where T<:AbstractWorkflow = VersionNumber(ver)
from_dict(::Type{T}, ::Type{VersionNumber}, ver::VersionNumber) where T<:AbstractWorkflow = ver
from_dict(::Type{T}, ::Type{VersionNumber}, ver::Real) where T<:AbstractWorkflow = VersionNumber(string(ver))
