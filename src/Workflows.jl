module Workflows

using Configurations

include("dialects/Dialects.jl")
using .Dialects: load_config, save_config

end
