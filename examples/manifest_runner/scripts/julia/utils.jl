using BenchmarkTools

function trial_to_dict(trial::BenchmarkTools.Trial)
    d = Dict{String, Any}()
    d["time"] = mean(trial.times)
    d["gctimes"] = mean(trial.gctimes)
    d["allocs"] = trial.allocs
    d["memory"] = trial.memory
    return d
end
