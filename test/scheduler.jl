@testset "scheduler" begin
    examples_dir = joinpath(@__DIR__, "examples")

    @testset "manifest" begin
        # cleanup before running test so that we don't get affected by previous runs
        rm(joinpath(examples_dir, "manifest", ".workflows"), recursive=true, force=true)
        rm(joinpath(examples_dir, "manifest", "test_outs"), recursive=true, force=true)

        with_sandbox(includes=["examples"]) do
            workdir = joinpath("examples", "manifest")

            filename = joinpath(workdir, "simple.toml")
            msg = @capture_out @suppress_err Workflows.execute(filename)
            # msg = @capture_out Workflows.execute(filename) # debug
            results = @test_nowarn JSON3.read(msg)

            @test sort!(String.(keys(results))) == ["1", "2", "exp"]
            @test sort!(String.(keys(JSON3.read(results["1"])))) == ["10", "100", "1000"]
            @test sort!(String.(keys(JSON3.read(results["2"])))) == ["1000", "2000", "3000"]
            @test results[:exp] isa Float64

            @test issubset([".workflows", "test_outs", "Manifest.toml"], readdir(workdir))
            @test strip(read(joinpath(workdir, "test_outs", "results.json"), String)) == strip(msg)
        end

        with_sandbox(includes=["examples"]) do
            workdir = joinpath("examples", "manifest")

            filename = joinpath(workdir, "loop.toml")
            msg = @capture_out @suppress_err Workflows.execute(filename)
            # msg = @capture_out Workflows.execute(filename) # debug
            results = @test_nowarn JSON3.read(msg)
            @test results[:exp] isa Float64
            @test results[:sum] == ["3", "5", "5", "7", "7", "9", "16", "4"]

            @test issubset([".workflows", "test_outs", "Manifest.toml"], readdir(workdir))
            @test strip(read(joinpath(workdir, "test_outs", "results.json"), String)) == strip(msg)
        end
    end
end
