module ConfigIOTest

using Workflows
using Workflows.Dialects
using Workflows: load_config, save_config
using Workflows.Dialects: ManifestWorkflow
using Suppressor
using Test

const tmp_testdir = mktempdir()
const example_dir = joinpath(@__DIR__, "examples")

@testset "config io" begin
    # More comprehensive parsing test goes to dialects, here we only ensure that the
    # `load_config` and `save_config` works as expected.

    tmpfile = joinpath(tmp_testdir, "tmp.toml")
    config_filename = joinpath(example_dir, "manifest", "good", "standard.toml")
    w = load_config(config_filename)
    @test w isa ManifestWorkflow
    save_config(tmpfile, w)
    w2 = load_config(tmpfile)
    @test w == w2
    # also test that YAML file are parsed exactly the same as TOML file
    config_filename = joinpath(example_dir, "manifest", "good", "standard.yml")
    w3 = load_config(config_filename)
    @test w == w3

    # extension sensitive
    tmptxt = joinpath(tmp_testdir, "tmp.txt")
    err = ArgumentError("unsupported file extension: \".txt\".")
    @test_throws err save_config(tmptxt, w)
    cp(tmpfile, tmptxt)
    @test_throws err load_config(tmptxt)

    @testset "version compat" begin
        # warn when we load a file with too new version
        config_filename = joinpath(example_dir, "manifest", "good", "new_version.toml")
        w = @test_nowarn @suppress_err load_config(config_filename)
        msg = @capture_err load_config(config_filename)
        @test occursin("workflow file version 999.999.999 might not be compatible", msg)

        # save config with current dialect version
        tmpfile = joinpath(tmp_testdir, "tmp.toml")
        save_config(tmpfile, w)
        w = @test_nowarn load_config(tmpfile)
        @test w.version == Dialects.spec_versions["manifest"]
    end
end
end
