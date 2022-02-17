src_file = get(ENV, "WORKFLOW_TMP_INFILE", "")
@assert isfile(src_file) "file $src_file not existed"

using JSON3
using DataFrames
using CSV

data = open(src_file) do io
    JSON3.read(io)
end

dfs = map(collect(keys(data))) do tid
    DataFrame(JSON3.read.(data[tid]))
end

df = reduce(dfs) do X, Y
    outerjoin(X, Y; on=intersect(names(X), names(Y)), matchmissing=:equal)
end

mkpath("reports")
CSV.write("reports/results.csv", df)
