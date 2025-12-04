"""
Gestión de conexiones y operaciones de base de datos
"""

import asyncio
import logging
from typing import Any, Dict, List, Optional

import asyncpg
from asyncpg import Connection, Pool

logger = logging.getLogger(__name__)

class DatabaseManager:
    """Gestor de conexiones y operaciones de base de datos"""
    
    def __init__(self, database_url: str):
        self.database_url = database_url
        self.pool: Optional[Pool] = None
        self._initialized = False
    
    async def initialize(self):
        """Inicializar pool de conexiones"""
        try:
            self.pool = await asyncpg.create_pool(
                self.database_url,
                min_size=2,
                max_size=10,
                command_timeout=30,
                server_settings={
                    'application_name': 'ai_platform_stats',
                    'jit': 'off'
                }
            )
            self._initialized = True
            logger.info("✅ Pool de conexiones de base de datos inicializado")
        except Exception as e:
            logger.error(f"❌ Error inicializando base de datos: {e}")
            raise
    
    async def close(self):
        """Cerrar pool de conexiones"""
        if self.pool:
            await self.pool.close()
            logger.info("✅ Pool de conexiones cerrado")
    
    async def fetch_one(self, query: str, params: tuple = None) -> Optional[asyncpg.Record]:
        """Ejecutar query y obtener un resultado"""
        if not self._initialized:
            raise RuntimeError("Database not initialized")
        
        async with self.pool.acquire() as conn:
            try:
                if params:
                    result = await conn.fetchrow(query, *params)
                else:
                    result = await conn.fetchrow(query)
                return result
            except Exception as e:
                logger.error(f"Error executing query: {query}, error: {e}")
                raise
    
    async def fetch_all(self, query: str, params: tuple = None) -> List[asyncpg.Record]:
        """Ejecutar query y obtener todos los resultados"""
        if not self._initialized:
            raise RuntimeError("Database not initialized")
        
        async with self.pool.acquire() as conn:
            try:
                if params:
                    results = await conn.fetch(query, *params)
                else:
                    results = await conn.fetch(query)
                return results
            except Exception as e:
                logger.error(f"Error executing query: {query}, error: {e}")
                raise
    
    async def execute_query(self, query: str, params: tuple = None) -> int:
        """Ejecutar query INSERT/UPDATE/DELETE y retornar filas afectadas"""
        if not self._initialized:
            raise RuntimeError("Database not initialized")
        
        async with self.pool.acquire() as conn:
            try:
                if params:
                    result = await conn.execute(query, *params)
                else:
                    result = await conn.execute(query)
                
                # Extraer número de filas afectadas del resultado
                if result.startswith('INSERT'):
                    return int(result.split()[-1])
                elif result.startswith('UPDATE'):
                    return int(result.split()[-1])
                elif result.startswith('DELETE'):
                    return int(result.split()[-1])
                else:
                    return 0
            except Exception as e:
                logger.error(f"Error executing query: {query}, error: {e}")
                raise
    
    async def execute_many(self, query: str, params_list: List[tuple]) -> None:
        """Ejecutar query múltiples veces con diferentes parámetros"""
        if not self._initialized:
            raise RuntimeError("Database not initialized")
        
        async with self.pool.acquire() as conn:
            try:
                await conn.executemany(query, params_list)
            except Exception as e:
                logger.error(f"Error executing batch query: {query}, error: {e}")
                raise
    
    async def insert_api_log(self, log_data: Dict[str, Any]) -> None:
        """Insertar log de API performance (v2.1 con is_ai_query)"""
        query = """
        INSERT INTO api_performance_logs (
            endpoint, endpoint_base, method, functionality, model_used, request_size_bytes,
            response_size_bytes, response_time, status_code, error_message,
            error_type, user_agent, client_ip, request_id, is_ai_query,
            query_complexity_score, fraud_risk_score, sql_execution_time, database_name
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19)
        """
        
        params = (
            log_data.get('endpoint'),
            log_data.get('endpoint_base'),  # NUEVO: endpoint sin parámetros
            log_data.get('method'),
            log_data.get('functionality'),
            log_data.get('model_used'),
            log_data.get('request_size_bytes'),
            log_data.get('response_size_bytes'),
            log_data.get('response_time'),
            log_data.get('status_code'),
            log_data.get('error_message'),
            log_data.get('error_type'),
            log_data.get('user_agent'),
            log_data.get('client_ip'),
            log_data.get('request_id'),
            log_data.get('is_ai_query', False),  # NUEVO: v2.1
            log_data.get('query_complexity_score'),
            log_data.get('fraud_risk_score'),
            log_data.get('sql_execution_time'),
            log_data.get('database_name')
        )
        
        await self.execute_query(query, params)
    
    async def update_model_metrics(self, model_data: Dict[str, Any]) -> None:
        """Actualizar métricas de modelo"""
        query = """
        INSERT INTO ai_models_metrics (
            model_name, model_type, model_size, status, port, host,
            last_health_check, total_requests, successful_requests, error_count,
            avg_response_time, min_response_time, max_response_time,
            memory_usage_mb, cpu_usage_percent, gpu_usage_percent,
            tokens_processed, model_load_time, uptime_seconds, updated_at
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20)
        ON CONFLICT (model_name) 
        DO UPDATE SET
            status = EXCLUDED.status,
            last_health_check = EXCLUDED.last_health_check,
            total_requests = EXCLUDED.total_requests,
            successful_requests = EXCLUDED.successful_requests,
            error_count = EXCLUDED.error_count,
            avg_response_time = EXCLUDED.avg_response_time,
            min_response_time = EXCLUDED.min_response_time,
            max_response_time = EXCLUDED.max_response_time,
            memory_usage_mb = EXCLUDED.memory_usage_mb,
            cpu_usage_percent = EXCLUDED.cpu_usage_percent,
            gpu_usage_percent = EXCLUDED.gpu_usage_percent,
            tokens_processed = EXCLUDED.tokens_processed,
            uptime_seconds = EXCLUDED.uptime_seconds,
            updated_at = EXCLUDED.updated_at
        """
        
        params = (
            model_data.get('model_name'),
            model_data.get('model_type'),
            model_data.get('model_size'),
            model_data.get('status'),
            model_data.get('port'),
            model_data.get('host', 'localhost'),
            model_data.get('last_health_check'),
            model_data.get('total_requests', 0),
            model_data.get('successful_requests', 0),
            model_data.get('error_count', 0),
            model_data.get('avg_response_time'),
            model_data.get('min_response_time'),
            model_data.get('max_response_time'),
            model_data.get('memory_usage_mb'),
            model_data.get('cpu_usage_percent'),
            model_data.get('gpu_usage_percent'),
            model_data.get('tokens_processed', 0),
            model_data.get('model_load_time'),
            model_data.get('uptime_seconds', 0),
            model_data.get('updated_at')
        )
        
        await self.execute_query(query, params)
    
    async def insert_system_resource(self, resource_data: Dict[str, Any]) -> None:
        """Insertar métricas de recursos del sistema"""
        query = """
        INSERT INTO system_resources (
            server_name, total_memory_mb, used_memory_mb, memory_usage_percent,
            total_cpu_cores, cpu_usage_percent, disk_total_gb, disk_used_gb,
            disk_usage_percent, gpu_count, gpu_memory_total_mb, gpu_memory_used_mb,
            network_rx_bytes, network_tx_bytes, active_connections,
            docker_containers_running
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16)
        """
        
        params = (
            resource_data.get('server_name', 'main-server'),
            resource_data.get('total_memory_mb'),
            resource_data.get('used_memory_mb'),
            resource_data.get('memory_usage_percent'),
            resource_data.get('total_cpu_cores'),
            resource_data.get('cpu_usage_percent'),
            resource_data.get('disk_total_gb'),
            resource_data.get('disk_used_gb'),
            resource_data.get('disk_usage_percent'),
            resource_data.get('gpu_count', 0),
            resource_data.get('gpu_memory_total_mb', 0),
            resource_data.get('gpu_memory_used_mb', 0),
            resource_data.get('network_rx_bytes', 0),
            resource_data.get('network_tx_bytes', 0),
            resource_data.get('active_connections', 0),
            resource_data.get('docker_containers_running', 0)
        )
        
        await self.execute_query(query, params)
    
    async def insert_alert(self, alert_data: Dict[str, Any]) -> None:
        """Insertar nueva alerta en el sistema"""
        query = """
        INSERT INTO system_alerts (
            alert_type, component, component_name, title, message,
            severity, metadata
        ) VALUES ($1, $2, $3, $4, $5, $6, $7)
        """
        
        params = (
            alert_data.get('alert_type'),
            alert_data.get('component'),
            alert_data.get('component_name'),
            alert_data.get('title'),
            alert_data.get('message'),
            alert_data.get('severity', 1),
            alert_data.get('metadata')
        )
        
        await self.execute_query(query, params)