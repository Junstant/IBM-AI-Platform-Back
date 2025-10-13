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
    ✅ VERSIÓN ACTUALIZADA: Incluye TODAS las columnas necesarias para el modelo
    """
    conn = get_db_connection()
    if conn:
        try:
            cur = conn.cursor()
            # ✅ INCLUIR TODAS LAS COLUMNAS QUE EL MODELO NECESITA
            cur.execute("""
                SELECT 
                    id, 
                    cuenta_origen_id, 
                    cuenta_destino_id, 
                    monto, 
                    comerciante, 
                    COALESCE(categoria_comerciante, 'Unknown') as categoria_comerciante,
                    ubicacion, 
                    COALESCE(ciudad, 'Buenos Aires') as ciudad,
                    COALESCE(pais, 'Argentina') as pais,
                    tipo_tarjeta, 
                    horario_transaccion, 
                    fecha_transaccion,
                    COALESCE(canal, 'pos') as canal,
                    COALESCE(distancia_ubicacion_usual, 0) as distancia_ubicacion_usual,
                    es_fraude
                FROM transacciones
                ORDER BY fecha_transaccion DESC, id DESC;
            """)
            transactions = cur.fetchall()
            
            # Obtener nombres de columnas
            columns = [desc[0] for desc in cur.description]
            
            # Convertir a DataFrame
            df = pd.DataFrame(transactions, columns=columns)
            
            # ✅ CONVERSIÓN SEGURA DE TIPOS DE DATOS
            if not df.empty:
                # Convertir Decimal a float
                if 'monto' in df.columns:
                    df['monto'] = df['monto'].apply(lambda x: float(x) if isinstance(x, Decimal) else x)
                
                if 'distancia_ubicacion_usual' in df.columns:
                    df['distancia_ubicacion_usual'] = df['distancia_ubicacion_usual'].apply(
                        lambda x: float(x) if isinstance(x, Decimal) else x
                    )
                
                # Convertir columnas numéricas
                numeric_columns = ['id', 'cuenta_origen_id', 'cuenta_destino_id', 'monto', 'distancia_ubicacion_usual']
                for col in numeric_columns:
                    if col in df.columns:
                        df[col] = pd.to_numeric(df[col], errors='coerce').fillna(0)
                
                # ✅ LIMPIAR VALORES STRING Y REEMPLAZAR NULL/NaN
                string_columns = ['comerciante', 'categoria_comerciante', 'ubicacion', 'ciudad', 'pais', 'tipo_tarjeta', 'canal']
                for col in string_columns:
                    if col in df.columns:
                        df[col] = df[col].astype(str).fillna('Unknown')
                        df[col] = df[col].replace(['None', 'nan', ''], 'Unknown')
            
            cur.close()
            return df
        except psycopg2.DatabaseError as e:
            print(f"❌ Error al obtener transacciones: {e}")
            return None
        finally:
            conn.close()
    return None

