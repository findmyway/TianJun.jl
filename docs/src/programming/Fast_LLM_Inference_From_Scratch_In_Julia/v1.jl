using NNlib: batched_mul, softmax, swish
using LinearAlgebra: triu!
using Statistics: mean

struct EmbeddingLayer
    weight::AbstractMatrix
end

(m::EmbeddingLayer)(ids) = m.weight[:, ids]

struct Dense
    weight::AbstractMatrix
end

(m::Dense)(x::AbstractMatrix) = m.weight * x
(m::Dense)(x) = reshape(m(reshape(x, size(x, 1), :)), :, size(x)[2:end]...)

struct RMSNorm
    eps::Float64
    weight::AbstractVector
end

function (m::RMSNorm)(x::AbstractArray{T}) where {T}
    m.weight .* T.(Float32.(x) ./ sqrt.(mean(Float32.(x) .^ 2, dims=1) .+ m.eps))
end

struct Attention
    q_proj::Dense
    k_proj::Dense
    v_proj::Dense
    o_proj::Dense
    rope_theta::Int
    head_dim::Int
    n_heads::Int
    n_kv_heads::Int
end

function apply_rotary_embedding(x::AbstractArray{T}, head_dim, rope_theta) where {T}
    inv_freq = one(T) ./ (rope_theta .^ ((0:2:(head_dim-1)) ./ T(head_dim)))
    freqs = reshape(inv_freq, :, 1) * reshape(0:size(x)[end]-1, 1, :)
    freqs_cos, freqs_sin = cos.(freqs), sin.(freqs)

    x_r = selectdim(reshape(x, :, 2, size(x)[2:end]...), 2, 1)
    x_i = selectdim(reshape(x, :, 2, size(x)[2:end]...), 2, 2)
    x_pos_r = freqs_cos .* x_r .- freqs_sin .* x_i
    x_pos_i = freqs_sin .* x_r .+ freqs_cos .* x_i
    vcat(x_pos_r, x_pos_i)
end

function causal_dot_product_attention(q::AbstractArray{T,4}, k::AbstractArray{T,4}, v::AbstractArray{T,4}) where {T}
    q = permutedims(q, (1, 3, 2, 4))
    kᵗ = permutedims(k, (3, 1, 2, 4))
    v = permutedims(v, (1, 3, 2, 4))

    head_dim = size(q, 1)
    seq_len = size(q, 2)
    scale = convert(T, sqrt(head_dim))
    logits = batched_mul(kᵗ, q ./ scale)

    mask = similar(q, Bool, seq_len, seq_len)
    fill!(mask, true)
    triu!(mask)

    masked_logits = ifelse.(mask, logits, typemin(T))
    scores = T.(softmax(Float32.(masked_logits)))
    out = batched_mul(v, scores)
    permutedims(out, (1, 3, 2, 4))
end

function (m::Attention)(x::AbstractArray{T,3}) where {T}
    xq, xk, xv = m.q_proj(x), m.k_proj(x), m.v_proj(x)
    xq = reshape(xq, m.head_dim, m.n_heads, size(xq, 2), size(xq, 3))
    xk = reshape(xk, m.head_dim, m.n_kv_heads, size(xk, 2), size(xk, 3))
    xv = reshape(xv, m.head_dim, m.n_kv_heads, size(xv, 2), size(xv, 3))

    xq, xk = apply_rotary_embedding.((xq, xk), m.head_dim, m.rope_theta)
    xk, xv = repeat.((xk, xv), inner=(1, m.n_heads ÷ m.n_kv_heads, 1, 1)) # GQA
    o = causal_dot_product_attention(xq, xk, xv)

    m.o_proj(reshape(o, m.head_dim * m.n_heads, size(o, 3), size(o, 4)))
end

struct FeedForwardLayer
    up_proj::Dense
    gate_proj::Dense
    down_proj::Dense
end

function (m::FeedForwardLayer)(x)
    h = m.up_proj(x)
    a = m.gate_proj(x)
    h = swish.(a) .* h
    o = m.down_proj(h)
end

struct TransformerBlock
    pre_norm::RMSNorm
    attn::Attention
    post_norm::RMSNorm
    ffn::FeedForwardLayer
end

function (m::TransformerBlock)(x)
    h = x |> m.pre_norm |> m.attn
    o = (x + h) |> m.post_norm |> m.ffn
    x + h + o
end

struct Llama3
    embedding_layer::EmbeddingLayer
    transformer_blocks::Vector{TransformerBlock}
    norm_layer::RMSNorm
    head::Dense
end

function (m::Llama3)(x)
    h = m.embedding_layer(x)
    for block in m.transformer_blocks
        h = block(h)
    end
    h = m.norm_layer(h)
    o = m.head(h)
end

using SafeTensors: load_safetensors
using JSON3

function load_model()
    ps_bf16 = load_safetensors("models/Llama-3.2-1B/model.safetensors")
    ps = Dict(k => Float32.(v) for (k, v) in ps_bf16)
    config = JSON3.read("models/Llama-3.2-1B/config.json")
    Llama3(
        EmbeddingLayer(ps["model.embed_tokens.weight"]'),
        [
            TransformerBlock(
                RMSNorm(config["rms_norm_eps"], ps["model.layers.$i.input_layernorm.weight"]),
                Attention(
                    Dense(ps["model.layers.$i.self_attn.q_proj.weight"]),
                    Dense(ps["model.layers.$i.self_attn.k_proj.weight"]),
                    Dense(ps["model.layers.$i.self_attn.v_proj.weight"]),
                    Dense(ps["model.layers.$i.self_attn.o_proj.weight"]),
                    config["rope_theta"],
                    config["head_dim"],
                    config["num_attention_heads"],
                    config["num_key_value_heads"],
                ),
                RMSNorm(config["rms_norm_eps"], ps["model.layers.$i.post_attention_layernorm.weight"]),
                FeedForwardLayer(
                    Dense(ps["model.layers.$i.mlp.up_proj.weight"]),
                    Dense(ps["model.layers.$i.mlp.gate_proj.weight"]),
                    Dense(ps["model.layers.$i.mlp.down_proj.weight"]),
                )
            )
            for i in 0:config["num_hidden_layers"]-1
        ],
        RMSNorm(config["rms_norm_eps"], ps["model.norm.weight"]),
        Dense(haskey(ps, "lm_head.weight") ? ps["lm_head.weight"] : ps["model.embed_tokens.weight"])
    )
end
