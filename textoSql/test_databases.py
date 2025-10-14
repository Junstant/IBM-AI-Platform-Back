#!/usr/bin/env python3
"""
Script de prueba para verificar que get_available_databases funciona
"""

import sys
import os

# Agregar el directorio actual al path para importar los módulos
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from connection_manager import connection_manager

def test_databases():
    print("🔍 Probando get_available_databases()...")
    
    try:
        # Probar discover_databases primero
        print("📊 Paso 1: Descubrir nombres de bases de datos...")
        discovered = connection_manager.discover_databases()
        print(f"   Encontradas: {discovered}")
        
        # Probar conexión individual a cada base de datos
        print("📊 Paso 2: Probar conexión individual a cada BD...")
        from smart_config import get_db_connection_params
        import psycopg2
        
        for db_name in discovered:
            try:
                print(f"   Probando {db_name}...")
                db_params = get_db_connection_params(db_name)
                print(f"     Parámetros: {db_params}")
                
                conn = psycopg2.connect(**db_params)
                cursor = conn.cursor()
                cursor.execute("SELECT 1")
                cursor.close()
                conn.close()
                print(f"     ✅ {db_name}: Conexión exitosa")
                
            except Exception as e:
                print(f"     ❌ {db_name}: Error - {e}")
        
        # Probar get_available_databases
        print("📊 Paso 3: Obtener bases de datos con información completa...")
        print(f"DEBUG: Estado del connection_manager antes de get_available_databases:")
        print(f"   - hasattr discovered_databases: {hasattr(connection_manager, 'discovered_databases')}")
        if hasattr(connection_manager, 'discovered_databases'):
            print(f"   - discovered_databases: {connection_manager.discovered_databases}")
        
        databases = connection_manager.get_available_databases()
        print(f"   Resultado: {databases}")
        print(f"   Tipo: {type(databases)}")
        print(f"   Cantidad: {len(databases)}")
        
        if databases:
            print("📊 Detalles de las bases de datos:")
            for i, db in enumerate(databases):
                print(f"   {i+1}. {db}")
        
        return databases
        
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()
        return []

if __name__ == "__main__":
    result = test_databases()
    
    if result:
        print(f"\n✅ SUCCESS: Encontradas {len(result)} bases de datos")
    else:
        print(f"\n❌ FAILED: No se encontraron bases de datos")