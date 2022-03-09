using LinearAlgebra
using BenchmarkTools
using JSON3
include(joinpath(@__DIR__, "utils.jl"))

n = parse(Int, ARGS[1])

x = rand(n)
b = @benchmark sum($x) samples=100 evals=1

rst = trial_to_dict(b)
rst["size"] = n
rst["name"] = "sum"
rst["framework"] = "julia"

JSON3.write(stdout, rst)
