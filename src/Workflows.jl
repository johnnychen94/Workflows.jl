module Workflows

using TOML
using JSON3
using CSV
using DataFrames

export run_workflow

include("parsing.jl")
include("drivers.jl")
include("report.jl")

function run_workflow(config_file)
    root = abspath(dirname(config_file))

    config = TOML.parsefile(config_file)
    verify_configuration(config)

    stage_names = get_stage_names(config)
    for cur_stage_name in stage_names
        stats = run_stage(config[cur_stage_name]; root)

        stage_config = get_stage_config(config, cur_stage_name)
        report_stage(stats, stage_config; root)
    end

    return true
end

function run_stage(taskpool; root)
    map(taskpool) do cur_task
        task_id = default_case_id(cur_task)
        stats = mapreduce(merge!, cur_task["run"]) do info
            try
                start_runner(info; root)
            catch err
                @warn "failed to run task" task=task_id err
                JSON3.read("{}")
            end
        end
        task_id => stats
    end
end

end #module
