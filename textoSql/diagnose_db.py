#!/usr/bin/env python3
"""
Script de diagnóstico para verificar la conectividad a la base de datos
"""

import os
import sys
from dotenv import load_dotenv
import psycopg2

# Cargar variables de entorno
load_dotenv()

def test_database_connection():
    """Probar conexión a la base de datos con diferentes configuraciones"""
    
    print("🔍 DIAGNÓSTICO DE CONEXIÓN A BASE DE DATOS")
    print("=" * 50)
    
    # Variables de entorno actuales
    db_host = os.getenv("DB_HOST")
    db_port = os.getenv("DB_PORT")
    db_user = os.getenv("DB_USER")
    db_password = os.getenv("DB_PASSWORD")
    db1_name = os.getenv("DB1_NAME")  # banco_global
    db2_name = os.getenv("DB2_NAME")  # bank_transactions
    
    print(f"📋 Variables de entorno:")
    print(f"   DB_HOST: {db_host}")
    print(f"   DB_PORT: {db_port}")
    print(f"   DB_USER: {db_user}")
    print(f"   DB_PASSWORD: {'*' * len(db_password) if db_password else 'None'}")
    print(f"   DB1_NAME: {db1_name}")
    print(f"   DB2_NAME: {db2_name}")
    print()
    
    # Configuraciones a probar
    configs_to_test = [
        {
            "name": "Docker (usando nombre del contenedor)",
            "host": "postgres",
            "port": db_port,
        },
        {
            "name": "Local (localhost)",
            "host": "localhost", 
            "port": db_port,
        },
        {
            "name": "Local (127.0.0.1)",
            "host": "127.0.0.1",
            "port": db_port,
        },
        {
            "name": "Puerto estándar PostgreSQL",
            "host": "localhost",
            "port": "5432",
        }
    ]
    
    databases_to_test = ["postgres", db1_name, db2_name]
    
    # Probar cada configuración
    for config in configs_to_test:
        print(f"🧪 Probando {config['name']}...")
        print(f"   Host: {config['host']}, Puerto: {config['port']}")
        
        for db_name in databases_to_test:
            if not db_name:
                continue
                
            try:
                connection_params = {
                    "host": config["host"],
                    "port": config["port"],
                    "user": db_user,
                    "password": db_password,
                    "dbname": db_name
                }
                
                conn = psycopg2.connect(**connection_params)
                cursor = conn.cursor()
                cursor.execute("SELECT version();")
                version = cursor.fetchone()[0]
                cursor.close()
                conn.close()
                
                print(f"   ✅ {db_name}: CONECTADO")
                print(f"      PostgreSQL: {version[:50]}...")
                
                # Si llegamos aquí, esta configuración funciona
                if config["host"] != db_host or config["port"] != db_port:
                    print(f"   💡 RECOMENDACIÓN: Actualizar .env con:")
                    print(f"      DB_HOST={config['host']}")
                    print(f"      DB_PORT={config['port']}")
                
                return True, config
                
            except Exception as e:
                print(f"   ❌ {db_name}: ERROR - {str(e)[:100]}")
        
        print()
    
    print("❌ No se pudo conectar con ninguna configuración")
    return False, None

def suggest_fixes():
    """Sugerir posibles soluciones"""
    print("\n🔧 POSIBLES SOLUCIONES:")
    print("=" * 30)
    print("1. Si usas Docker:")
    print("   - Verificar que el contenedor PostgreSQL esté corriendo")
    print("   - Usar DB_HOST=postgres (nombre del contenedor)")
    print("   - Verificar el puerto en docker-compose.yaml")
    print()
    print("2. Si usas PostgreSQL local:")
    print("   - Usar DB_HOST=localhost o DB_HOST=127.0.0.1")
    print("   - Verificar que PostgreSQL esté corriendo en puerto 8070 o 5432")
    print("   - Verificar usuario y contraseña")
    print()
    print("3. Comandos para verificar PostgreSQL:")
    print("   - Docker: docker ps | grep postgres")
    print("   - Local: sudo systemctl status postgresql")
    print("   - Conexión manual: psql -h localhost -p 8070 -U postgres")

if __name__ == "__main__":
    success, working_config = test_database_connection()
    
    if success:
        print(f"\n🎉 CONEXIÓN EXITOSA con configuración: {working_config['name']}")
        print("La aplicación TextoSQL debería funcionar correctamente.")
    else:
        suggest_fixes()
        
    print(f"\n📝 Para aplicar cambios, edita el archivo .env en:")
    print(f"   {os.path.abspath('.env')}")