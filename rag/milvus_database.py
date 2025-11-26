"""
Gestor de base de datos vectorial con Milvus
Sistema RAG completo con búsqueda semántica de alta performance
"""
import logging
import json
from typing import List, Dict, Tuple, Optional
from datetime import datetime

from pymilvus import (
    connections,
    Collection,
    CollectionSchema,
    FieldSchema,
    DataType,
    utility
)

from config import config

logger = logging.getLogger(__name__)

class MilvusRAGDatabase:
    """Cliente para Milvus con operaciones RAG optimizadas"""
    
    def __init__(self):
        """Conectar a Milvus y crear colecciones"""
        try:
            # Conectar a Milvus
            connections.connect(
                alias="default",
                host=config.MILVUS_HOST,
                port=config.MILVUS_PORT,
                timeout=30
            )
            logger.info(f"✅ Conectado a Milvus: {config.MILVUS_HOST}:{config.MILVUS_PORT}")
            
            # Crear colecciones
            self._create_collections()
            
        except Exception as e:
            logger.error(f"❌ Error conectando a Milvus: {e}")
            raise
    
    def _create_collections(self):
        """Crear colecciones para documentos y chunks"""
        
        # Colección de chunks con embeddings
        chunks_collection_name = "rag_chunks"
        
        if utility.has_collection(chunks_collection_name):
            self.chunks_collection = Collection(chunks_collection_name)
            self.chunks_collection.load()
            logger.info(f"📚 Colección '{chunks_collection_name}' cargada")
        else:
            # Definir schema para chunks
            fields = [
                FieldSchema(name="id", dtype=DataType.INT64, is_primary=True, auto_id=True),
                FieldSchema(name="document_id", dtype=DataType.INT64),
                FieldSchema(name="chunk_index", dtype=DataType.INT64),
                FieldSchema(name="content", dtype=DataType.VARCHAR, max_length=65535),
                FieldSchema(name="filename", dtype=DataType.VARCHAR, max_length=512),
                FieldSchema(name="content_type", dtype=DataType.VARCHAR, max_length=128),
                FieldSchema(name="file_size", dtype=DataType.INT64),
                FieldSchema(name="created_at", dtype=DataType.INT64),  # timestamp
                FieldSchema(name="embedding", dtype=DataType.FLOAT_VECTOR, dim=config.EMBEDDING_DIMENSION)
            ]
            
            schema = CollectionSchema(
                fields=fields,
                description="RAG document chunks with embeddings"
            )
            
            # Crear colección
            self.chunks_collection = Collection(
                name=chunks_collection_name,
                schema=schema
            )
            
            # Crear índice HNSW para búsqueda vectorial ultra rápida
            index_params = {
                "metric_type": "COSINE",  # Cosine similarity
                "index_type": "HNSW",     # Hierarchical Navigable Small World
                "params": {
                    "M": 16,              # Conexiones por nodo
                    "efConstruction": 200 # Calidad de construcción
                }
            }
            
            self.chunks_collection.create_index(
                field_name="embedding",
                index_params=index_params
            )
            
            self.chunks_collection.load()
            logger.info(f"✅ Colección '{chunks_collection_name}' creada con índice HNSW")
        
        # Diccionario en memoria para metadata de documentos (simple y rápido)
        self.documents_metadata = {}
        self._load_documents_metadata()
    
    def _load_documents_metadata(self):
        """Cargar metadata de documentos desde Milvus"""
        try:
            # Obtener todos los document_id únicos
            results = self.chunks_collection.query(
                expr="document_id >= 0",
                output_fields=["document_id", "filename", "content_type", "file_size", "created_at"]
            )
            
            # Agrupar por document_id
            for result in results:
                doc_id = result["document_id"]
                if doc_id not in self.documents_metadata:
                    self.documents_metadata[doc_id] = {
                        "id": doc_id,
                        "filename": result["filename"],
                        "content_type": result["content_type"],
                        "file_size": result["file_size"],
                        "uploaded_at": datetime.fromtimestamp(result["created_at"]),
                        "total_chunks": 0
                    }
                self.documents_metadata[doc_id]["total_chunks"] += 1
            
            logger.info(f"📖 Metadata cargada: {len(self.documents_metadata)} documentos")
            
        except Exception as e:
            logger.warning(f"⚠️ No se pudo cargar metadata: {e}")
            self.documents_metadata = {}
    
    def insert_document(
        self,
        filename: str,
        content_type: str,
        file_size: int,
        metadata: Optional[Dict] = None
    ) -> int:
        """
        Registrar documento (genera ID único)
        
        Args:
            filename: Nombre del archivo
            content_type: Tipo MIME
            file_size: Tamaño en bytes
            metadata: Metadata adicional (opcional)
        
        Returns:
            document_id: ID único del documento
        """
        # Generar ID único (timestamp + hash)
        doc_id = hash(filename + str(datetime.now().timestamp())) % (10 ** 9)
        
        # Guardar en metadata
        self.documents_metadata[doc_id] = {
            "id": doc_id,
            "filename": filename,
            "content_type": content_type,
            "file_size": file_size,
            "uploaded_at": datetime.now(),
            "total_chunks": 0,
            "metadata": metadata or {}
        }
        
        logger.info(f"✅ Documento registrado: ID {doc_id} - {filename}")
        return doc_id
    
    def insert_chunks(
        self,
        document_id: int,
        chunks: List[Tuple[int, str, List[float], Dict]]
    ):
        """
        Insertar chunks con embeddings en Milvus
        
        Args:
            document_id: ID del documento
            chunks: Lista de (chunk_index, content, embedding, metadata)
        """
        try:
            if not chunks:
                logger.warning(f"⚠️ No hay chunks para insertar (doc_id={document_id})")
                return
            
            # Obtener metadata del documento
            doc_meta = self.documents_metadata.get(document_id, {})
            filename = doc_meta.get("filename", "unknown")
            content_type = doc_meta.get("content_type", "text/plain")
            file_size = doc_meta.get("file_size", 0)
            timestamp = int(datetime.now().timestamp())
            
            # Preparar datos para inserción batch
            entities = []
            for chunk_index, content, embedding, chunk_metadata in chunks:
                if not embedding or len(embedding) != config.EMBEDDING_DIMENSION:
                    logger.warning(f"⚠️ Chunk {chunk_index} sin embedding válido, omitiendo")
                    continue
                
                entities.append([
                    document_id,
                    chunk_index,
                    content[:65535],  # Limitar longitud
                    filename[:512],
                    content_type[:128],
                    file_size,
                    timestamp,
                    embedding
                ])
            
            if not entities:
                logger.error(f"❌ No hay chunks válidos para insertar (doc_id={document_id})")
                return
            
            # Insertar en Milvus
            insert_result = self.chunks_collection.insert([
                [e[0] for e in entities],  # document_id
                [e[1] for e in entities],  # chunk_index
                [e[2] for e in entities],  # content
                [e[3] for e in entities],  # filename
                [e[4] for e in entities],  # content_type
                [e[5] for e in entities],  # file_size
                [e[6] for e in entities],  # created_at
                [e[7] for e in entities],  # embedding
            ])
            
            self.chunks_collection.flush()
            
            # Actualizar contador de chunks
            if document_id in self.documents_metadata:
                self.documents_metadata[document_id]["total_chunks"] = len(entities)
            
            logger.info(f"✅ {len(entities)} chunks insertados en Milvus (doc_id={document_id})")
            
        except Exception as e:
            logger.error(f"❌ Error insertando chunks: {e}")
            raise
    
    def similarity_search(
        self,
        query_embedding: List[float],
        top_k: int = 5
    ) -> List[Dict]:
        """
        Búsqueda por similitud vectorial usando HNSW
        
        Args:
            query_embedding: Vector de la consulta
            top_k: Número de resultados
            
        Returns:
            Lista de chunks relevantes con similarity score
        """
        try:
            search_params = {
                "metric_type": "COSINE",
                "params": {"ef": 64}  # Calidad de búsqueda
            }
            
            results = self.chunks_collection.search(
                data=[query_embedding],
                anns_field="embedding",
                param=search_params,
                limit=top_k,
                output_fields=["document_id", "chunk_index", "content", "filename"]
            )
            
            chunks = []
            for hits in results:
                for hit in hits:
                    chunks.append({
                        "id": hit.id,
                        "document_id": hit.entity.get("document_id"),
                        "chunk_index": hit.entity.get("chunk_index"),
                        "content": hit.entity.get("content"),
                        "filename": hit.entity.get("filename"),
                        "similarity": float(hit.distance)  # Cosine similarity [0-1]
                    })
            
            logger.info(f"🔍 Búsqueda vectorial: {len(chunks)} resultados (top_k={top_k})")
            return chunks
            
        except Exception as e:
            logger.error(f"❌ Error en búsqueda: {e}")
            raise
    
    def text_search(self, query: str, top_k: int = 5) -> List[Dict]:
        """
        Búsqueda de texto simple (fallback sin embeddings)
        Nota: Milvus no soporta búsqueda de texto full-text,
        este método existe solo por compatibilidad
        """
        logger.warning("⚠️ text_search llamado en Milvus - se requieren embeddings para búsqueda")
        return []
    
    def get_all_documents(self) -> List[Dict]:
        """Obtener todos los documentos"""
        return [
            {
                "id": doc_id,
                "filename": meta["filename"],
                "content_type": meta["content_type"],
                "file_size": meta["file_size"],
                "total_chunks": meta["total_chunks"],
                "uploaded_at": meta["uploaded_at"]
            }
            for doc_id, meta in self.documents_metadata.items()
        ]
    
    def get_document(self, document_id: int) -> Optional[Dict]:
        """Obtener documento específico"""
        meta = self.documents_metadata.get(document_id)
        if not meta:
            return None
        
        return {
            "id": document_id,
            "filename": meta["filename"],
            "content_type": meta["content_type"],
            "file_size": meta["file_size"],
            "total_chunks": meta["total_chunks"],
            "uploaded_at": meta["uploaded_at"]
        }
    
    def get_document_chunks(self, document_id: int) -> List[Dict]:
        """Obtener todos los chunks de un documento"""
        try:
            results = self.chunks_collection.query(
                expr=f"document_id == {document_id}",
                output_fields=["chunk_index", "content"]
            )
            
            return [
                {
                    "chunk_index": r["chunk_index"],
                    "content": r["content"]
                }
                for r in results
            ]
            
        except Exception as e:
            logger.error(f"❌ Error obteniendo chunks: {e}")
            return []
    
    def delete_document(self, document_id: int) -> bool:
        """Eliminar documento y todos sus chunks"""
        try:
            # Eliminar de Milvus
            expr = f"document_id == {document_id}"
            self.chunks_collection.delete(expr)
            self.chunks_collection.flush()
            
            # Eliminar de metadata
            if document_id in self.documents_metadata:
                del self.documents_metadata[document_id]
            
            logger.info(f"🗑️ Documento {document_id} eliminado de Milvus")
            return True
            
        except Exception as e:
            logger.error(f"❌ Error eliminando documento: {e}")
            return False
    
    def get_document_stats(self) -> Dict:
        """Obtener estadísticas del sistema"""
        try:
            total_chunks = self.chunks_collection.num_entities
            total_docs = len(self.documents_metadata)
            total_size = sum(meta["file_size"] for meta in self.documents_metadata.values())
            
            return {
                "total_documents": total_docs,
                "total_chunks": total_chunks,
                "total_size_bytes": total_size
            }
        except Exception as e:
            logger.error(f"❌ Error obteniendo stats: {e}")
            return {
                "total_documents": 0,
                "total_chunks": 0,
                "total_size_bytes": 0
            }
    
    def test_connection(self):
        """Probar conexión a Milvus"""
        try:
            utility.list_collections()
            return True
        except Exception as e:
            logger.error(f"❌ Test de conexión falló: {e}")
            raise
