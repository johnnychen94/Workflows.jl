module ForeignTypeTest

using Test
using Workflows.Dialects: task_id, task_name, task_deps, task_outs, task_groups
using Workflows.Dialects: runner_type, runner_info
using Workflows.Dialects: load_config, save_config
using Workflows.Dialects: AbstractTask

struct ForeignTask <: AbstractTask end

@testset "foreign" begin

@testset "foreign task" begin
    t = ForeignTask()
    @test_throws ErrorException task_id(t)
    @test_throws ErrorException task_name(t)
    @test_throws ErrorException task_deps(t)
    @test_throws ErrorException task_outs(t)
    @test_throws ErrorException task_groups(t)
    @test_throws ErrorException runner_type(t)
    @test_throws ErrorException runner_info(t)
end


@testset "foreign dialect" begin
    config_filename = joinpath(@__DIR__, "examples", "foreign", "foreign.toml")
    err = ErrorException("unsupported workflow dialect \"foreign\".")
    @test_throws err load_config(config_filename)
end

end #testset

end #module
