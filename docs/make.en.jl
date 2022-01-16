using Documenter
using TianJun

include("common.jl")
recursive_replace(@__DIR__, r"\.en(?<ext>(\.md)?)$" => s"\g<ext>")

const BUILD_DIR = "build.en"

makedocs(
    modules = [TianJun],
    format = Documenter.HTML(
        prettyurls = true,
        analytics = "UA-132847825-3",
        footer = "Powered by [Documenter.jl](https://github.com/JuliaDocs/Documenter.jl) and the [Julia Programming Language](https://julialang.org/). All contents published at this site follows [CC-BY-4.0](https://creativecommons.org/licenses/by/4.0/) by default. For the Chinese version, please visit [tianjun.me](https://tianjun.me).",
        lang = "en-US",
        assets = [
            "assets/favicon.ico",
            "assets/custom.css",
        ]
    ),
    sitename = "Jun Tian",
    linkcheck = haskey(ENV, "CI"),
    build = BUILD_DIR,
    pages = [
        "👋 About" => "index.md",
        "💻 Programming" => [
            "A Deep Dive into Distributed.jl" => "programming/A_Deep_Dive_into_Distributed.jl/index.md"
        ],
        "📖 Reading" => [
            "Notes on Distributional Reinforcement Learning" => "reading/Notes_on_Distributional_Reinforcement_Learning/index.md"
        ],
        "🙋 Ask Me Anything" => "AMA.md",
        "🔗 Blogroll" => "blogroll.md",
    ]
)

cp(joinpath(@__DIR__, "CNAME"), joinpath(@__DIR__, BUILD_DIR, "CNAME"); force = true)