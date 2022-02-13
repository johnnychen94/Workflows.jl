@static if VERSION < v"1.7"
# copied from https://github.com/JuliaLang/julia/blob/a400a24a5d9e6609740814e4092538feb499ce60/base/stream.jl#L1290-L1415

function redirect_stdio(;stdin=nothing, stderr=nothing, stdout=nothing)
    stdin  === nothing || redirect_stdin(stdin)
    stderr === nothing || redirect_stderr(stderr)
    stdout === nothing || redirect_stdout(stdout)
end

function redirect_stdio(f; stdin=nothing, stderr=nothing, stdout=nothing)

    function resolve(new::Nothing, oldstream, mode)
        (new=nothing, close=false, old=nothing)
    end
    function resolve(path::AbstractString, oldstream,mode)
        (new=open(path, mode), close=true, old=oldstream)
    end
    function resolve(new, oldstream, mode)
        (new=new, close=false, old=oldstream)
    end

    same_path(x, y) = false
    function same_path(x::AbstractString, y::AbstractString)
        # if x = y = "does_not_yet_exist.txt" then samefile will return false
        (abspath(x) == abspath(y)) || samefile(x,y)
    end
    if same_path(stderr, stdin)
        throw(ArgumentError("stdin and stderr cannot be the same path"))
    end
    if same_path(stdout, stdin)
        throw(ArgumentError("stdin and stdout cannot be the same path"))
    end

    new_in , close_in , old_in  = resolve(stdin , Base.stdin , "r")
    new_out, close_out, old_out = resolve(stdout, Base.stdout, "w")
    if same_path(stderr, stdout)
        # make sure that in case stderr = stdout = "same/path"
        # only a single io is used instead of opening the same file twice
        new_err, close_err, old_err = new_out, false, Base.stderr
    else
        new_err, close_err, old_err = resolve(stderr, Base.stderr, "w")
    end

    redirect_stdio(; stderr=new_err, stdin=new_in, stdout=new_out)

    try
        return f()
    finally
        redirect_stdio(;stderr=old_err, stdin=old_in, stdout=old_out)
        close_err && close(new_err)
        close_in  && close(new_in )
        close_out && close(new_out)
    end
end
end
