using JSON3

rst = Dict()
rst["exp"] = @elapsed sum(exp, 1:10)

mkpath("test_outs")
open(joinpath("test_outs", "exp.json"), "w") do io
    JSON3.write(io, rst)
end

# this message will be discarded for shell runner with `enable_stdout=false`
println("You should not see this message!")
@warn "You should not see this message!"
