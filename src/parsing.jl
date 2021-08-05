function default_case_id(case_info)
    # case sensitive
    tags = sort(case_info["tags"]) # order insensitive
    join([case_info["name"], tags...], "_")
end

# Each stage can take a very long time to run, so it's a good practice
# to eagerly verify the configuration so that we don't waste time in
# running a broken workflow.
function verify_configuration(config)
    stage_names = get_stage_names(config)

    # verify if there are duplicate stages
    duplicate_stages = setdiff(stage_names, Set(stage_names))
    isempty(duplicate_stages) || throw(ArgumentError("Stages $duplicate_stages are duplicated."))

    # verify if every stage has its associated tasks
    missing_stages = setdiff(stage_names, keys(config))
    isempty(missing_stages) || throw(ArgumentError("Stages $missing_stages are not configured."))

    # TODO: verify that each task consists of multiple sub-tasks

    return true
end

function get_stage_names(config)
    map(x->x["name"], config["stages"])
end

function get_stage_config(config, stage_name)
    stages_config = config["stages"]
    idx = findfirst(stages_config) do stage
        stage["name"] == stage_name
    end
    stages_config[idx]
end
