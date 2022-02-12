using JSON3

rst = Dict{Int,Float64}()
for sz in [1000, 2000, 3000]
    x = 1:sz
    sum(x)
    rst[sz] = @elapsed sum(x)
end

print(JSON3.write(rst))
