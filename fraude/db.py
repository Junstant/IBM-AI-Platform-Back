# db.py
import psycopg2
import os
from dotenv import load_dotenv

load_dotenv()

def get_db_connection():
    """
    Establece y devuelve una conexión a la base de datos de PostgreSQL.
    """
    try:
        conn = psycopg2.connect(
            dbname=os.getenv("DB_NAME_FRAUDE"),
            user=os.getenv("DB_USER"),
            password=os.getenv("DB_PASSWORD"),
            host=os.getenv("DB_HOST"),  # Usar host desde .env
            port=os.getenv("DB_PORT")
        )
        return conn
    except psycopg2.OperationalError as e:
        print(f"Error al conectar a la base de datos: {e}")
        return None

def fetch_transactions():
    """
    Obtiene todas las transacciones de la base de datos con las columnas correctas.
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
            cur.close()
            return transactions
        except psycopg2.DatabaseError as e:
            print(f"Error al obtener transacciones: {e}")
            return []
        finally:
            conn.close()
    return []

