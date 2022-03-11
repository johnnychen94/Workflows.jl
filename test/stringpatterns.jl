module StringPatternsTest

using Workflows.StringPatterns
using Test

@testset "render" begin
    @testset "string" begin
        msg = raw"echo ${{ matrix.greet}}, ${{ matrix.name   }}"

        config = Dict("matrix" => Dict("greet" => "hello", "name" => "world"))
        @test "echo hello, world" == render(msg, config)

        # extra patterns are ignored
        config = Dict("matrix" => Dict("greet" => "hello", "name" => "world"), "spam" => nothing)
        @test render(msg, config) == "echo hello, world"

        # all occurences of the same name are substituted
        msg = raw"echo ${{ matrix.greet }}, ${{ matrix.name }}, ${{ matrix.greet }}"
        config = Dict("matrix" => Dict("greet" => "hello", "name" => "world"))
        @test render(msg, config) == "echo hello, world, hello"

        config = Dict("a" => Dict("b" => 3))
        @test "3" == render(raw"${{ a.b }}", config)

        config = Dict("a" => [1, 2])
        @test "1 2" == render(raw"${{ a }}", config)
        @test "1" == render(raw"${{ a[1] }}", config)

        config = Dict("a"=>[Dict("b"=>[1, 2]), Dict("b"=>[3, 4])])
        @test "1 2" == render(raw"${{ a[1].b }}", config)
        @test "3" == render(raw"${{ a[2].b[1] }}", config)

        @test "." == render(".", Dict())

        # missing entries is not allowed; we want to eagerly check potential errors
        config = Dict{String,Any}()
        @test_throws KeyError render(raw"${{ a }}", config)

        # "a.b"-like key are not allowed because it introduces ambiguity
        config = Dict{String,Any}("a.b"=>3, "a"=>Dict("b"=>4)) # "${{ a.b }}" is 3 or 4??
        @test_throws ErrorException("key \"a.b\" should not contain dot.") render(raw"${{ a.b }}", config)
    end

    @testset "dict" begin
        # test nested structures are substituted correctly
        config = Dict{String, Any}(
            "x" => raw"${{ x }}",
            "y" => [raw"${{ y1 }}", raw"${{ y2 }}", raw"${{ x }}"],
            "z" => Dict(
                "z1" => raw"${{ z1 }}",
                "z2" => [raw"${{ z21 }}", ]
            ),
        )
        patterns = Dict(
            "x" => "value:x",
            "y1" => "value:y1",
            "y2" => raw"${{ y2 }}",
            "z1" => "value:z1",
            "z21" => "value:z21",
        )
        config_new = render(config, patterns)
        @test config_new == Dict{String, Any}(
            "x" => "value:x",
            "y" => ["value:y1", raw"${{ y2 }}", "value:x"],
            "z" => Dict(
                "z1" => "value:z1",
                "z2" => ["value:z21", ]
            ),
        )
    end
end

end
