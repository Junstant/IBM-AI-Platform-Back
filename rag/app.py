"""
🧠 RAG API - Retrieval-Augmented Generation
===========================================
Sistema completo de RAG con embeddings vectoriales y LLM
"""
import logging
import time
from typing import List, Optional
from pathlib import Path
from datetime import datetime

from fastapi import FastAPI, UploadFile, File, HTTPException, Form
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

# Importar componentes locales
from config import config
from milvus_database import MilvusRAGDatabase  # Milvus Vector Database
from document_processor import DocumentProcessor
from embeddings import EmbeddingsGenerator, get_embeddings_generator
from llm_client import LLMClient, get_llm_client

# Configurar logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# =====================================================
# MODELOS PYDANTIC
# =====================================================

class QueryRequest(BaseModel):
    """Solicitud de consulta"""
    query: str = Field(..., description="Pregunta o consulta del usuario")
    top_k: int = Field(5, ge=1, le=20, description="Número de resultados")

class QueryResponse(BaseModel):
    """Respuesta de consulta"""
    answer: str = Field(..., description="Respuesta generada")
    sources: List[dict] = Field(..., description="Chunks relevantes encontrados")
    query: str = Field(..., description="Consulta original")
    query_time: float = Field(..., description="Tiempo de query en segundos")

class DocumentInfo(BaseModel):
    """Información de documento"""
    id: int
    filename: str
    content_type: str
    file_size: int
    total_chunks: int
    uploaded_at: datetime

class StatsResponse(BaseModel):
    """Estadísticas del sistema"""
    total_documents: int
    total_chunks: int
    total_size_bytes: int
    embedding_model: str = Field(description="Modelo de embeddings actual")
    llm_model: str = Field(description="Modelo LLM actual")
    embedding_dimension: int = Field(description="Dimensión de vectores")
    milvus_connected: bool = Field(description="Estado de Milvus")

# =====================================================
# APLICACIÓN FASTAPI
# =====================================================

app = FastAPI(
    title="🧠 RAG API - Retrieval-Augmented Generation",
    description="Sistema RAG completo con embeddings vectoriales y LLM para respuestas inteligentes",
    version="2.0.0"
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# =====================================================
# VARIABLES GLOBALES
# =====================================================

db = None
embeddings_gen = None
llm_client = None
current_llm_model = config.DEFAULT_LLM_MODEL
current_embedding_model = config.EMBEDDING_MODEL  # ✅ Usar modelo de embeddings correcto

# =====================================================
# EVENTOS DE CICLO DE VIDA
# =====================================================

@app.on_event("startup")
async def startup():
    """Inicializar componentes al arrancar"""
    global db, embeddings_gen, llm_client
    try:
        logger.info("🚀 Iniciando RAG API con Milvus Vector Database...")
        
        # Inicializar Milvus Vector Database
        db = MilvusRAGDatabase()
        logger.info("✅ Milvus Vector Database inicializado y listo")
        
        # Inicializar generador de embeddings (REQUERIDO para embeddings vectoriales)
        embeddings_gen = get_embeddings_generator()
        logger.info("✅ Generador de embeddings inicializado")
        
        # Inicializar cliente LLM
        llm_client = get_llm_client()
        logger.info("✅ Cliente LLM inicializado")
        
        logger.info("🎉 RAG API lista con Milvus + Embeddings + LLM!")
    except Exception as e:
        logger.error(f"❌ Error en startup: {e}")
        raise

@app.on_event("shutdown")
async def shutdown():
    """Limpieza al cerrar"""
    logger.info("👋 Cerrando RAG API...")

# =====================================================
# ENDPOINTS
# =====================================================

@app.get("/models")
async def get_models():
    """
    📋 Obtener modelos disponibles para embeddings y LLM
    """
    return {
        "embedding_models": [
            {
                "id": model_id,
                "name": model_info["name"],
                "description": model_info["description"],
                "dimensions": model_info["dimensions"]
            }
            for model_id, model_info in config.AVAILABLE_EMBEDDING_MODELS.items()
        ],
        "llm_models": [
            {
                "id": model_id,
                "name": model_info["name"],
                "description": model_info.get("description", "")  # ✅ Usar .get() para evitar KeyError
            }
            for model_id, model_info in config.AVAILABLE_LLM_MODELS.items()
        ],
        "current": {
            "embedding_model": current_embedding_model,
            "llm_model": current_llm_model
        }
    }

@app.get("/health")
async def health_check():
    """Health check con información de Milvus Vector Database"""
    return {
        "status": "healthy",
        "service": "RAG API v3 with Milvus Vector Database",
        "version": "3.0.0",
        "features": {
            "vector_database": "Milvus v2.3.1 with HNSW index",
            "embeddings": "enabled" if embeddings_gen else "disabled",
            "llm": "enabled" if llm_client else "disabled",
            "vector_search": "HNSW (high-performance similarity search)"
        },
        "milvus": "connected" if db else "disconnected",
        "milvus_host": f"{config.MILVUS_HOST}:{config.MILVUS_PORT}",
        "embedding_model": config.EMBEDDING_MODEL,
        "embedding_dimension": config.EMBEDDING_DIMENSION,
        "llm_model": current_llm_model
    }

@app.post("/upload", response_model=DocumentInfo)
async def upload_document(
    file: UploadFile = File(...),
    embedding_model: str = None,
    llm_model: str = None
):
    """📤 Subir documento y procesarlo en chunks con embeddings"""
    global embeddings_gen, llm_client, current_embedding_model, current_llm_model
    try:
        # Cambiar modelo de embeddings si se especifica
        if embedding_model and embedding_model != current_embedding_model:
            if embedding_model not in config.AVAILABLE_EMBEDDING_MODELS:
                raise HTTPException(status_code=400, detail=f"Modelo no válido: {embedding_model}")
            current_embedding_model = embedding_model
            embeddings_gen = EmbeddingsGenerator()  # Reinicializar con nuevo modelo
            logger.info(f"🔄 Modelo de embeddings cambiado a: {embedding_model}")
        
        # Cambiar modelo LLM si se especifica
        if llm_model and llm_model != current_llm_model:
            if llm_model not in config.AVAILABLE_LLM_MODELS:
                raise HTTPException(status_code=400, detail=f"Modelo LLM no válido: {llm_model}")
            current_llm_model = llm_model
            llm_client = get_llm_client()  # Reinicializar con nuevo modelo
            logger.info(f"🔄 Modelo LLM cambiado a: {llm_model}")
        
        logger.info(f"📤 Subiendo documento: {file.filename}")
        
        # Validar tipo de archivo
        if not file.filename:
            raise HTTPException(status_code=400, detail="Nombre de archivo vacío")
        
        file_extension = Path(file.filename).suffix.lower()
        if file_extension not in config.ALLOWED_EXTENSIONS:
            raise HTTPException(
                status_code=400, 
                detail=f"Tipo de archivo no soportado: {file_extension}. Permitidos: {config.ALLOWED_EXTENSIONS}"
            )
        
        # Leer contenido del archivo
        content = await file.read()
        file_size = len(content)
        
        # Extraer texto del documento
        logger.info("📄 Extrayendo texto...")
        text_content = DocumentProcessor.extract_text(content, file.filename)
        chunks = DocumentProcessor.chunk_text(text_content)
        logger.info(f"✂️ Documento dividido en {len(chunks)} chunks")
        
        # Generar embeddings para cada chunk (REQUERIDO para búsqueda vectorial)
        logger.info("🔮 Generando embeddings vectoriales...")
        if not embeddings_gen:
            raise HTTPException(
                status_code=500, 
                detail="Servicio de embeddings no disponible"
            )
        
        embeddings = embeddings_gen.generate_embeddings_batch(chunks)
        logger.info(f"✅ {len(embeddings)} embeddings generados (dim: {config.EMBEDDING_DIMENSION})")
        
        # Preparar chunks con embeddings
        chunk_data = []
        for idx, (chunk, embedding) in enumerate(zip(chunks, embeddings)):
            chunk_data.append((idx, chunk, embedding, {}))
        
        # Insertar en Milvus
        doc_id = db.insert_document(
            filename=file.filename,
            content_type=file.content_type or "application/octet-stream",
            file_size=file_size,
            metadata={"chunks_count": len(chunks)}
        )
        
        db.insert_chunks(doc_id, chunk_data)
        
        logger.info(f"✅ Documento {doc_id} almacenado en Milvus: {len(chunks)} chunks vectorizados")
        
        return DocumentInfo(
            id=doc_id,
            filename=file.filename,
            content_type=file.content_type or "application/octet-stream",
            file_size=file_size,
            total_chunks=len(chunks),
            uploaded_at=datetime.now()
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Error subiendo documento: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Error procesando documento: {str(e)}")


@app.post("/query", response_model=QueryResponse)
async def query_documents(request: QueryRequest):
    """🔍 Búsqueda inteligente con embeddings vectoriales y respuesta generada por LLM"""
    start_time = time.time()
    try:
        logger.info(f"🔍 Consultando: '{request.query}' (top_k={request.top_k})")
        
        # Generar embedding de la consulta (REQUERIDO para búsqueda vectorial)
        if not embeddings_gen:
            raise HTTPException(
                status_code=500, 
                detail="Servicio de embeddings no disponible"
            )
        
        logger.info("🔮 Generando embedding de consulta...")
        query_embedding = embeddings_gen.generate_embedding(request.query)
        
        # Búsqueda vectorial semántica en Milvus (cosine similarity)
        results = db.similarity_search(query_embedding, top_k=request.top_k)
        logger.info(f"📊 Búsqueda vectorial Milvus: {len(results)} resultados")
        
        if not results:
            raise HTTPException(
                status_code=404, 
                detail="No se encontraron documentos relevantes"
            )
        
        # Construir contexto para el LLM
        context_parts = []
        for i, r in enumerate(results, 1):
            context_parts.append(
                f"[Fuente {i}: {r['filename']}]\n{r['content']}"
            )
        
        context = "\n\n---\n\n".join(context_parts)
        
        # Generar respuesta usando LLM
        logger.info("🤖 Generando respuesta con LLM...")
        answer = await llm_client.generate_rag_response(request.query, context)
        
        # Preparar fuentes
        sources = []
        for r in results:
            sources.append({
                "document_id": r["document_id"],
                "filename": r["filename"],
                "chunk_index": r["chunk_index"],
                "similarity": r["similarity"],
                "preview": r["content"][:200] + "..." if len(r["content"]) > 200 else r["content"]
            })
        
        query_time = time.time() - start_time
        logger.info(f"✅ Respuesta generada con {len(sources)} fuentes (tiempo: {query_time:.2f}s)")
        
        return QueryResponse(
            answer=answer,
            sources=sources,
            query=request.query,
            query_time=query_time
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Error en consulta: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/stats", response_model=StatsResponse)
async def get_stats():
    """📊 Obtener estadísticas del sistema"""
    try:
        stats = db.get_document_stats()
        return StatsResponse(
            total_documents=stats['total_documents'],
            total_chunks=stats['total_chunks'],
            total_size_bytes=stats['total_size_bytes'],
            embedding_model=config.EMBEDDING_MODEL,
            llm_model=current_llm_model,
            embedding_dimension=config.EMBEDDING_DIMENSION,
            milvus_connected=True if db else False
        )
    except Exception as e:
        logger.error(f"❌ Error obteniendo estadísticas: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# =====================================================
# ENDPOINT RAÍZ
# =====================================================

@app.get("/")
async def root():
    """Información de la API RAG con Milvus"""
    return {
        "service": "🧠 RAG API v2 - Retrieval-Augmented Generation with Milvus",
        "version": "2.0.0",
        "description": "Sistema RAG de alta performance con Milvus vector database",
        "status": "running",
        "technology": {
            "vector_database": "Milvus (production-grade)",
            "search_algorithm": "HNSW (ultra-fast)",
            "embeddings": f"{config.EMBEDDING_MODEL} ({config.EMBEDDING_DIMENSION}D)",
            "llm": f"{config.LLM_HOST}",
            "performance": "Billions of vectors @ < 10ms latency"
        },
        "features": {
            "semantic_search": "✅ Búsqueda semántica avanzada",
            "vector_similarity": "✅ Cosine similarity HNSW indexed",
            "llm_generation": "✅ Respuestas contextualizadas",
            "supported_formats": ["PDF", "DOCX", "TXT", "CSV", "XLSX", "MD"]
        },
        "endpoints": {
            "health": "GET /health - Estado del sistema",
            "models": "GET /models - Modelos disponibles",
            "upload": "POST /upload - Subir documento + vectorización automática",
            "query": "POST /query - Búsqueda semántica + respuesta LLM",
            "documents": "GET /documents - Listar documentos",
            "delete": "DELETE /documents/{id} - Eliminar documento",
            "stats": "GET /stats - Estadísticas Milvus",
            "docs": "GET /docs - Documentación Swagger"
        },
        "milvus_info": {
            "host": config.MILVUS_HOST,
            "port": config.MILVUS_PORT,
            "collection": "rag_chunks",
            "index_type": "HNSW",
            "metric": "COSINE"
        }
    }


