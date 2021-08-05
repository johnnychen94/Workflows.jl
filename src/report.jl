function report_stage(stats, stage_config; root)
    stage_run_info = stage_config["run"]

    df = make_dataframe(stats, stage_run_info["metrics"])

    reporter = stage_run_info["driver"]
    if reporter == "csv"
        for outpath in stage_run_info["out"]
            isabspath(outpath) || (outpath = joinpath(root, outpath))
            CSV.write(outpath, df)
        end
    else
        throw(ArgumentError("Unsupported metrics reporter $reporter"))
    end
end

function make_dataframe(stats, metrics_info)
    filtered_stats = map(metrics_info) do k
        k => map(stats) do task_item
            string(get(task_item.second, k, ""))
        end
    end
    data = [
        "id" => map(first, stats),
        filtered_stats...
    ]
    DataFrame(data)
end
