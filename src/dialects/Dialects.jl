module Dialects

using Configurations
using TOML
using Printf
using ..TaskGraphs

import Configurations: from_dict, to_dict

const spec_versions = begin
    config = TOML.parsefile(joinpath(@__DIR__, "..", "..", "dialects.toml"))
    Dict(k=>VersionNumber(v["version"]) for (k, v) in config)
end

abstract type AbstractTask end
TaskGraphs.TaskNode(t::AbstractTask) = TaskNode(task_id(t), task_requires(t))

abstract type AbstractWorkflow end
TaskGraphs.TaskGraph(w::AbstractWorkflow) = TaskGraph([TaskNode(t) for t in workflow_tasks(w)])

include("traits.jl")
include("simpletask.jl")
include("looptask.jl")
include("manifest.jl")
include("utils.jl")
include("config_io.jl")

end #module
