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
    task_groups(t::AbstractTask)::Vector{String}

Return the groups that task `t` belongs to.
"""
task_groups(::T) where T<:AbstractTask = error("Not implemented for task type $(T).")

"""
    task_deps(t::AbstractTask)::Vector{String}

Return the assumed dependencies that task `t` requires so as to be executed successfully.
"""
task_deps(::T) where T<:AbstractTask = error("Not implemented for task type $(T).")

"""
    task_outs(t::AbstractTask)::Vector{String}

Return the assumed outputs that task execution of `t` will create, if executed
successfully.
"""
task_outs(::T) where T<:AbstractTask = error("Not implemented for task type $(T).")

"""
    task_requires(t::AbstractTask)::Vector{String}

Return the required task IDs that should be executed before task `t`. For task node `t`
in a task graph, they are the IDs of its direct parent nodes.
"""
task_requires(::T) where T<:AbstractTask = error("Not implemented for task type $(T)")

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

"""
    workflow_tasks(w::AbstractWorkflow)

Return tasks of workflow `w` as iterable object.
"""
workflow_tasks(::T) where T<:AbstractWorkflow = error("Not implemented for workflow type $(T)")

"""
    to_manifest(w::AbstractWorkflow)

Convert workflow `w` to [`ManifestWorkflow`](@ref).
"""
to_manifest(::T) where T<:AbstractWorkflow = error("Not implemented for workflow type $(T)")
Base.convert(::Type{ManifestWorkflow}, w::AbstractWorkflow) = to_manifest(w)
