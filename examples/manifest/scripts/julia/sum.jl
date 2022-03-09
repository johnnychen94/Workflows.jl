using LinearAlgebra
using BenchmarkTools
using JSON3
include(joinpath(@__DIR__, "utils.jl"))

rst = Dict()
for n in [64, 128, 256, 512, 1024, 2048, 4096, 8192]
    x = rand(n)
    b = @benchmark sum($x) samples=100 evals=1
    rst[n] = trial_to_dict(b)
end

JSON3.write(rst)
