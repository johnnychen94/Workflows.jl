using LinearAlgebra
using BenchmarkTools
using JSON3
include(joinpath(@__DIR__, "utils.jl"))

n = parse(Int, ARGS[1])

b = @benchmark rand($n) samples=100 evals=1

rst = trial_to_dict(b)
rst["size"] = n
rst["name"] = "rand"
rst["framework"] = "julia"

JSON3.write(stdout, rst)
