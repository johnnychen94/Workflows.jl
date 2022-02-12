using JSON3

rst = Dict{Int,Float64}()
for sz in [10, 100, 1000]
    x = 1:sz
    sum(x)
    rst[sz] = @elapsed sum(x)
end

JSON3.write(rst)
