import torch

dtype = torch.float32
device = "cpu"

from transformers import AutoModelForCausalLM, AutoTokenizer
import time

model_id = "models/Llama-3.2-1B-Instruct"
tokenizer = AutoTokenizer.from_pretrained(model_id)
model = AutoModelForCausalLM.from_pretrained(model_id, torch_dtype=dtype).to(device)
model_inputs = tokenizer(["The key to life is"], return_tensors="pt").to(device)

# warmup
model.generate(**model_inputs, max_new_tokens=1)

n_generated_tokens = 0
avg_time = 0
N = 5
for _ in range(N):
    start_time = time.time()
    model_outputs = model.generate(
        **model_inputs,
        max_new_tokens=1000,
        temperature=None,
        top_p=None,
        do_sample=False,
    )
    avg_time += time.time() - start_time
    n_generated_tokens = model_outputs.nelement() - model_inputs["input_ids"].nelement()
avg_time /= N

print(f"{n_generated_tokens / avg_time} tokens/sec")
