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
    eps::Float32
    weight::AbstractVector
end

function (m::RMSNorm)(x::AbstractArray{T}) where {T}
    m.weight .* T.(Float32.(x) ./ sqrt.(mean(Float32.(x) .^ 2, dims=1) .+ m.eps))
end


struct RopeScaling
    factor::Float32
    high_freq_factor::Float32
    low_freq_factor::Float32
    original_max_position_embeddings::Int
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
    rope_scaling::RopeScaling
end

function apply_rope_scaling(inv_freq::AbstractArray{T}, config::RopeScaling) where {T}
    old_ctx_len = config.original_max_position_embeddings
    low_freq_wavelen = old_ctx_len / config.low_freq_factor
    high_freq_wavelen = old_ctx_len / config.high_freq_factor

    map(inv_freq) do freq
        wavelen = 2π / freq
        scaled_freq = if wavelen > low_freq_wavelen
            freq / config.factor
        elseif wavelen > high_freq_wavelen
            smooth = (old_ctx_len / wavelen - config.low_freq_factor) / (config.high_freq_factor - config.low_freq_factor)
            (1 - smooth) * freq / config.factor + smooth * freq
        else
            freq
        end
        T(scaled_freq)
    end
end

function apply_rotary_embedding(x::AbstractArray{T}, head_dim, rope_theta, rope_scaling) where {T}
    inv_freq = one(T) ./ (rope_theta .^ ((0:2:(head_dim-1)) ./ T(head_dim)))
    inv_freq = apply_rope_scaling(inv_freq, rope_scaling)
    freqs = reshape(inv_freq, :, 1) * reshape(0:size(x, 3)-1, 1, :)
    freqs = reshape(freqs, size(freqs, 1), 1, size(freqs, 2)) # for broadcasting along multi head dimension
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

    xq = apply_rotary_embedding(xq, m.head_dim, m.rope_theta, m.rope_scaling)
    xk = apply_rotary_embedding(xk, m.head_dim, m.rope_theta, m.rope_scaling)
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
    ps_bf16 = load_safetensors("models/Llama-3.2-1B-Instruct/model.safetensors")
    ps = Dict(k => Float32.(v) for (k, v) in ps_bf16)
    config = JSON3.read("models/Llama-3.2-1B-Instruct/config.json")
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
                    RopeScaling(
                        config["rope_scaling"]["factor"],
                        config["rope_scaling"]["high_freq_factor"],
                        config["rope_scaling"]["low_freq_factor"],
                        config["rope_scaling"]["original_max_position_embeddings"],
                    )
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

#####

import HuggingFaceTokenizers as HFT

TOKENIZER = HFT.from_file(HFT.Tokenizer, "models/Llama-3.2-1B-Instruct/tokenizer.json")
encode(s) = HFT.encode(TOKENIZER, s).ids .+ 1
decode(ids) = HFT.decode(TOKENIZER, ids .- 1)

function generate(model=load_model(), prompt="The key to life is"; max_new_tokens=1000, stop_condition=(==(128009 + 1)))
    tokens = encode(prompt)
    for _ in 1:max_new_tokens
        logits = model(reshape(tokens, :, 1))
        token = argmax(logits[:, end])
        tokens = vcat(tokens, [token])
        stop_condition(token) && break
    end
    decode(tokens)
end

expected_reply = """The key to life is not to be afraid to take risks and try new things. It's not about being perfect, but about being willing to learn and grow from your mistakes.

As the great philosopher, Nelson Mandela, once said, "The greatest glory in living lies not in never falling, but in rising every time we fall." This quote reminds us that failure is an inevitable part of the journey, but it's how we respond to it that truly matters.

In today's fast-paced world, it's easy to get caught up in the idea that success is just a destination, and that we need to be perfect to achieve it. But the truth is, success is a journey, not a destination. It's the accumulation of small wins, the learning from our mistakes, and the growth that comes from taking risks.

So, I want to leave you with a challenge today. Take a deep breath, and remember that it's okay to be imperfect. It's okay to make mistakes. It's okay to take risks. Because it's in those moments of uncertainty that we discover our greatest strengths, and it's in those moments of growth that we discover our true potential.

So, go out there and take the leap. Take the risk. And remember, as Nelson Mandela said, "The greatest glory in living lies not in never falling, but in rising every time we fall.\""""