@option struct ShellRunner <: AbstractTaskRunner
    command::Vector{String}
    workdir::String = "@__DIR__"
    """set true to capture the last non-empty line of stdout as execution result. The captured result will not be printed to stdout."""
    capture_stdout::Bool = false
    """set false to disable stdout, i.e., redirect to devnull."""
    enable_stdout::Bool = true
    """set false to disable stderr, i.e., redirect to devnull."""
    enable_stderr::Bool = true
    """set false to suppress the errors with warning if the command fails to execute."""
    strict::Bool = true
end
build_runner(::Val{:shell}, run_info::AbstractDict) = from_dict(ShellRunner, run_info)

function Configurations.from_dict(::Type{ShellRunner}, ::OptionField{:command}, ::Type{Vector{String}}, command)
    isa(command, String) ? [command] : command
end

function execute_task(exec::ShellRunner, t::AbstractTask; workdir::String=".", env=nothing)
    rst = ""
    workdir = replace(exec.workdir, "@__DIR__" => workdir)
    cd(workdir) do
        for cmd in exec.command
            cmd = strip(cmd)
            @debug "executing task $(task_id(t)) in shell runner" workdir=pwd()
            # TODO: redirect stdout as result
            stdout = exec.enable_stdout ? Base.stdout : devnull
            stderr = exec.enable_stderr ? Base.stderr : devnull
            try
                if exec.capture_stdout
                    rst = capture_run(cmd; stdout=stdout, stderr=stderr, env=env)
                else
                    rst = non_capture_run(cmd; stdout=stdout, stderr=stderr, env=env)
                end
            catch err
                exec.strict ? rethrow() : @warn "failed to execute task $(task_id(t)) in shell runner" err
                # TODO(johnnychen94): maybe cleanup intermediate results?
            end
        end
    end
    return rst # result of last command
end


struct ShellExecutionError <: Exception
    msg::String
end

"""
    capture_run(cmd; [stdout], [stderr], [env])

Run command `cmd` and capture the last non-empty line of `stdout` as the function result.

# Examples

```julia
# supprssing io with `devnull` doesn't affect the capturing
julia>capture_run(`printf "hello world \\n2"`; stdout=devnull)
"2"

julia>capture_run(`julia -e 'println("hello world"); println(rand(1:4, 4, 4))'`; stdout=devnull)
"[2 1 4 4; 1 2 3 4; 3 2 4 4; 1 1 1 2]"

# escape sequences are kept faithfully; it's the caller's responsibility to appropriately handle them.
julia> capture_run(`julia -e 'println("\e[0;31mred")'`)
"\e[0;31mred"
```
"""
function capture_run(cmd::Union{Cmd, Base.OrCmds}; stdout=stdout, stderr=stderr)
    interval = 0.1 # 100ms
    isnewline_char(x) = x == UInt8('\n') # TODO(johnnychen94): maybe also check CRLF?

    function continue_line!(line, buffer)
        data = take!(buffer)
        idx = findlast(isnewline_char, data)
        if isnothing(idx)
            # if the current line is not yet finished
            append!(line, data)
        else
            # otherwise, we get a new line and the previous results can be safely printed

            if length(line) > 0 && (isnewline_char(line[end]))
                write(stdout, line)
                resize!(line, 0)
            end

            # now let's check if the new contents has if only one non-empty line
            if last(idx) == length(data)
                # ignore trailing newlines by searching backwards from the first position
                # that is not '\n'.
                prev_idx = findprev(x->!isnewline_char(x), data, first(idx))
                if isnothing(prev_idx)
                    # with only `\n`s, simply appending to line should be sufficient if this
                    # happens to be the last line, we will eventually discard the trailing
                    # newlines
                    append!(line, data)
                else
                    prev_idx = findprev(isnewline_char, data, prev_idx)
                    if isnothing(prev_idx)
                        # if contains only one line, great
                        append!(line, data)
                    else
                        # otherwise, only append the last non-empty line
                        write(stdout, @view data[1:last(prev_idx)])
                        resize!(line, 0)
                        append!(line, @view data[last(prev_idx)+1:end])
                    end
                end
            else
                # otherwise, print previous lines to stdout, and reset the current line with
                # new line content
                write(stdout, @view data[1:last(idx)])
                resize!(line, 0)
                append!(line, @view data[last(idx)+1:end])
            end
        end

        return line
    end

    line = UInt8[]
    buffer = IOBuffer()
    proc = try
        run(pipeline(cmd, stdout=buffer, stderr=stderr), wait=false)
    catch err
        err isa Base.IOError && rethrow(ShellExecutionError(err.msg))
        rethrow()
    end

    while process_running(proc)
        continue_line!(line, buffer)
        sleep(interval)
    end

    @assert process_exited(proc)
    if proc.exitcode != 0
        # If the process existed unexpectedly, the last non-empty line in the buffer is
        # almost useless. Thus here we directly rethrow the errors, and let the caller
        # decide how to handle the exception.
        write(stdout, line)
        throw(ShellExecutionError("non-zero exit code: $(proc.exitcode)"))
    end
    continue_line!(line, buffer)

    # discard trailing '\n's
    idx = findprev(x->!isnewline_char(x), line, length(line))
    if isnothing(idx)
        return ""
    else
        resize!(line, idx)
    end
    # if it contains multiple lines, only capture the last line
    idx = findfirst(isnewline_char, line)
    if !(isnothing(idx) || (idx == length(line)))
        write(stdout, @view line[1:last(idx)])
        return String(line[last(idx)+1:end])
    else
        return String(line)
    end
end

function capture_run(cmd::AbstractString; env=nothing, kwargs...)
    try
        capture_run(build_cmd_pipeline(cmd; env=env); kwargs...)
    catch err
        if err isa ShellExecutionError
            rethrow(ShellExecutionError("failed to execute command `$cmd`: $(err.msg)"))
        end
        rethrow()
    end
end

"""
    non_capture_run(cmd; [stdout], [stderr], [env])

Run command `cmd` similar to `run(pipeline(cmd; stdout, stderr); wait=true)` except that it
throws `ShellExecutionError` if the command fails.
"""
function non_capture_run(cmd::Union{Cmd, Base.OrCmds}; stdout=stdout, stderr=stderr)
    interval = 0.1 #100ms
    proc = try
        # set `wait=false` here and do manual check for better exception handling
        run(pipeline(cmd, stdout=stdout, stderr=stderr); wait=false)
    catch err
        err isa Base.IOError && rethrow(ShellExecutionError(err.msg))
        rethrow()
    end
    while process_running(proc)
        sleep(interval)
    end
    @assert process_exited(proc)
    if proc.exitcode != 0
        throw(ShellExecutionError("non-zero exit code: $(proc.exitcode)"))
    end
end

function non_capture_run(cmd::AbstractString; env=nothing, kwargs...)
    try
        non_capture_run(build_cmd_pipeline(cmd; env=env); kwargs...)
    catch err
        if err isa ShellExecutionError
            rethrow(ShellExecutionError("failed to execute command `$cmd`: $(err.msg)"))
        end
        rethrow()
    end
    return "" # to keep consistent with `capture_run` version
end

# TODO(johnnychen94): support shell pipes such as "grep results.csv julia | cut -d, -f2" (#7)
function build_cmd_pipeline(cmd::AbstractString; env=nothing)
    # We can't simply interpolate the entire string by `$(cmd)`:
    # ```julia
    # cmd = "echo 'hello world'"
    # run(`$cmd`) # errors
    # run(`echo 'hello world'`) # works
    # ```
    return Cmd(Cmd(Base.shell_split(cmd)); env=env)
end
