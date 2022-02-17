@option struct SimpleTask <: AbstractTask
    name::String
    id::String
    groups::Vector{String} = String[]
    deps::Vector{String} = String[]
    outs::Vector{String} = String[]
    runner::String # TODO(johnnychen94): verify runner type
    run::Dict{String, Any} = Dict{String, Any}()
end
task_id(t::SimpleTask) = t.id
task_name(t::SimpleTask) = t.name
task_groups(t::SimpleTask) = t.groups
task_deps(t::SimpleTask) = t.deps
task_outs(t::SimpleTask) = t.outs
runner_type(t::SimpleTask) = t.runner
runner_info(t::SimpleTask) = t.run
