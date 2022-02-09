using Workflows
using Test

@testset "Workflows.jl" begin
    @info "run dialects test"
    @testset "dialects" begin
        include("dialects/foreign.jl")
        include("dialects/manifest.jl")
        include("dialects/config_io.jl")
    end
end
