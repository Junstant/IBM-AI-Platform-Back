#!/usr/bin/env python3
"""
Script simple para agregar transacciones de prueba a la base de datos limpia
"""
import psycopg2
import os
from datetime import datetime, date, time
from dotenv import load_dotenv

load_dotenv()

def get_db_connection():
    """Conectar a la base de datos bank_transactions"""
    try:
        conn = psycopg2.connect(
            dbname="bank_transactions",
            user=os.getenv("DB_USER", "postgres"),
            password=os.getenv("DB_PASSWORD", "root"),
            host=os.getenv("DB_HOST", "localhost"),
            port=os.getenv("DB_PORT", "8070")
        )
        return conn
    except psycopg2.OperationalError as e:
        print(f"Error conectando a la base de datos: {e}")
        return None

def insert_sample_transactions():
    """Insertar algunas transacciones de prueba"""
    conn = get_db_connection()
    if not conn:
        print("❌ No se pudo conectar a la base de datos")
        return
    
    try:
        cur = conn.cursor()
        
        # Transacciones de prueba (algunas normales, algunas fraudulentas)
        sample_transactions = [
            # Transacciones normales
            (12345, None, 150.00, 'Supermercado Central', 'Av. Corrientes 1500', 'Débito', '14:30:00', False),
            (12346, None, 50.00, 'Farmacia del Centro', 'Florida 800', 'Débito', '10:15:00', False),
            (12347, None, 2500.00, 'Apple Store Unicenter', 'Unicenter Shopping', 'Crédito', '16:45:00', False),
            (12348, None, 80.00, 'Shell Estación Norte', 'Panamericana Km 25', 'Débito', '08:20:00', False),
            
            # Transacciones fraudulentas (patrones sospechosos)
            (12349, None, 9500.00, 'E-Shop Sospechoso', 'Servidor Offshore', 'Crédito', '03:22:00', True),
            (12350, None, 15000.00, 'Casino Internacional', 'Las Vegas Strip', 'Crédito', '02:15:00', True),
            (12351, None, 500.00, 'Kiosco Villa 31', 'Villa 31, CABA', 'Débito', '23:55:00', True),
            (12352, None, 25000.00, 'Western Union Miami', 'Online Transfer', 'Crédito', '04:10:00', True),
        ]
        
        for transaction in sample_transactions:
            cur.execute("""
                INSERT INTO transacciones 
                (cuenta_origen_id, cuenta_destino_id, monto, comerciante, ubicacion, 
                 tipo_tarjeta, horario_transaccion, es_fraude)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                ON CONFLICT (numero_transaccion) DO NOTHING
            """, transaction)
        
        conn.commit()
        cur.close()
        print(f"✅ Insertadas {len(sample_transactions)} transacciones de prueba")
        
    except Exception as e:
        print(f"❌ Error insertando transacciones: {e}")
        conn.rollback()
    finally:
        conn.close()

def check_transactions():
    """Verificar que las transacciones se insertaron correctamente"""
    conn = get_db_connection()
    if not conn:
        return
    
    try:
        cur = conn.cursor()
        cur.execute("SELECT COUNT(*) FROM transacciones")
        total = cur.fetchone()[0]
        
        cur.execute("SELECT COUNT(*) FROM transacciones WHERE es_fraude = true")
        fraud_count = cur.fetchone()[0]
        
        cur.close()
        print(f"📊 Total transacciones: {total}")
        print(f"🚨 Transacciones fraudulentas: {fraud_count}")
        print(f"✅ Transacciones normales: {total - fraud_count}")
        
    except Exception as e:
        print(f"❌ Error verificando transacciones: {e}")
    finally:
        conn.close()

if __name__ == "__main__":
    print("🔍 Agregando datos de prueba para detección de fraude...")
    insert_sample_transactions()
    check_transactions()
    print("✅ Proceso completado")