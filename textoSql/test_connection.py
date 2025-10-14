#!/usr/bin/env python3
"""
Script simple para probar la nueva configuración inteligente
"""

import sys
import os

# Agregar el directorio actual al path para imports
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

try:
    from smart_config import get_db_connection_params, DB1_NAME, DB2_NAME
    print("✅ Imports exitosos")
    
    print(f"\n📋 Nombres de bases de datos:")
    print(f"   DB1_NAME (TextoSQL): {DB1_NAME}")
    print(f"   DB2_NAME (Fraude): {DB2_NAME}")
    
    print(f"\n🔧 Configuración de conexión para {DB1_NAME}:")
    params = get_db_connection_params(DB1_NAME)
    for key, value in params.items():
        if key == 'password':
            print(f"   {key}: {'*' * len(str(value))}")
        else:
            print(f"   {key}: {value}")
    
    # Probar conexión real
    print(f"\n🧪 Probando conexión real...")
    try:
        import psycopg2
        conn = psycopg2.connect(**params)
        cursor = conn.cursor()
        cursor.execute("SELECT current_database(), current_user, version();")
        db_name, user, version = cursor.fetchone()
        cursor.close()
        conn.close()
        
        print(f"✅ CONEXIÓN EXITOSA!")
        print(f"   Base de datos: {db_name}")
        print(f"   Usuario: {user}")
        print(f"   PostgreSQL: {version[:50]}...")
        
    except Exception as e:
        print(f"❌ ERROR DE CONEXIÓN: {e}")
        print(f"\n💡 Posibles soluciones:")
        print(f"   1. Verificar que PostgreSQL esté corriendo")
        print(f"   2. Verificar credenciales en .env")
        print(f"   3. Si usas Docker, verificar que el contenedor esté activo")
        print(f"   4. Si es local, usar: DB_HOST=localhost en .env")
        
except ImportError as e:
    print(f"❌ Error de import: {e}")
    print("Instalar dependencias con: pip install psycopg2-binary python-dotenv")

except Exception as e:
    print(f"❌ Error general: {e}")

print(f"\n📁 Directorio actual: {os.getcwd()}")
print(f"📄 Archivo .env: {os.path.abspath('.env') if os.path.exists('.env') else 'NO ENCONTRADO'}")
