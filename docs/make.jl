using Documenter, SeisDownload

makedocs(;
    modules=[SeisDownload],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
    ],
    repo="https://github.com/kura-okubo/SeisDownload.jl/blob/{commit}{path}#L{line}",
    sitename="SeisDownload.jl",
    authors="kurama",
    assets=String[],
)

deploydocs(;
    repo="github.com/kura-okubo/SeisDownload.jl",
    target = "build",
    deps   = nothing,
    make   = nothing,
)
