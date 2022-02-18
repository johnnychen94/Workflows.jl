# A light implementation of graphs to avoid dependencies to Graphs.jl
module TaskGraphs

export TaskNode, TaskGraph
export prenodes, min_subgraph

using SparseArrays

"""
    TaskNode(id, parents)

Build a task node.

## Fields

- `id{T}`: id of the current task node
- `parents::Vector{T}`: ids of parent nodes

## Examples

```jldoctest; setup=:(using Workflows.TaskGraphs)
julia> TaskNode(5, [1, 3]) # TaskNode 5 with parent nodes: 1 and 3
TaskNode{Int64}(5, [1, 3])

julia> TaskNode("task3", ["task1", "task2"]) # task node "task3" with parent nodes: "task1" and "task2"
TaskNode{String}("task2", ["task1"])
```
"""
struct TaskNode{T}
    id::T
    parents::Vector{T}
    function TaskNode{T}(id::T, parents::Vector{T}) where T
        id in parents && error("A node can not be parents of itself.")
        # Checking duplication of `parents` might introduce unnecessary computations and
        # memory allocations. Thus we don't check it here for now.
        new{T}(id, parents)
    end
    TaskNode(id::T, parents::Vector) where T = TaskNode{T}(id, convert(Vector{T}, parents))
end

Base.:(==)(a::TaskNode, b::TaskNode) = a.id == b.id && a.parents == b.parents

"""
    TaskGraph(nodes::Vector{TaskNode})

Build the DAG task graph from nodes.

## Fields

- `ids::Vector{T}`: ids of all nodes
- `matrix::SparseMatrixCSC{Bool,Int}`: adjacency matrix of the graph

## Examples

```jldoctest; setup=:(using Workflows.TaskGraphs)
julia> nodes = [TaskNode(1, []), TaskNode(3, []), TaskNode(5, [1, 3]), TaskNode(6, [1, 5])]
4-element Vector{TaskNode{Int64}}:
 TaskNode{Int64}(1, Int64[])
 TaskNode{Int64}(3, Int64[])
 TaskNode{Int64}(5, [1, 3])
 TaskNode{Int64}(6, [1, 5])

julia> G = TaskGraph(nodes);

julia> G.ids
4-element Vector{Int64}:
 1
 3
 5
 6

julia> G.matrix
4×4 SparseMatrixCSC{Bool, Int64} with 4 stored entries:
 ⋅  ⋅  1  1
 ⋅  ⋅  1  ⋅
 ⋅  ⋅  ⋅  1
 ⋅  ⋅  ⋅  ⋅

julia> G[5] # get node object from node id: 5
TaskNode{Int64}(5, [1, 3])
```
"""
struct TaskGraph{T}
    ids::Vector{T}
    matrix::SparseMatrixCSC{Bool, Int}
    lookup::Dict{T,Int}
end

function TaskGraph(d::AbstractDict{T,TaskNode{T}}) where T
    ids = collect(keys(d))
    nodes = TaskNode{T}[]
    for nid in ids
        n = d[nid]
        n.id == nid || error("Task node id $(n.id) doesn't equal to dictionary key $nid.")
        push!(nodes, n)
    end
    return TaskGraph(nodes)
end

# TODO(johnnychen94): define equality between two task graph.
# The equality should be mutation/permutation invariant.

function TaskGraph(nodes::Vector{<:TaskNode})
    ids = map(n->n.id, nodes)
    rids = Dict(id=>i for (i, id) in enumerate(ids))
    Is, Js = Int[], Int[]
    Vs = Bool[]
    # TODO(johnnychen94): tweak the graph build for better performance?
    for (i, n) in enumerate(nodes)
        for p in n.parents
            push!(Is, rids[p])
            push!(Js, i)
            push!(Vs, true)
        end
    end
    n = length(ids)
    return TaskGraph(ids, sparse(Is, Js, Vs, n, n), rids)
end

# TaskGraph is dictionary-like object
function Base.getindex(G::TaskGraph{T}, id::T) where T
    TaskNode(id, G.ids[G.matrix[:, G.lookup[id]].nzind])
end

"""
    prenodes(graph::TaskGraph, node::TaskNode)
    prenodes(graph::TaskGraph, node_id)

Find all direct and indirect ancestors of `node` in given directed acyclic graph.

```jldoctest; setup=:(using Workflows.TaskGraphs)
julia> graph = TaskGraph([TaskNode(1, []), TaskNode(3, [1, ]), TaskNode(4, [3,]), TaskNode(5, [3, 4])]);

julia> graph.matrix
4×4 SparseMatrixCSC{Bool, Int64} with 4 stored entries:
 ⋅  1  ⋅  ⋅
 ⋅  ⋅  1  1
 ⋅  ⋅  ⋅  1
 ⋅  ⋅  ⋅  ⋅

julia> prenodes(graph, 5) # node 1 is indirect parent of node 5
3-element Vector{TaskNode{Int64}}:
 TaskNode{Int64}(3, [1])
 TaskNode{Int64}(1, Int64[])
 TaskNode{Int64}(4, [3])
```
"""
function prenodes(graph::TaskGraph, node::NT) where NT <: TaskNode
    node.id in graph.ids || error("Node $(node.id) not found in graph.")
    finished = falses(length(graph.ids))
    visited = falses(length(graph.ids))
    trace = NT[]
    for nid in node.parents
        pnode = graph[nid]
        _prenodes!(trace, finished, visited, graph, pnode)
    end
    return trace
end
prenodes(graph::TaskGraph{T}, node_id::T) where T = prenodes(graph, graph[node_id])

function _prenodes!(trace, finished, visited, graph, node)
    nid = graph.lookup[node.id]
    finished[nid] && return
    visited[nid] && error("Cycle graph detected around node id $nid.")
    visited[nid] = true
    push!(trace, node)
    pnode_ids = node.parents
    if isempty(pnode_ids)
        finished[nid] = true
        return
    end
    for pnid in pnode_ids
        pnode = graph[pnid]
        _prenodes!(trace, finished, visited, graph, pnode)
        finished[graph.lookup[pnid]] = true
    end
    finished[nid] = true
    return
end

end # module
