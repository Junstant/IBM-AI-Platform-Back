"""
Colector de métricas del sistema y recursos
"""

import asyncio
import logging
import platform
import shutil
import subprocess
from datetime import datetime
from typing import Dict

import psutil

logger = logging.getLogger(__name__)

class MetricsCollector:
    """Colector de métricas de sistema y recursos"""
    
    def __init__(self, db_manager):
        self.db_manager = db_manager
        self._collecting = False
        self.server_name = platform.node() or "main-server"
    
    async def start_system_monitoring(self):
        """Iniciar monitoreo de recursos del sistema"""
        self._collecting = True
        logger.info("📊 Iniciando colección de métricas del sistema...")
        
        while self._collecting:
            try:
                await self.collect_system_metrics()
                await asyncio.sleep(60)  # Cada minuto
            except Exception as e:
                logger.error(f"Error en system monitoring: {e}")
                await asyncio.sleep(30)
    
    def stop_system_monitoring(self):
        """Detener monitoreo de sistema"""
        self._collecting = False
        logger.info("🛑 Deteniendo colección de métricas del sistema")
    
    async def collect_system_metrics(self):
        """Recopilar métricas del sistema"""
        try:
            # Métricas de memoria
            memory = psutil.virtual_memory()
            total_memory_mb = memory.total // (1024 * 1024)
            used_memory_mb = memory.used // (1024 * 1024)
            memory_usage_percent = memory.percent
            
            # Métricas de CPU
            cpu_usage_percent = psutil.cpu_percent(interval=1)
            total_cpu_cores = psutil.cpu_count()
            
            # Métricas de disco
            disk = psutil.disk_usage('/')
            disk_total_gb = disk.total // (1024 * 1024 * 1024)
            disk_used_gb = disk.used // (1024 * 1024 * 1024)
            disk_usage_percent = (disk.used / disk.total) * 100
            
            # Métricas de red
            network = psutil.net_io_counters()
            network_rx_bytes = network.bytes_recv
            network_tx_bytes = network.bytes_sent
            
            # Métricas de GPU (si está disponible)
            gpu_count, gpu_memory_total_mb, gpu_memory_used_mb = await self._get_gpu_metrics()
            
            # Conexiones activas de PostgreSQL
            active_connections = await self._get_postgres_connections()
            
            # Contenedores Docker activos
            docker_containers = await self._get_docker_containers()
            
            # Crear objeto de métricas
            resource_data = {
                'server_name': self.server_name,
                'total_memory_mb': total_memory_mb,
                'used_memory_mb': used_memory_mb,
                'memory_usage_percent': memory_usage_percent,
                'total_cpu_cores': total_cpu_cores,
                'cpu_usage_percent': cpu_usage_percent,
                'disk_total_gb': disk_total_gb,
                'disk_used_gb': disk_used_gb,
                'disk_usage_percent': disk_usage_percent,
                'gpu_count': gpu_count,
                'gpu_memory_total_mb': gpu_memory_total_mb,
                'gpu_memory_used_mb': gpu_memory_used_mb,
                'network_rx_bytes': network_rx_bytes,
                'network_tx_bytes': network_tx_bytes,
                'active_connections': active_connections,
                'docker_containers_running': docker_containers
            }
            
            # Guardar en base de datos
            await self.db_manager.insert_system_resource(resource_data)
            
            logger.debug(f"📊 Métricas recopiladas: RAM {memory_usage_percent:.1f}%, "
                        f"CPU {cpu_usage_percent:.1f}%, Disco {disk_usage_percent:.1f}%")
            
        except Exception as e:
            logger.error(f"Error recopilando métricas del sistema: {e}")
    
    async def _get_gpu_metrics(self) -> tuple:
        """Obtener métricas de GPU usando nvidia-smi"""
        try:
            # Intentar usar nvidia-smi
            result = subprocess.run([
                'nvidia-smi', 
                '--query-gpu=count,memory.total,memory.used',
                '--format=csv,noheader,nounits'
            ], capture_output=True, text=True, timeout=10)
            
            if result.returncode == 0:
                lines = result.stdout.strip().split('\n')
                gpu_count = len(lines)
                total_memory = 0
                used_memory = 0
                
                for line in lines:
                    parts = line.split(', ')
                    if len(parts) >= 3:
                        total_memory += int(parts[1])
                        used_memory += int(parts[2])
                
                return gpu_count, total_memory, used_memory
            else:
                return 0, 0, 0
                
        except (subprocess.TimeoutExpired, FileNotFoundError, Exception):
            # nvidia-smi no disponible o error
            return 0, 0, 0
    
    async def _get_postgres_connections(self) -> int:
        """Obtener número de conexiones activas de PostgreSQL"""
        try:
            query = """
            SELECT count(*) 
            FROM pg_stat_activity 
            WHERE state = 'active' AND pid <> pg_backend_pid()
            """
            result = await self.db_manager.fetch_one(query)
            return result[0] if result else 0
        except Exception as e:
            logger.debug(f"Error obteniendo conexiones PostgreSQL: {e}")
            return 0
    
    async def _get_docker_containers(self) -> int:
        """Obtener número de contenedores Docker activos"""
        try:
            result = subprocess.run([
                'docker', 'ps', '-q'
            ], capture_output=True, text=True, timeout=10)
            
            if result.returncode == 0:
                containers = result.stdout.strip().split('\n')
                return len([c for c in containers if c.strip()])
            else:
                return 0
                
        except (subprocess.TimeoutExpired, FileNotFoundError, Exception):
            # Docker no disponible o error
            return 0
    
    async def get_current_metrics(self) -> Dict:
        """Obtener métricas actuales del sistema sin guardar en BD"""
        try:
            memory = psutil.virtual_memory()
            cpu_usage = psutil.cpu_percent(interval=1)
            disk = psutil.disk_usage('/')
            
            return {
                'memory_usage_percent': memory.percent,
                'cpu_usage_percent': cpu_usage,
                'disk_usage_percent': (disk.used / disk.total) * 100,
                'available_memory_gb': memory.available // (1024 * 1024 * 1024),
                'total_memory_gb': memory.total // (1024 * 1024 * 1024),
                'cpu_cores': psutil.cpu_count(),
                'load_average': psutil.getloadavg() if hasattr(psutil, 'getloadavg') else None,
                'timestamp': datetime.now().isoformat()
            }
        except Exception as e:
            logger.error(f"Error obteniendo métricas actuales: {e}")
            return {}
    
    async def calculate_hourly_metrics(self):
        """Calcular métricas agregadas por hora"""
        try:
            # Ejecutar función SQL para calcular métricas
            await self.db_manager.execute_query("SELECT calculate_daily_metrics()")
            logger.info("✅ Métricas horarias calculadas")
        except Exception as e:
            logger.error(f"Error calculando métricas horarias: {e}")
    
    async def cleanup_old_data(self):
        """Limpiar datos antiguos"""
        try:
            # Ejecutar función SQL de limpieza
            await self.db_manager.execute_query("SELECT cleanup_old_logs()")
            logger.info("✅ Limpieza de datos antiguos completada")
        except Exception as e:
            logger.error(f"Error en limpieza de datos: {e}")
    
    async def get_database_metrics(self):
        """Recopilar métricas específicas de la base de datos"""
        try:
            # Métricas de tablas principales
            tables = [
                'ai_models_metrics',
                'functionality_metrics', 
                'api_performance_logs',
                'accuracy_metrics',
                'system_resources',
                'system_alerts'
            ]
            
            metrics = {}
            
            for table in tables:
                # Contar filas
                query = f"SELECT COUNT(*) FROM {table}"
                count_result = await self.db_manager.fetch_one(query)
                
                # Tamaño de tabla
                size_query = f"""
                SELECT pg_size_pretty(pg_total_relation_size('{table}')) as size,
                       pg_total_relation_size('{table}') as size_bytes
                """
                size_result = await self.db_manager.fetch_one(size_query)
                
                metrics[table] = {
                    'row_count': count_result[0] if count_result else 0,
                    'size_pretty': size_result['size'] if size_result else '0 bytes',
                    'size_bytes': size_result['size_bytes'] if size_result else 0
                }
            
            # Estadísticas generales de la BD
            db_stats_query = """
            SELECT 
                pg_database_size(current_database()) as db_size,
                (SELECT count(*) FROM pg_stat_activity WHERE state = 'active') as active_connections,
                (SELECT count(*) FROM pg_stat_activity) as total_connections
            """
            db_stats = await self.db_manager.fetch_one(db_stats_query)
            
            metrics['database_stats'] = {
                'total_size_bytes': db_stats['db_size'] if db_stats else 0,
                'active_connections': db_stats['active_connections'] if db_stats else 0,
                'total_connections': db_stats['total_connections'] if db_stats else 0
            }
            
            return metrics
            
        except Exception as e:
            logger.error(f"Error obteniendo métricas de base de datos: {e}")
            return {}