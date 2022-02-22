module LoopTaskTest

using Workflows: load_config
using Workflows.Dialects: render
using Workflows.Dialects: LoopTask, SimpleTask
using Workflows.Dialects: task_id, task_name, task_groups, task_deps, task_outs
using Workflows.Dialects: runner_type, runner_info
using Workflows.Runners: execute_task
using Test

@testset "render" begin
    @testset "string" begin
        msg = raw"echo ${{ matrix.greet}}, ${{ matrix.name   }}"
        patterns = Dict{String,String}()

        # missing patterns is okay
        patterns["matrix.greet"] = "hello"
        @test render(msg, patterns) == raw"echo hello, ${{ matrix.name   }}"

        patterns["matrix.name"] = "world"
        @test render(msg, patterns) == "echo hello, world"

        # extra patterns are ignored
        patterns["something_else"] = "spam"
        @test render(msg, patterns) == "echo hello, world"

        # all occurences of the same name are substituted
        msg = raw"echo ${{ matrix.greet }}, ${{ matrix.name }}, ${{ matrix.greet }}"
        patterns = Dict("matrix.greet"=>"hello", "matrix.name"=>"world")
        @test render(msg, patterns) == "echo hello, world, hello"
    end

    @testset "dict" begin
        # test nested structures are substituted correctly
        config = Dict{String, Any}(
            "x" => raw"${{ x }}",
            "y" => [raw"${{ y1 }}", raw"${{ y2 }}", raw"${{ x }}"],
            "z" => Dict(
                "z1" => raw"${{ z1 }}",
                "z2" => [raw"${{ z21 }}", ]
            ),
        )
        patterns = Dict(
            "x" => "value:x",
            "y1" => "value:y1", # y2 missing
            "z1" => "value:z1",
            "z21" => "value:z21",
        )
        config_new = render(config, patterns)
        @test config_new == Dict{String, Any}(
            "x" => "value:x",
            "y" => ["value:y1", raw"${{ y2 }}", "value:x"],
            "z" => Dict(
                "z1" => "value:z1",
                "z2" => ["value:z21", ]
            ),
        )
    end
end

@testset "looptask" begin
    casedir = joinpath(@__DIR__, "examples", "manifest")

    w = load_config(joinpath(casedir, "good", "loop.toml"))
    t = w.tasks["1"]
    @test t isa LoopTask
    @test task_id(t) == "1"
    @test task_groups(t) == ["A", "B", "C"]
    unrolled = collect(t)
    @test length(unrolled) == 6
    @test all(t->isa(t, SimpleTask), unrolled)
    @test all(t->startswith(task_id(t), "1@"), unrolled)
    @test all(t->runner_type(t) == "shell", unrolled)
    @test all(t->runner_info(t)["capture"] == true, unrolled)
    @test all(t->task_groups(t) == ["A", "B", "C"], unrolled)
    @test runner_info(unrolled[1])["command"] == "julia --startup=no -e 'println(\"1 2\")'"
    @test runner_info(unrolled[end])["command"] == "julia --startup=no -e 'println(\"4 10\")'"

    # test loop task can be executed correctly
    rst = execute_task(t)
    # Although the execution order might be undetermined, the result order should be fixed
    @test rst == ["1 2", "1 8", "1 10", "4 2", "4 8", "4 10"]

    # duplicated includes/excludes (#23)
    w = load_config(joinpath(casedir, "good", "loop_duplicated.toml"))
    unrolled = collect(w.tasks["1"])
    @test length(unrolled) == 3

    w = load_config(joinpath(casedir, "bad", "loop_duplicated.toml"))
    msg = "Ambiguous \"matrix\" configuration: [Dict(\"matrix.b\" => \"6\", \"matrix.a\" => \"5\")] are listed in both \"includes\" and \"excludes\"."
    @test_throws ErrorException(msg) collect(w.tasks["1"])
end

end # module
