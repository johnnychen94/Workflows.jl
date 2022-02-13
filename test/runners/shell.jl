@testset "capture_run" begin
    # single line
    rst = capture_run(`julia --startup=no -e 'println("hello world")'`)
    @test rst == "hello world"

    # last evaluation result is not the return value
    rst = capture_run(`julia --startup=no -e 'println("hello world"); 1+1'`)
    @test rst == "hello world"

    # stderr is also not the return value
    io = IOBuffer()
    rst = capture_run(`julia --startup=no -e 'println("hello world"); @info "hi"'`; stderr=io)
    @test String(take!(io)) == "[ Info: hi\n"
    @test rst == "hello world"

    # multiple lines
    io = IOBuffer()
    rst = capture_run(`julia --startup=no -e 'println("hello world"); print(1+1)'`, stdout=io)
    @test String(take!(io)) == "hello world\n"
    @test rst == "2"

    # last \n is discarded
    io = IOBuffer()
    rst = capture_run(`julia --startup=no -e 'println("hello world"); println(1+1)'`, stdout=io)
    @test String(take!(io)) == "hello world\n"
    @test rst == "2"

    # if errors, throw exception
    io = IOBuffer()
    try
        capture_run(`julia --startup=no -e 'error("some error")'`; stderr=io)
    catch err
        @test err == ShellExecutionError("non-zero exit code: 1")
    finally
        @test occursin("ERROR: some error", String(take!(io)))
    end
    try
        capture_run(`not_a_command`)
    catch err
        @test err isa ShellExecutionError && occursin("could not spawn `not_a_command`", err.msg)
    end

    # multiple trailing '\n's are ignored
    io = IOBuffer()
    rst = capture_run(`julia --startup=no -e 'println("hello \n\n\nworld\n\n\n")'`; stdout=io)
    @test String(take!(io)) == "hello \n\n\n"
    @test rst == "world"
    io = IOBuffer()
    rst = capture_run(`julia --startup=no -e 'println("hello \n\n\nworld")'`; stdout=io)
    @test String(take!(io)) == "hello \n\n\n"
    @test rst == "world"
    if !Sys.iswindows()
        io = IOBuffer()
        @test "world" == capture_run(`printf "hello \n\n\nworld"`; stdout=io)
        @test String(take!(io)) == "hello \n\n\n"
        io = IOBuffer()
        @test "world" == capture_run(`printf "hello \n\n\nworld\n"`; stdout=io)
        @test String(take!(io)) == "hello \n\n\n"
        io = IOBuffer()
        @test "world" == capture_run(`printf "hello \n\n\nworld\n\n\n"`; stdout=io)
        @test String(take!(io)) == "hello \n\n\n"
    end

    # Test if a looooooooooong line is kept as expected
    function test_large_data(n = 1000)
        script = """
        using TOML
        data = 1:$n
        TOML.print(Dict("data"=>data))
        """
        rst = with_sandbox() do
            write("script.jl", script)
            capture_run(`julia --startup=no script.jl`; stdout=devnull)
        end
        @test TOML.parse(rst)["data"] == collect(1:n)
    end
    for (n_repeat, sz) in [(3, 1), (3, 10), (3, 100), (2, 1000), (1, 10000), (1, 100000)]
        for _ in 1:n_repeat
            test_large_data(sz)
        end
    end
end

@testset "Runner: shell" begin
    # The workdir setup is a little bit tricky here as we usually triggers the test
    # in project root dir with `pkg> test`. To successfully run the tests interactively,
    # we need to set pwd to the "test/runners" dir.
    scripts_dir = joinpath(@__DIR__, "scripts")
    workdir_prefix = basename(@__DIR__)

    taskinfo = Dict{String,Any}(
        "name" => "task1",
        "id" => "1",
        "runner" => "shell",
    )

    taskinfo["run"] = Dict(
        "command" => "julia --startup=no scripts/sum.jl",
        "capture" => true,
    )
    t = from_dict(SimpleTask, taskinfo)
    exec = build_runner(t)
    dirs, rst = with_sandbox(includes=[scripts_dir]) do
        readdir(workdir_prefix), execute_task(t; workdir=workdir_prefix)
    end
    @test dirs == ["scripts"]
    @test rst == ""

    # check if we successfully parsed the stdout as return value
    taskinfo["run"] = Dict(
        "command" => "julia --startup=no scripts/println_sum.jl",
        "capture" => true,
    )
    t = from_dict(SimpleTask, taskinfo)
    exec = build_runner(t)
    dirs, rst = with_sandbox(includes=[scripts_dir]) do
        readdir(workdir_prefix), execute_task(t; workdir=workdir_prefix)
    end
    @test dirs == ["scripts"]
    @test rst == "55"

    # non-capture mode shell runner
    taskinfo["run"] = Dict(
        "command" => "julia --startup=no scripts/println_sum.jl"
    )
    t = from_dict(SimpleTask, taskinfo)
    exec = build_runner(t)
    @test exec.capture == false # default is non-capturing
    with_sandbox(includes=[scripts_dir]) do
        dirs = readdir(workdir_prefix)
        rst = @suppress_out execute_task(t; workdir=workdir_prefix)
        out = @capture_out execute_task(t; workdir=workdir_prefix)
        @test dirs == ["scripts"]
        @test rst == ""
        @test out == "55\n"
    end

    # check if we can successfully suppress stdout/stderr
    taskinfo["run"] = Dict(
        "command" => "julia --startup=no scripts/log_println_sum.jl",
        "enable_stdout" => false,
        "enable_stderr" => false,
        "capture" => true,
    )
    t = from_dict(SimpleTask, taskinfo)
    exec = build_runner(t)
    dirs, rst = with_sandbox(includes=[scripts_dir]) do
        readdir(workdir_prefix), execute_task(t; workdir=workdir_prefix)
    end
    @test dirs == ["scripts"]
    @test rst == "55"

    # strict mode: error
    taskinfo["run"] = Dict(
        "command" => "julia --startup=no nothing.jl",
        "strict" => true,
        "enable_stderr" => false
    )
    t = from_dict(SimpleTask, taskinfo)
    exec = build_runner(t)
    @test exec.strict == true
    try
        execute_task(t)
    catch err
        @test err == ShellExecutionError("failed to execute command `julia --startup=no nothing.jl`: non-zero exit code: 1")
    end

    # non-strict mode: warning instead of error
    taskinfo["run"] = Dict(
        "command" => "julia --startup=no nothing.jl",
        "strict" => false
    )
    t = from_dict(SimpleTask, taskinfo)
    exec = build_runner(t)
    @test exec.strict == false
    msg = @capture_err execute_task(t)
    @test occursin("SystemError: opening file", msg) || occursin("could not open file", msg)
    @test occursin("failed to execute command `julia --startup=no nothing.jl`", msg)

    # env passing
    taskinfo["run"] = Dict(
        "command" => "julia --startup=no scripts/envcheck.jl",
        "capture" => true,
    )
    t = from_dict(SimpleTask, taskinfo)
    exec = build_runner(t)
    dirs, rst = with_sandbox(includes=[scripts_dir]) do
        # this would otherwise fail if `env=nothing`
        env=copy(ENV); env["HOWLONG"] = "forever!"
        readdir(workdir_prefix), execute_task(t; workdir=workdir_prefix, env=env)
    end
    @test dirs == ["scripts"]
    @test rst == "forever!"

    # check command split
    # cmd = "echo 'hello world'"
    # `echo 'hello world'` is different from `$(cmd)`
    taskinfo["run"] = Dict(
        "command" => "julia --startup=no -e 'println(\"hello world\")'",
        "capture" => true
    )
    t = from_dict(SimpleTask, taskinfo)
    exec = build_runner(t)
    rst = execute_task(t)
    @test rst == "hello world"
end
