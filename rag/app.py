"""
🧠 RAG API - Retrieval-Augmented Generation
===========================================
Sistema completo de RAG con embeddings vectoriales y LLM
"""
import logging
from typing import List, Optional
from pathlib import Path
from datetime import datetime

from fastapi import FastAPI, UploadFile, File, HTTPException, Form
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

# Importar componentes locales
from config import config
from milvus_database import MilvusRAGDatabase
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
current_embedding_model = config.DEFAULT_LLM_MODEL

# =====================================================
# EVENTOS DE CICLO DE VIDA
# =====================================================

@app.on_event("startup")
async def startup():
    """Inicializar componentes al arrancar"""
    global db, embeddings_gen, llm_client
    try:
        logger.info("🚀 Iniciando RAG API con Milvus...")
        
        # Inicializar Milvus
        db = MilvusRAGDatabase()
        logger.info("✅ Milvus inicializado y listo")
        
        # Inicializar generador de embeddings (REQUERIDO para Milvus)
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
    """Health check con información de Milvus"""
    return {
        "status": "healthy",
        "service": "RAG API v2 with Milvus",
        "version": "2.0.0",
        "features": {
            "vector_database": "Milvus",
            "embeddings": "enabled" if embeddings_gen else "disabled",
            "llm": "enabled" if llm_client else "disabled",
            "vector_search": "HNSW (ultra-fast semantic search)"
        },
        "database": "Milvus connected" if db else "disconnected",
        "milvus_host": f"{config.MILVUS_HOST}:{config.MILVUS_PORT}",
        "embedding_model": current_embedding_model,
        "embedding_dimension": config.EMBEDDING_DIMENSION,
        "llm_model": current_llm_model
    }

@app.post("/upload", response_model=DocumentInfo)
async def upload_document(
    file: UploadFile = File(...),
    embedding_model: str = None,
    llm_model: str = None
):
    """
    📤 Subir documento y procesarlo en chunks con embeddings
    
    Soporta: PDF, DOCX, TXT, CSV, XLSX
    
    Parámetros:
    - file: Documento a procesar
    - embedding_model: Modelo para embeddings (opcional, usa el actual si no se especifica)
    - llm_model: Modelo LLM (opcional, usa el actual si no se especifica)
    """
    global embeddings_gen, llm_client, current_embedding_model, current_llm_model
    try:
        # Cambiar modelo de embeddings si se especifica
        if embedding_model and embedding_model != current_embedding_model:
            if embedding_model not in config.AVAILABLE_EMBEDDING_MODELS:
                raise HTTPException(
                    status_code=400,
                    detail=f"Modelo de embedding no válido: {embedding_model}"
                )
            logger.info(f"🔄 Cambiando modelo de embedding: {current_embedding_model} → {embedding_model}")
            model_info = config.AVAILABLE_EMBEDDING_MODELS[embedding_model]
            embeddings_gen = EmbeddingsGenerator(
                emb_model=embedding_model,
                emb_endpoint=f"http://{model_info['host']}:{model_info['port']}",
                emb_dimension=model_info['dimensions']
            )
            current_embedding_model = embedding_model
        
        # Cambiar modelo LLM si se especifica
        if llm_model and llm_model != current_llm_model:
            if llm_model not in config.AVAILABLE_LLM_MODELS:
                raise HTTPException(
                    status_code=400,
                    detail=f"Modelo LLM no válido: {llm_model}"
                )
            logger.info(f"🔄 Cambiando modelo LLM: {current_llm_model} → {llm_model}")
            model_info = config.AVAILABLE_LLM_MODELS[llm_model]
            llm_client = LLMClient(
                host=model_info['host'],
                port=model_info['port']
            )
            current_llm_model = llm_model
        
        logger.info(f"📤 Subiendo documento: {file.filename}")
        
        # Validar tipo de archivo
        if not file.filename:
            raise HTTPException(status_code=400, detail="Nombre de archivo inválido")
        
        file_extension = Path(file.filename).suffix.lower()
        if file_extension not in ['.pdf', '.docx', '.txt', '.csv', '.xlsx']:
            raise HTTPException(
                status_code=400,
                detail=f"Tipo de archivo no soportado: {file_extension}"
            )
        
        # Leer contenido del archivo
        content = await file.read()
        file_size = len(content)
        
        # Extraer texto del documento
        logger.info("📄 Extrayendo texto...")
        text_content = DocumentProcessor.extract_text(content, file.filename)
        chunks = DocumentProcessor.chunk_text(text_content)
        logger.info(f"✂️ Documento dividido en {len(chunks)} chunks")
        
        # Generar embeddings para cada chunk (REQUERIDO para Milvus)
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
        
    except Exception as e:
        logger.error(f"❌ Error subiendo documento: {e}")
        raise HTTPException(status_code=500, detail=f"Error procesando documento: {str(e)}")

@app.post("/query", response_model=QueryResponse)
async def query_documents(request: QueryRequest):
    """
    🔍 Búsqueda inteligente con embeddings vectoriales y respuesta generada por LLM
    
    Proceso:
    1. Genera embedding de la consulta
    2. Búsqueda vectorial de chunks similares
    3. LLM genera respuesta contextualizada
    """
    try:
        logger.info(f"🔍 Consultando: '{request.query}' (top_k={request.top_k})")
        
        # Generar embedding de la consulta (REQUERIDO para Milvus)
        if not embeddings_gen:
            raise HTTPException(
                status_code=500,
                detail="Servicio de embeddings no disponible"
            )
        
        logger.info("🔮 Generando embedding de consulta...")
        query_embedding = embeddings_gen.generate_embedding(request.query)
        
        # Búsqueda vectorial semántica en Milvus
        results = db.similarity_search(query_embedding, top_k=request.top_k)
        logger.info(f"📊 Búsqueda vectorial Milvus: {len(results)} resultados")
        
        if not results:
            logger.warning("⚠️ No se encontraron resultados")
            return QueryResponse(
                answer="No encontré información relevante en los documentos para responder tu pregunta.",
                sources=[],
                query=request.query
            )
        
        # Construir contexto para el LLM
        context_parts = []
        for i, r in enumerate(results, 1):
            source_info = f"[Fuente {i}: {r['filename']}]"
            context_parts.append(f"{source_info}\n{r['content']}")
        
        context = "\n\n---\n\n".join(context_parts)
        
        # Generar respuesta usando LLM
        logger.info("🤖 Generando respuesta con LLM...")
        answer = await llm_client.generate_rag_response(request.query, context)
        
        # Preparar fuentes
        sources = []
        for i, r in enumerate(results, 1):
            similarity_key = 'similarity' if 'similarity' in r else 'rank'
            sources.append({
                "filename": r['filename'],
                "content": r['content'][:400] + "..." if len(r['content']) > 400 else r['content'],
                "similarity": float(r.get(similarity_key, 0.0)),
                "chunk_index": r.get('chunk_index', i - 1)
            })
        
        logger.info(f"✅ Respuesta generada con {len(sources)} fuentes")
        
        return QueryResponse(
            answer=answer,
            sources=sources,
            query=request.query
        )
        
    except Exception as e:
        logger.error(f"❌ Error en consulta: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/documents", response_model=List[DocumentInfo])
async def list_documents():
    """📚 Listar todos los documentos"""
    try:
        docs = db.get_all_documents()
        return [
            DocumentInfo(
                id=doc['id'],
                filename=doc['filename'],
                content_type=doc['content_type'],
                file_size=doc['file_size'],
                total_chunks=doc['total_chunks'],
                uploaded_at=doc['uploaded_at']
            )
            for doc in docs
        ]
    except Exception as e:
        logger.error(f"❌ Error listando documentos: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.delete("/documents/{document_id}")
async def delete_document(document_id: int):
    """🗑️ Eliminar documento"""
    try:
        deleted = db.delete_document(document_id)
        if not deleted:
            raise HTTPException(status_code=404, detail="Documento no encontrado")
        
        return {"message": f"Documento {document_id} eliminado correctamente"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Error eliminando documento: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/stats", response_model=StatsResponse)
async def get_stats():
    """📊 Obtener estadísticas del sistema"""
    try:
        stats = db.get_document_stats()
        return StatsResponse(**stats)
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


