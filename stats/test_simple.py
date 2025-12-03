"""
🧪 SCRIPT SIMPLE PARA PROBAR STATS API V2.0
Prueba rápida de todos los endpoints de la API
"""

import requests
import json
from datetime import datetime, timedelta

# Configuración
BASE_URL = "http://localhost:8003"  # ✅ CORREGIDO: Stats API está en puerto 8003, NO 8004
HEADERS = {"Content-Type": "application/json"}

def print_section(title):
    print(f"\n{'='*60}")
    print(f"  {title}")
    print(f"{'='*60}")

def test_endpoint(name, url, method="GET", data=None):
    """Prueba un endpoint y muestra el resultado"""
    print(f"\n🔹 {name}")
    print(f"   URL: {url}")
    
    try:
        if method == "GET":
            response = requests.get(url, headers=HEADERS, timeout=10)
        else:
            response = requests.post(url, headers=HEADERS, json=data, timeout=10)
        
        print(f"   Status: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            print(f"   ✅ Success: {json.dumps(result, indent=2)[:200]}...")
            return True
        else:
            print(f"   ❌ Error: {response.text[:200]}")
            return False
    except Exception as e:
        print(f"   ❌ Exception: {str(e)}")
        return False

def main():
    print_section("🚀 PROBANDO STATS API V2.0")
    
    # Health check
    print_section("1. HEALTH CHECK")
    test_endpoint(
        "Health Check",
        f"{BASE_URL}/health"
    )
    
    # Métricas generales
    print_section("2. MÉTRICAS GENERALES")
    
    end_date = datetime.now()
    start_date = end_date - timedelta(days=7)
    
    test_endpoint(
        "Métricas Globales",
        f"{BASE_URL}/api/stats/metrics/global?"
        f"start_date={start_date.isoformat()}&"
        f"end_date={end_date.isoformat()}"
    )
    
    test_endpoint(
        "Métricas por Servicio",
        f"{BASE_URL}/api/stats/metrics/by-service?"
        f"start_date={start_date.isoformat()}&"
        f"end_date={end_date.isoformat()}"
    )
    
    # Performance
    print_section("3. PERFORMANCE")
    
    test_endpoint(
        "Top Endpoints (mejores)",
        f"{BASE_URL}/api/stats/performance/top-endpoints?limit=5&worst=false"
    )
    
    test_endpoint(
        "Top Endpoints (peores)",
        f"{BASE_URL}/api/stats/performance/top-endpoints?limit=5&worst=true"
    )
    
    test_endpoint(
        "Heatmap de Performance",
        f"{BASE_URL}/api/stats/performance/heatmap?"
        f"start_date={start_date.isoformat()}&"
        f"end_date={end_date.isoformat()}"
    )
    
    # Trends
    print_section("4. TENDENCIAS")
    
    test_endpoint(
        "Tendencias Horarias",
        f"{BASE_URL}/api/stats/trends/hourly?"
        f"start_date={start_date.isoformat()}&"
        f"end_date={end_date.isoformat()}&"
        f"service=rag"
    )
    
    test_endpoint(
        "Tendencias Diarias",
        f"{BASE_URL}/api/stats/trends/daily?"
        f"start_date={start_date.isoformat()}&"
        f"end_date={end_date.isoformat()}"
    )
    
    # Comparaciones
    print_section("5. COMPARACIONES")
    
    test_endpoint(
        "Comparación de Periodos",
        f"{BASE_URL}/api/stats/compare/periods?"
        f"start_date_1={start_date.isoformat()}&"
        f"end_date_1={end_date.isoformat()}&"
        f"start_date_2={(start_date - timedelta(days=7)).isoformat()}&"
        f"end_date_2={start_date.isoformat()}"
    )
    
    test_endpoint(
        "Comparación de Servicios",
        f"{BASE_URL}/api/stats/compare/services?"
        f"service_1=rag&"
        f"service_2=texto-sql&"
        f"start_date={start_date.isoformat()}&"
        f"end_date={end_date.isoformat()}"
    )
    
    # Alertas
    print_section("6. ALERTAS Y SALUD")
    
    test_endpoint(
        "Alertas Activas",
        f"{BASE_URL}/api/stats/alerts/active"
    )
    
    test_endpoint(
        "Estado de Modelos",
        f"{BASE_URL}/api/models/status"
    )
    
    # Admin endpoints (sin autenticación para demo)
    print_section("7. ENDPOINTS ADMIN (DEMO)")
    
    test_endpoint(
        "Calcular Métricas Diarias",
        f"{BASE_URL}/api/admin/calculate-metrics",
        method="POST"
    )
    
    test_endpoint(
        "Refrescar Modelos",
        f"{BASE_URL}/api/admin/refresh-models",
        method="POST"
    )
    
    print_section("✅ PRUEBAS COMPLETADAS")
    print("\n💡 Tip: Revisa que todos los endpoints respondan con 200 OK")
    print("💡 Tip: Si hay errores 404, verifica que tengas datos en las tablas")
    print("💡 Tip: Si hay errores 500, revisa los logs del container\n")

if __name__ == "__main__":
    main()
