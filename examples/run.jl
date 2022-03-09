# script to run all examples in `examples/` directory

using Workflows

files = [
    joinpath("manifest", "benchmark.toml"),
    joinpath("manifest_loop", "benchmark.toml"),
    joinpath("manifest_loop", "benchmark.yml"),
]

for f in files
    @info "Run workflow" file=f
    Workflows.execute(joinpath(@__DIR__, f))
end
