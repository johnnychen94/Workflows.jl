module WorkflowsOpsTest

using Workflows
using Workflows.Configurations
using Workflows.Dialects: LoopTask, TaskVector
using Workflows.Dialects: task_id, task_name
using Workflows.Dialects: workflow_tasks
using Test

@testset "workflow operations" begin
    example_dir = joinpath(@__DIR__, "examples", "manifest", "good")
    @testset "filter" begin
        filename = joinpath(example_dir, "filter.toml")
        w = Workflows.load_config(filename)
        @test sort!(map(t->task_id(t), workflow_tasks(w))) == ["1", "2", "3", "4_1", "4_2", "5"]

        w1 = filter(x->true, w)
        @test w == w1
        @test w !== w1

        sw = filter(w) do t
            task_id(t) == "4_1"
        end
        sw1 = filter(w) do t
            task_name(t) == "summary_single"
        end
        @test sw == sw1
        @test sort!(map(t->task_id(t), workflow_tasks(sw))) == ["1", "2", "4_1"]

        sw = filter(w) do t
            task_id(t) == "4_2"
        end
        @test sort!(map(t->task_id(t), workflow_tasks(sw))) == ["3", "4_2"]

        sw = filter(w) do t
            task_id(t) == "5"
        end
        @test w == sw

        sw = filter(w; strict=false) do t
            task_id(t) == "5"
        end
        @test sort!(map(t->task_id(t), workflow_tasks(sw))) == ["5"]
    end

    @testset "merge" begin
        w1 = Workflows.load_config(joinpath(example_dir, "merge_1.toml"))
        w2 = Workflows.load_config(joinpath(example_dir, "merge_2.toml"))
        w3 = Workflows.load_config(joinpath(example_dir, "merge_3.toml"))

        w = merge(w1, w2)
        w_ref = Workflows.load_config(joinpath(example_dir, "merge_12.toml"))
        @test w.version == w_ref.version
        @test w.dialect == w_ref.dialect
        @test w.tasks == w_ref.tasks

        w = merge(w1, w2, w3)
        w_ref = Workflows.load_config(joinpath(example_dir, "merge_123.toml"))
        @test w.version == w_ref.version
        @test w.dialect == w_ref.dialect
        @test w.tasks == w_ref.tasks

        # except for Vector and Dict, conflicts are not allowed
        w1 = Workflows.load_config(joinpath(example_dir, "merge_1.toml"))
        w2 = Workflows.load_config(joinpath(example_dir, "merge_2.toml"))
        w2.tasks["4"].run["command"] = "other commands"
        @test_throws ErrorException("failed to merge task id 4: conflict detected.") merge(w1, w2)

        w1 = Workflows.load_config(joinpath(example_dir, "merge_1.toml"))
        w2 = Workflows.load_config(joinpath(example_dir, "merge_2.toml"))
        w2_config = to_dict(w2)
        w2_config["tasks"][1]["name"] = "another name"
        w2 = from_dict(typeof(w2), w2_config)
        @test_throws ErrorException("failed to merge task id 4: conflict detected.") merge(w1, w2)

        @testset "LoopTask" begin
            w1 = Workflows.load_config(joinpath(example_dir, "merge_loop_1.toml"))
            w2 = Workflows.load_config(joinpath(example_dir, "merge_loop_2.toml"))
            w3 = Workflows.load_config(joinpath(example_dir, "merge_loop_3.toml"))

            w = merge(w1, w2)
            w_ref = Workflows.load_config(joinpath(example_dir, "merge_loop_12.toml"))
            @test w.version == w_ref.version
            @test w.dialect == w_ref.dialect
            # task "4" needs special comparison: the order, id, definition layout might be different,
            # but the overall generated tasks are the same.
            @test w.tasks["4"] isa TaskVector
            @test w_ref.tasks["4"] isa LoopTask
            w_task4 = w.tasks["4"].tasks
            w_ref_task4 = collect(w_ref.tasks["4"])
            @test setdiff(map(t->t.run["command"], w_task4), map(t->t.run["command"], w_ref_task4)) |> isempty
            # and test for other tasks
            delete!(w.tasks, "4")
            delete!(w_ref.tasks, "4")
            @test w.tasks == w_ref.tasks

            w = merge(w1, w2, w3)
            w_ref = Workflows.load_config(joinpath(example_dir, "merge_loop_123.toml"))
            @test w.version == w_ref.version
            @test w.dialect == w_ref.dialect
            # task "4" needs special comparison: the order, id, definition layout might be different,
            # but the overall generated tasks are the same.
            @test w.tasks["4"] isa TaskVector
            @test w_ref.tasks["4"] isa LoopTask
            w_task4 = w.tasks["4"].tasks
            w_ref_task4 = collect(w_ref.tasks["4"])
            @test setdiff(map(t->t.run["command"], w_task4), map(t->t.run["command"], w_ref_task4)) |> isempty
            # and test for other tasks
            delete!(w.tasks, "4")
            delete!(w_ref.tasks, "4")
            @test w.tasks == w_ref.tasks
        end
    end
end

end
