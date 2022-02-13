@testset "Runner: juliamodule" begin
    @testset "workdir" begin
        # The workdir setup is a little bit tricky here as we usually triggers the test
        # in project root dir with `pkg> test`. To successfully run the tests interactively,
        # we need to set pwd to the "test/runners" dir.
        scripts_dir = joinpath(@__DIR__, "scripts")
        workdir_prefix = basename(@__DIR__)

        taskinfo = Dict{String,Any}(
            "name" => "task1",
            "id" => "1",
            "runner" => "juliamodule",
        )

        # default workdir with relpath: `"@__DIR__"` will be replaced by `workdir="."`
        taskinfo["run"] = Dict(
            "script" => "scripts/sum.jl"
        )
        t = from_dict(SimpleTask, taskinfo)
        exec = build_runner(t)
        @test exec == JuliaModuleRunner(script="scripts/sum.jl", workdir="@__DIR__")
        dirs, rst = with_sandbox(includes=[scripts_dir]) do
            readdir(workdir_prefix), execute_task(t; workdir=workdir_prefix)
        end
        @test dirs == ["scripts"]
        @test rst == 55

        # default workdir with relpath
        taskinfo["run"] = Dict(
            "script" => "sum.jl"
        )
        t = from_dict(SimpleTask, taskinfo)
        exec = build_runner(t)
        @test exec == JuliaModuleRunner(script="sum.jl", workdir="@__DIR__")
        dirs, rst = with_sandbox(includes=[scripts_dir]) do
            # `"@__DIR__"` will be replaced by `runners/scripts`
            readdir(workdir_prefix), execute_task(t; workdir="$workdir_prefix/scripts")
        end
        @test dirs == ["scripts"]
        @test rst == 55

        # custom workdir with relpath
        taskinfo["run"] = Dict(
            "script" => "sum.jl",
            "workdir" => "$workdir_prefix/scripts"
        )
        t = from_dict(SimpleTask, taskinfo)
        exec = build_runner(t)
        @test exec == JuliaModuleRunner(script="sum.jl", workdir="$workdir_prefix/scripts")
        dirs, rst = with_sandbox(includes=[scripts_dir]) do
            # `workdir` doesn't affect here at all
            workdir = joinpath(tempdir(), "somewhere")
            readdir(workdir_prefix), execute_task(t; workdir=workdir)
        end
        @test dirs == ["scripts"]
        @test rst == 55

        # custom workdir with relpath and @__DIR__
        taskinfo["run"] = Dict(
            "script" => "sum.jl",
            "workdir" => "@__DIR__/scripts"
        )
        t = from_dict(SimpleTask, taskinfo)
        exec = build_runner(t)
        @test exec == JuliaModuleRunner(script="sum.jl", workdir="@__DIR__/scripts")
        dirs, rst = with_sandbox(includes=[scripts_dir]) do
            # "@__DIR__/scripts" will be replaced by relative path "runners/scripts"
            readdir(workdir_prefix), execute_task(t; workdir=workdir_prefix)
        end
        @test dirs == ["scripts"]
        @test rst == 55

        # check if we can successfully suppress stdout/stderr
        taskinfo["run"] = Dict(
            "script" => "scripts/verbose_sum.jl",
            "enable_stdout" => false,
            "enable_stderr" => false
        )
        t = from_dict(SimpleTask, taskinfo)
        exec = build_runner(t)
        rst = with_sandbox(includes=[scripts_dir]) do
            execute_task(t; workdir=workdir_prefix)
        end
        @test rst == 55

        # by default, it's strict mode
        taskinfo["run"] = Dict(
            "script" => "scripts/error_sum.jl",
        )
        t = from_dict(SimpleTask, taskinfo)
        exec = build_runner(t)
        with_sandbox(includes=[scripts_dir]) do
            try
                execute_task(t; workdir=workdir_prefix)
            catch err
                @test err isa ErrorException
                @test err.msg == "Hi 你好"
            end
        end

        # but we can suppress exception with warnings
        taskinfo["run"] = Dict(
            "script" => "scripts/error_sum.jl",
            "strict" => false
        )
        t = from_dict(SimpleTask, taskinfo)
        exec = build_runner(t)
        with_sandbox(includes=[scripts_dir]) do
            msg = @capture_err execute_task(t; workdir=workdir_prefix)
            @test occursin("Warning: failed to execute task 1 in juliamodule runner", msg)
            @test occursin("err = Hi 你好", msg)
        end

        # custom workdir with abspath and @__DIR__
        taskinfo["run"] = Dict(
            "script" => "sum.jl",
            "workdir" => joinpath(pwd(), "@__DIR__/scripts")
        )
        t = from_dict(SimpleTask, taskinfo)
        exec = build_runner(t)
        @test exec == JuliaModuleRunner(script="sum.jl", workdir=joinpath(pwd(), "@__DIR__/scripts"))
        dirs, rst = with_sandbox() do
            # This might be a little bit unintuitive
            # "$(pwd())/@__DIR__/scripts" will be replaced by absolute path "$(pwd())/runners/scripts"
            readdir(), execute_task(t; workdir=workdir_prefix)
        end
        @test dirs == []
        @test rst == 55

        # custom workdir with abspath
        taskinfo["run"] = Dict(
            "script" => "sum.jl",
            "workdir" => scripts_dir
        )
        t = from_dict(SimpleTask, taskinfo)
        exec = build_runner(t)
        @test exec == JuliaModuleRunner(script="sum.jl", workdir=scripts_dir)
        dirs, rst = with_sandbox() do
            # `workdir` doesn't affect here at all
            workdir = joinpath(tempdir(), "somewhere")
            readdir(), execute_task(t; workdir=workdir)
        end
        @test dirs == []
        @test rst == 55
    end
end
