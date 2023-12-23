using Documenter
using TianJun

include("common.jl")

recursive_replace(@__DIR__, r"\.zh(?<ext>(\.md)?)$" => s"\g<ext>")

const BUILD_DIR = "build.zh"

makedocs(
    modules = [TianJun],
    format = Documenter.HTML(
        prettyurls = true,
        analytics = "UA-132847825-3",
        lang = "zh-CN",
        footer = "本站基于 [Documenter.jl](https://github.com/JuliaDocs/Documenter.jl) 和 [Julia 编程语言](https://julialang.org/) 构建，所有内容默认遵循[CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)协议。英文版请访问[juntian.me](https://juntian.me)。",
        assets = [
            "assets/favicon.ico",
            "assets/custom.css",
        ]
    ),
    sitename = "田俊",
    warnonly=[:linkcheck, :cross_references],
    build = BUILD_DIR,
    pages = [
        "👋 关于" => "index.md",
        "💻 编程" => [
            "如何在Julia中计算点积?" => "programming/Dot_Product_in_Julia/index.md"
        ],
        "🙋 提问" => "AMA.md",
        "🔗 友链" => "blogroll.md",
        "🗃️ 存档" => [
            "20210812" => "essays/archive.md",
            hide("notebook_demo/pluto.md"),
            hide("essays/A_Draft_Design_of_Distributed_Reinforcement_Learning_in_Julia/index.md"),
            hide("essays/A_Dream/index.md"),
            hide("essays/A_Guide_to_Wrap_a_C++_Library_with_CXXWrap.jl_and_BinaryBuilder.jl_in_Julia/index.md"),
            hide("essays/A_Pratical_Guide_to_Distributed_Computing_in_Julia/index.md"),
            hide("essays/A_Short_Introduction_to_AI_for_children/index.md"),
            hide("essays/About_Recent/index.md"),
            hide("essays/About_This_Site/index.md"),
            hide("essays/All_About_Zipper/index.md"),
            hide("essays/An_Introduction_to_Flux.jl/index.md"),
            hide("essays/An_Introduction_to_Parallel_Computing_in_Julia_From_Bottom_Up/index.md"),
            hide("essays/An_Overview_of_Existing_Reinforcement_Learning_Libraries/index.md"),
            hide("essays/CUDA_in_One_Picture/index.md"),
            hide("essays/Categorical_Sampling_on_GPU_with_Julia/index.md"),
            hide("essays/Data_Science_London_Scikit-Learn/index.md"),
            hide("essays/From_Python_to_Julia/index.md"),
            hide("essays/Implementing_Readers_Writer_Lock_in_Julia/index.md"),
            hide("essays/Increase_Your_PPT_Skills/index.md"),
            hide("essays/Introduction_to_Deep_Learning_Libraries/index.md"),
            hide("essays/Learn_Some_Julia_Packages/index.md"),
            hide("essays/Lets_Play_Hanabi/index.md"),
            hide("essays/Locks_Threads_Tasks_Channels_Actors/index.md"),
            hide("essays/My_Interview_Questions/index.md"),
            hide("essays/Notes_on_Artificial_Intelligence_Foundations_of_Computational_Agents/index.md"),
            hide("essays/Notes_on_CS3110/index.md"),
            hide("essays/Notes_on_Computer_Age_Statistical_Inference/index.md"),
            hide("essays/Notes_on_Machine_Learning_A_Bayesian_and_Optimization_Perspective/index.md"),
            hide("essays/Notes_on_Statistical_Rethinking/index.md"),
            hide("essays/Oneday_Out_of_School/index.md"),
            hide("essays/Optional_in_Java_8/index.md"),
            hide("essays/Parallel_Computing/index.md"),
            hide("essays/Paraphrase_Generation/index.md"),
            hide("essays/Quantum_Computing/index.md"),
            hide("essays/Random_Thoughts_on_Chatbot/index.md"),
            hide("essays/Recursion_Memoize_Y-Combinator_in_Clojure/index.md"),
            hide("essays/Reinforcement_Learning_in_Action/index.md"),
            hide("essays/RelationExtraction/index.md"),
            hide("essays/Some_Interesting_Papers/index.md"),
            hide("essays/Some_Interesting_Quil_Examples/index.md"),
            hide("essays/Some_Thoughts_Recently/index.md"),
            hide("essays/Test/index.md"),
            hide("essays/The_Chinese_Translation_of_Bayesian_Analysis_with_Python/index.md"),
            hide("essays/The_EM_Algorithm/index.md"),
            hide("essays/The_Gambler_Ruin_Problem/index.md"),
            hide("essays/The_Past_Year_at_DidiChuxing/index.md"),
            hide("essays/The_Senior_Software_Engineer/index.md"),
            hide("essays/Thinking_in_NLP/index.md"),
            hide("essays/Throwing_Eggs_from_a_Building/index.md"),
            hide("essays/Understand_Buddy_in_Clojure/index.md"),
            hide("essays/Understanding_Variational_Autoencoder/index.md"),
            hide("essays/Write_Python_in_Lisp/index.md"),
            hide("essays/Write_a_Reinforcement_Learning_Package_in_Julia_from_Scratch/index.md"),
            hide("essays/[4]_Learn_Python_Together_Basic/index.md"),
            hide("essays/[6]_Learn_Python_Together_Data_Structure/index.md"),
        ]
    ]
)

cp(joinpath(@__DIR__, "CNAME"), joinpath(@__DIR__, BUILD_DIR, "CNAME");force=true)
