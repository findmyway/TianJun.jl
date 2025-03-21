using BFloat16s

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

@kwdef struct RopeScaling
    dim::Int
    rope_theta::Float32
    max_position_embeddings::Int

    scaling_factor::Float32
    beta_slow::Float32
    beta_fast::Float32
    original_max_position_embeddings::Int

    cache::Ref{@NamedTuple{cos::Array, sin::Array}} = Ref{@NamedTuple{cos::Array, sin::Array}}()
end


# Eq 17 in YaRN paper, given r of α or β, find the corresponding d
r2d(r, D, b, L) = (D * log(L / (2π * r))) / (2log(b))

# Eq 22 in YaRN paper
mscale(scale, mscale) = scale <= 1.0 ? 1.0 : 0.1 * mscale * log(scale) + 1.0

function set_cos_sin_cache(r::RopeScaling)
end

function (r::RopeScaling)(seq_len::Int)
    if !isassigned(r.cache)
        freq_extra = 1 ./ (r.rope_theta .^ ((0:2:(r.dim-1)) ./ r.dim))
        freq_inter = 1 ./ (r.scaling_factor .* r.rope_theta .^ ((0:2:(r.dim-1)) ./ r.dim))

        low = floor(Int, r2d(r.beta_fast, r.dim, r.rope_theta, r.original_max_position_embeddings))
        high = ceil(Int, r2d(r.beta_slow, r.dim, r.rope_theta, r.original_max_position_embeddings))
        mask = vcat(zeros(low), range(0, 1, length=high - low + 1), ones(r.dim ÷ 2 - high - 1))

        inv_freq = freq_inter .* mask .+ freq_extra .* (1 .- mask)
        t = 0:(r.max_position_embeddings-1)
        freqs = inv_freq * t'

        # !!! mscal is skipped here.
        # see https://github.com/ggml-org/llama.cpp/discussions/7416
        emb = vcat(freqs, freqs)
        r.cache[] = (cos=BFloat16.(cos.(emb)), sin=BFloat16.(sin.(emb)))
    end

    cos, sin = r.cache[]

    @view cos[:, 1:seq_len], @view sin[:, 1:seq_len]
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

    rope_scaling::RopeScaling
end

function apply_rotary_pos_emb()
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
    qᴿ = apply_rotary_pos_emb(qᴿ)
    q = vcat(qᶜ, qᴿ)

    cKV = m.kv_proj(h)
    kᴿ = @view cKV[m.kv_lora_rank+1:end, :, :, :]
    kᴿ = apply_rotary_pos_emb(kᴿ)

    cᴷⱽ = @view cKV[1:m.kv_lora_rank, :, :, :]
    cᴷⱽ = cᴷⱽ |> m.kv_layernorm |> m.k_v_proj
    kᶜ = @view cᴷⱽ[1:m.qk_nope_head_dim, :, :, :]
    k = vcat(kᶜ, kᴿ)

    v = @view cᴷⱽ[m.qk_nope_head_dim+1:end, :, :, :]
    o = causal_dot_product_attention(q, k, v)
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