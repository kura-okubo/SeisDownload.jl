push!(LOAD_PATH,"../src/")

using Documenter, SeisDownload

makedocs(
    modules=[SeisDownload],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
        "Functions" => "Functions.md",
    ],
    repo="https://github.com/kura-okubo/SeisDownload.jl/blob/{commit}{path}#L{line}",
    sitename="SeisDownload.jl",
    authors="kurama",
)

deploydocs(
    repo="github.com/kura-okubo/SeisDownload.jl",
    target = "build",
    deps   = nothing,
    make   = nothing,
)
