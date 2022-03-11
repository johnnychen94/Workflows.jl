# custom runner task
#   requires: `runner`, `script`
#   optional: `args`, `matrix`
#   ignores: `run`
@option struct CustomRunnerWorkflow <: AbstractWorkflow
    version::VersionNumber
    dialect::String = "manifest_runner"
    runners::Dict{String,Any} = Dict{String,Any}()
    tasks::Vector{Dict{String,Any}} = Dict{String,Any}[]
    function CustomRunnerWorkflow(version::VersionNumber, dialect::String, runners, tasks)
        @assert dialect == "manifest_runner"
        new(version, dialect, runners, tasks)
    end
end
load_config(::Val{:manifest_runner}, config) = from_dict(CustomRunnerWorkflow, config)
Base.convert(::Type{ManifestWorkflow}, w::CustomRunnerWorkflow) = to_manifest(w)

function to_manifest(w::CustomRunnerWorkflow)
    runners = w.runners

    init_tasks = Dict{String,Any}()
    init_tasks_used = Dict{String,Bool}()
    for (rname, rconfig) in runners
        haskey(rconfig, "init") || continue
        tconfig = Dict(
            "name" => "initialize $rname runner",
            "id" => "_gen_$(rname)_init",
            "runner" => rconfig["init"]["runner"],
            "run" => rconfig["init"]["run"],
        )
        init_tasks[rname] = tconfig
        init_tasks_used[rname] = false
    end

    tasks = Dict{String,Any}[]
    for t in w.tasks
        t = deepcopy(t)
        rname = t["runner"]
        if !(rname in keys(runners))
            if !(rname in _builtin_runners)
                error("unrecognized runner type \"$rname\".")
            else
                push!(tasks, t)
                continue
            end
        end

        if haskey(init_tasks, rname) && !init_tasks_used[rname]
            init_tasks_used[rname] = true
            push!(tasks, init_tasks[rname])
        end

        # rewrite task by submitting `runners` with custom `run` information
        runner_config = Dict{String,Any}("tasks"=>Dict{String,Any}())
        if haskey(t, "run")
            runner_config["tasks"]["run"] = deepcopy(t["run"])
        end
        t["run"] = render(runners[rname]["run"], runner_config)
        t["runner"] = runners[rname]["runner"]

        if haskey(init_tasks, rname)
            if haskey(t, "requires")
                push!(t["requires"], init_tasks[rname]["id"])
            else
                t["requires"] = [init_tasks[rname]["id"]]
            end
        end
        push!(tasks, t)
    end

    return from_dict(ManifestWorkflow, Dict{String,Any}(
        "version" => v"0.1",
        "dialect" => "manifest",
        "tasks" => tasks,
    ))
end
