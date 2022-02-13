using JSON3

# This environment variable is set before the task execution process is spawned
src_file = ENV["WORKFLOW_TMP_INFILE"]

@assert isfile(src_file)

data = open(src_file, "r") do io
    JSON3.read(io)
end |> Dict

extra = open(joinpath("test_outs", "exp.json")) do io
    JSON3.read(io)
end |> Dict

merge!(data, extra)

mkpath("test_outs")
open(joinpath("test_outs", "results.json"), "w") do io
    JSON3.write(io, data)
end
