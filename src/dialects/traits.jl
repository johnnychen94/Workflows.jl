"""
    task_id(t::AbstractTask)::String

Return the unique ID of task `t`.

We assume that `task_id(x) == task_id(y)` if and only if the execution of task `x` is
"equivalent" to that of task `y`.
"""
task_id(::T) where T<:AbstractTask = error("Not implemented for task type $(T).")

"""
    task_name(t::AbstractTask)::String

Return the task name of task `t`.

Unlike [`taskid`](@ref), task names does not need to be unique.
"""
task_name(::T) where T<:AbstractTask = error("Not implemented for task type $(T).")

"""
    task_groups(t::AbstractTask)::Set

Return the groups that task `t` belongs to.
"""
task_groups(::T) where T<:AbstractTask = error("Not implemented for task type $(T).")

"""
    task_deps(t::AbstractTask)::Set

Return the assumed dependencies that task `t` requires so as to be executed successfully.
"""
task_deps(::T) where T<:AbstractTask = error("Not implemented for task type $(T).")

"""
    task_outs(t::AbstractTask)::Set

Return the assumed outputs that task execution of `t` will create, if executed
successfully.
"""
task_outs(::T) where T<:AbstractTask = error("Not implemented for task type $(T).")


"""
    runner_type(t::AbstractTask)::String

Return the runner type of task `t`.
"""
runner_type(::T) where T<:AbstractTask = error("Not implemented for task type $(T).")

"""
    runner_info(t::AbstractTask)::Dict{String, Any}

Return the extra information for task `t` runner.
"""
runner_info(::T) where T<:AbstractTask = error("Not implemented for task type $(T).")
