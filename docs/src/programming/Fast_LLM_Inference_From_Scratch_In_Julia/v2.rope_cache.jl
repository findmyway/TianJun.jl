include("v1.vanilla.jl")

# In v1, the `freqs_cos` and `freqs_sin` are recalculated across layers.

using Base.ScopedValues

function rope_cache(max_seq_len, head_dim, rope_theta, rope_scaling, T=Float32)
    inv_freq = one(T) ./ (rope_theta .^ ((0:2:(head_dim-1)) ./ T(head_dim)))
    inv_freq = apply_rope_scaling(inv_freq, rope_scaling)
    freqs = reshape(inv_freq, :, 1) * reshape(0:max_seq_len-1, 1, :)
    freqs = reshape(freqs, size(freqs, 1), 1, size(freqs, 2)) # for broadcasting along multi head dimension
    cos.(freqs), sin.(freqs)
end

ROPE_CACHE = ScopedValue{Union{Nothing,Tuple{AbstractArray,AbstractArray}}}(nothing)

function apply_rotary_embedding(x::AbstractArray{T}, head_dim, rope_theta, rope_scaling) where {T}
    seq_len = size(x, 3)
    cache = ROPE_CACHE[]
    if isnothing(cache)
        freqs_cos, freqs_sin = rope_cache(seq_len, head_dim, rope_theta, rope_scaling, T)
    else
        freqs_cos_cache, freqs_sin_cache = cache
        freqs_cos = view(freqs_cos_cache, :, :, 1:seq_len)
        freqs_sin = view(freqs_sin_cache, :, :, 1:seq_len)
    end

    x_r = selectdim(reshape(x, :, 2, size(x)[2:end]...), 2, 1)
    x_i = selectdim(reshape(x, :, 2, size(x)[2:end]...), 2, 2)
    x_pos_r = freqs_cos .* x_r .- freqs_sin .* x_i
    x_pos_i = freqs_sin .* x_r .+ freqs_cos .* x_i
    vcat(x_pos_r, x_pos_i)
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