"""
    PipelineOrder(stages::Vector{Vector{String}})

Creates a pipeline execution order object.

Stages `[["1", "2"], ["3", "4", "5"], ["6"]]` would create the following pipeline:

```text
| Stage 1 |  Stage 2 | Stage 3 |
| ------- | -------- | ------  |
| Task 1  |  Task 3  |         |
| Task 2  |  Task 4  | Task 6  |
|         |  Task 5  |         |
```

The task scheduler would first execute all tasks `["1", "2"]` in stage 1, and then all tasks
`["3", "4", "5"]` in stage 2, and finally all tasks `["6"]` in stage 3. The execution order
for tasks in the same stage is undefined.
"""
struct PipelineOrder <: AbstractExecutionOrder
    stages::Vector{Vector{String}}
    function PipelineOrder(stages::Vector{<:Vector})
        flatten_tasks = union(String[], stages...)
        tasks = vcat(stages...)
        if length(tasks) != length(flatten_tasks)
            ids = filter(flatten_tasks) do id
                count(isequal(id), tasks) > 1
            end
            throw(ArgumentError("duplicate tasks detected in \"order\": $ids."))
        end
        return new(stages)
    end
end
PipelineOrder(stages::Vector{String}) = PipelineOrder([[x] for x in stages])
Base.:(==)(p1::PipelineOrder, p2::PipelineOrder) = p1.stages == p2.stages

# TODO(johnnychen94): add DAG support
