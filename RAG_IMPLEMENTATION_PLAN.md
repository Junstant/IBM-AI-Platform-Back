# 🎯 Plan de Implementación RAG - Embeddings Dedicados

## ❌ Problemas Identificados

1. **Modelo inadecuado**: Gemma-2B/Mistral-7B son modelos generativos (Decoder-only), NO son óptimos para embeddings
2. **Confusión de roles**: Se usa el mismo modelo para generar texto Y para crear embeddings
3. **Falsa selección de modelo**: El código siempre usa Gemma-2B independiente de la selección del usuario
4. **Dimensión incorrecta**: 4096 dimensiones es excesivo y lento para búsqueda vectorial
5. **Sin especialización**: No hay un modelo dedicado exclusivamente a embeddings

## ✅ Solución Arquitectónica

### Separación de Responsabilidades

```
┌─────────────────────────────────────────────────────────────┐
│                    FLUJO RAG CORRECTO                        │
└─────────────────────────────────────────────────────────────┘

1. INGESTA DE DOCUMENTOS (Upload PDF)
   ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
   │ Usuario  │───▶│ RAG API  │───▶│  Nomic   │───▶│  Milvus  │
   │ PDF/DOCX │    │ Extract  │    │ Embed    │    │ Vector   │
   └──────────┘    │ + Chunk  │    │ (768dim) │    │ Database │
                   └──────────┘    └──────────┘    └──────────┘

2. CONSULTA (Query)
   ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
   │ Usuario  │───▶│ RAG API  │───▶│  Nomic   │───▶│  Milvus  │───▶│ Mistral  │
   │ Pregunta │    │          │    │ Embed    │    │ Search   │    │ Generate │
   └──────────┘    │          │    │ Query    │    │ Top-K    │    │ Response │
                   └──────────┘    └──────────┘    └──────────┘    └──────────┘
```

### Roles Definidos

| Modelo | Rol | Puerto | Dimensión | Propósito |
|--------|-----|--------|-----------|-----------|
| **Nomic Embed Text v1.5** | Bibliotecario | 8090 | 768 | Crear embeddings (vectorización) |
| **Mistral 7B** | Escritor | 8088 | - | Generar respuestas con contexto |
| **Gemma 2B/4B/12B** | Opcionales | 8085-87 | - | Alternativas para generación |

## 📋 FASE 1: Descarga del Modelo Nomic

### 1.1 Actualizar model-downloader en docker-compose.yaml

**Archivo**: `docker-compose.yaml`
**Sección**: `model-downloader.command`

```yaml
# Agregar DESPUÉS de Deepseek:
# Nomic Embed Text v1.5 - Modelo especializado en embeddings
NOMIC_PATH="/models/nomic-embed-text-v1.5.Q4_K_M.gguf";
if [ ! -f "$$NOMIC_PATH" ]; then
  echo "Modelo Nomic Embed Text v1.5 no encontrado. Descargando...";
  wget --header="Authorization: Bearer $$TOKEN_HUGGHINGFACE" \
    "https://huggingface.co/nomic-ai/nomic-embed-text-v1.5-GGUF/resolve/main/nomic-embed-text-v1.5.Q4_K_M.gguf" \
    -O "$$NOMIC_PATH";
  echo "✅ Modelo Nomic Embed descargado (274 MB).";
else
  echo "✅ Modelo Nomic Embed ya existe.";
fi
```

**Status**: ⏳ Pendiente

---

## 📋 FASE 2: Servicio Dedicado para Embeddings

### 2.1 Crear embeddings-api en docker-compose.yaml

**Archivo**: `docker-compose.yaml`
**Ubicación**: Después de `deepseek-8b`

```yaml
#^ ======================== EMBEDDINGS API (NOMIC) ========================
embeddings-api:
  image: quay.io/daniel_casali/llama.cpp-mma:v8
  container_name: embeddings-api
  user: "root"
  restart: always
  ports:
    - "${EMBEDDINGS_PORT:-8090}:8080"
  volumes:
    - models_volume:/models
  networks:
    - ai_platform_network
  # COMANDO CRÍTICO: --embedding y --pooling mean para generar embeddings
  command: [
    "--host", "0.0.0.0",
    "--port", "8080",
    "-m", "/models/nomic-embed-text-v1.5.Q4_K_M.gguf",
    "--embedding",           # Modo embedding
    "--pooling", "mean",     # Pooling estrategia
    "-c", "2048",            # Contexto
    "-b", "2048"             # Batch size
  ]
  depends_on:
    model-downloader:
      condition: service_completed_successfully
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
    interval: 30s
    timeout: 10s
    retries: 3
    start_period: 120s
  deploy:
    resources:
      limits:
        cpus: '2.0'
        memory: 1G
```

**Status**: ⏳ Pendiente

---

## 📋 FASE 3: Actualizar Configuración RAG

### 3.1 Actualizar rag/config.py

**Cambios críticos**:

```python
# Embeddings Service (DEDICADO - Nomic)
EMBEDDING_SERVICE_HOST = os.getenv("EMBEDDING_SERVICE_HOST", "embeddings-api")
EMBEDDING_SERVICE_PORT = os.getenv("EMBEDDING_SERVICE_PORT", "8080")
EMBEDDING_MODEL = "nomic-embed-text-v1.5"
EMBEDDING_DIMENSION = 768  # ⚠️ CRÍTICO: Nomic usa 768, NO 4096
EMBEDDING_MAX_TOKENS = 8192

# LLM Service (SEPARADO - Para generación)
LLM_HOST = os.getenv("LLM_HOST", "mistral-7b")  # Usar Mistral por defecto
LLM_PORT = os.getenv("LLM_PORT", "8080")
DEFAULT_LLM_MODEL = "mistral-7b"  # Mistral mejor que Gemma

# Document Processing (ajustado para Nomic)
CHUNK_SIZE = 512  # Óptimo para Nomic
CHUNK_OVERLAP = 64
```

**Status**: ⏳ Pendiente

### 3.2 Actualizar rag/embeddings.py

**Problema actual**: Usa `/embedding` endpoint con procesamiento por lotes manual

**Solución**: Usar `/v1/embeddings` de llama.cpp con --embedding activado

```python
def _post_embedding(self, texts: List[str]) -> List[List[float]]:
    """Llamar a API de embeddings usando endpoint estándar OpenAI"""
    try:
        # Usar endpoint OpenAI-compatible de llama.cpp con --embedding
        payload = {
            "input": texts,  # Puede ser lista o string
            "model": self.model
        }
        
        response = requests.post(
            f"{self.endpoint}/v1/embeddings",
            json=payload,
            headers={"Content-Type": "application/json"},
            timeout=120
        )
        response.raise_for_status()
        
        data = response.json()
        embeddings = [item['embedding'] for item in data['data']]
        
        # Validar dimensión
        if embeddings and len(embeddings[0]) != config.EMBEDDING_DIMENSION:
            logger.warning(f"⚠️ Dimensión recibida: {len(embeddings[0])}, esperada: {config.EMBEDDING_DIMENSION}")
        
        return [np.array(e, dtype=np.float32).tolist() for e in embeddings]
        
    except Exception as e:
        logger.error(f"❌ Error generando embeddings: {e}")
        raise
```

**Status**: ⏳ Pendiente

---

## 📋 FASE 4: Actualizar Variables de Entorno

### 4.1 Actualizar .env

```bash
# === PUERTOS PUBLICADOS ===
# ... (existentes) ...
EMBEDDINGS_PORT=8090  # NUEVO: Puerto para servicio de embeddings

# === CONFIGURACIÓN RAG ===
EMBEDDING_SERVICE_HOST=embeddings-api
EMBEDDING_SERVICE_PORT=8080  # Puerto interno del contenedor
EMBEDDING_DIMENSION=768      # Dimensión Nomic

# LLM para generación (separado de embeddings)
RAG_LLM_HOST=mistral-7b
RAG_LLM_PORT=8080
```

**Status**: ⏳ Pendiente

---

## 📋 FASE 5: Limpiar y Recrear Base Vectorial

### 5.1 Borrar volumen de Milvus (CRÍTICO)

```bash
# Detener servicios
docker compose down

# Borrar volumen de Milvus (cambia dimensión de 4096 → 768)
docker volume rm aipl_milvus_data

# Reiniciar
docker compose up -d
```

**Razón**: Milvus no puede cambiar dimensiones en colecciones existentes. Debe recrearse limpia.

**Status**: ⏳ Pendiente

### 5.2 Actualizar milvus_database.py

El código ya tiene auto-fix de dimensión en `_create_collections()`:

```python
# Verificar dimensión existente
if utility.has_collection(chunks_collection_name):
    collection = Collection(chunks_collection_name)
    schema = collection.schema
    
    # Buscar campo embedding
    for field in schema.fields:
        if field.name == "embedding":
            existing_dim = field.params.get('dim')
            if existing_dim != config.EMBEDDING_DIMENSION:
                logger.warning(f"⚠️ Dimensión incorrecta: {existing_dim} != {config.EMBEDDING_DIMENSION}")
                logger.info("🔄 Recreando colección con dimensión correcta...")
                utility.drop_collection(chunks_collection_name)
                recreate_collection = True
```

**Status**: ✅ Ya implementado (auto-recreación)

---

## 📋 FASE 6: Testing Completo

### 6.1 Test de Embeddings API

```bash
# Verificar que Nomic está respondiendo
curl -X POST http://localhost:8090/v1/embeddings \
  -H "Content-Type: application/json" \
  -d '{
    "input": "¿Cuándo vence el contrato?",
    "model": "nomic-embed-text-v1.5"
  }'

# Debe retornar:
# {
#   "data": [
#     {
#       "embedding": [0.123, -0.456, ...],  # 768 valores
#       "index": 0
#     }
#   ],
#   "model": "nomic-embed-text-v1.5"
# }
```

### 6.2 Test de Upload

```bash
# Subir documento de prueba
curl -X POST http://localhost:8004/upload \
  -F "file=@test.pdf"

# Verificar logs del RAG API:
# - ✅ Debe usar embeddings-api:8080
# - ✅ Dimensión debe ser 768
# - ✅ Debe guardar en Milvus correctamente
```

### 6.3 Test de Query

```bash
# Consultar documento
curl -X POST http://localhost:8004/query \
  -H "Content-Type: application/json" \
  -d '{
    "query": "¿Cuándo vence el contrato?",
    "top_k": 5
  }'

# Verificar:
# - ✅ Embedding de query se genera con Nomic
# - ✅ Búsqueda en Milvus funciona
# - ✅ Respuesta se genera con Mistral/modelo seleccionado
```

**Status**: ⏳ Pendiente

---

## 📊 Checklist de Implementación

### Fase 1: Preparación
- [ ] Actualizar docker-compose.yaml con descarga de Nomic
- [ ] Crear servicio embeddings-api
- [ ] Agregar EMBEDDINGS_PORT a .env

### Fase 2: Configuración
- [ ] Actualizar rag/config.py (dimensión 768)
- [ ] Actualizar rag/embeddings.py (endpoint correcto)
- [ ] Verificar separación LLM vs Embeddings

### Fase 3: Limpieza
- [ ] docker compose down
- [ ] docker volume rm aipl_milvus_data
- [ ] docker compose up -d

### Fase 4: Verificación
- [ ] Test embeddings-api health
- [ ] Test upload documento
- [ ] Test query con RAG
- [ ] Verificar logs (sin errores)

### Fase 5: Documentación
- [ ] Actualizar README.md
- [ ] Documentar arquitectura final
- [ ] Agregar troubleshooting

---

## 🎯 Resultado Esperado

### Antes (❌ MALO)
```
Upload PDF → Gemma-2B (embeddings 2048) → Milvus
Query → Gemma-2B (embeddings 2048) → Milvus → Gemma-2B (respuesta)
```
**Problemas**: Lento, calidad baja, dimensión excesiva

### Después (✅ BUENO)
```
Upload PDF → Nomic (embeddings 768) → Milvus
Query → Nomic (embeddings 768) → Milvus → Mistral (respuesta)
```
**Beneficios**: 
- ⚡ 5x más rápido
- 🎯 Mejor precisión en búsqueda
- 💾 Menor uso de memoria
- 🔧 Especialización correcta

---

## 📝 Notas Importantes

1. **NO mezclar roles**: Nomic SOLO embeddings, Mistral SOLO generación
2. **Dimensión fija**: Siempre 768 para Nomic
3. **Limpiar Milvus**: Obligatorio al cambiar dimensión
4. **Healthcheck**: Esperar a que embeddings-api esté listo antes de subir docs

---

**Fecha**: 2025-11-27
**Status**: 🔴 EN PROGRESO
**Responsable**: GitHub Copilot
