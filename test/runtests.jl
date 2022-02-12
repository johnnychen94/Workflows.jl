using Configurations
using Workflows.Dialects: SimpleTask
using Workflows.Runners: execute_task, build_runner, capture_run
using Workflows.Runners: JuliaModuleRunner
using Suppressor
using Test
using TOML

include("testutils.jl")

@testset "Workflows.jl" begin
    @info "run dialects test"
    @testset "dialects" begin
        include("dialects/foreign.jl")
        include("dialects/manifest.jl")
        include("dialects/config_io.jl")
    end

    @testset "runners" begin
        include("runners/juliamodule.jl")
    end
end
