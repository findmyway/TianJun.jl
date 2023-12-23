function recursive_replace(dir, (pattern, substitute))
    for (root, dirs, files) in walkdir(dir)
        for f in files
            if !isnothing(match(pattern, f))
                cp(
                    joinpath(root, f),
                    joinpath(root, replace(f, pattern => substitute))
                    ;force=true
                )
            end
        end
    end
end

#=
```@blog_meta
last_update="2021-08-13"
create="2021-08-12"
download_link="../x.txt"
tags=["Archive", "记录", "Test"]
```
=#

using Badges

function blog_meta(;
    create=nothing,
    last_update = nothing,
    download_link = nothing,
    tags = []
)
    html = ""

    if !isnothing(last_update)
        html *= Badge(
            label="Last Update",
            message=last_update,
            color="#97C40F"
        ) |> Badges.render
    end

    if !isnothing(create)
        html *= Badge(
            label="Create",
            message=create
        ) |> Badges.render
    end

    if !isnothing(download_link)
        html *= Badge(
            label="⇩",
            message=basename(download_link),
            rightLink=download_link
        ) |> Badges.render
    end

    for t in tags
        html *= Badge(
            label= "#",
            message=t,
            color="#0F80C1",
            rightLink="/search/?q=$t"
        ) |> Badges.render
    end

    "<div class=blogmeta>$html</div>"
end

using Documenter: Selectors, Expanders, iscode
using Documenter.Expanders: ExpanderPipeline

abstract type BlogMetaBlocks <: ExpanderPipeline end
Selectors.order(::Type{BlogMetaBlocks}) = 20.0
Selectors.matcher(::Type{BlogMetaBlocks}, node, page, doc) = iscode(node, r"^@blog_meta")

# refer the implementation of `@meta`

function Selectors.runner(::Type{BlogMetaBlocks}, node, page, doc)
    x = node.element
    curmod = get(page.globals.meta, :CurrentModule, Main)
    fields = Dict{Symbol, Any}()
    lines = Documenter.find_block_in_file(x.code, page.source)
    @debug "Evaluating @blog_meta block:\n$(x.code)"

    for (ex, str) in Documenter.parseblock(x.code, doc, page)
        if Documenter.isassign(ex)
            try
                fields[ex.args[1]] = Core.eval(curmod, ex.args[2])
            catch err
                push!(doc.internal.errors, :autodocs_block)
                @warn("""
                    failed to evaluate `$(strip(str))` in `@blog_meta` block in $(Documenter.locrepr(page.source, lines))
                    ```$(x.language)
                    $(x.code)
                    ```
                    """, exception = err)
            end
        end
    end

    if haskey(fields, :create)
        content = blog_meta(
            ;create=get(fields, :create, nothing),
            last_update=get(fields, :last_update, nothing),
            download_link=get(fields, :download_link, nothing),
            tags=get(fields, :tags, [])
        )
        node.element = Documenter.RawNode(:html, content)
    end
end


#=
```@inline ../path/to/your.html
```
=#

abstract type InlineBlocks <: ExpanderPipeline end
Selectors.order(::Type{InlineBlocks}) = 21.0
Selectors.matcher(::Type{InlineBlocks}, node, page, doc) = iscode(node, r"^@inline")

function Selectors.runner(::Type{InlineBlocks}, node, page, doc)
    x = node.element
    m = match(r"@inline\s+(\S+)\s*(\S+)?\s*(\S+)?\s*$", x.info)
    m === nothing && error("invalid '@inline path [width] [height]' syntax: $(x.info)")
    f = m[1]
    w = something(m[2], "100%")
    h = something(m[3], "100vh")

    node.element = Documenter.RawNode(:html, "<iframe src=\"$f\" style=\"width: $w;height: $h\"></iframe>")
end

#=
```@comment
```
=#

const COMMENT_TEMPLATE = """
    <script src="https://utteranc.es/client.js"
            repo="findmyway/TianJun.jl"
            issue-term="url"
            label="💬Comment"
            theme="github-light"
            crossorigin="anonymous"
            async>
    </script>
    """

abstract type CommentBlocks <: ExpanderPipeline end
Selectors.order(::Type{CommentBlocks}) = 22.0
Selectors.matcher(::Type{CommentBlocks}, node, page, doc) = iscode(node, r"^@comment")

function Selectors.runner(::Type{CommentBlocks}, node, page, doc)
    node.element = Documenter.RawNode(:html, COMMENT_TEMPLATE)
end

#=
```@embed https://github.com/findmyway/TianJun.jl/blob/ca409281346785f779fc88b770ee8a10f5d07ea2/LICENSE#L1-L21
```
=#

using MarkdownAST
using URIs
using Downloads

abstract type EmbedBlocks <: ExpanderPipeline end
Selectors.order(::Type{EmbedBlocks}) = 23.0
Selectors.matcher(::Type{EmbedBlocks}, node, page, doc) = iscode(node, r"^@embed")

function Selectors.runner(::Type{EmbedBlocks}, node, page, doc)
    x = node.element
    m = match(r"@embed\s+(\S+)$", x.info)
    m === nothing && error("invalid '@embed path' syntax: $(x.info)")
    L = URIs.URI(m[1])
    (user, repo, _, branch, filepath...) = URIs.splitpath(L)
    lines = Downloads.download(
        "https://raw.githubusercontent.com/$user/$repo/$branch/$(join(filepath, '/'))";
    ) |> readlines

    match_res = match(r"L(?<start>\d+)(-L(?<end>\d+))?", L.fragment)
    if isnothing(match_res)
        s, e = 1, length(lines)
    else
        s, e = match_res[:start], match_res[:end]
        s = isnothing(s) ? 1 : parse(Int, s)
        e = isnothing(e) ? length(lines) : parse(Int, e)
    end

    lang = lstrip(splitext(filepath[end])[end], '.')
    if lang == "jl"
        lang = "julia"
    end

    node.element = Documenter.MultiOutput(node.element)
    push!(node.children, Documenter.Node(MarkdownAST.CodeBlock(lang, join(lines[s:e], "\n"))))
    push!(node.children, Documenter.Node(Documenter.MultiOutputElement(Documenter.RawNode(
        :html,
        """
        <div class="code_snippet_title">
        ❤️
        Source: <a href="$(L)">$(filepath[end])</a>
        ❤️
        </div>
        """
    ))))
end