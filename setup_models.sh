#!/bin/bash
# =============================================================================
# setup_models.sh - Configuración de Modelos Fuelling
# =============================================================================

# Token actualizado según tu solicitud
HF_TOKEN="${HF_TOKEN}"
COMFYUI_DIR="/workspace/ComfyUI"

echo "================================================"
echo "  ComfyUI Model Setup — Fuelling Edition"
echo "================================================"

# PASO 1: Persistencia de ComfyUI
if [ ! -f "${COMFYUI_DIR}/main.py" ]; then
    echo "[ Copiando ComfyUI base a /workspace... ]"
    mkdir -p ${COMFYUI_DIR}
    cp -rn /ComfyUI/. ${COMFYUI_DIR}/
fi

# PASO 2: Preparar Directorios
mkdir -p ${COMFYUI_DIR}/models/loras \
         ${COMFYUI_DIR}/models/checkpoints \
         ${COMFYUI_DIR}/models/diffusion_models \
         ${COMFYUI_DIR}/models/text_encoders \
         ${COMFYUI_DIR}/models/vae \
         ${COMFYUI_DIR}/models/ultralytics/bbox \
         ${COMFYUI_DIR}/models/ultralytics/segm \
         ${COMFYUI_DIR}/models/sam3
         

# ── Funciones de descarga ─────────────────────────────────────────────────────

download_if_missing() {
    local url="$1" dest="$2" auth="$3"
    if [ -f "$dest" ] && [ -s "$dest" ]; then return 0; fi
    echo "  Descargando: $(basename $dest)"
    if [ -n "$auth" ]; then
        wget -q --show-progress --header="Authorization: Bearer $auth" -O "$dest" "$url"
    else
        wget -q --show-progress -O "$dest" "$url"
    fi
}

download_hf_repo() {
    local repo="$1" dest_dir="$2"
    echo "  Descargando repo HF: $repo en $dest_dir"
    HF_TOKEN=${HF_TOKEN} huggingface-cli download "$repo" --local-dir "$dest_dir" --local-dir-use-symlinks False
}

# ── SECCIÓN DE DESCARGAS (Nuevos Comandos Integrados) ─────────────────────────

# --- LORAS ---
echo "[ LoRAs ]"
cd ${COMFYUI_DIR}/models/loras && rm -rf split_files/
# Nuevos repos solicitados
download_hf_repo "exjadev/fuelling-zimage-lora" "."
download_hf_repo "exjadev/fuelling-sdxl-v2" "."
# Civitai Instagram Filter
download_if_missing "https://civitai.red/api/download/models/2617751?type=Model&format=SafeTensor&token=e3a803e3831ec4832fd75d014b2d385e" \
    "instagram-filter.safetensors"

# --- CHECKPOINTS ---
echo "[ Checkpoints ]"
cd ${COMFYUI_DIR}/models/checkpoints && rm -rf split_files/
download_if_missing "https://civitai.red/api/download/models/2755468?type=Model&format=SafeTensor&size=full&fp=fp16&token=e3a803e3831ec4832fd75d014b2d385e" \
    "sdxl_nsfw.safetensors"

# --- DIFFUSION MODELS ---
echo "[ Diffusion Models ]"
cd ${COMFYUI_DIR}/models/diffusion_models && rm -rf split_files/
download_if_missing "https://huggingface.co/vantagewithai/Z-Image-Turbo-GGUF/resolve/main/z_image_turbo-bf16.gguf" \
    "z_image_turbo-bf16.gguf"

# --- TEXT ENCODERS ---
echo "[ Text Encoders ]"
cd ${COMFYUI_DIR}/models/text_encoders && rm -rf split_files/
download_if_missing "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/text_encoders/qwen_3_4b.safetensors" \
    "qwen_3_4b.safetensors"

# ── BBOX Ultralytics ──────────────────────────────────────────────────────────
echo ""
echo "[ BBOX Ultralytics ]"
cd ${COMFYUI_DIR}/models/ultralytics/bbox && rm -rf split_files/
download_if_missing "https://huggingface.co/Bingsu/adetailer/resolve/main/face_yolov8m.pt" \
    "face_yolov8m.pt"


# --- VAE ---
echo "[ VAE ]"
cd ${COMFYUI_DIR}/models/vae && rm -rf split_files/
download_if_missing "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/vae/ae.safetensors" \
    "ae.safetensors"

# --- SAM3 ---
echo "[ SAM3 ]"
cd ${COMFYUI_DIR}/models/sam3
download_if_missing "https://huggingface.co/facebook/sam3/resolve/main/sam3.pt" \
    "sam3.pt" "$HF_TOKEN"


    # ── SAMS (ReActor/Segment Anything) ──────────────────────────────────────────
echo "[ SAM3 ]"
cd ${COMFYUI_DIR}/models/sams
download_if_missing "https://huggingface.co/datasets/Gourieff/ReActor/resolve/main/models/sams/sam_vit_b_01ec64.pth" \
    "sam_vit_b_01ec64.pth" 

# ── Lanzar ComfyUI ────────────────────────────────────────────────────────────
echo ""
echo "================================================"
echo "  Setup full. starting ComfyUI..."
echo "================================================"

exec python /workspace/ComfyUI/main.py --listen 0.0.0.0 --port 8188