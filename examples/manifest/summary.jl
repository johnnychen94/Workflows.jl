src_file = get(ENV, "WORKFLOW_TMP_INFILE", "")
@assert isfile(src_file) "file $src_file not existed"

using JSON3
using DataFrames
using CSV
using PrettyTables

data = open(src_file) do io
    JSON3.read(io)
end

# flatten and merge results into one single big dataframe
dfs = map(String.(keys(data))) do tid
    X = JSON3.read(data[tid])
    X_df = map(collect(keys(X))) do sz
        d = Dict(X[sz])
        d[:size] = parse(Int, String(sz))
        d[:tid] = tid
        d
    end |> DataFrame
end
df = reduce(dfs) do X, Y
    outerjoin(X, Y; on=intersect(names(X), names(Y)), matchmissing=:equal)
end

# format markdown reports
buffer = IOBuffer()
for df_sz in groupby(df, :size)
    println(buffer, "# size: ", df_sz[!, :size][1], "\n")

    # drop the types line provided by DataFrames
    tmp_buffer = IOBuffer()
    PrettyTables.pretty_table(
        tmp_buffer,
        df_sz;
        tf=PrettyTables.tf_markdown)
    lines = split(String(take!(tmp_buffer)), "\n")
    println(buffer, lines[1])
    foreach(l->println(buffer, l), lines[3:end])

    println(buffer)
end

# save final results
isdir("reports") || mkdir("reports")
CSV.write("reports/results.csv", df)
write("reports/report.md", take!(buffer))
