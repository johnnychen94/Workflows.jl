module TaskGraphsTest

using Workflows.TaskGraphs
using Test

@testset "TaskNode" begin
    @test_nowarn @inferred TaskNode(1, [2, 3])
    @test_nowarn @inferred TaskNode("node_3", ["node_1", "node_2"])
    @test_throws Exception TaskNode(1, [2.2, ])
    @test_throws Exception TaskNode("node_3", [1, 2])
    @test_throws Exception TaskNode("node_3", ["node_1", "node_3"])
    # @test_throws Exception TaskNode("node_3", ["node_1", "node_1"])

    @test TaskNode(1, [2, 3]) == TaskNode(1, [2, 3]) # check ==
end

@testset "TaskGraph" begin
    nodes = [
        TaskNode(1, []),
        TaskNode(3, [1, ]),
        TaskNode(2, [1, 3])
    ]
    graph = @inferred TaskGraph(nodes)
    @test graph.ids == [1, 3, 2]
    @test graph[1] == nodes[1]
    @test graph[3] == nodes[2]

    d = Dict(n.id=>n for n in nodes)
    graph = TaskGraph(d)
    @test graph[1] == nodes[1]
    @test graph[3] == nodes[2]

    # id can be of "any" type
    nodes = [
        TaskNode("1", []),
        TaskNode("3", ["1", ]),
        TaskNode("2", ["1", "3"])
    ]
    graph = TaskGraph(nodes)
    @test_throws MethodError graph[1]
    @test graph["1"] == nodes[1]
    @test graph["3"] == nodes[2]
    @test sort(graph.ids) == ["1", "2", "3"]

    @testset "cyclic graph" begin
            # Cyclic graph can be constructed, but it has merely no usage. We might want to introduce
        # more eager check on it in the future.
        nodes = [
            TaskNode(1, [3, ]),
            TaskNode(2, [1, ]),
            TaskNode(3, [2, ])
        ]
        @test_nowarn TaskGraph(nodes)
    end
end

end #module
