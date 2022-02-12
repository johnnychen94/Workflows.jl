const _sandbox_root = mktempdir()

"""
    with_sandbox(f; includes=[""])

run function `f()` in a simple sandbox directory, with `includes` copied there.

# Examples

```julia
julia> with_sandbox() do
    pwd()
end
"/private/var/folders/34/km3mmt5930gc4pzq1d08jvjw0000gn/T/jl_rNgOVo/jl_BSkXtM"

julia> with_sandbox(includes=["scripts", "not_exists"]) do
    readdir()
end
┌ Warning: source path not existed
│   path = "not_exists"
└ @ Main REPL[35]:9
1-element Vector{String}:
"scripts"
```
"""
function with_sandbox(f; includes::Vector{String}=String[], follow_symlinks=false)
    sandbox_root = mktempdir(_sandbox_root)
    for src_path in includes
        dst_path = joinpath(sandbox_root, relpath(abspath(src_path)))
        if ispath(src_path)
            mkpath(dirname(dst_path))
            cp(src_path, dst_path; follow_symlinks=follow_symlinks)
        else
            @warn "source path not existed" path=src_path
        end
    end
    cd(f, sandbox_root)
end
