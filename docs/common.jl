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

using Documenter: Utilities, Expanders, Documents
using Documenter.Utilities: Selectors
using Documenter.Expanders: ExpanderPipeline, iscode

abstract type BlogMetaBlocks <: ExpanderPipeline end
Selectors.order(::Type{BlogMetaBlocks}) = 20.0
Selectors.matcher(::Type{BlogMetaBlocks}, node, page, doc) = iscode(node, r"^@blog_meta")

function Selectors.runner(::Type{BlogMetaBlocks}, x, page, doc)
    curmod = get(page.globals.meta, :CurrentModule, Main)
    fields = Dict{Symbol, Any}()
    lines = Utilities.find_block_in_file(x.code, page.source)
    @debug "Evaluating @blog_meta block:\n$(x.code)"

    for (ex, str) in Utilities.parseblock(x.code, doc, page)
        if Utilities.isassign(ex)
            try
                fields[ex.args[1]] = Core.eval(curmod, ex.args[2])
            catch err
                push!(doc.internal.errors, :autodocs_block)
                @warn("""
                    failed to evaluate `$(strip(str))` in `@blog_meta` block in $(Utilities.locrepr(page.source, lines))
                    ```$(x.language)
                    $(x.code)
                    ```
                    """, exception = err)
            end
        end
    end

    if haskey(fields, :create)
        page.mapping[x] = blog_meta(
            ;create=get(fields, :create, nothing),
            last_update=get(fields, :last_update, nothing),
            download_link=get(fields, :download_link, nothing),
            tags=get(fields, :tags, [])
        ) |> Documents.RawHTML
    end
end


#=
```@inline ../path/to/your.html
```
=#

abstract type InlineBlocks <: ExpanderPipeline end
Selectors.order(::Type{InlineBlocks}) = 21.0
Selectors.matcher(::Type{InlineBlocks}, node, page, doc) = iscode(node, r"^@inline")

function Selectors.runner(::Type{InlineBlocks}, x, page, doc)
    m = split(x.language)
    if length(m) == 2
        f = m[2]
        page.mapping[x] = Documents.RawHTML("<iframe src=\"$f\"></iframe>")
    end
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

function Selectors.runner(::Type{CommentBlocks}, x, page, doc)
    page.mapping[x] = Documents.RawHTML(COMMENT_TEMPLATE)
end

#=
```@embed https://github.com/findmyway/TianJun.jl/blob/ca409281346785f779fc88b770ee8a10f5d07ea2/LICENSE#L1-L21
```
=#

using Markdown
using URIs
using Downloads

abstract type EmbedBlocks <: ExpanderPipeline end
Selectors.order(::Type{EmbedBlocks}) = 23.0
Selectors.matcher(::Type{EmbedBlocks}, node, page, doc) = iscode(node, r"^@embed")

function Selectors.runner(::Type{EmbedBlocks}, x, page, doc)
    m = split(x.language)
    if length(m) == 2
        L = URI(m[2])
        (user, repo, _, branch, filepath...) = URIs.splitpath(L)
        lines = Downloads.download(
            "$(L.scheme)://raw.githubusercontent.com/$user/$repo/$branch/$(join(filepath, '/'))";
        ) |> readlines

        m = match(r"L(?<start>\d+)(-L(?<end>\d+))?", L.fragment)
        if isnothing(m)
            s, e = 1, length(lines)
        else
            s, e = m[:start], m[:end]
            s = isnothing(s) ? 1 : parse(Int, s)
            e = isnothing(e) ? length(lines) : parse(Int, e)
        end

        lang = lstrip(splitext(filepath[end])[end], '.')
        if lang == "jl"
            lang = "julia"
        end

        page.mapping[x] = Documents.MultiOutput(
            [
                Markdown.Code(lang, join(lines[s:e], "\n")),
                Documents.RawHTML("""
                    <div class="code_snippet_title">
                    ❤️
                    Source: <a href="$(m[2])">$(filepath[end])</a>
                    ❤️
                    </div>
                    """)
            ]
        )
    end
end