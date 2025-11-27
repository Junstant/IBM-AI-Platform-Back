"""
Configuración de bases de datos para toda la plataforma

Proporciona configuración centralizada para PostgreSQL, Milvus y otras bases de datos.
"""

import os
from typing import Dict, Optional
from .base import get_config


class DatabaseConfig:
    """Configuración de bases de datos"""
    
    def __init__(self):
        """Inicializar configuración de bases de datos"""
        self.base_config = get_config()
        
        # PostgreSQL - Configuración base
        self.db_user = os.getenv("DB_USER", "postgres")
        self.db_password = os.getenv("DB_PASSWORD", "root")
        self.db_port_external = int(os.getenv("DB_PORT", "8070"))
        self.db_port_internal = int(os.getenv("DB_INTERNAL_PORT", "5432"))
        
        # Nombres de bases de datos
        self.banco_global_db = os.getenv("DB1_NAME", "banco_global")
        self.bank_transactions_db = os.getenv("DB2_NAME", "bank_transactions")
        self.stats_db = os.getenv("DB3_NAME", "ai_platform_stats")
        self.rag_db = os.getenv("DB_NAME", "ai_platform_rag")
        
        # Nombres de contenedores
        self.postgres_container = os.getenv("POSTGRES_CONTAINER_NAME", "postgres")
        
        # Milvus Configuration
        self.milvus_host = self._get_milvus_host()
        self.milvus_port = int(os.getenv("MILVUS_PORT", "19530"))
        self.milvus_collection_name = os.getenv("MILVUS_COLLECTION_NAME", "documents")
        
        # MinIO (para Milvus)
        self.minio_host = self._get_minio_host()
        self.minio_port = int(os.getenv("MINIO_PORT", "9000"))
        self.minio_console_port = int(os.getenv("MINIO_CONSOLE_PORT", "9001"))
        self.minio_access_key = os.getenv("MINIO_ROOT_USER", "minioadmin")
        self.minio_secret_key = os.getenv("MINIO_ROOT_PASSWORD", "minioadmin")
        
        # Etcd (para Milvus)
        self.etcd_host = self._get_etcd_host()
        self.etcd_port = int(os.getenv("ETCD_CLIENT_PORT", "2379"))
    
    def _get_milvus_host(self) -> str:
        """Obtener host de Milvus según el entorno"""
        if self.base_config.is_docker:
            return "milvus"
        return os.getenv("MILVUS_HOST", "localhost")
    
    def _get_minio_host(self) -> str:
        """Obtener host de MinIO según el entorno"""
        if self.base_config.is_docker:
            return "minio"
        return os.getenv("MINIO_HOST", "localhost")
    
    def _get_etcd_host(self) -> str:
        """Obtener host de etcd según el entorno"""
        if self.base_config.is_docker:
            return "etcd"
        return os.getenv("ETCD_HOST", "localhost")
    
    def get_postgres_host(self) -> str:
        """Obtener host de PostgreSQL según el entorno"""
        if self.base_config.is_docker:
            return self.postgres_container
        return os.getenv("DB_HOST", "localhost")
    
    def get_postgres_port(self) -> int:
        """Obtener puerto de PostgreSQL según el entorno"""
        return self.db_port_internal if self.base_config.is_docker else self.db_port_external
    
    def get_database_url(self, database_name: str) -> str:
        """
        Construir URL de conexión para PostgreSQL
        
        Args:
            database_name: Nombre de la base de datos
            
        Returns:
            str: URL de conexión completa
        """
        host = self.get_postgres_host()
        port = self.get_postgres_port()
        
        return (
            f"postgresql://{self.db_user}:{self.db_password}"
            f"@{host}:{port}/{database_name}"
        )
    
    def get_async_database_url(self, database_name: str) -> str:
        """
        Construir URL asíncrona de conexión para PostgreSQL (asyncpg)
        
        Args:
            database_name: Nombre de la base de datos
            
        Returns:
            str: URL de conexión asíncrona
        """
        return self.get_database_url(database_name).replace('postgresql://', 'postgresql+asyncpg://')
    
    def get_milvus_config(self) -> Dict[str, any]:
        """
        Obtener configuración completa de Milvus
        
        Returns:
            dict: Configuración de Milvus
        """
        return {
            'host': self.milvus_host,
            'port': self.milvus_port,
            'collection_name': self.milvus_collection_name,
            'minio_address': f"{self.minio_host}:{self.minio_port}",
            'minio_access_key': self.minio_access_key,
            'minio_secret_key': self.minio_secret_key
        }
    
    def to_dict(self) -> Dict[str, any]:
        """Convertir configuración a diccionario"""
        return {
            'postgres': {
                'host': self.get_postgres_host(),
                'port': self.get_postgres_port(),
                'user': self.db_user,
                'databases': {
                    'banco_global': self.banco_global_db,
                    'bank_transactions': self.bank_transactions_db,
                    'stats': self.stats_db,
                    'rag': self.rag_db
                }
            },
            'milvus': self.get_milvus_config()
        }
    
    def __repr__(self) -> str:
        return f"<DatabaseConfig postgres={self.get_postgres_host()}:{self.get_postgres_port()}>"
