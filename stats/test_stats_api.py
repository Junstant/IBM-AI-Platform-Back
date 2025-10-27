"""
Script de pruebas para el sistema de estadísticas AI Platform
"""

import asyncio
import time
import json
import aiohttp
import logging
from datetime import datetime

# Configurar logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class StatsAPITester:
    """Clase para probar la API de estadísticas"""
    
    def __init__(self, base_url: str = "http://localhost:8003"):
        self.base_url = base_url
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
                    return True
                else:
                    logger.error(f"❌ Health check failed: {response.status}")
                    return False
        except Exception as e:
            logger.error(f"❌ Error en health check: {e}")
            return False
    
    async def test_dashboard_summary(self):
        """Probar endpoint de resumen del dashboard"""
        logger.info("📊 Probando dashboard summary...")
        
        try:
            async with self.session.get(f"{self.base_url}/api/stats/dashboard-summary") as response:
                if response.status == 200:
                    data = await response.json()
                    logger.info("✅ Dashboard summary OK:")
                    logger.info(f"   Modelos activos: {data.get('active_models', 0)}")
                    logger.info(f"   Consultas diarias: {data.get('daily_queries', 0)}")
                    logger.info(f"   Tiempo promedio: {data.get('avg_response_time', 0):.3f}s")
                    return True
                else:
                    logger.error(f"❌ Dashboard summary failed: {response.status}")
                    return False
        except Exception as e:
            logger.error(f"❌ Error en dashboard summary: {e}")
            return False
    
    async def test_models_status(self):
        """Probar endpoint de estado de modelos"""
        logger.info("🤖 Probando models status...")
        
        try:
            async with self.session.get(f"{self.base_url}/api/stats/models-status") as response:
                if response.status == 200:
                    data = await response.json()
                    logger.info(f"✅ Models status OK: {len(data)} modelos encontrados")
                    
                    for model in data[:3]:  # Mostrar solo los primeros 3
                        logger.info(f"   {model['model_name']}: {model['status']} "
                                  f"({model['success_rate']:.1f}% success)")
                    return True
                else:
                    logger.error(f"❌ Models status failed: {response.status}")
                    return False
        except Exception as e:
            logger.error(f"❌ Error en models status: {e}")
            return False
    
    async def test_functionality_performance(self):
        """Probar endpoint de performance por funcionalidad"""
        logger.info("⚡ Probando functionality performance...")
        
        try:
            async with self.session.get(f"{self.base_url}/api/stats/functionality-performance") as response:
                if response.status == 200:
                    data = await response.json()
                    logger.info(f"✅ Functionality performance OK: {len(data)} funcionalidades")
                    
                    for func in data:
                        logger.info(f"   {func['functionality']}: {func['total_queries']} queries "
                                  f"({func['success_rate']:.1f}% success)")
                    return True
                else:
                    logger.error(f"❌ Functionality performance failed: {response.status}")
                    return False
        except Exception as e:
            logger.error(f"❌ Error en functionality performance: {e}")
            return False
    
    async def test_system_resources(self):
        """Probar endpoint de recursos del sistema"""
        logger.info("💻 Probando system resources...")
        
        try:
            async with self.session.get(f"{self.base_url}/api/stats/system-resources?hours=1") as response:
                if response.status == 200:
                    data = await response.json()
                    logger.info(f"✅ System resources OK: {len(data)} registros")
                    
                    if data:
                        latest = data[0]
                        logger.info(f"   CPU: {latest.get('cpu_usage_percent', 0):.1f}%")
                        logger.info(f"   RAM: {latest.get('memory_usage_percent', 0):.1f}%")
                        logger.info(f"   Disco: {latest.get('disk_usage_percent', 0):.1f}%")
                    return True
                else:
                    logger.error(f"❌ System resources failed: {response.status}")
                    return False
        except Exception as e:
            logger.error(f"❌ Error en system resources: {e}")
            return False
    
    async def test_alerts(self):
        """Probar endpoint de alertas"""
        logger.info("🚨 Probando alerts...")
        
        try:
            async with self.session.get(f"{self.base_url}/api/stats/alerts?resolved=false") as response:
                if response.status == 200:
                    data = await response.json()
                    logger.info(f"✅ Alerts OK: {len(data)} alertas activas")
                    
                    critical_alerts = [a for a in data if a.get('severity', 0) >= 4]
                    if critical_alerts:
                        logger.warning(f"⚠️  {len(critical_alerts)} alertas críticas encontradas")
                        for alert in critical_alerts[:2]:
                            logger.warning(f"   {alert['title']}")
                    return True
                else:
                    logger.error(f"❌ Alerts failed: {response.status}")
                    return False
        except Exception as e:
            logger.error(f"❌ Error en alerts: {e}")
            return False
    
    async def test_admin_functions(self):
        """Probar funciones administrativas"""
        logger.info("🔧 Probando admin functions...")
        
        try:
            # Calcular métricas manualmente
            async with self.session.post(f"{self.base_url}/api/admin/calculate-metrics") as response:
                if response.status == 200:
                    data = await response.json()
                    logger.info(f"✅ Calculate metrics OK: {data.get('message')}")
                else:
                    logger.warning(f"⚠️  Calculate metrics warning: {response.status}")
            
            # Refrescar modelos
            async with self.session.post(f"{self.base_url}/api/admin/refresh-models") as response:
                if response.status == 200:
                    data = await response.json()
                    logger.info(f"✅ Refresh models OK: {data.get('message')}")
                    return True
                else:
                    logger.warning(f"⚠️  Refresh models warning: {response.status}")
                    return False
                    
        except Exception as e:
            logger.error(f"❌ Error en admin functions: {e}")
            return False
    
    async def simulate_api_calls(self, count: int = 10):
        """Simular llamadas API para generar métricas"""
        logger.info(f"🎯 Simulando {count} llamadas API...")
        
        endpoints = [
            "/",
            "/health",
            "/api/stats/dashboard-summary",
            "/api/stats/models-status",
            "/api/stats/alerts"
        ]
        
        success_count = 0
        
        for i in range(count):
            endpoint = endpoints[i % len(endpoints)]
            try:
                async with self.session.get(f"{self.base_url}{endpoint}") as response:
                    if response.status < 400:
                        success_count += 1
                
                # Pequeña pausa entre requests
                await asyncio.sleep(0.1)
                
            except Exception as e:
                logger.debug(f"Error en simulación: {e}")
        
        logger.info(f"✅ Simulación completada: {success_count}/{count} requests exitosas")
        return success_count

async def run_tests():
    """Ejecutar todas las pruebas"""
    logger.info("🚀 Iniciando pruebas del sistema de estadísticas AI Platform")
    logger.info("=" * 60)
    
    start_time = time.time()
    passed_tests = 0
    total_tests = 0
    
    async with StatsAPITester() as tester:
        # Lista de pruebas
        tests = [
            ("Health Check", tester.test_health_check),
            ("Dashboard Summary", tester.test_dashboard_summary),
            ("Models Status", tester.test_models_status),
            ("Functionality Performance", tester.test_functionality_performance),
            ("System Resources", tester.test_system_resources),
            ("Alerts", tester.test_alerts),
            ("Admin Functions", tester.test_admin_functions),
        ]
        
        # Ejecutar pruebas
        for test_name, test_func in tests:
            total_tests += 1
            logger.info(f"\n--- {test_name} ---")
            
            try:
                if await test_func():
                    passed_tests += 1
            except Exception as e:
                logger.error(f"❌ {test_name} falló con excepción: {e}")
        
        # Simular tráfico
        logger.info(f"\n--- Simulación de Tráfico ---")
        await tester.simulate_api_calls(20)
        
        # Esperar un poco para que se procesen las métricas
        logger.info("⏳ Esperando procesamiento de métricas...")
        await asyncio.sleep(2)
        
        # Verificar métricas después de la simulación
        logger.info(f"\n--- Verificación Post-Simulación ---")
        await tester.test_dashboard_summary()
    
    # Resumen final
    execution_time = time.time() - start_time
    logger.info("=" * 60)
    logger.info("📊 RESUMEN DE PRUEBAS")
    logger.info(f"Pruebas pasadas: {passed_tests}/{total_tests}")
    logger.info(f"Tiempo de ejecución: {execution_time:.2f} segundos")
    
    if passed_tests == total_tests:
        logger.info("🎉 ¡Todas las pruebas pasaron exitosamente!")
        return True
    else:
        logger.warning(f"⚠️  {total_tests - passed_tests} pruebas fallaron")
        return False

if __name__ == "__main__":
    # Ejecutar pruebas
    try:
        success = asyncio.run(run_tests())
        exit(0 if success else 1)
    except KeyboardInterrupt:
        logger.info("🛑 Pruebas interrumpidas por el usuario")
        exit(1)
    except Exception as e:
        logger.error(f"❌ Error ejecutando pruebas: {e}")
        exit(1)