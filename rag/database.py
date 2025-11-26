"""
Gestor de base de datos RAG - MODO BÁSICO (sin pgvector)
Compatible con PostgreSQL en PowerPC sin extensiones ML
"""
import os
import logging
from typing import List, Dict, Tuple, Optional
import psycopg2
from psycopg2.extras import RealDictCursor
from sqlalchemy import create_engine, text
from sqlalchemy.pool import NullPool

from config import config

logger = logging.getLogger(__name__)

class RAGDatabase:
    """Gestor de base de datos para RAG (modo básico sin pgvector)"""
    
    def __init__(self):
        """Inicializar conexión a PostgreSQL"""
        # ✅ FIX: Usar el método get_database_url() en lugar del atributo
        self.engine = create_engine(
            config.get_database_url(),
            poolclass=NullPool,
            echo=False
        )
        
        # Inicializar esquema
        self._initialize_schema()
    
    def _initialize_schema(self):
        """Inicializar esquema con detección automática de pgvector"""
        with self.engine.connect() as conn:
            try:
                # Intentar crear extensión pgvector
                pgvector_available = False
                try:
                    conn.execute(text("CREATE EXTENSION IF NOT EXISTS vector"))
                    conn.commit()
                    pgvector_available = True
                    logger.info("✅ Extensión pgvector habilitada")
                except Exception as e:
                    # ✅ FIX: Hacer rollback explícito para limpiar estado de transacción
                    conn.rollback()
                    logger.warning(f"⚠️ pgvector no disponible: {e}")
                    logger.info("📝 Usando modo básico sin embeddings vectoriales")
                
                # ✅ Tabla de documentos
                conn.execute(text("""
                    CREATE TABLE IF NOT EXISTS documents (
                        id SERIAL PRIMARY KEY,
                        filename VARCHAR(500) NOT NULL,
                        content_type VARCHAR(100),
                        file_size INTEGER,
                        total_chunks INTEGER DEFAULT 0,
                        metadata JSONB DEFAULT '{}'::jsonb,
                        uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    )
                """))
                
                # ✅ Tabla de chunks (con o sin embedding según disponibilidad)
                if pgvector_available:
                    conn.execute(text(f"""
                        CREATE TABLE IF NOT EXISTS document_chunks (
                            id SERIAL PRIMARY KEY,
                            document_id INTEGER REFERENCES documents(id) ON DELETE CASCADE,
                            chunk_index INTEGER NOT NULL,
                            content TEXT NOT NULL,
                            embedding vector({config.EMBEDDING_DIMENSION}),
                            metadata JSONB DEFAULT '{{}}'::jsonb,
                            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                        )
                    """))
                else:
                    conn.execute(text("""
                        CREATE TABLE IF NOT EXISTS document_chunks (
                            id SERIAL PRIMARY KEY,
                            document_id INTEGER REFERENCES documents(id) ON DELETE CASCADE,
                            chunk_index INTEGER NOT NULL,
                            content TEXT NOT NULL,
                            metadata JSONB DEFAULT '{}'::jsonb,
                            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                        )
                    """))
                
                # ✅ Índices
                conn.execute(text("""
                    CREATE INDEX IF NOT EXISTS idx_chunks_document 
                    ON document_chunks(document_id)
                """))
                
                if pgvector_available:
                    # Índice HNSW para búsqueda vectorial rápida
                    try:
                        conn.execute(text("""
                            CREATE INDEX IF NOT EXISTS idx_chunks_embedding 
                            ON document_chunks USING hnsw (embedding vector_cosine_ops)
                        """))
                    except:
                        logger.warning("⚠️ No se pudo crear índice HNSW, usando tabla sin índice vectorial")
                
                # Índice para búsqueda de texto completo (siempre útil)
                conn.execute(text("""
                    CREATE INDEX IF NOT EXISTS idx_chunks_content 
                    ON document_chunks USING gin(to_tsvector('spanish', content))
                """))
                
                conn.commit()
                
                if pgvector_available:
                    logger.info(f"✅ Esquema RAG con pgvector inicializado (dim: {config.EMBEDDING_DIMENSION})")
                else:
                    logger.info("✅ Esquema RAG inicializado en modo básico (sin embeddings)")
                    # Deshabilitar embeddings en config
                    config.ENABLE_EMBEDDINGS = False
                
            except Exception as e:
                logger.error(f"❌ Error inicializando esquema: {e}")
                conn.rollback()  # ✅ Rollback en caso de error general
                raise
    
    def insert_document(
        self,
        filename: str,
        content_type: str,
        file_size: int,
        metadata: Optional[Dict] = None
    ) -> int:
        """Insertar documento en la base de datos"""
        import json
        
        with self.engine.connect() as conn:
            result = conn.execute(
                text("""
                    INSERT INTO documents (filename, content_type, file_size, metadata)
                    VALUES (:filename, :content_type, :file_size, CAST(:metadata AS jsonb))
                    RETURNING id
                """),
                {
                    "filename": filename,
                    "content_type": content_type,
                    "file_size": file_size,
                    "metadata": json.dumps(metadata or {})
                }
            )
            conn.commit()
            doc_id = result.fetchone()[0]
            logger.info(f"✅ Documento {doc_id} insertado: {filename}")
            return doc_id
    
    def insert_chunks(
        self,
        document_id: int,
        chunks: List[Tuple[int, str, List[float], Dict]]
    ):
        """Insertar chunks (con embeddings si están disponibles)"""
        import json
        
        with self.engine.connect() as conn:
            for chunk_index, content, embedding, metadata in chunks:
                # Detectar si hay embeddings
                if embedding and len(embedding) > 0 and config.ENABLE_EMBEDDINGS:
                    # Insertar CON embedding vectorial
                    conn.execute(
                        text("""
                            INSERT INTO document_chunks 
                            (document_id, chunk_index, content, embedding, metadata)
                            VALUES (:doc_id, :idx, :content, :embedding::vector, CAST(:metadata AS jsonb))
                        """),
                        {
                            "doc_id": document_id,
                            "idx": chunk_index,
                            "content": content,
                            "embedding": str(embedding),  # pgvector acepta string "[1.0, 2.0, ...]"
                            "metadata": json.dumps(metadata or {})
                        }
                    )
                else:
                    # Insertar SIN embedding (modo básico)
                    conn.execute(
                        text("""
                            INSERT INTO document_chunks 
                            (document_id, chunk_index, content, metadata)
                            VALUES (:doc_id, :idx, :content, CAST(:metadata AS jsonb))
                        """),
                        {
                            "doc_id": document_id,
                            "idx": chunk_index,
                            "content": content,
                            "metadata": json.dumps(metadata or {})
                        }
                    )
            
            # Actualizar contador de chunks
            conn.execute(
                text("UPDATE documents SET total_chunks = :count WHERE id = :id"),
                {"count": len(chunks), "id": document_id}
            )
            conn.commit()
            
            if config.ENABLE_EMBEDDINGS and chunks and chunks[0][2]:
                logger.info(f"✅ {len(chunks)} chunks con embeddings insertados para documento {document_id}")
            else:
                logger.info(f"✅ {len(chunks)} chunks insertados para documento {document_id} (sin embeddings)")
    
    def similarity_search(
        self,
        query_embedding: List[float],
        top_k: int = 5
    ) -> List[Dict]:
        """
        Búsqueda vectorial usando pgvector (cosine similarity)
        Retorna los chunks más similares semánticamente
        """
        with self.engine.connect() as conn:
            results = conn.execute(
                text("""
                    SELECT 
                        dc.id,
                        dc.document_id,
                        dc.chunk_index,
                        dc.content,
                        dc.metadata,
                        d.filename,
                        1 - (dc.embedding <=> :query_emb::vector) as similarity
                    FROM document_chunks dc
                    JOIN documents d ON d.id = dc.document_id
                    WHERE dc.embedding IS NOT NULL
                    ORDER BY dc.embedding <=> :query_emb::vector
                    LIMIT :limit
                """),
                {"query_emb": str(query_embedding), "limit": top_k}
            )
            
            return [dict(row._mapping) for row in results]
    
    def text_search(self, query: str, top_k: int = 5) -> List[Dict]:
        """
        Búsqueda de texto simple con ILIKE (compatible con cualquier PostgreSQL)
        Fallback seguro sin dependencias de diccionarios o extensiones
        """
        with self.engine.connect() as conn:
            # Búsqueda simple con ILIKE (case-insensitive)
            # Dividir query en palabras y buscar cada una
            search_term = f"%{query}%"
            
            results = conn.execute(
                text("""
                    SELECT 
                        dc.id,
                        dc.document_id,
                        dc.chunk_index,
                        dc.content,
                        dc.metadata,
                        d.filename,
                        1.0 as rank
                    FROM document_chunks dc
                    JOIN documents d ON d.id = dc.document_id
                    WHERE dc.content ILIKE :search
                    ORDER BY dc.document_id DESC, dc.chunk_index ASC
                    LIMIT :limit
                """),
                {"search": search_term, "limit": top_k}
            )
            
            return [dict(row._mapping) for row in results]
    
    def get_all_documents(self) -> List[Dict]:
        """Obtener todos los documentos"""
        with self.engine.connect() as conn:
            results = conn.execute(
                text("""
                    SELECT id, filename, content_type, file_size, 
                           total_chunks, metadata, uploaded_at, updated_at
                    FROM documents
                    ORDER BY uploaded_at DESC
                """)
            )
            return [dict(row._mapping) for row in results]
    
    def get_document(self, document_id: int) -> Optional[Dict]:
        """Obtener documento específico"""
        with self.engine.connect() as conn:
            result = conn.execute(
                text("""
                    SELECT id, filename, content_type, file_size,
                           total_chunks, metadata, uploaded_at, updated_at
                    FROM documents
                    WHERE id = :id
                """),
                {"id": document_id}
            )
            row = result.fetchone()
            return dict(row._mapping) if row else None
    
    def get_document_chunks(self, document_id: int) -> List[Dict]:
        """Obtener todos los chunks de un documento"""
        with self.engine.connect() as conn:
            results = conn.execute(
                text("""
                    SELECT id, document_id, chunk_index, content, metadata, created_at
                    FROM document_chunks
                    WHERE document_id = :doc_id
                    ORDER BY chunk_index
                """),
                {"doc_id": document_id}
            )
            return [dict(row._mapping) for row in results]
    
    def delete_document(self, document_id: int) -> bool:
        """Eliminar documento y sus chunks (CASCADE automático)"""
        with self.engine.connect() as conn:
            result = conn.execute(
                text("DELETE FROM documents WHERE id = :id"),
                {"id": document_id}
            )
            conn.commit()
            deleted = result.rowcount > 0
            
            if deleted:
                logger.info(f"✅ Documento {document_id} eliminado")
            else:
                logger.warning(f"⚠️ Documento {document_id} no encontrado")
            
            return deleted
    
    def get_document_stats(self) -> Dict:
        """Obtener estadísticas del sistema"""
        with self.engine.connect() as conn:
            result = conn.execute(text("""
                SELECT 
                    COUNT(DISTINCT d.id) as total_documents,
                    COUNT(dc.id) as total_chunks,
                    COALESCE(SUM(d.file_size), 0) as total_size_bytes
                FROM documents d
                LEFT JOIN document_chunks dc ON d.id = dc.document_id
            """))
            
            stats = dict(result.fetchone()._mapping)
            return stats
