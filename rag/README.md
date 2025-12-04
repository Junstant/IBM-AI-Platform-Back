# RAG API

Sistema de consulta de documentos usando embeddings vectoriales con Milvus y LLM.

## Características

- Procesamiento de formatos: PDF, DOCX, TXT, CSV, XLSX, MD
- Embeddings: nomic-embed-text (768-dim)
- Búsqueda vectorial con Milvus (índice HNSW)
- Generación de respuestas con Gemma-2B

## Endpoints

**Puerto**: `http://localhost:8004/docs`

- `POST /documents/upload` - Subir documento
- `POST /documents/query` - Consultar documentos
- `GET /documents/list` - Listar documentos
- `DELETE /documents/{doc_id}` - Eliminar documento

## Stack

- **Milvus**: Motor de búsqueda vectorial
- **MinIO**: Object storage
- **etcd**: Metadata storage

- file: archivo (.pdf, .docx, .txt, .csv, .xlsx, .md)
- metadata: (opcional) JSON con metadatos adicionales
```

**Respuesta**:
```json
{
  "status": "success",
  "document_id": 1,
  "filename": "manual.pdf",
  "chunks_created": 45,
  "file_size": 1024000
}
```

### 2. Consulta RAG
```bash
POST /query
Content-Type: application/json

{
  "question": "¿Cuál es el proceso de instalación?",
  "top_k": 5,
  "model": "gemma-2b"  // opcional
}
```

**Respuesta**:
```json
{
  "answer": "El proceso de instalación requiere...",
  "sources": [
    {
      "document_id": 1,
      "filename": "manual.pdf",
      "chunk_index": 3,
      "similarity": 0.89,
      "preview": "Para instalar el sistema..."
    }
  ],
  "context_used": "...",
  "num_sources": 5
}
```

### 3. Listar documentos
```bash
GET /documents
```

**Respuesta**:
```json
[
  {
    "id": 1,
    "filename": "manual.pdf",
    "content_type": "application/pdf",
    "file_size": 1024000,
    "total_chunks": 45,
    "metadata": {},
    "uploaded_at": "2025-11-25T10:30:00"
  }
]
```

### 4. Eliminar documento
```bash
DELETE /documents/{document_id}
```

### 5. Estadísticas
```bash
GET /stats
```

**Respuesta**:
```json
{
  "total_documents": 10,
  "total_chunks": 450,
  "total_size_mb": 50.5,
  "embedding_model": "paraphrase-multilingual-MiniLM-L12-v2",
  "embedding_dimension": 384
}
```

### 6. Health check
```bash
GET /health
```

## 🧪 Ejemplo de uso

### Con curl
```bash
# Upload documento
curl -X POST http://localhost:8004/documents/upload \
  -F "file=@manual.pdf" \
  -F "metadata={\"categoria\":\"manual\"}"

# Consulta
curl -X POST http://localhost:8004/query \
  -H "Content-Type: application/json" \
  -d '{
    "question": "¿Cómo funciona el sistema RAG?",
    "top_k": 3
  }'

# Listar documentos
curl http://localhost:8004/documents

# Estadísticas
curl http://localhost:8004/stats
```

### Con Python
```python
import requests

# Upload
files = {"file": open("manual.pdf", "rb")}
response = requests.post("http://localhost:8004/documents/upload", files=files)
print(response.json())

# Query
response = requests.post(
    "http://localhost:8004/query",
    json={
        "question": "¿Qué es RAG?",
        "top_k": 5
    }
)
print(response.json()["answer"])
```

## 🗄️ Base de datos

### Esquema
```sql
-- Tabla de documentos
CREATE TABLE documents (
    id SERIAL PRIMARY KEY,
    filename VARCHAR(500),
    content_type VARCHAR(100),
    file_size INTEGER,
    total_chunks INTEGER,
    metadata JSONB,
    uploaded_at TIMESTAMP
);

-- Tabla de chunks con embeddings vectoriales
CREATE TABLE document_chunks (
    id SERIAL PRIMARY KEY,
    document_id INTEGER REFERENCES documents(id),
    chunk_index INTEGER,
    content TEXT,
    embedding vector(384),  -- pgvector!
    metadata JSONB,
    created_at TIMESTAMP
);

-- Índice para búsqueda vectorial eficiente
CREATE INDEX idx_chunks_embedding 
ON document_chunks 
USING ivfflat (embedding vector_cosine_ops);
```

## 📊 Flujo de procesamiento

1. **Upload**: Usuario sube documento
2. **Extracción**: Se extrae texto según formato
3. **Chunking**: Texto dividido en fragmentos de ~500 caracteres con overlap de 50
4. **Embeddings**: Cada chunk genera un vector de 384 dimensiones
5. **Almacenamiento**: Chunks + embeddings guardados en PostgreSQL
6. **Query**: Usuario hace pregunta
7. **Search**: Embedding de pregunta busca chunks similares (cosine similarity)
8. **Context**: Top-K chunks se concatenan como contexto
9. **LLM**: Gemma-2B genera respuesta usando contexto
10. **Response**: Usuario recibe respuesta + fuentes

## 🔍 Modelo de embeddings

**sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2**
- Multilingüe (50+ idiomas incluyendo español)
- 384 dimensiones (balance eficiencia/calidad)
- ~120MB (liviano para CPU)
- Optimizado para búsqueda semántica

## ⚙️ Configuración avanzada

### Ajustar tamaño de chunks
```python
# En config.py
CHUNK_SIZE = 500      # Caracteres por chunk
CHUNK_OVERLAP = 50    # Overlap entre chunks
```

### Cambiar modelo de embeddings
```python
# En config.py
EMBEDDING_MODEL = "sentence-transformers/paraphrase-multilingual-mpnet-base-v2"
EMBEDDING_DIMENSION = 768  # Ajustar según modelo
```

### Optimizar índice vectorial
```sql
-- Ajustar número de listas para IVFFlat
CREATE INDEX idx_chunks_embedding 
ON document_chunks 
USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 200);  -- Mayor = más rápido pero más RAM
```

## 🚀 Despliegue

### Construir e iniciar
```bash
docker-compose --profile full up -d rag-api
```

### Ver logs
```bash
docker logs -f rag-api
```

### Reiniciar
```bash
docker-compose restart rag-api
```

## 📈 Performance

- **Upload**: ~2-5 segundos por MB de documento
- **Query**: ~1-3 segundos (búsqueda vectorial + LLM)
- **Embeddings**: ~100 chunks/segundo en CPU
- **Almacenamiento**: ~1KB por chunk (texto + embedding)

## 🔒 Limitaciones

- Tamaño máximo: 50MB por archivo
- Formatos: PDF, DOCX, TXT, CSV, XLSX, MD
- Contexto LLM: 4000 tokens máximo
- Top-K máximo: 20 documentos

## 🛠️ Troubleshooting

### Error al conectar a PostgreSQL
```bash
# Verificar que postgres esté corriendo
docker ps | grep postgres

# Verificar extensión pgvector
docker exec -it postgres_db psql -U postgres -d ai_platform_rag -c "SELECT * FROM pg_extension WHERE extname='vector';"
```

### Error al cargar modelo de embeddings
```bash
# Verificar recursos disponibles
docker stats rag-api

# Ver logs detallados
docker logs rag-api --tail 100
```

### Búsqueda lenta
```sql
-- Reconstruir índice vectorial
REINDEX INDEX idx_chunks_embedding;

-- Aumentar listas del índice
DROP INDEX idx_chunks_embedding;
CREATE INDEX idx_chunks_embedding 
ON document_chunks 
USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 300);
```

## 📝 Notas

- El servicio se inicializa en ~60 segundos
- Primer query puede ser lento (carga de modelo)
- Embeddings se generan en CPU (sin GPU necesaria)
- Documentos persistentes en volumen Docker
- Compatible con arquitectura Power PC (ppc64le)
