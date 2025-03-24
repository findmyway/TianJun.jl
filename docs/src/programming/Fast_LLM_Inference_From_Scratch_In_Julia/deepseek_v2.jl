using BFloat16s
using SafeTensors: load_sharded_safetensors

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

#####
# YaRN
#####

# Eq 17 in YaRN paper, given r of α or β, find the corresponding d
r2d(r, D, b, L) = (D * log(L / (2π * r))) / (2log(b))

# (Modified) Eq 22 in YaRN paper
mscale(scale, mscale) = scale <= 1.0 ? 1.0 : 0.1 * mscale * log(scale) + 1.0

struct RopeCache
    cos::Array
    sin::Array
end

function RopeCache(; dim, rope_theta, max_position_embeddings, scaling_factor, beta_slow, beta_fast, original_max_position_embeddings)
    freq_extra = 1 ./ (rope_theta .^ ((0:2:(dim-1)) ./ dim))
    freq_inter = 1 ./ (scaling_factor .* rope_theta .^ ((0:2:(dim-1)) ./ dim))

    low = floor(Int, r2d(beta_fast, dim, rope_theta, original_max_position_embeddings))
    high = ceil(Int, r2d(beta_slow, dim, rope_theta, original_max_position_embeddings))
    mask = vcat(zeros(low), range(0, 1, length=high - low + 1), ones(dim ÷ 2 - high - 1))

    inv_freq = freq_inter .* mask .+ freq_extra .* (1 .- mask)
    t = 0:(max_position_embeddings-1)
    freqs = inv_freq * t'

    # !!! mscal is skipped here.
    # see https://github.com/ggml-org/llama.cpp/discussions/7416
    RopeCache(BFloat16.(cos.(freqs)), BFloat16.(sin.(freqs)))
end


#####
# MLA
#####

struct Attention
    num_heads::Int
    q_head_dim::Int
    qk_nope_head_dim::Int
    kv_lora_rank::Int

    q_proj::Dense
    kv_proj::Dense
    kv_layernorm::RMSNorm
    k_v_proj::Dense
    o_proj::Dense

    rope_cache::RopeCache
end

function apply_rotary_pos_emb(x, cache)
    D, H, T, B = size(x)
    freqs_cos = reshape(cache.cos[:, 1:T], :, 1, T)
    freqs_sin = reshape(cache.sin[:, 1:T], :, 1, T)

    # !!! different from the llama implementation
    x_r = selectdim(reshape(x, 2, :, size(x)[2:end]...), 1, 1)
    x_i = selectdim(reshape(x, 2, :, size(x)[2:end]...), 1, 2)

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

function (m::Attention)(h)
    D, T, B = size(h)

    cQ = m.q_proj(h)
    cQ = reshape(cQ, m.q_head_dim, m.num_heads, T, B)
    qᶜ = @view cQ[1:m.qk_nope_head_dim, :, :, :]
    qᴿ = @view cQ[m.qk_nope_head_dim+1:end, :, :, :]
    qᴿ = apply_rotary_pos_emb(qᴿ, m.rope_cache)
    q = vcat(qᶜ, qᴿ)

    cKV = m.kv_proj(h)
    kᴿ = @view cKV[m.kv_lora_rank+1:end, :, :, :]
    kᴿ = apply_rotary_pos_emb(kᴿ, m.rope_cache)

    cᴷⱽ = @view cKV[1:m.kv_lora_rank, :, :, :]
    cᴷⱽ = cᴷⱽ |> m.kv_layernorm |> m.k_v_proj
    kᶜ = @view cᴷⱽ[1:m.qk_nope_head_dim, :, :, :]
    k = vcat(kᶜ, kᴿ)

    v = @view cᴷⱽ[m.qk_nope_head_dim+1:end, :, :, :]
    o = causal_dot_product_attention(q, k, v)
end

struct FeedForwardLayer
    up_proj::Dense
    gate_proj::Dense
    down_proj::Dense
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

function load_model()
    ps = load_sharded_safetensors("models/DeepSeek-V2-Lite-Chat")
end