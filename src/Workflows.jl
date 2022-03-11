module Workflows

using Configurations
using SHA
using JSON3

include("taskgraphs/TaskGraphs.jl")
using .TaskGraphs
include("stringpatterns/StringPatterns.jl")
using .StringPatterns

include("dialects/Dialects.jl")
using .Dialects: load_config, save_config
using .Dialects: AbstractWorkflow, ManifestWorkflow
using .Dialects: task_id, task_deps
include("runners/Runners.jl")
using .Runners: execute_task
include("scheduler.jl")


"""
Interfaces:

- [`Workflows.execute`](@ref)
"""
Workflows

end
