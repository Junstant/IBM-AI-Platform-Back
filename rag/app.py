"""
🧠 RAG API - Retrieval-Augmented Generation (Modo Básico)
==========================================================
Sistema de gestión de documentos SIN embeddings (PowerPC compatible)
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
from database import RAGDatabase
from document_processor import DocumentProcessor

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
    title="🧠 RAG API (Modo Básico)",
    description="Gestión de documentos sin embeddings (PowerPC compatible)",
    version="1.0.0"
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

# =====================================================
# EVENTOS DE CICLO DE VIDA
# =====================================================

@app.on_event("startup")
async def startup():
    """Inicializar base de datos al arrancar"""
    global db
    try:
        logger.info("🚀 Iniciando RAG API...")
        db = RAGDatabase()
        logger.info("✅ Base de datos inicializada")
        logger.info("⚠️ Embeddings deshabilitados (PowerPC - sin ML libraries)")
        logger.info("✅ RAG API lista (modo básico sin embeddings)!")
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

@app.get("/health")
async def health_check():
    """Health check"""
    return {
        "status": "healthy",
        "service": "RAG API",
        "mode": "básico (sin embeddings)",
        "database": "connected" if db else "disconnected"
    }

@app.post("/upload", response_model=DocumentInfo)
async def upload_document(file: UploadFile = File(...)):
    """
    📤 Subir documento y procesarlo en chunks
    
    Soporta: PDF, DOCX, TXT, CSV, XLSX
    """
    try:
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
        
        # Guardar temporalmente
        temp_path = Path(config.UPLOAD_DIR) / file.filename
        temp_path.parent.mkdir(parents=True, exist_ok=True)
        
        with open(temp_path, 'wb') as f:
            f.write(content)
        
        # Procesar documento
        processor = DocumentProcessor()
        text_content = processor.extract_text(temp_path)
        chunks = processor.chunk_text(text_content)
        
        # Preparar chunks sin embeddings
        chunk_data = []
        for idx, chunk in enumerate(chunks):
            chunk_data.append((idx, chunk, [], {}))  # Sin embedding
        
        # Insertar en base de datos
        doc_id = db.insert_document(
            filename=file.filename,
            content_type=file.content_type or "application/octet-stream",
            file_size=file_size,
            metadata={"chunks_count": len(chunks)}
        )
        
        db.insert_chunks(doc_id, chunk_data)
        
        # Limpiar archivo temporal
        temp_path.unlink(missing_ok=True)
        
        logger.info(f"✅ Documento {doc_id} procesado: {len(chunks)} chunks")
        
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
    🔍 Buscar en documentos usando búsqueda de texto completo
    
    Nota: Sin embeddings, usa búsqueda de texto PostgreSQL
    """
    try:
        logger.info(f"🔍 Consultando: {request.query}")
        
        # Búsqueda de texto completo (sin embeddings)
        results = db.text_search(request.query, top_k=request.top_k)
        
        if not results:
            return QueryResponse(
                answer="No se encontraron documentos relevantes para tu consulta.",
                sources=[],
                query=request.query
            )
        
        # Generar respuesta básica (sin LLM)
        context = "\n\n".join([r['content'][:500] for r in results[:3]])
        answer = f"Encontré {len(results)} resultado(s) relacionado(s):\n\n{context}"
        
        sources = [
            {
                "filename": r['filename'],
                "content": r['content'][:300],
                "rank": float(r['rank'])
            }
            for r in results
        ]
        
        logger.info(f"✅ {len(results)} resultados encontrados")
        
        return QueryResponse(
            answer=answer,
            sources=sources,
            query=request.query
        )
        
    except Exception as e:
        logger.error(f"❌ Error en consulta: {e}")
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
    """Información de la API"""
    return {
        "service": "RAG API",
        "version": "1.0.0",
        "mode": "básico (sin embeddings)",
        "status": "running",
        "endpoints": {
            "health": "/health",
            "upload": "POST /upload",
            "query": "POST /query",
            "documents": "GET /documents",
            "delete": "DELETE /documents/{id}",
            "stats": "GET /stats",
            "docs": "/docs"
        }
    }
