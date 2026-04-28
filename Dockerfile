FROM ls250824/run-comfyui-image:24032026

ENV DEBIAN_FRONTEND=noninteractive
# ComfyUI ya esta en /ComfyUI en la imagen base
# setup_models.sh lo copiara a /workspace/ComfyUI al primer arranque

RUN apt-get update -qq && apt-get install -y -qq git wget && \
    pip install -q gdown && \
    rm -rf /var/lib/apt/lists/*

# Custom Nodes en /ComfyUI (se copian al workspace en el primer arranque)
RUN cd /ComfyUI/custom_nodes && \
    git clone --depth=1 https://github.com/rgthree/rgthree-comfy && \
    git clone --depth=1 https://github.com/ltdrdata/ComfyUI-Impact-Pack && \
    git clone --depth=1 https://github.com/cubiq/ComfyUI_essentials && \
    git clone --depth=1 https://github.com/city96/ComfyUI-GGUF && \
    git clone --depth=1 https://github.com/ltdrdata/ComfyUI-Impact-Subpack && \
    git clone --depth=1 https://github.com/chrisgoringe/cg-use-everywhere

RUN for dir in rgthree-comfy ComfyUI-Impact-Pack ComfyUI_essentials ComfyUI-GGUF ComfyUI-Impact-Subpack cg-use-everywhere; do \
      REQ="/ComfyUI/custom_nodes/${dir}/requirements.txt"; \
      if [ -f "$REQ" ]; then pip install -q -r "$REQ"; fi; \
    done

RUN mkdir -p /ComfyUI/user/default/workflows
COPY nsfw-ultratozimage-fuelling.json /ComfyUI/user/default/workflows/nsfw-workflow.json
COPY sfw-comfyui-workflow-fuelling.json /ComfyUI/user/default/workflows/sfw-workflow.json
COPY Upscaler-fuelling.json /ComfyUI/user/default/workflows/upscaler.json


RUN apt-get update -qq && apt-get install -y -qq git wget && \
    pip install -q gdown huggingface_hub && \
    rm -rf /var/lib/apt/lists/*


RUN rm -rf /ComfyUI/ComfyUI-Login /ComfyUI/ComfyUI-login

COPY setup_models.sh /setup_models.sh
RUN chmod +x /setup_models.sh

EXPOSE 8188
CMD ["/setup_models.sh"]