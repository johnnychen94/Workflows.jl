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

function Base.iterate(o::PipelineOrder)
    (length(o.stages) >= 1 && length(o.stages[1]) >= 1) || return nothing
    status = falses(sum(length, o.stages))
    status[1] = true
    return o.stages[1][1], status
end
function Base.iterate(o::PipelineOrder, state)
    length(o.stages) == 0 && return nothing
    n = 0
    for i in 1:length(o.stages)
        cur_stage = o.stages[i]
        stage_status = @view state[n+1:n+length(cur_stage)]
        n += length(cur_stage)
        all(stage_status) && continue
        idx = findfirst(x->!x, stage_status)
        if !isnothing(idx)
            # Techniquelly, this can be thread unsafe in the sense that one task can be
            # executed multiple times in parallel. It's the caller's duty to maintain the
            # runtime status pool.
            stage_status[idx] = true
            return cur_stage[idx], state
        end
    end
    return nothing
end

# TODO(johnnychen94): add DAG support
