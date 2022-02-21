module WorkflowsOpsTest

using Workflows
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
end

end
