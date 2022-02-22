"""
    filter(f, w::AbstractWorkflow; strict=true)::ManifestWorkflow

Create a minimal sub-workflow from `w` by applying function `f` to each task. The order is
preserved in the new workflow.

For each task `t` in the new workflow, `f(t)` holds. If setting keyword `strict=true`, then
all prerequisite tasks will also be included so ensure the sub-workflow is reproducible.

# Examples

```julia-repl
julia> file = joinpath(pkgdir(Workflows), "examples", "manifest", "benchmark_loop", "benchmark.toml")

julia> w = Workflows.load_config(file); w.tasks
Dict{String, Workflows.Dialects.AbstractTask} with 5 entries:
  "summary"         => SimpleTask(name="summary", id="summary", runner="shell")
  "julia_benchmark" => LoopTask(name="basic", id="julia_benchmark")
  "julia_init"      => SimpleTask(name="Initialize julia dependencies", id="julia_init", runner="shell")
  "numpy_benchmark" => LoopTask(name="basic", id="numpy_benchmark")
  "python_init"     => SimpleTask(name="Initialize python dependencies", id="python_init", runner="shell")

julia> sw = filter(t->"Framework:Julia" in task_groups(t), w); sw.tasks
Dict{String, Workflows.Dialects.AbstractTask} with 2 entries:
  "julia_benchmark" => LoopTask(name="basic", id="julia_benchmark")
  "julia_init"      => SimpleTask(name="Initialize julia dependencies", id="julia_init", runner="shell")

julia> sw = filter(t->"Framework:Julia" in task_groups(t), w; strict=false); sw.tasks
Dict{String, Workflows.Dialects.AbstractTask} with 1 entry:
  "julia_benchmark" => LoopTask(name="basic", id="julia_benchmark")
```
"""
function Base.filter(f, w::AbstractWorkflow; strict=true)
    # Generic workflow type should implement its conversion to ManifestWorkflow
    w = convert(ManifestWorkflow, w)
    return strict ? _strict_filter(f, w) : _simple_filter(f, w)
end

function _strict_filter(f, w::ManifestWorkflow)
    tasks_of_interest = [t for t in values(w.tasks) if f(t)]

    graph = TaskGraph(w)
    tasks_of_interest = TaskNode.(tasks_of_interest)

    subgraph = min_subgraph(graph, tasks_of_interest)
    subtasks = Dict(id=>w.tasks[id] for id in subgraph.ids)
    return ManifestWorkflow(w.version, w.dialect, subtasks)
end

function _simple_filter(f, w::ManifestWorkflow)
    subtasks = Dict(id=>t for (id, t) in w.tasks if f(t))
    return ManifestWorkflow(w.version, w.dialect, subtasks)
end


struct MergeConflictError <: Exception
    msg::String
end

"""
    merge(w::AbstractWorkflow, ws::AbstractWorkflow...)::ManifestWorkflow

Construct a manifest workflow from the given workflows. If compatible, tasks with the same
id will be merged; otherwise the merge operation will error.
"""
function Base.merge(w::AbstractWorkflow, ws::AbstractWorkflow...)
    x = convert(ManifestWorkflow, w)
    x === w && (x = from_dict(ManifestWorkflow, to_dict(x)))

    for y in ws
        y = convert(ManifestWorkflow, y)
        x.version == y.version || error("Can't merge workflows of different versions: $(x.version) and $(y.version).")
        for t in workflow_tasks(y)
            tid = task_id(t)
            if haskey(x.tasks, tid)
                # if two graphs have tasks of the same id, then merge the tasks
                old_t = x.tasks[tid]
                new_t = _merge_task(old_t, t)
                x.tasks[task_id(t)] = new_t
            else
                x.tasks[task_id(t)] = t
            end
        end
    end
    return x
end

_merge_task(::T1, ::T2) where {T1<:AbstractTask, T2<:AbstractTask} = error("can't merge tasks of types: $(T1) and $(T2)")

const LoopOrTaskVector = Union{LoopTask, TaskVector}
_merge_task(t1::LoopOrTaskVector, t2::AbstractTask) = __merge_task(t1, t2)
_merge_task(t1::AbstractTask, t2::LoopOrTaskVector) = __merge_task(t1, t2)
_merge_task(t1::LoopOrTaskVector, t2::LoopOrTaskVector) = __merge_task(t1, t2)
function __merge_task(ts::AbstractTask...)
    t = TaskVector(ts...)
    tasks = t.tasks
    return length(tasks) == 1 ? tasks[1] : t # not type-stable
end

function _merge_task(t1::SimpleTask, t2::SimpleTask)
    task_id(t1) == task_id(t2) || error("Task IDs should be the same, instead they are: $(task_id(t1)) and $(task_id(t2))")
    try
        from_dict(SimpleTask, _merge_config!(to_dict(t1), to_dict(t2)))
    catch err
        err isa MergeConflictError && error("failed to merge task id $(task_id(t1)): conflict detected.")
        rethrow()
    end
end
# deep nested merge!/append!
function _merge_config!(d1::AbstractDict, d2::AbstractDict)
    for k in keys(d1)
        if haskey(d2, k)
            d1[k] = _merge_config!(d1[k], d2[k])
        end
    end
    return d1
end
_merge_config!(x::AbstractVector, y::AbstractVector) = unique!(Base.append!(x, y))
_merge_config!(x, y) = x == y ? y : throw(MergeConflictError("$x != $y"))
