export blog_meta

using Badges

function blog_meta(;
    create,
    last_update = nothing,
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

    html *= Badge(
        label="Create",
        message=create
    ) |> Badges.render

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
