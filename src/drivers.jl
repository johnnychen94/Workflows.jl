function start_runner(task_info; root)
    task_runner = task_info["driver"]
    json_strings = if task_runner == "julia"
        julia_runner(task_info; root)
    elseif task_runner == "shell"
       shell_runner(task_info; root)
    else
        throw(ArgumentError("Unsupported task runner $(task_runner)"))
    end

    JSON3.read(json_strings)
end

function julia_runner(task_info; root)
    script = strip(task_info["source"])
    cd(root) do
        # run scripts in a sandbox module
        m = Module(gensym())
        Core.eval(m, :(Base.include($m, $script)))
    end
end

function shell_runner(task_info; root)
    cmd = strip(task_info["command"])
    @assert !isempty(cmd)
    cd(root) do
        out_io = IOBuffer()
        run(pipeline(`sh -c $cmd`; stdout=out_io, stderr=devnull))
        String(take!(out_io))
    end
end
