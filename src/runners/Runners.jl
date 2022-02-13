module Runners

using Configurations
using ..Dialects: AbstractTask
using ..Dialects: task_id, task_name, task_groups, task_deps, task_outs
using ..Dialects: runner_type, runner_info

abstract type AbstractTaskRunner end

"""
    execute_task([exec::AbstractTaskRunner], t::AbstractTask; workdir=".")

Execute task `t` using runner `exec` in folder `workdir`.
"""
execute_task(task::AbstractTask; kwargs...) = execute_task(build_runner(task), task; kwargs...)
execute_task(r::RT, t::AbstractTask; kwargs...) where RT<:AbstractTaskRunner = error("Not implemented for runner type: $RT.")

"""
    build_runner(t::AbstractTask)

Build the runner object for task `t`.
"""
build_runner(t::AbstractTask) = build_runner(Val(Symbol(runner_type(t))), runner_info(t))
build_runner(::Val{runner_type}, run_info::AbstractDict) where runner_type = error("Not implemented for runner type: $runner_type.")

include("juliamodule.jl") # runner = "juliamodule"

include("compat.jl")

end #module