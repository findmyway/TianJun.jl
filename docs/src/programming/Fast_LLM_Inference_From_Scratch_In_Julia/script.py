from transformers import AutoProcessor, Gemma3ForConditionalGeneration
from PIL import Image
import torch

model_id = "models/gemma-3-4b-it"
processor = AutoProcessor.from_pretrained(model_id)

with open("me.jpg", 'rb') as f_img:
    image = Image.open(f_img)
    prompt = "<start_of_image> in this image, there is"
    model_inputs = processor(text=prompt, images=image, return_tensors="pt")

model = Gemma3ForConditionalGeneration.from_pretrained(model_id).eval()

with torch.inference_mode():
    generation = model.generate(**model_inputs, max_new_tokens=100, do_sample=False)
    generation = generation[0][100:]

decoded = processor.decode(generation, skip_special_tokens=True)
print(decoded)