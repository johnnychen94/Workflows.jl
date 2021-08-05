using ImageMorphology
using TestImages
using BenchmarkTools, JSON3

img = TestImages.shepp_logan(400)

rst = @benchmark erode($img, 1) seconds=1

Dict(
    "memory" => rst.memory, # byte
    "time" => median(rst.times)/1e6, # ms
) |> JSON3.write
