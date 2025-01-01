include("v2.rope_cache.jl")

@kwdef mutable struct KVCache
    k_cache = nothing
    v_cache = nothing
end

function (c::KVCache)(k, v)
    c.k_cache = isnothing(c.k_cache) ? k : cat(c.k_cache, k; dims=2)
    c.v_cache = isnothing(c.v_cache) ? v : cat(c.v_cache, v; dims=2)
    c.k_cache, c.v_cache
end

function (m::Attention)(x::AbstractArray{T,3}, n_prev_tokens::Int, kv_cache) where {T}
    xq, xk, xv = m.q_proj(x), m.k_proj(x), m.v_proj(x)

    xk, xv = kv_cache(xk, xv)

    xq = reshape(xq, m.head_dim, m.n_heads, size(xq, 2), size(xq, 3))
    xk = reshape(xk, m.head_dim, m.n_kv_heads, size(xk, 2), size(xk, 3))
    xv = reshape(xv, m.head_dim, m.n_kv_heads, size(xv, 2), size(xv, 3))

    xq = apply_rotary_embedding(xq, m.head_dim, m.rope_theta, m.rope_scaling; n_prev_tokens)
    xk = apply_rotary_embedding(xk, m.head_dim, m.rope_theta, m.rope_scaling)
    xk, xv = repeat.((xk, xv), inner=(1, m.n_heads ÷ m.n_kv_heads, 1, 1)) # GQA
    o = causal_dot_product_attention(xq, xk, xv)

    m.o_proj(reshape(o, m.head_dim * m.n_heads, size(o, 3), size(o, 4)))
end

function (m::TransformerBlock)(x, n_prev_tokens, kv_cache)
    h = m.pre_norm(x)
    h = m.attn(h, n_prev_tokens, kv_cache)
    o = (x + h) |> m.post_norm |> m.ffn
    x + h + o
end

function (m::Llama3)(x, n_prev_tokens, kv_caches)
    h = m.embedding_layer(x)
    for (i, block) in enumerate(m.transformer_blocks)
        h = block(h, n_prev_tokens, kv_caches[i])
    end
    h = m.norm_layer(h)
    o = m.head(h)
end

function cached_generate(args...; kw...)
    config = JSON3.read("models/Llama-3.2-1B/config.json")
    with(
        ROPE_CACHE => rope_cache(
            config["rope_scaling"]["original_max_position_embeddings"],
            config["head_dim"],
            config["rope_theta"],
            RopeScaling(
                config["rope_scaling"]["factor"],
                config["rope_scaling"]["high_freq_factor"],
                config["rope_scaling"]["low_freq_factor"],
                config["rope_scaling"]["original_max_position_embeddings"],
            )
        )
    ) do
        generate(args...; kw...)
    end
end

function generate(model=load_model(), prompt="The key to life is"; max_new_tokens=1000, stop_condition=(==(128009 + 1)))
    tokens = encode(prompt)
    new_tokens = []
    kv_caches = [KVCache() for _ in 1:length(model.transformer_blocks)]
    @showprogress for i in 1:max_new_tokens
        if i == 1 # prefill
            inputs = reshape(tokens, :, 1)
            n_prev_tokens = 0
        else
            inputs = [new_tokens[end];;]
            n_prev_tokens = length(tokens) + length(new_tokens) - 1
        end
        logits = model(inputs, n_prev_tokens, kv_caches)
        token = argmax(logits[:, end])
        push!(new_tokens, token)
        stop_condition(token) && break
    end
    decode(vcat(tokens, new_tokens))
end