using Workflows
using Documenter

DocMeta.setdocmeta!(Workflows, :DocTestSetup, :(using Workflows); recursive=true)

makedocs(;
    modules=[Workflows],
    authors="Johnny Chen <johnnychen94@hotmail.com>",
    repo="https://github.com/johnnychen94/Workflows.jl/blob/{commit}{path}#{line}",
    sitename="Workflows.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://johnnychen94.github.io/Workflows.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/johnnychen94/Workflows.jl",
)
