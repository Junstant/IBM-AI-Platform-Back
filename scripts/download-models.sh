#!/bin/bash

# Script para descargar modelos de Hugging Face manualmente
echo "📥 DESCARGADOR DE MODELOS DE HUGGING FACE"
echo "========================================="

cd "$(dirname "$0")/.."

# Crear directorio de modelos si no existe
mkdir -p models

# Función para descargar modelo con progreso
download_model() {
    local name="$1"
    local url="$2"
    local filename="$3"
    
    echo "📥 Descargando $name..."
    echo "URL: $url"
    echo "Archivo: $filename"
    
    if [ -f "models/$filename" ]; then
        echo "✅ $name ya existe"
        return 0
    fi
    
    echo "⏳ Iniciando descarga..."
    if curl -L --progress-bar -o "models/$filename" "$url"; then
        echo "✅ $name descargado exitosamente"
        ls -lh "models/$filename"
        return 0
    else
        echo "❌ Error descargando $name"
        rm -f "models/$filename"
        return 1
    fi
}

# Lista de modelos con sus URLs
declare -A MODELS=(
    ["mistral-7b"]="https://huggingface.co/SanctumAI/Mistral-7B-Instruct-v0.3-GGUF/resolve/main/mistral-7b-instruct-v0.3.Q4_K_M.gguf|mistral-7b-instruct-v0.3.Q4_K_M.gguf"
    ["gemma-2b"]="https://huggingface.co/lmstudio-community/gemma-2-2b-it-GGUF/resolve/main/gemma-2-2b-it-Q4_K_S.gguf|gemma-2-2b-it-Q4_K_S.gguf"
    ["granite-8b"]="https://huggingface.co/bartowski/granite-3.3-8b-instruct-GGUF/resolve/main/granite-3.3-8b-instruct-Q4_K_M.gguf|granite-3.3-8b-instruct-Q4_K_M.gguf"
    ["granite-2b"]="https://huggingface.co/bartowski/granite-3.1-2b-instruct-GGUF/resolve/main/granite-3.1-2b-instruct-Q4_K_M.gguf|granite-3.1-2b-instruct-Q4_K_M.gguf"
    ["gemma-4b"]="https://huggingface.co/bartowski/gemma-3-4b-it-GGUF/resolve/main/gemma-3-4b-it-IQ4_NL.gguf|google_gemma-3-4b-it-IQ4_NL.gguf"
    ["gemma-12b"]="https://huggingface.co/bartowski/gemma-3-12b-it-GGUF/resolve/main/gemma-3-12b-it-Q4_K_M.gguf|google_gemma-3-12b-it-Q4_K_M.gguf"
    ["deepseek-1.5b"]="https://huggingface.co/bartowski/DeepSeek-R1-Distill-Qwen-1.5B-GGUF/resolve/main/DeepSeek-R1-Distill-Qwen-1.5B-Q8_0.gguf|DeepSeek-R1-Distill-Qwen-1.5B-Q8_0.gguf"
    ["deepseek-8b"]="https://huggingface.co/bartowski/DeepSeek-R1-Distill-Llama-8B-GGUF/resolve/main/DeepSeek-R1-Distill-Llama-8B-Q4_K_L.gguf|DeepSeek-R1-Distill-Llama-8B-Q4_K_L.gguf"
    ["deepseek-14b"]="https://huggingface.co/bartowski/DeepSeek-R1-Distill-Qwen-14B-GGUF/resolve/main/DeepSeek-R1-Distill-Qwen-14B-Q4_K_M.gguf|DeepSeek-R1-Distill-Qwen-14B-Q4_K_M.gguf"
    ["gpt-oss-20b"]="https://huggingface.co/mradermacher/GPT-OSS-20B-GGUF/resolve/main/GPT-OSS-20B.f16.gguf|gpt-oss-20b-f16.gguf"
)

# Función para mostrar menú
show_menu() {
    echo ""
    echo "📋 MODELOS DISPONIBLES:"
    echo "======================"
    echo "1)  Mistral 7B (~4GB) - Modelo conversacional potente"
    echo "2)  Gemma 2B (~1.5GB) - Modelo pequeño y rápido"
    echo "3)  Granite 8B (~5GB) - Modelo IBM para código"
    echo "4)  Granite 2B (~1.5GB) - Modelo IBM pequeño"
    echo "5)  Gemma 4B (~2.5GB) - Modelo Google mediano"
    echo "6)  Gemma 12B (~7GB) - Modelo Google grande"
    echo "7)  DeepSeek 1.5B (~1GB) - Modelo pequeño razonamiento"
    echo "8)  DeepSeek 8B (~5GB) - Modelo mediano razonamiento"
    echo "9)  DeepSeek 14B (~8GB) - Modelo grande razonamiento"
    echo "10) GPT OSS 20B (~38GB) - Modelo muy grande"
    echo ""
    echo "a) Descargar modelos básicos (Gemma 2B + Granite 2B)"
    echo "b) Descargar modelos medianos (+ Mistral 7B + Granite 8B)"
    echo "c) Descargar todos los modelos"
    echo "s) Ver estado de descargas"
    echo "q) Salir"
    echo ""
}

# Función para mostrar estado
show_status() {
    echo ""
    echo "📊 ESTADO DE MODELOS:"
    echo "===================="
    total_size=0
    for key in "${!MODELS[@]}"; do
        IFS='|' read -r url filename <<< "${MODELS[$key]}"
        if [ -f "models/$filename" ]; then
            size=$(ls -lh "models/$filename" | awk '{print $5}')
            echo "✅ $key: $filename ($size)"
            # Sumar al total (aproximado)
            size_mb=$(ls -l "models/$filename" | awk '{print $5}')
            total_size=$((total_size + size_mb / 1024 / 1024))
        else
            echo "❌ $key: No descargado"
        fi
    done
    echo ""
    echo "💾 Espacio total usado: ~${total_size}MB"
    echo "📁 Directorio: $(pwd)/models"
}

# Función para descargar conjunto de modelos
download_set() {
    local models=("$@")
    for model in "${models[@]}"; do
        if [[ -v MODELS[$model] ]]; then
            IFS='|' read -r url filename <<< "${MODELS[$model]}"
            download_model "$model" "$url" "$filename"
            echo ""
        fi
    done
}

# Menú principal
while true; do
    show_menu
    read -p "Selecciona una opción: " choice
    
    case $choice in
        1)  IFS='|' read -r url filename <<< "${MODELS[mistral-7b]}"; download_model "Mistral 7B" "$url" "$filename" ;;
        2)  IFS='|' read -r url filename <<< "${MODELS[gemma-2b]}"; download_model "Gemma 2B" "$url" "$filename" ;;
        3)  IFS='|' read -r url filename <<< "${MODELS[granite-8b]}"; download_model "Granite 8B" "$url" "$filename" ;;
        4)  IFS='|' read -r url filename <<< "${MODELS[granite-2b]}"; download_model "Granite 2B" "$url" "$filename" ;;
        5)  IFS='|' read -r url filename <<< "${MODELS[gemma-4b]}"; download_model "Gemma 4B" "$url" "$filename" ;;
        6)  IFS='|' read -r url filename <<< "${MODELS[gemma-12b]}"; download_model "Gemma 12B" "$url" "$filename" ;;
        7)  IFS='|' read -r url filename <<< "${MODELS[deepseek-1.5b]}"; download_model "DeepSeek 1.5B" "$url" "$filename" ;;
        8)  IFS='|' read -r url filename <<< "${MODELS[deepseek-8b]}"; download_model "DeepSeek 8B" "$url" "$filename" ;;
        9)  IFS='|' read -r url filename <<< "${MODELS[deepseek-14b]}"; download_model "DeepSeek 14B" "$url" "$filename" ;;
        10) IFS='|' read -r url filename <<< "${MODELS[gpt-oss-20b]}"; download_model "GPT OSS 20B" "$url" "$filename" ;;
        a|A) 
            echo "📥 Descargando modelos básicos..."
            download_set "gemma-2b" "granite-2b"
            ;;
        b|B)
            echo "📥 Descargando modelos medianos..."
            download_set "gemma-2b" "granite-2b" "mistral-7b" "granite-8b"
            ;;
        c|C)
            echo "📥 Descargando todos los modelos..."
            download_set "gemma-2b" "granite-2b" "mistral-7b" "granite-8b" "gemma-4b" "gemma-12b" "deepseek-1.5b" "deepseek-8b" "deepseek-14b" "gpt-oss-20b"
            ;;
        s|S) show_status ;;
        q|Q) echo "👋 ¡Hasta luego!"; exit 0 ;;
        *) echo "❌ Opción no válida" ;;
    esac
    
    echo ""
    read -p "Presiona Enter para continuar..."
done