@option struct LoopTask <: AbstractTask
    name::String
    id::String
    runner::String
    groups::Vector{String} = String[]
    deps::Vector{String} = String[]
    outs::Vector{String} = String[]
    matrix::Dict{String} = Dict{String,Any}()
    run::Dict{String, Any} = Dict{String, Any}()
end

task_id(t::LoopTask) = t.id
task_name(t::LoopTask) = t.name
task_groups(t::LoopTask) = t.groups
task_deps(t::LoopTask) = t.deps
task_outs(t::LoopTask) = t.outs
runner_type(t::LoopTask) = t.runner
runner_info(::LoopTask) = error("LoopTask must be unrolled first to get runner information")

function Base.show(io::IO, t::LoopTask)
    print(io, "LoopTask(name=\"", task_name(t), "\", id=\"", task_id(t), "\")")
end
