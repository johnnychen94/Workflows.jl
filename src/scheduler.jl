"""
    execute(filename::AbstractString; workdir=dirname(filename), kwargs...)
    execute(w::AbstractWorkflow; workdir=".", kwargs...)

Execute workflow `w` or workflow defined in file `filename`.

# Parameters

- `workdir`: the working folder to execute the workflow.
- `cleanup=false`: true to clean the internal tmp files in `.workflows/tmp` folder when
  julia exits.
"""
function execute(filename::AbstractString; workdir="", kwargs...)
    w = load_config(filename)
    workdir = isempty(workdir) ? dirname(filename) : workdir
    execute(w; workdir=workdir, kwargs...)
end

function execute(w::ManifestWorkflow; workdir=".", cleanup=false)
    tasklocks = Dict{String,ReentrantLock}()
    results = Dict{String,Any}() # store the captured stdout result of shell runner

    tmpdir = workflow_tmpdir(w; workdir=workdir)
    # TODO(johnnychen94): support normal/verbose/quite mode
    @info "execute workflow" workdir cleanup tmpdir
    if cleanup
        atexit() do
            tmpdir = abspath(tmpdir)
            rm(tmpdir; recursive=true, force=true)
            tmproot = dirname(tmpdir)
            if isempty(readdir(tmproot))
                rm(tmproot)
            end
        end
    end

    # TODO(johnnychen94): support threads (#6)
    for taskid in w.order
        haskey(tasklocks, taskid) || (tasklocks[taskid] = ReentrantLock())
        lock(tasklocks[taskid]) do
            t = w.tasks[taskid]
            tid = task_id(t)

            # If this task requests STDOUT results from previous tasks, then dump the data
            # as json file and store the file path as environment variable. The task
            # script/command is responsible for appropriately handling this.
            stdout_deps = _get_stdout_deps(results, t)
            tmpfile = joinpath(tmpdir, "deps_$tid.json")
            env = _dump_stdout_to_temp(tmpfile, stdout_deps; workdir=workdir)
            if !isnothing(env)
                @info "prepare task: $(tid)" tmpfile
            end

            @info "Executing task: $(tid)"
            results[taskid] = execute_task(t; workdir=workdir, env=env)
        end
    end
    return
end


function _dump_stdout_to_temp(filename::String, data::Dict; workdir)
    isempty(data) && return nothing

    tmpdir = dirname(filename)
    isdir(tmpdir) || mkpath(tmpdir)
    open(filename, "w") do io
        JSON3.write(io, data)
    end

    env = copy(ENV)
    env["WORKFLOW_TMP_INFILE"] = relpath(filename, workdir)
    return env
end

function _get_stdout_deps(results, t)
    # `results` is readonly here

    # Prepare all `@__STDOUT__*` results required by task `t` and dump into filesystem
    function get_result(name)
        m = match(r"@__STDOUT__(?<taskid>.*)", name)
        isnothing(m) && return nothing
        id = m[:taskid]
        if !haskey(results, id)
            @warn "task \"$(task_id(t))\" requests stdout of task \"$id\" but failed to get it"
            return nothing
        end
        return id => results[id]
    end
    return Dict(filter!(x->!isnothing(x), map(get_result, task_deps(t))))
end

function workflow_tmpdir(w; workdir=".")
    val = bytes2hex(sha256(to_toml(w)))[1:8]
    return joinpath(workdir, ".workflows", "tmp", val)
end
