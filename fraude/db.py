# db.py
import psycopg2
import pandas as pd
import os
import time
from decimal import Decimal
from dotenv import load_dotenv

load_dotenv()

def get_db_connection(max_retries=5, retry_delay=2):
    """
    Establece y devuelve una conexión a la base de datos de PostgreSQL.
    Incluye lógica de reintentos para manejar casos donde la DB no está lista.
    """
    for attempt in range(max_retries):
        try:
            conn = psycopg2.connect(
                dbname=os.getenv("DB2_NAME", "bank_transactions"),  # Base de datos específica para fraude
                user=os.getenv("DB_USER", "postgres"),
                password=os.getenv("DB_PASSWORD", "root"),
                host=os.getenv("DB_HOST", "postgres"),  # Nombre del servicio Docker
                port=os.getenv("DB_INTERNAL_PORT", "5432")  # ✅ Puerto interno del contenedor
            )
            print(f"✅ Conexión a base de datos establecida exitosamente")
            return conn
        except psycopg2.OperationalError as e:
            if attempt < max_retries - 1:
                print(f"⏳ Intento {attempt + 1}/{max_retries} - DB no está lista, reintentando en {retry_delay}s...")
                time.sleep(retry_delay)
            else:
                print(f"❌ Error al conectar a la base de datos después de {max_retries} intentos: {e}")
                return None
    return None

def fetch_transactions():
    """
    Obtiene todas las transacciones de la base de datos como DataFrame.
    """
    conn = get_db_connection()
    if conn:
        try:
            cur = conn.cursor()
            cur.execute("""
                SELECT 
                    id, 
                    cuenta_origen_id, 
                    cuenta_destino_id, 
                    monto, 
                    comerciante, 
                    ubicacion, 
                    tipo_tarjeta, 
                    horario_transaccion, 
                    fecha_transaccion,
                    es_fraude
                FROM transacciones;
            """)
            transactions = cur.fetchall()
            
            # Obtener nombres de columnas
            columns = [desc[0] for desc in cur.description]
            
            # Convertir a DataFrame
            df = pd.DataFrame(transactions, columns=columns)
            
            # Convertir tipos de datos problemáticos
            if 'monto' in df.columns:
                df['monto'] = df['monto'].apply(lambda x: float(x) if isinstance(x, Decimal) else x)
            
            # Asegurar que las columnas numéricas sean float
            numeric_columns = ['id', 'cuenta_origen_id', 'cuenta_destino_id', 'monto']
            for col in numeric_columns:
                if col in df.columns:
                    df[col] = pd.to_numeric(df[col], errors='coerce')
            
            cur.close()
            return df
        except psycopg2.DatabaseError as e:
            print(f"Error al obtener transacciones: {e}")
            return None
        finally:
            conn.close()
    return None

