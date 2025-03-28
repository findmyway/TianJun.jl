using FileIO
using ImageCore: colorview
using PythonCall: pyconvert
using SafeTensors: load_sharded_safetensors
using Flux: CrossCor

import HuggingFaceTokenizers as HFT

#####
# Processor
#####
struct Processor
    boi_token_index::Int
    eoi_token_index::Int
    image_token_index::Int
    mm_tokens_per_image::Int

    height::Int
    width::Int
    mean::Vector{Float32}
    std::Vector{Float32}

    tokenizer::Any
end


function (p::Processor)(text::String, image::String)
    # !!! Pan-and-Scan crops are ignored here for simplicity
    img = load(image) # (C, H, W)
    # The default BICUBIC interpolation in PIL is not found in Julia, so here we assume the image input is already resized for reproducibility
    @assert size(img) == (p.height, p.width)
    img = Float32.((channelview(img) .- reshape(p.mean, 3, 1, 1)) ./ reshape(p.std, 3, 1, 1))

    boi_token = pyconvert(String, p.tokenizer.py_tokenizer.id_to_token(p.boi_token_index))
    eoi_token = pyconvert(String, p.tokenizer.py_tokenizer.id_to_token(p.eoi_token_index))
    image_token = pyconvert(String, p.tokenizer.py_tokenizer.id_to_token(p.image_token_index))
    # Here we assume only one image is present in the text for simplicity
    @assert length(findall(boi_token, text)) == 1
    expanded_text = replace(text, boi_token => "\n\n$(boi_token)$(repeat(image_token, p.mm_tokens_per_image))$(eoi_token)\n\n")
    tids = HFT.encode(p.tokenizer, expanded_text).ids .+ 1
    tids, img
end

#####
# SigLIP
#####

struct SiglipVisionEmbedding
    patch_embedding::CrossCor
    pos_embedding::Matrix
end

function (m::SiglipVisionEmbedding)(x)
    patch_emb = m.patch_embedding(permutedims(x, (3, 2, 1, 4)))
    patch_emb = permutedims(patch_emb, (3, 2, 1, 4))
    patch_emb = reshape(patch_emb, size(patch_emb, 1), :, size(patch_emb, 4))
    pos_emb = reshape(m.pos_embedding, size(m.pos_embedding)..., 1)
    patch_emb .+ pos_emb
end

struct SiglipEncoderLayer
end

#####
using JSON3

function verification()
    ps = load_sharded_safetensors("models/gemma-3-4b-it-fp32")
    c = JSON3.read("models/gemma-3-4b-it-fp32/config.json")
    pc = JSON3.read("models/gemma-3-4b-it-fp32/preprocessor_config.json")
    tokenizer = HFT.from_file(HFT.Tokenizer, "models/gemma-3-4b-it-fp32/tokenizer.json")
    p = Processor(
        c["boi_token_index"],
        c["eoi_token_index"],
        c["image_token_index"],
        c["mm_tokens_per_image"],
        pc["size"]["height"],
        pc["size"]["width"],
        pc["image_mean"],
        pc["image_std"],
        tokenizer
    )
    emb = SiglipVisionEmbedding(
        CrossCor(
            permutedims(ps["vision_tower.vision_model.embeddings.patch_embedding.weight"], (4, 3, 2, 1)),
            ps["vision_tower.vision_model.embeddings.patch_embedding.bias"],
            stride=c["vision_config"]["patch_size"]
        ),
        ps["vision_tower.vision_model.embeddings.position_embedding.weight"]'
    )
end