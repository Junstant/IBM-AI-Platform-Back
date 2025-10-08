# db.py
import psycopg2
import pandas as pd
import os
from decimal import Decimal
from dotenv import load_dotenv

load_dotenv()

def get_db_connection():
    """
    Establece y devuelve una conexión a la base de datos de PostgreSQL.
    """
    try:
        conn = psycopg2.connect(
            dbname="bank_transactions",  # Base de datos específica para fraude
            user=os.getenv("DB_USER", "postgres"),
            password=os.getenv("DB_PASSWORD", "root"),
            host=os.getenv("DB_HOST", "localhost"),
            port=os.getenv("DB_PORT", "8070")
        )
        return conn
    except psycopg2.OperationalError as e:
        print(f"Error al conectar a la base de datos: {e}")
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

