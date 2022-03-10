module ManifestRunnerDialectTest

using Configurations
using TOML
using Workflows: load_config
using Workflows.Dialects: ManifestWorkflow, CustomRunnerWorkflow
using Suppressor
using Test

@testset "manifest_runner" begin
    @testset "positive cases" begin
        # manifest_runner dialect is an incremental build of manifest
        casedir = joinpath(@__DIR__, "examples", "manifest", "good")

        config = TOML.parsefile(joinpath(casedir, "standard.toml"))
        w1 = from_dict(ManifestWorkflow, config)
        config["dialect"] = "manifest_runner"
        w2 = from_dict(CustomRunnerWorkflow, config)
        w3 = convert(ManifestWorkflow, w2)
        @test w1 isa ManifestWorkflow
        @test w2 isa CustomRunnerWorkflow
        @test w3 isa ManifestWorkflow
        @test w1 == w3


        casedir = joinpath(@__DIR__, "examples", "manifest_runner", "good")

        w1 = @test_nowarn load_config(joinpath(casedir, "mix.yml"))
        w2 = load_config(joinpath(casedir, "mix_ref.yml"))
        @test w1 isa CustomRunnerWorkflow
        @test w2 isa ManifestWorkflow
        w3 = convert(ManifestWorkflow, w1)
        @test w2 == w3

        # custom runner + matrix
        w1 = @test_nowarn load_config(joinpath(casedir, "matrix.yml"))
        w2 = load_config(joinpath(casedir, "matrix_ref.yml"))
        w3 = convert(ManifestWorkflow, w1)
        @test w2 == w3

        # run field is ignored but there will be warning messages
        w1 = load_config(joinpath(casedir, "run_override.yml"))
        w2 = load_config(joinpath(casedir, "run_override_ref.yml"))
        w3 = @suppress_err convert(ManifestWorkflow, w1)
        @test w2 == w3
        msg = @capture_err convert(ManifestWorkflow, w1)
        @test occursin("\"run\" field for task \"julia1\" is overridden by custom runner \"julia\".", msg)
    end

    # TODO(johnnychen94): add negative cases
end

end
