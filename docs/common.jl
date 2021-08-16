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

# @blog_meta

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


# inline
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