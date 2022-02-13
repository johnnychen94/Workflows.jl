module ManifestDialectTest

using Configurations
using Workflows
using Workflows.Dialects
using Workflows.Dialects: ManifestWorkflow
using Workflows.Dialects: PipelineOrder
using Workflows.Dialects: task_id, task_name, task_groups, task_deps, task_outs
using Workflows.Dialects: runner_type, runner_info
using Test
using TOML

function load_back(w)
    io = IOBuffer()
    to_toml(io, w)
    config = TOML.parse(String(take!(io)))
    from_dict(ManifestWorkflow, config)
end

@testset "manifest" begin
    @testset "properties" begin
        casedir = joinpath(@__DIR__, "examples", "manifest", "good")

        filename = joinpath(casedir, "standard.toml")
        w = from_toml(ManifestWorkflow, filename)
        w2 = load_back(w)
        @test w == w2
    end

    @testset "positive cases" begin
        casedir = joinpath(@__DIR__, "examples", "manifest", "good")

        # test default options
        filename = joinpath(casedir, "optional.toml")
        w = from_toml(ManifestWorkflow, filename)
        t = w.tasks["1"]
        @test task_name(t) == "task1"
        @test task_id(t) == "1"
        @test task_groups(t) == String[] # optional
        @test task_deps(t) == String[] # optional
        @test task_outs(t) == String[] # optional
        @test runner_type(t) == "juliamodule"
        @test runner_info(t)["script"] == "main.jl"

        # ensure default options will be correctly overridden by user configurations
        filename = joinpath(casedir, "optional_custom.toml")
        w = from_toml(ManifestWorkflow, filename)
        t = w.tasks["1"]
        @test runner_info(t)["workdir"] == "somewhere"
        @test task_groups(t) == String["groupA", "groupB"]
        @test task_deps(t) == String["dirA", "fileB"]
        @test task_outs(t) == String["@__STDOUT__"]

        # order can be Vector{String}
        filename = joinpath(casedir, "flat_order.toml")
        w = from_toml(ManifestWorkflow, filename)
        @test w.order isa PipelineOrder
        @test w.order.stages == [["1"], ["2"]]

        # empty workflow is allowed
        filename = joinpath(casedir, "empty.toml")
        w = from_toml(ManifestWorkflow, filename)
        @test length(w.tasks) == 0
        @test w.order isa PipelineOrder
        @test length(w.order.stages) == 0
    end

    @testset "negative cases" begin
        casedir = joinpath(@__DIR__, "examples", "manifest", "bad")

        # task ID should be unique across the workflow
        filename = joinpath(casedir, "duplicate_taskid.toml")
        err = ArgumentError("duplicate tasks detected: [\"1\"].")
        @test_throws err from_toml(ManifestWorkflow, filename)

        # DAG required: one task can't be executed multiple times
        filename = joinpath(casedir, "duplicate_order.toml")
        err = ArgumentError("duplicate tasks detected in \"order\": [\"1\"].")
        @test_throws err from_toml(ManifestWorkflow, filename)

        # each task defined in the workflow should have a well-defined execution order
        filename = joinpath(casedir, "missing_order.toml")
        err = ArgumentError("some tasks are not defined in \"order\": [\"2\"].")
        @test_throws err from_toml(ManifestWorkflow, filename)

        # each item listed in the order should have a corresponding task
        filename = joinpath(casedir, "missing_task.toml")
        err = ArgumentError("\"order\" contains some undefined tasks: [\"3\"].")
        @test_throws err from_toml(ManifestWorkflow, filename)
    end
end

end
