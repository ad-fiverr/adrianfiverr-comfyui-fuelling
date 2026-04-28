FROM ls250824/run-comfyui-image:24032026 

ENV DEBIAN_FRONTEND=noninteractive
ENV COMFYUI_DIR=/workspace/ComfyUI

# El token se pasa como build-arg para mayor seguridad
ARG HF_TOKEN

RUN apt-get update -qq && apt-get install -y -qq git wget && \
    pip install -q gdown huggingface_hub && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p ${COMFYUI_DIR}/custom_nodes \
             ${COMFYUI_DIR}/models/loras \
             ${COMFYUI_DIR}/models/checkpoints \
             ${COMFYUI_DIR}/models/diffusion_models \
             ${COMFYUI_DIR}/models/text_encoders \
             ${COMFYUI_DIR}/models/vae \
             ${COMFYUI_DIR}/models/sam3 \
             ${COMFYUI_DIR}/user/default/workflows

# ── Custom Nodes ──────────────────────────────────────────────────────────────
RUN cd ${COMFYUI_DIR}/custom_nodes && \
    git clone --depth=1 https://github.com/rgthree/rgthree-comfy && \
    git clone --depth=1 https://github.com/ltdrdata/ComfyUI-Impact-Pack && \
    git clone --depth=1 https://github.com/cubiq/ComfyUI_essentials && \
    git clone --depth=1 https://github.com/city96/ComfyUI-GGUF && \
    git clone --depth=1 https://github.com/ltdrdata/ComfyUI-Impact-Subpack && \
    git clone --depth=1 https://github.com/chrisgoringe/cg-use-everywhere 

RUN for dir in rgthree-comfy ComfyUI-Impact-Pack ComfyUI_essentials ComfyUI-GGUF ComfyUI-Impact-Subpack cg-use-everywhere; do \
      REQ="${COMFYUI_DIR}/custom_nodes/${dir}/requirements.txt"; \
      if [ -f "$REQ" ]; then pip install -q -r "$REQ"; fi; \
    done 

COPY nsfw-ultratozimage-fuelling.json ${COMFYUI_DIR}/user/default/workflows/nsfw-workflow.json
COPY sfw-comfyui-workflow-fuelling.json ${COMFYUI_DIR}/user/default/workflows/sfw-workflow.json
COPY Upscaler-fuelling.json ${COMFYUI_DIR}/user/default/workflows/upscaler.json

# ── LoRAs ─────────────────────────────────────────────────────────────────────
RUN cd ${COMFYUI_DIR}/models/loras && rm -rf split_files/ && \
    # Usando huggingface-cli para los repositorios indicados
    HF_TOKEN=${HF_TOKEN} huggingface-cli download exjadev/fuelling-zimage-lora --local-dir . --local-dir-use-symlinks False && \
    HF_TOKEN=${HF_TOKEN} huggingface-cli download exjadev/fuelling-sdxl-v2 --local-dir . --local-dir-use-symlinks False && \
    # Civitai Lora
    wget -q "<https://civitai.red/api/download/models/2617751?type=Model&format=SafeTensor&token=e3a803e3831ec4832fd75d014b2d385e>" -O instagram-filter.safetensors 

# ── Checkpoints ───────────────────────────────────────────────────────────────
RUN cd ${COMFYUI_DIR}/models/checkpoints && rm -rf split_files/ && \
    # Civitai Checkpoint (NSFW)
    wget -q "<https://civitai.red/api/download/models/2755468?type=Model&format=SafeTensor&size=full&fp=fp16&token=e3a803e3831ec4832fd75d014b2d385e>" -O sdxl_nsfw.safetensors

# ── Diffusion Models ──────────────────────────────────────────────────────────
RUN cd ${COMFYUI_DIR}/models/diffusion_models && rm -rf split_files/ && \
    wget -q https://huggingface.co/vantagewithai/Z-Image-Turbo-GGUF/resolve/main/z_image_turbo-bf16.gguf && \
    wget -q --header="Authorization: Bearer ${HF_TOKEN}" \
           https://huggingface.co/black-forest-labs/FLUX.2-klein-9b-fp8/resolve/main/flux-2-klein-9b-fp8.safetensors 

# ── Text Encoders ─────────────────────────────────────────────────────────────
RUN cd ${COMFYUI_DIR}/models/text_encoders && rm -rf split_files/ && \
    wget -q https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/text_encoders/qwen_3_4b.safetensors && \
    wget -q --header="Authorization: Bearer ${HF_TOKEN}" \
        https://huggingface.co/Comfy-Org/vae-text-encorder-for-flux-klein-9b/resolve/main/split_files/text_encoders/qwen_3_8b_fp8mixed.safetensors

# ── VAE ───────────────────────────────────────────────────────────────────────
RUN cd ${COMFYUI_DIR}/models/vae && rm -rf split_files/ && \
    wget -q https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/vae/ae.safetensors && \
    wget -q https://huggingface.co/Comfy-Org/flux2-dev/resolve/main/split_files/vae/flux2-vae.safetensors

# ── SAM3 ──────────────────────────────────────────────────────────────────────
RUN cd ${COMFYUI_DIR}/models/sam3 && \
    wget -q --header="Authorization: Bearer ${HF_TOKEN}" \
        https://huggingface.co/facebook/sam3/resolve/main/sam3.pt && \
    wget -q https://huggingface.co/1038lab/sam3/resolve/main/sam3.safetensors 

# ── Cleanup ───────────────────────────────────────────────────────────────────
RUN rm -rf ${COMFYUI_DIR}/ComfyUI-Login \
           ${COMFYUI_DIR}/ComfyUI-login

EXPOSE 8188