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
