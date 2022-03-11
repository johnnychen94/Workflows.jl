module LoopTaskTest

using Workflows: load_config
using Workflows.Dialects: LoopTask, SimpleTask
using Workflows.Dialects: task_id, task_groups
using Workflows.Dialects: runner_type, runner_info
using Workflows.Runners: execute_task
using Test

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
    @test all(t->runner_info(t)["capture_stdout"] == true, unrolled)
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
    msg = "Ambiguous \"matrix\" configuration: [Dict(\"b\" => \"6\", \"a\" => \"5\")] are listed in both \"includes\" and \"excludes\"."
    @test_throws ErrorException(msg) collect(w.tasks["1"])
end

end # module
