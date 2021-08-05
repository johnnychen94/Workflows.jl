# Usage:
# ```julia
# pkg> activate example/benchmark
# julia> include("example/benchmark/main.jl")
# ```

using Workflows

run_workflow(joinpath(@__DIR__, "Benchmark.toml"))
