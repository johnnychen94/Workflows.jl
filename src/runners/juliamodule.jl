@option struct JuliaModuleRunner <: AbstractTaskRunner
    script::String
    workdir::String = "@__DIR__"
    """set false to disable stdout, i.e., redirect to devnull."""
    enable_stdout::Bool = true
    """set false to disable stderr, i.e., redirect to devnull."""
    enable_stderr::Bool = true
    """set false to suppress the errors with warning if the command fails to execute."""
    strict::Bool = true
end
build_runner(::Val{:juliamodule}, run_info::AbstractDict) = from_dict(JuliaModuleRunner, run_info)

function execute_task(exec::JuliaModuleRunner, t::AbstractTask; workdir::String=".", kwargs...)
    script = strip(exec.script)
    workdir = replace(exec.workdir, "@__DIR__" => workdir)
    stdout = exec.enable_stdout ? Base.stdout : devnull
    stderr = exec.enable_stderr ? Base.stderr : devnull
    cd(workdir) do
        script = abspath(script)
        m = Module(gensym())
        @debug "Executing task $(task_id(t)) in julia module" workdir=pwd() script
        Core.eval(m, :(include(x) = Base.include($m, x)))
        try
            out = redirect_stdio(stdout=stdout, stderr=stderr, stdin=devnull) do
                Core.eval(m, :(Base.include($m, $script)))
            end
            return out
        catch err
            # Unwrap the LoadError due to `include("script.jl")` call so that it looks like
            # a "real" `julia script.jl` process.
            err = err isa LoadError ? err.error : err
            exec.strict ? rethrow(err) : @warn "failed to execute task $(task_id(t)) in juliamodule runner" err
        end
    end
end
