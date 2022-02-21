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
    @info "run graph tests"
    @testset "TaskGraphs" begin
        include("taskgraphs.jl")
    end

    @info "run dialects test"
    @testset "dialects" begin
        include("dialects/foreign.jl")
        include("dialects/manifest.jl")
        include("dialects/looptask.jl")
        include("dialects/config_io.jl")
    end

    @info "run runners test"
    @testset "runners" begin
        include("runners/juliamodule.jl")
        include("runners/shell.jl")
    end

    @info "run schduler test"
    include("scheduler.jl")
end
