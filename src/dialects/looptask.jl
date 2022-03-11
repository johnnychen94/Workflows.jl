@option struct LoopTask <: AbstractTask
    name::String
    id::String
    runner::String
    groups::Vector{String} = String[]
    deps::Vector{String} = String[]
    requires::Vector{String} = String[]
    outs::Vector{String} = String[]
    matrix::Dict{String} = Dict{String,Any}()
    run::Dict{String, Any} = Dict{String, Any}()
end

task_id(t::LoopTask) = t.id
task_name(t::LoopTask) = t.name
task_groups(t::LoopTask) = t.groups
task_deps(t::LoopTask) = t.deps
task_requires(t::LoopTask) = t.requires
task_outs(t::LoopTask) = t.outs
runner_type(t::LoopTask) = t.runner
runner_info(::LoopTask) = error("LoopTask must be unrolled first to get runner information")

function Base.show(io::IO, t::LoopTask)
    print(io, "LoopTask(name=\"", task_name(t), "\", id=\"", task_id(t), "\")")
end

function Base.collect(t::LoopTask)
    special_names = ("includes", "excludes")
    matrix_keys = [k for k in keys(t.matrix) if !in(k, special_names)]
    excludes = get(t.matrix, "excludes", Dict{String,Any}[])
    excludes = Dict{String,String}[Dict("matrix.$k"=>string(v) for (k, v) in patterns) for patterns in excludes]
    unique!(excludes)
    includes = get(t.matrix, "includes", Dict{String,Any}[])
    includes = Dict{String,String}[Dict("matrix.$k"=>string(v) for (k, v) in patterns) for patterns in includes]
    unique!(includes)
    special_common = intersect(includes, excludes)
    isempty(special_common) || error("Ambiguous \"matrix\" configuration: $special_common are listed in both \"includes\" and \"excludes\".")

    function _build_task(t, patterns; count::Int)
        config = Dict{String,Any}()
        config["name"] = t.name
        config["runner"] = t.runner
        config["groups"] = t.groups
        config["requires"] = t.requires
        config["deps"] = t.deps
        config["outs"] = t.outs
        config["id"] = t.id * "@$count"
        config["run"] = render(t.run, patterns)
        return from_dict(SimpleTask, config)
    end

    items = SimpleTask[]
    patterns = Dict{String, String}()
    id_count = 1
    seen = Dict{String,String}[]
    for v in Base.Iterators.product(getindex.(Ref(t.matrix), matrix_keys)...)
        length(matrix_keys) == 0 && continue
        for (i, k) in enumerate(matrix_keys)
            patterns["matrix.$k"] = string(v[i])
        end
        patterns in excludes && continue
        push!(items, _build_task(t, patterns; count=id_count))
        isempty(includes) || push!(seen, copy(patterns))
        id_count += 1
    end
    for patterns in includes
        patterns in seen && continue
        push!(items, _build_task(t, patterns; count=id_count))
        id_count += 1
    end

    return items
end


# TaskVector is a simple collection of tasks while still preserving the `AbstractTask`
# hierarchy. This can be used to store the unrolled LoopTask.
struct TaskVector{T<:AbstractTask} <: AbstractTask
    tasks::Vector{T}
    name::String
    id::String
    requires::Vector{String}
    outs::Vector{String}
    deps::Vector{String}
    groups::Vector{String}
end
TaskVector(ts::Vector) = TaskVector(ts...)
function TaskVector(ts::AbstractTask...)
    ids = unique(map(task_id, ts))
    length(ids) == 1 || throw(ArgumentError("TaskVector can't contain tasks of different IDs: $ids"))
    id = ids[1]

    names = unique(map(task_name, ts))
    length(names) == 1 || throw(ArgumentError("TaskVector can't contain tasks of different names: $names"))
    name = names[1]

    i = 1
    tasks = mapreduce(append!, ts) do t
        map(_unroll(t)) do new_t
            # re-assign the task IDs to ensure uniqueness
            t_config = to_dict(new_t)
            t_config["id"] = split(t_config["id"], "@")[1] * "@$i"
            i += 1
            from_dict(typeof(new_t), t_config)
        end
    end
    requires = mapreduce(task_requires, append!, ts)
    groups = mapreduce(task_groups, append!, ts)
    outs = mapreduce(task_outs, append!, ts)
    deps = mapreduce(task_deps, append!, ts)
    return TaskVector(tasks, name, id, requires,outs, deps, groups)
end

task_id(t::TaskVector) = t.id
task_name(t::TaskVector) = t.name
task_groups(t::TaskVector) = t.groups
task_deps(t::TaskVector) = t.deps
task_requires(t::TaskVector) = t.requires
task_outs(t::TaskVector) = t.outs
Base.show(io::IO, t::TaskVector) = print(io, "TaskVector(name=\"", task_name(t), "\", id=\"", task_id(t), "\")")

_unroll(t::SimpleTask) = [t]
_unroll(t::LoopTask) = collect(t)
_unroll(t::TaskVector) = t.tasks
