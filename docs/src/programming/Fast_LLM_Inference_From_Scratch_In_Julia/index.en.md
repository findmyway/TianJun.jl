# Fast LLM Inference From Scratch In Julia

In the past year at 01.ai, I've been mainly working on pre-training (MoE to be more specific) LLMs. And I only have very limited understanding of the inference part. Recently, I spent some time on learning [vLLM][] and [SGLang][]. It's a quite challenging experience and I really learned a lot from it. In this post, I'll try to explain those core ideas in my favorite Julia programming language.

## A Simple CPU Implementation

Below we'll focus on the model `Llama-3.2-1B-Instruct` first.

## TODO List

- [ ] Batch inference
- [ ] Different sampling strategy

## References

- [Fast LLM Inference From Scratch](https://andrewkchan.dev/posts/yalm.html#section-1)

[vLLM]: https://github.com/vllm-project/vllm/
[SGLang]: https://github.com/sgl-project/sglang