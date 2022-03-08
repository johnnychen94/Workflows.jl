@option struct ManifestWorkflow <: AbstractWorkflow
    version::VersionNumber
    dialect::String = "manifest"
    tasks::Dict{String,AbstractTask} = Dict{String,AbstractTask}()
    function ManifestWorkflow(version::VersionNumber, dialect::String, tasks)
        @assert dialect == "manifest"
        new(version, dialect, tasks)
    end
end
Base.convert(::Type{ManifestWorkflow}, w::ManifestWorkflow) = w
load_config(::Val{:manifest}, config::AbstractDict) = from_dict(ManifestWorkflow, config)
workflow_tasks(w::ManifestWorkflow) = values(w.tasks)

# To more efficiently get a task of specific task id, we convert the list to dictionary
# before construction. Because this is different from how we represent it in the
# configuration file, which is a list, we hereby patch it with `from_dict`/`to_dict`
# methods.
function from_dict(::Type{ManifestWorkflow}, ::OptionField{:tasks}, ::Type{Dict{String,AbstractTask}}, tasks)
    taskids = map(t->t["id"], tasks)
    taskids_set = Set(taskids)
    if length(taskids) != length(taskids_set)
        ids = filter(taskids_set) do id
            count(isequal(id), taskids) > 1
        end
        throw(ArgumentError("duplicate tasks detected: $(collect(ids))."))
    end
    function _build_task(config)
        T = haskey(config, "matrix") ? LoopTask : SimpleTask
        from_dict(T, config)
    end
    return Dict(t["id"]=>_build_task(t) for t in tasks)
end

function to_dict(::Type{ManifestWorkflow}, tasks::Dict{String,AbstractTask}, option::Configurations.ToDictOption)
    map(to_dict, values(tasks))
end
