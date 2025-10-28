"""
Sistema de health checks automáticos para modelos IA
"""

import asyncio
import aiohttp
import logging
import time
from datetime import datetime
from typing import Dict, List, Optional

import psutil

from config import Settings

logger = logging.getLogger(__name__)

class ModelHealthChecker:
    """Monitor de salud de modelos IA"""
    
    def __init__(self, db_manager):
        self.db_manager = db_manager
        self.settings = Settings()
        self.model_urls = self.settings.get_model_urls()
        self._monitoring = False
        self._start_time = time.time()
    
    async def initialize_models(self):
        """Inicializar modelos en la base de datos"""
        logger.info("🔄 Inicializando modelos en base de datos...")
        
        for model_name, config in self.settings.models_config.items():
            model_data = {
                'model_name': model_name,
                'model_type': config['type'],
                'model_size': config['size'],
                'status': 'inactive',
                'port': config['port'],
                'host': 'localhost',
                'last_health_check': datetime.now(),
                'total_requests': 0,
                'successful_requests': 0,
                'error_count': 0,
                'avg_response_time': None,
                'min_response_time': None,
                'max_response_time': None,
                'memory_usage_mb': None,
                'cpu_usage_percent': None,
                'gpu_usage_percent': None,
                'tokens_processed': 0,
                'model_load_time': None,
                'uptime_seconds': 0,
                'updated_at': datetime.now()
            }
            
            await self.db_manager.update_model_metrics(model_data)
        
        logger.info(f"✅ {len(self.settings.models_config)} modelos inicializados")
    
    async def start_health_monitoring(self):
        """Iniciar monitoreo continuo de salud de modelos"""
        self._monitoring = True
        logger.info("🏥 Iniciando monitoreo de salud de modelos...")
        
        while self._monitoring:
            try:
                await self.check_all_models()
                await asyncio.sleep(self.settings.health_check_interval)
            except Exception as e:
                logger.error(f"Error en health monitoring: {e}")
                await asyncio.sleep(30)  # Esperar menos tiempo en caso de error
    
    def stop_health_monitoring(self):
        """Detener monitoreo de salud"""
        self._monitoring = False
        logger.info("🛑 Deteniendo monitoreo de salud de modelos")
    
    async def check_all_models(self):
        """Verificar salud de todos los modelos"""
        logger.info("🔍 Verificando salud de todos los modelos...")
        
        tasks = []
        for model_name in self.settings.models_config.keys():
            task = asyncio.create_task(self.check_model_health(model_name))
            tasks.append(task)
        
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        # Procesar resultados
        healthy_count = 0
        for i, result in enumerate(results):
            model_name = list(self.settings.models_config.keys())[i]
            if isinstance(result, Exception):
                logger.error(f"Error checking {model_name}: {result}")
            elif result:
                healthy_count += 1
        
        logger.info(f"✅ Health check completado: {healthy_count}/{len(tasks)} modelos saludables")
    
    async def check_model_health(self, model_name: str) -> bool:
        """Verificar salud de un modelo específico"""
        config = self.settings.models_config.get(model_name)
        if not config:
            logger.warning(f"Modelo {model_name} no encontrado en configuración")
            return False
        
        url = self.model_urls.get(model_name)
        if not url:
            logger.warning(f"URL no encontrada para modelo {model_name}")
            return False
        
        start_time = time.time()
        status = 'error'
        error_count = 0
        response_time = None
        
        try:
            # Determinar endpoint de health check según el tipo
            if config['type'] == 'llm':
                health_endpoint = f"{url}/health"
                # Fallback para llama.cpp que no tiene /health
                test_endpoint = f"{url}/v1/models"
            else:
                # APIs de fraude y textosql
                health_endpoint = f"{url}/health"
                test_endpoint = f"{url}/"
            
            async with aiohttp.ClientSession(
                timeout=aiohttp.ClientTimeout(total=self.settings.model_timeout_threshold)
            ) as session:
                # Intentar endpoint de salud primero
                try:
                    async with session.get(health_endpoint) as response:
                        response_time = time.time() - start_time
                        if response.status == 200:
                            status = 'active'
                        else:
                            status = 'error'
                            error_count = 1
                except:
                    # Fallback al endpoint de test
                    try:
                        async with session.get(test_endpoint) as response:
                            response_time = time.time() - start_time
                            if response.status == 200:
                                status = 'active'
                            else:
                                status = 'error'
                                error_count = 1
                    except:
                        response_time = time.time() - start_time
                        status = 'error'
                        error_count = 1
        
        except asyncio.TimeoutError:
            response_time = self.settings.model_timeout_threshold
            status = 'error'
            error_count = 1
            logger.warning(f"Timeout checking {model_name}")
        except Exception as e:
            response_time = time.time() - start_time
            status = 'error'
            error_count = 1
            logger.error(f"Error checking {model_name}: {e}")
        
        # Obtener métricas de recursos del sistema para el modelo
        memory_usage, cpu_usage = await self._get_model_resource_usage(model_name, config['port'])
        
        # Actualizar métricas en base de datos
        model_data = {
            'model_name': model_name,
            'model_type': config['type'],
            'model_size': config['size'],
            'status': status,
            'port': config['port'],
            'host': 'localhost',
            'last_health_check': datetime.now(),
            'error_count': error_count,
            'avg_response_time': response_time,
            'min_response_time': response_time if response_time else None,
            'max_response_time': response_time if response_time else None,
            'memory_usage_mb': memory_usage,
            'cpu_usage_percent': cpu_usage,
            'gpu_usage_percent': None,  # TODO: Implementar GPU monitoring
            'uptime_seconds': int(time.time() - self._start_time) if status == 'active' else 0,
            'updated_at': datetime.now()
        }
        
        await self.db_manager.update_model_metrics(model_data)
        
        # Log del resultado
        status_emoji = "✅" if status == 'active' else "❌"
        logger.info(f"{status_emoji} {model_name}: {status} ({response_time:.3f}s)")
        
        return status == 'active'
    
    async def _get_model_resource_usage(self, model_name: str, port: int) -> tuple:
        """Obtener uso de recursos de un modelo específico"""
        try:
            # Buscar proceso por puerto
            memory_usage = None
            cpu_usage = None
            
            for proc in psutil.process_iter(['pid', 'name', 'connections', 'memory_info', 'cpu_percent']):
                try:
                    # Verificar si el proceso usa el puerto específico
                    connections = proc.info['connections']
                    if connections:
                        for conn in connections:
                            if hasattr(conn, 'laddr') and conn.laddr and conn.laddr.port == port:
                                # Proceso encontrado
                                memory_info = proc.info['memory_info']
                                if memory_info:
                                    memory_usage = memory_info.rss // (1024 * 1024)  # MB
                                
                                cpu_usage = proc.info['cpu_percent']
                                break
                    
                    if memory_usage is not None:
                        break
                        
                except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess):
                    continue
            
            return memory_usage, cpu_usage
            
        except Exception as e:
            logger.debug(f"Error getting resource usage for {model_name}: {e}")
            return None, None
    
    async def get_model_status(self, model_name: str) -> Optional[Dict]:
        """Obtener estado actual de un modelo"""
        query = """
        SELECT * FROM ai_models_metrics 
        WHERE model_name = $1
        ORDER BY updated_at DESC 
        LIMIT 1
        """
        result = await self.db_manager.fetch_one(query, (model_name,))
        return dict(result) if result else None
    
    async def get_all_models_status(self) -> List[Dict]:
        """Obtener estado de todos los modelos"""
        query = "SELECT * FROM models_status_detailed ORDER BY model_type, model_name"
        results = await self.db_manager.fetch_all(query)
        return [dict(row) for row in results]
    
    async def is_model_healthy(self, model_name: str) -> bool:
        """Verificar si un modelo está saludable"""
        status = await self.get_model_status(model_name)
        if not status:
            return False
        
        # Verificar estado y última verificación
        is_active = status['status'] == 'active'
        last_check = status['last_health_check']
        
        # Considerar no saludable si no se ha verificado en los últimos 10 minutos
        if isinstance(last_check, datetime):
            time_since_check = datetime.now() - last_check
            is_recent = time_since_check.total_seconds() < 600  # 10 minutos
        else:
            is_recent = False
        
        return is_active and is_recent