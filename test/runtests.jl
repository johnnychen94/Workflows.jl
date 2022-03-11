using Configurations
using JSON3
using Workflows
using Workflows.Dialects: SimpleTask
using Workflows.Runners: execute_task, build_runner, capture_run
using Workflows.Runners: ShellExecutionError
using Workflows.Runners: JuliaModuleRunner, ShellRunner
using Suppressor
using Test
using TOML

include("testutils.jl")

@testset "Workflows.jl" begin
    @info "test TaskGraph"
    @testset "TaskGraphs" begin
        include("taskgraphs.jl")
    end

    @info "test StringPatterns"
    @testset "StringPatterns" begin
        include("stringpatterns.jl")
    end

    @info "test dialects"
    @testset "dialects" begin
        include("dialects/foreign.jl")
        include("dialects/manifest.jl")
        include("dialects/manifest_runner.jl")
        include("dialects/looptask.jl")
        include("dialects/config_io.jl")
        include("dialects/workflow_ops.jl")
    end

    @info "test runners"
    @testset "runners" begin
        include("runners/juliamodule.jl")
        include("runners/shell.jl")
    end

    @info "test schduler"
    include("scheduler.jl")
end
