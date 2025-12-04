#!/usr/bin/env python3
"""
Test Stats API v2.1: Validar filtro de is_ai_query
Verificar que solo queries AI incrementan daily_queries
"""

import requests
import time
from datetime import datetime

BASE_URL = "http://localhost:8003"

def get_current_daily_queries():
    """Obtener contador actual de daily_queries"""
    response = requests.get(f"{BASE_URL}/api/stats/v2.0/dashboard/summary")
    if response.status_code == 200:
        data = response.json()
        return data.get('daily_queries', 0)
    return None

def test_stats_endpoint_should_not_count():
    """Verificar que endpoints de stats NO incrementan contador"""
    print("\n=== TEST 1: Stats endpoints NO deben incrementar daily_queries ===")
    
    # Obtener contador inicial
    initial_count = get_current_daily_queries()
    print(f"Contador inicial: {initial_count}")
    
    # Hacer 5 requests al endpoint de stats
    for i in range(5):
        response = requests.get(f"{BASE_URL}/api/stats/v2.0/dashboard/summary")
        print(f"  Request {i+1}: {response.status_code}, X-AI-Query: {response.headers.get('X-AI-Query')}")
        time.sleep(0.5)
    
    # Verificar contador final
    final_count = get_current_daily_queries()
    print(f"Contador final: {final_count}")
    print(f"Diferencia: {final_count - initial_count if initial_count and final_count else 'N/A'}")
    
    if final_count == initial_count:
        print("✅ CORRECTO: Stats endpoints NO incrementan contador")
        return True
    else:
        print(f"❌ ERROR: Contador incrementó de {initial_count} a {final_count}")
        return False

def test_ai_query_should_count():
    """Verificar que queries AI SÍ incrementan contador"""
    print("\n=== TEST 2: Queries AI deben incrementar daily_queries ===")
    
    # Obtener contador inicial
    initial_count = get_current_daily_queries()
    print(f"Contador inicial: {initial_count}")
    
    # Hacer POST a LLM proxy (simulando query AI)
    ai_endpoints = [
        ("/proxy/8088/completion", {"prompt": "test"}),
    ]
    
    success = False
    for endpoint, payload in ai_endpoints:
        try:
            response = requests.post(
                f"http://localhost{endpoint}",
                json=payload,
                timeout=5
            )
            print(f"  Request a {endpoint}: {response.status_code}, X-AI-Query: {response.headers.get('X-AI-Query')}")
            success = True
            break
        except Exception as e:
            print(f"  Request a {endpoint}: FAILED ({e})")
    
    if not success:
        print("⚠️  SKIP: No se pudo conectar a demos AI (esperado si no están corriendo)")
        return None
    
    # Esperar que se procese
    time.sleep(2)
    
    # Verificar contador final
    final_count = get_current_daily_queries()
    print(f"Contador final: {final_count}")
    print(f"Diferencia: {final_count - initial_count if initial_count and final_count else 'N/A'}")
    
    if final_count > initial_count:
        print(f"✅ CORRECTO: Query AI incrementó contador (+{final_count - initial_count})")
        return True
    else:
        print(f"❌ ERROR: Contador no incrementó")
        return False

def test_get_requests_should_not_count():
    """Verificar que requests GET NO incrementan contador"""
    print("\n=== TEST 3: GET requests NO deben incrementar daily_queries ===")
    
    initial_count = get_current_daily_queries()
    print(f"Contador inicial: {initial_count}")
    
    # Hacer GET a varios endpoints
    test_endpoints = [
        "/api/stats/v2.0/services/status",
        "/api/stats/v2.0/alerts/active",
        "/api/stats/v2.0/activity/recent",
    ]
    
    for endpoint in test_endpoints:
        response = requests.get(f"{BASE_URL}{endpoint}")
        print(f"  GET {endpoint}: {response.status_code}, X-AI-Query: {response.headers.get('X-AI-Query')}")
        time.sleep(0.3)
    
    final_count = get_current_daily_queries()
    print(f"Contador final: {final_count}")
    
    if final_count == initial_count:
        print("✅ CORRECTO: GET requests NO incrementan contador")
        return True
    else:
        print(f"❌ ERROR: Contador incrementó de {initial_count} a {final_count}")
        return False

def verify_header_presence():
    """Verificar que header X-AI-Query está presente"""
    print("\n=== TEST 4: Header X-AI-Query debe estar presente ===")
    
    response = requests.get(f"{BASE_URL}/api/stats/v2.0/dashboard/summary")
    header = response.headers.get('X-AI-Query')
    
    if header:
        print(f"✅ Header encontrado: X-AI-Query={header}")
        return True
    else:
        print("❌ Header X-AI-Query no encontrado")
        return False

def test_alerts_have_id_field():
    """Verificar que alerts tienen campo id como string"""
    print("\n=== TEST 5: Alerts deben tener campo id (string) ===")
    
    response = requests.get(f"{BASE_URL}/api/stats/v2.0/alerts/active")
    if response.status_code == 200:
        data = response.json()
        alerts = data.get('alerts', [])
        
        if not alerts:
            print("⚠️  No hay alerts activas para verificar")
            return None
        
        first_alert = alerts[0]
        has_alert_id = 'alert_id' in first_alert
        has_id = 'id' in first_alert
        id_is_string = isinstance(first_alert.get('id'), str) if has_id else False
        
        print(f"  alert_id presente: {has_alert_id}")
        print(f"  id presente: {has_id}")
        print(f"  id es string: {id_is_string}")
        
        if has_alert_id and has_id and id_is_string:
            print(f"✅ CORRECTO: Alert tiene alert_id={first_alert['alert_id']} e id='{first_alert['id']}'")
            return True
        else:
            print(f"❌ ERROR: Campos faltantes o tipo incorrecto")
            return False
    else:
        print(f"❌ ERROR: No se pudo obtener alerts ({response.status_code})")
        return False

if __name__ == "__main__":
    print("=" * 60)
    print("TESTS STATS API v2.1 - Query Counter Filter")
    print("=" * 60)
    
    results = {
        "Stats endpoints no cuentan": test_stats_endpoint_should_not_count(),
        "GET requests no cuentan": test_get_requests_should_not_count(),
        "Header X-AI-Query presente": verify_header_presence(),
        "Alerts tienen campo id": test_alerts_have_id_field(),
        "AI queries sí cuentan": test_ai_query_should_count(),
    }
    
    print("\n" + "=" * 60)
    print("RESUMEN")
    print("=" * 60)
    
    for test_name, result in results.items():
        if result is True:
            status = "✅ PASS"
        elif result is False:
            status = "❌ FAIL"
        else:
            status = "⚠️  SKIP"
        print(f"{status} - {test_name}")
    
    passed = sum(1 for r in results.values() if r is True)
    failed = sum(1 for r in results.values() if r is False)
    skipped = sum(1 for r in results.values() if r is None)
    
    print(f"\nTotal: {passed} passed, {failed} failed, {skipped} skipped")
