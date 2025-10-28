"""
Sistema de alertas automático y proactivo
"""

import asyncio
import json
import logging
from datetime import datetime, timedelta
from typing import Dict, List, Optional

logger = logging.getLogger(__name__)

class AlertSystem:
    """Sistema de alertas automático"""
    
    def __init__(self, db_manager):
        self.db_manager = db_manager
        self._monitoring = False
        
        # Configuración de umbrales
        self.thresholds = {
            'model_timeout': 30.0,  # segundos
            'api_error_rate': 10.0,  # porcentaje
            'memory_usage': 90.0,    # porcentaje
            'cpu_usage': 90.0,       # porcentaje
            'disk_usage': 85.0,      # porcentaje
            'response_time': 10.0,   # segundos
            'consecutive_errors': 5   # número de errores consecutivos
        }
    
    async def start_alert_monitoring(self):
        """Iniciar monitoreo de alertas"""
        self._monitoring = True
        logger.info("🚨 Iniciando sistema de alertas...")
        
        while self._monitoring:
            try:
                await self.check_all_alerts()
                await asyncio.sleep(120)  # Cada 2 minutos
            except Exception as e:
                logger.error(f"Error en alert monitoring: {e}")
                await asyncio.sleep(60)
    
    def stop_alert_monitoring(self):
        """Detener monitoreo de alertas"""
        self._monitoring = False
        logger.info("🛑 Deteniendo sistema de alertas")
    
    async def check_all_alerts(self):
        """Verificar todas las condiciones de alerta"""
        try:
            # Verificar modelos no responsivos
            await self.check_unresponsive_models()
            
            # Verificar APIs con alta tasa de error
            await self.check_high_error_rate_apis()
            
            # Verificar uso de recursos del sistema
            await self.check_system_resources()
            
            # Verificar tiempos de respuesta altos
            await self.check_high_response_times()
            
            # Verificar errores consecutivos
            await self.check_consecutive_errors()
            
            logger.debug("✅ Verificación de alertas completada")
            
        except Exception as e:
            logger.error(f"Error verificando alertas: {e}")
    
    async def check_unresponsive_models(self):
        """Verificar modelos que no responden"""
        query = """
        SELECT model_name, model_type, status, last_health_check, avg_response_time
        FROM ai_models_metrics
        WHERE (
            status = 'error' OR 
            last_health_check < NOW() - INTERVAL '10 minutes' OR
            avg_response_time > $1
        ) AND status != 'maintenance'
        """
        
        results = await self.db_manager.fetch_all(query, (self.thresholds['model_timeout'],))
        
        for row in results:
            model_name = row['model_name']
            status = row['status']
            last_check = row['last_health_check']
            response_time = row['avg_response_time']
            
            # Verificar si ya existe una alerta similar reciente
            if await self._alert_exists('model', model_name, 'unresponsive'):
                continue
            
            # Determinar severidad y mensaje
            if status == 'error':
                severity = 4  # Crítico
                title = f"Modelo {model_name} no responde"
                message = f"El modelo {model_name} está en estado de error y no responde a health checks."
            elif last_check and (datetime.now() - last_check).total_seconds() > 600:
                severity = 3  # Alto
                title = f"Modelo {model_name} sin health check reciente"
                message = f"El modelo {model_name} no ha reportado estado en los últimos 10 minutos."
            elif response_time and response_time > self.thresholds['model_timeout']:
                severity = 2  # Medio
                title = f"Modelo {model_name} con respuesta lenta"
                message = f"El modelo {model_name} tiene tiempo de respuesta alto: {response_time:.2f}s"
            else:
                continue
            
            await self._create_alert(
                alert_type='error',
                component='model',
                component_name=model_name,
                title=title,
                message=message,
                severity=severity,
                metadata={'status': status, 'response_time': response_time}
            )
    
    async def check_high_error_rate_apis(self):
        """Verificar APIs con alta tasa de error"""
        query = """
        SELECT 
            functionality,
            endpoint,
            COUNT(*) as total_requests,
            COUNT(*) FILTER (WHERE status_code >= 400) as error_requests,
            ROUND(
                (COUNT(*) FILTER (WHERE status_code >= 400)::DECIMAL / COUNT(*) * 100), 2
            ) as error_rate
        FROM api_performance_logs
        WHERE timestamp >= NOW() - INTERVAL '1 hour'
        GROUP BY functionality, endpoint
        HAVING COUNT(*) >= 10 
        AND (COUNT(*) FILTER (WHERE status_code >= 400)::DECIMAL / COUNT(*) * 100) > $1
        """
        
        results = await self.db_manager.fetch_all(query, (self.thresholds['api_error_rate'],))
        
        for row in results:
            functionality = row['functionality']
            endpoint = row['endpoint']
            error_rate = row['error_rate']
            total_requests = row['total_requests']
            error_requests = row['error_requests']
            
            # Verificar si ya existe alerta similar
            alert_key = f"{functionality}_{endpoint}_error_rate"
            if await self._alert_exists('api', alert_key, 'high_error_rate'):
                continue
            
            severity = 4 if error_rate > 50 else 3
            
            await self._create_alert(
                alert_type='error',
                component='api',
                component_name=alert_key,
                title=f"Alta tasa de error en {functionality}",
                message=f"El endpoint {endpoint} tiene {error_rate}% de errores "
                       f"({error_requests}/{total_requests} requests) en la última hora.",
                severity=severity,
                metadata={
                    'functionality': functionality,
                    'endpoint': endpoint,
                    'error_rate': error_rate,
                    'total_requests': total_requests,
                    'error_requests': error_requests
                }
            )
    
    async def check_system_resources(self):
        """Verificar uso de recursos del sistema"""
        query = """
        SELECT 
            memory_usage_percent,
            cpu_usage_percent,
            disk_usage_percent
        FROM system_resources
        WHERE timestamp >= NOW() - INTERVAL '5 minutes'
        ORDER BY timestamp DESC
        LIMIT 1
        """
        
        result = await self.db_manager.fetch_one(query)
        if not result:
            return
        
        memory_usage = result['memory_usage_percent']
        cpu_usage = result['cpu_usage_percent']
        disk_usage = result['disk_usage_percent']
        
        # Verificar memoria
        if memory_usage > self.thresholds['memory_usage']:
            if not await self._alert_exists('system', 'memory', 'high_usage'):
                severity = 5 if memory_usage > 95 else 4
                await self._create_alert(
                    alert_type='critical',
                    component='system',
                    component_name='memory',
                    title=f"Uso de memoria crítico: {memory_usage:.1f}%",
                    message=f"El sistema está usando {memory_usage:.1f}% de la memoria disponible.",
                    severity=severity,
                    metadata={'memory_usage_percent': memory_usage}
                )
        
        # Verificar CPU
        if cpu_usage > self.thresholds['cpu_usage']:
            if not await self._alert_exists('system', 'cpu', 'high_usage'):
                severity = 4 if cpu_usage > 95 else 3
                await self._create_alert(
                    alert_type='warning',
                    component='system',
                    component_name='cpu',
                    title=f"Uso de CPU alto: {cpu_usage:.1f}%",
                    message=f"El sistema está usando {cpu_usage:.1f}% de CPU.",
                    severity=severity,
                    metadata={'cpu_usage_percent': cpu_usage}
                )
        
        # Verificar disco
        if disk_usage > self.thresholds['disk_usage']:
            if not await self._alert_exists('system', 'disk', 'high_usage'):
                severity = 4 if disk_usage > 95 else 3
                await self._create_alert(
                    alert_type='warning',
                    component='system',
                    component_name='disk',
                    title=f"Uso de disco alto: {disk_usage:.1f}%",
                    message=f"El sistema está usando {disk_usage:.1f}% del espacio en disco.",
                    severity=severity,
                    metadata={'disk_usage_percent': disk_usage}
                )
    
    async def check_high_response_times(self):
        """Verificar tiempos de respuesta altos"""
        query = """
        SELECT 
            functionality,
            AVG(response_time) as avg_response_time,
            PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY response_time) as p95_response_time,
            COUNT(*) as request_count
        FROM api_performance_logs
        WHERE timestamp >= NOW() - INTERVAL '30 minutes'
        AND status_code < 400
        GROUP BY functionality
        HAVING AVG(response_time) > %s OR 
               PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY response_time) > %s
        """
        
        results = await self.db_manager.fetch_all(query, (
            self.thresholds['response_time'], 
            self.thresholds['response_time'] * 2
        ))
        
        for row in results:
            functionality = row['functionality']
            avg_response_time = row['avg_response_time']
            p95_response_time = row['p95_response_time']
            request_count = row['request_count']
            
            if await self._alert_exists('api', functionality, 'slow_response'):
                continue
            
            severity = 3 if avg_response_time > 20 else 2
            
            await self._create_alert(
                alert_type='warning',
                component='api',
                component_name=functionality,
                title=f"Tiempos de respuesta lentos en {functionality}",
                message=f"La funcionalidad {functionality} tiene tiempos de respuesta altos: "
                       f"promedio {avg_response_time:.2f}s, P95 {p95_response_time:.2f}s "
                       f"({request_count} requests en 30 min).",
                severity=severity,
                metadata={
                    'functionality': functionality,
                    'avg_response_time': avg_response_time,
                    'p95_response_time': p95_response_time,
                    'request_count': request_count
                }
            )
    
    async def check_consecutive_errors(self):
        """Verificar errores consecutivos en APIs"""
        query = """
        WITH recent_requests AS (
            SELECT 
                functionality,
                endpoint,
                status_code,
                timestamp,
                ROW_NUMBER() OVER (PARTITION BY functionality, endpoint ORDER BY timestamp DESC) as rn
            FROM api_performance_logs
            WHERE timestamp >= NOW() - INTERVAL '1 hour'
        ),
        consecutive_errors AS (
            SELECT 
                functionality,
                endpoint,
                COUNT(*) as consecutive_count
            FROM recent_requests
            WHERE rn <= $1 AND status_code >= 400
            GROUP BY functionality, endpoint
            HAVING COUNT(*) = $2
        )
        SELECT * FROM consecutive_errors
        """
        
        threshold = self.thresholds['consecutive_errors']
        results = await self.db_manager.fetch_all(query, (threshold, threshold))
        
        for row in results:
            functionality = row['functionality']
            endpoint = row['endpoint']
            consecutive_count = row['consecutive_count']
            
            alert_key = f"{functionality}_{endpoint}_consecutive_errors"
            if await self._alert_exists('api', alert_key, 'consecutive_errors'):
                continue
            
            await self._create_alert(
                alert_type='error',
                component='api',
                component_name=alert_key,
                title=f"Errores consecutivos en {functionality}",
                message=f"El endpoint {endpoint} ha fallado {consecutive_count} veces consecutivas.",
                severity=4,
                metadata={
                    'functionality': functionality,
                    'endpoint': endpoint,
                    'consecutive_count': consecutive_count
                }
            )
    
    async def _alert_exists(self, component: str, component_name: str, alert_subtype: str) -> bool:
        """Verificar si ya existe una alerta similar en las últimas 2 horas"""
        query = """
        SELECT COUNT(*) 
        FROM system_alerts
        WHERE component = $1 
        AND component_name = $2
        AND title ILIKE $3
        AND created_at >= NOW() - INTERVAL '2 hours'
        AND resolved = FALSE
        """
        
        result = await self.db_manager.fetch_one(query, (
            component, 
            component_name, 
            f"%{alert_subtype}%"
        ))
        
        return result[0] > 0 if result else False
    
    async def _create_alert(self, alert_type: str, component: str, component_name: str,
                           title: str, message: str, severity: int, metadata: dict = None):
        """Crear nueva alerta"""
        try:
            alert_data = {
                'alert_type': alert_type,
                'component': component,
                'component_name': component_name,
                'title': title,
                'message': message,
                'severity': severity,
                'metadata': json.dumps(metadata) if metadata else None
            }
            
            await self.db_manager.insert_alert(alert_data)
            
            # Log de la alerta
            severity_emoji = {1: "ℹ️", 2: "⚠️", 3: "🔶", 4: "🔴", 5: "🚨"}
            emoji = severity_emoji.get(severity, "❓")
            logger.warning(f"{emoji} ALERTA [{component}]: {title}")
            
        except Exception as e:
            logger.error(f"Error creando alerta: {e}")
    
    async def resolve_alert(self, alert_id: int, resolved_by: str = "system") -> bool:
        """Resolver una alerta específica"""
        try:
            query = """
            UPDATE system_alerts 
            SET resolved = TRUE, resolved_at = NOW(), resolved_by = $1
            WHERE id = $2 AND resolved = FALSE
            """
            
            result = await self.db_manager.execute_query(query, (resolved_by, alert_id))
            return result > 0
            
        except Exception as e:
            logger.error(f"Error resolviendo alerta {alert_id}: {e}")
            return False
    
    async def get_active_alerts(self, severity_min: int = 1) -> List[Dict]:
        """Obtener alertas activas"""
        query = """
        SELECT * FROM system_alerts
        WHERE resolved = FALSE 
        AND severity >= %s
        ORDER BY severity DESC, created_at DESC
        """
        
        results = await self.db_manager.fetch_all(query, (severity_min,))
        return [dict(row) for row in results]
    
    async def get_alert_summary(self) -> Dict:
        """Obtener resumen de alertas"""
        query = """
        SELECT 
            COUNT(*) FILTER (WHERE resolved = FALSE AND severity >= 4) as critical_alerts,
            COUNT(*) FILTER (WHERE resolved = FALSE AND severity = 3) as high_alerts,
            COUNT(*) FILTER (WHERE resolved = FALSE AND severity <= 2) as low_alerts,
            COUNT(*) FILTER (WHERE resolved = TRUE AND created_at >= NOW() - INTERVAL '24 hours') as resolved_today
        FROM system_alerts
        WHERE created_at >= NOW() - INTERVAL '24 hours'
        """
        
        result = await self.db_manager.fetch_one(query)
        
        if result:
            return {
                'critical_alerts': result['critical_alerts'],
                'high_alerts': result['high_alerts'],
                'low_alerts': result['low_alerts'],
                'resolved_today': result['resolved_today'],
                'total_active': result['critical_alerts'] + result['high_alerts'] + result['low_alerts']
            }
        else:
            return {
                'critical_alerts': 0,
                'high_alerts': 0,
                'low_alerts': 0,
                'resolved_today': 0,
                'total_active': 0
            }