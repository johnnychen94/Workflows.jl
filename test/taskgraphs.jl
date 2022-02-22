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
        # Cyclic graph can be constructed, but it has merely no usage. We might want to
        # introduce more eager check on it in the future.
        nodes = [
            TaskNode(1, [3, ]),
            TaskNode(2, [1, ]),
            TaskNode(3, [2, ])
        ]
        @test_nowarn TaskGraph(nodes)
    end

    @testset "repeated node IDs" begin
        # repeated node ids are not allowed
        nodes = [
            TaskNode(1, [2]),
            TaskNode(2, [3]),
            TaskNode(3, []),
            TaskNode(1, [2]),
        ]
        @test_throws ArgumentError("Duplicate node IDs are not allowed: [1]") TaskGraph(nodes)
    end
end

@testset "prenodes" begin
    # DAG
    same_nodes(X, Y) = length(setdiff(map(n->n.id, X), map(n->n.id, Y))) == 0
    nodes = [
        TaskNode(1, []),
        TaskNode(2, []),
        TaskNode(3, [1]),
        TaskNode(4, [1, 6]),
        TaskNode(5, [2, 4]),
        TaskNode(6, [1]),
        TaskNode(7, [4]),
        TaskNode(8, [7]),
        TaskNode(9, [5, 7]),
    ]
    graph = TaskGraph(nodes)
    @test prenodes(graph, 9) == prenodes(graph, nodes[9])
    @test same_nodes(prenodes(graph, 1), nodes[[]])
    @test same_nodes(prenodes(graph, 2), nodes[[]])
    @test same_nodes(prenodes(graph, 3), nodes[[1]])
    @test same_nodes(prenodes(graph, 4), nodes[[1, 6]])
    @test same_nodes(prenodes(graph, 5), nodes[[1, 2, 4, 6]])
    @test same_nodes(prenodes(graph, 6), nodes[[1]])
    @test same_nodes(prenodes(graph, 7), nodes[[1, 4, 6]])
    @test same_nodes(prenodes(graph, 8), nodes[[1, 4, 6, 7]])
    @test same_nodes(prenodes(graph, 9), nodes[[1, 2, 4, 5, 6, 7]])

    # cyclic graph is not allowed
    nodes = [
        TaskNode(1, [2]),
        TaskNode(2, [3]),
        TaskNode(3, [1]),
    ]
    graph = TaskGraph(nodes)
    @test_throws ErrorException("Cycle graph detected around node id 2.") prenodes(graph, 1)
    @test_throws ErrorException("Cycle graph detected around node id 3.") prenodes(graph, 2)
    @test_throws ErrorException("Cycle graph detected around node id 1.") prenodes(graph, 3)
end

@testset "min_subgraph" begin
    same_nodes(X, Y) = length(setdiff(map(n->n.id, X), map(n->n.id, Y))) == 0
    nodes = [
        TaskNode(1, []),
        TaskNode(2, []),
        TaskNode(3, [1]),
        TaskNode(4, [1, 6]),
        TaskNode(5, [2, 4]),
        TaskNode(6, [1]),
        TaskNode(7, [4]),
        TaskNode(8, [7]),
        TaskNode(9, [5, 7]),
    ]
    graph = TaskGraph(nodes)
    sg = min_subgraph(graph, [5,7])
    @test sg.ids == [2, 4, 1, 6, 5, 7]
    @test sg.matrix == Bool[
        0  0  0  0  1  0
        0  0  0  0  1  1
        0  1  0  1  0  0
        0  1  0  0  0  0
        0  0  0  0  0  0
        0  0  0  0  0  0
    ]
    @test all([nodes[i] == sg[i] for i in sg.ids])
end

end #module
