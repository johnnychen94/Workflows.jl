module Dialects

using Configurations
using TOML
using Printf

import Configurations: from_dict, to_dict

const spec_versions = begin
    config = TOML.parsefile(joinpath(@__DIR__, "..", "..", "dialects.toml"))
    Dict(k=>VersionNumber(v["version"]) for (k, v) in config)
end

abstract type AbstractTask end
abstract type AbstractWorkflow end
abstract type AbstractExecutionOrder end

include("traits.jl")
include("orders.jl")
include("simpletask.jl")
include("manifest.jl")
include("utils.jl")
include("config_io.jl")

end #module
