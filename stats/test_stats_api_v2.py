"""
Script de pruebas para Stats API v2.0
Actualizado para usar los nuevos endpoints v2.0
"""

import asyncio
import logging
import aiohttp
from datetime import datetime

# Configurar logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class StatsAPITesterV2:
    """Clase para probar la API de estadísticas v2.0"""
    
    def __init__(self, base_url: str = "http://localhost:8003"):
        self.base_url = base_url
        self.api_v2 = f"{base_url}/api/stats"
        self.session = None
    
    async def __aenter__(self):
        self.session = aiohttp.ClientSession()
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        if self.session:
            await self.session.close()
    
    async def test_health_check(self):
        """Probar health check"""
        logger.info("🔍 Probando health check...")
        
        try:
            async with self.session.get(f"{self.base_url}/health") as response:
                if response.status == 200:
                    data = await response.json()
                    logger.info(f"✅ Health check OK: {data['status']}")
                    logger.info(f"   Version: {data.get('version', 'unknown')}")
                    return True
                else:
                    logger.error(f"❌ Health check failed: {response.status}")
                    return False
        except Exception as e:
            logger.error(f"❌ Error en health check: {e}")
            return False
    
    async def test_dashboard_summary(self):
        """Probar endpoint de dashboard summary v2.0"""
        logger.info("📊 Probando /api/stats/dashboard/summary...")
        
        try:
            async with self.session.get(f"{self.api_v2}/dashboard/summary") as response:
                if response.status == 200:
                    data = await response.json()
                    logger.info("✅ Dashboard Summary v2.0 OK:")
                    logger.info(f"   Total requests 24h: {data.get('total_requests_24h', 0)}")
                    logger.info(f"   Total errors 24h: {data.get('total_errors_24h', 0)}")
                    logger.info(f"   Avg response time: {data.get('avg_response_time', 0):.3f}s")
                    logger.info(f"   Success rate: {data.get('success_rate', 0):.2f}%")
                    logger.info(f"   Active services: {data.get('active_services', 0)}")
                    return True
                else:
                    logger.error(f"❌ Dashboard summary failed: {response.status}")
                    return False
        except Exception as e:
            logger.error(f"❌ Error: {e}")
            return False
    
    async def test_services_status(self):
        """Probar endpoint de servicios v2.0"""
        logger.info("🤖 Probando /api/stats/services/status...")
        
        try:
            async with self.session.get(f"{self.api_v2}/services/status") as response:
                if response.status == 200:
                    data = await response.json()
                    services = data.get('services', [])
                    logger.info(f"✅ Services Status v2.0 OK: {len(services)} servicios")
                    
                    # Separar por tipo
                    llms = [s for s in services if s['service_type'] == 'llm']
                    apis = [s for s in services if s['service_type'] == 'api']
                    
                    logger.info(f"   - LLM Models: {len(llms)}")
                    logger.info(f"   - API Services: {len(apis)}")
                    
                    for service in services[:3]:
                        logger.info(f"   {service['service_name']}: {service['status']} ({service['success_rate']:.2f}%)")
                    
                    return True
                else:
                    logger.error(f"❌ Services status failed: {response.status}")
                    return False
        except Exception as e:
            logger.error(f"❌ Error: {e}")
            return False
    
    async def test_system_resources(self):
        """Probar endpoint de recursos del sistema v2.0"""
        logger.info("💻 Probando /api/stats/system/resources...")
        
        try:
            async with self.session.get(f"{self.api_v2}/system/resources") as response:
                if response.status == 200:
                    data = await response.json()
                    logger.info("✅ System Resources v2.0 OK:")
                    logger.info(f"   CPU usage: {data.get('cpu_usage', 0):.2f}%")
                    logger.info(f"   Memory usage: {data.get('memory_usage', 0):.2f}%")
                    logger.info(f"   Disk usage: {data.get('disk_usage', 0):.2f}%")
                    return True
                else:
                    logger.error(f"❌ System resources failed: {response.status}")
                    return False
        except Exception as e:
            logger.error(f"❌ Error: {e}")
            return False
    
    async def test_hourly_trends(self):
        """Probar endpoint de tendencias horarias v2.0"""
        logger.info("📈 Probando /api/stats/trends/hourly...")
        
        try:
            async with self.session.get(f"{self.api_v2}/trends/hourly?hours=24") as response:
                if response.status == 200:
                    data = await response.json()
                    trends = data.get('trends', [])
                    logger.info(f"✅ Hourly Trends v2.0 OK: {len(trends)} períodos")
                    
                    if trends:
                        latest = trends[0]
                        logger.info(f"   Último período:")
                        logger.info(f"   - Requests: {latest.get('total_requests', 0)}")
                        logger.info(f"   - Avg time: {latest.get('avg_response_time', 0):.3f}s")
                        logger.info(f"   - P95: {latest.get('p95', 0):.3f}s")
                        logger.info(f"   - P99: {latest.get('p99', 0):.3f}s")
                    
                    return True
                else:
                    logger.error(f"❌ Hourly trends failed: {response.status}")
                    return False
        except Exception as e:
            logger.error(f"❌ Error: {e}")
            return False
    
    async def test_functionality_performance(self):
        """Probar endpoint de performance por funcionalidad v2.0"""
        logger.info("⚡ Probando /api/stats/functionality/performance...")
        
        try:
            async with self.session.get(f"{self.api_v2}/functionality/performance") as response:
                if response.status == 200:
                    data = await response.json()
                    functionalities = data.get('functionalities', [])
                    logger.info(f"✅ Functionality Performance v2.0 OK: {len(functionalities)} funcionalidades")
                    
                    for func in functionalities:
                        logger.info(f"   {func['functionality']}:")
                        logger.info(f"     - Requests: {func['total_requests']}")
                        logger.info(f"     - Success rate: {func['success_rate']:.2f}%")
                        logger.info(f"     - P95: {func.get('p95', 0):.3f}s")
                    
                    return True
                else:
                    logger.error(f"❌ Functionality performance failed: {response.status}")
                    return False
        except Exception as e:
            logger.error(f"❌ Error: {e}")
            return False
    
    async def test_recent_errors(self):
        """Probar endpoint de errores recientes v2.0"""
        logger.info("🚨 Probando /api/stats/errors/recent...")
        
        try:
            async with self.session.get(f"{self.api_v2}/errors/recent?hours=24") as response:
                if response.status == 200:
                    data = await response.json()
                    errors = data.get('errors', [])
                    logger.info(f"✅ Recent Errors v2.0 OK: {len(errors)} errores")
                    
                    for error in errors[:5]:
                        logger.info(f"   [{error['status_code']}] {error['endpoint']}")
                        logger.info(f"     - Type: {error['error_type']}")
                        logger.info(f"     - Count: {error['count']}")
                    
                    return True
                else:
                    logger.error(f"❌ Recent errors failed: {response.status}")
                    return False
        except Exception as e:
            logger.error(f"❌ Error: {e}")
            return False
    
    async def test_active_alerts(self):
        """Probar endpoint de alertas activas v2.0"""
        logger.info("🔔 Probando /api/stats/alerts/active...")
        
        try:
            async with self.session.get(f"{self.api_v2}/alerts/active") as response:
                if response.status == 200:
                    data = await response.json()
                    alerts = data.get('alerts', [])
                    logger.info(f"✅ Active Alerts v2.0 OK: {len(alerts)} alertas activas")
                    
                    for alert in alerts[:3]:
                        logger.info(f"   [{alert['severity']}] {alert['title']}")
                        logger.info(f"     - Component: {alert['component_name']}")
                        logger.info(f"     - Type: {alert['alert_type']}")
                    
                    return True
                else:
                    logger.error(f"❌ Active alerts failed: {response.status}")
                    return False
        except Exception as e:
            logger.error(f"❌ Error: {e}")
            return False
    
    async def test_activity_log(self):
        """Probar endpoint de activity log v2.0"""
        logger.info("📜 Probando /api/stats/activity/recent...")
        
        try:
            async with self.session.get(f"{self.api_v2}/activity/recent?limit=10") as response:
                if response.status == 200:
                    data = await response.json()
                    activities = data.get('activities', [])
                    logger.info(f"✅ Activity Log v2.0 OK: {len(activities)} actividades")
                    
                    for activity in activities[:3]:
                        logger.info(f"   [{activity['activity_type']}] {activity['title']}")
                        logger.info(f"     - Component: {activity['component_name']}")
                    
                    return True
                else:
                    logger.error(f"❌ Activity log failed: {response.status}")
                    return False
        except Exception as e:
            logger.error(f"❌ Error: {e}")
            return False
    
    async def test_detailed_metrics(self):
        """Probar endpoint de métricas detalladas v2.0"""
        logger.info("📊 Probando /api/stats/metrics/detailed...")
        
        try:
            async with self.session.get(f"{self.api_v2}/metrics/detailed?hours=24") as response:
                if response.status == 200:
                    data = await response.json()
                    metrics = data.get('metrics', [])
                    logger.info(f"✅ Detailed Metrics v2.0 OK: {len(metrics)} métricas")
                    
                    if metrics:
                        metric = metrics[0]
                        logger.info(f"   Ejemplo de métrica:")
                        logger.info(f"   - Endpoint: {metric.get('endpoint_base', 'N/A')}")
                        logger.info(f"   - Requests: {metric.get('total_requests', 0)}")
                        logger.info(f"   - P50: {metric.get('p50', 0):.3f}s")
                        logger.info(f"   - P95: {metric.get('p95', 0):.3f}s")
                        logger.info(f"   - P99: {metric.get('p99', 0):.3f}s")
                    
                    return True
                else:
                    logger.error(f"❌ Detailed metrics failed: {response.status}")
                    return False
        except Exception as e:
            logger.error(f"❌ Error: {e}")
            return False


async def run_all_tests():
    """Ejecutar todos los tests de la API v2.0"""
    logger.info("=" * 80)
    logger.info("🧪 INICIANDO TESTS DE STATS API V2.0")
    logger.info("=" * 80)
    logger.info("")
    
    async with StatsAPITesterV2() as tester:
        tests = [
            ("Health Check", tester.test_health_check),
            ("Dashboard Summary", tester.test_dashboard_summary),
            ("Services Status", tester.test_services_status),
            ("System Resources", tester.test_system_resources),
            ("Hourly Trends", tester.test_hourly_trends),
            ("Functionality Performance", tester.test_functionality_performance),
            ("Recent Errors", tester.test_recent_errors),
            ("Active Alerts", tester.test_active_alerts),
            ("Activity Log", tester.test_activity_log),
            ("Detailed Metrics", tester.test_detailed_metrics),
        ]
        
        results = []
        for name, test_func in tests:
            try:
                result = await test_func()
                results.append((name, result))
                logger.info("")
            except Exception as e:
                logger.error(f"❌ Test '{name}' crashed: {e}")
                results.append((name, False))
                logger.info("")
        
        # Resumen final
        logger.info("=" * 80)
        logger.info("📋 RESUMEN DE TESTS")
        logger.info("=" * 80)
        
        passed = sum(1 for _, result in results if result)
        total = len(results)
        
        for name, result in results:
            status = "✅ PASS" if result else "❌ FAIL"
            logger.info(f"{status} - {name}")
        
        logger.info("")
        logger.info(f"Total: {passed}/{total} tests pasaron")
        logger.info(f"Porcentaje de éxito: {(passed/total*100):.1f}%")
        
        return passed == total


if __name__ == "__main__":
    success = asyncio.run(run_all_tests())
    exit(0 if success else 1)
