# app.py
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
import pandas as pd
from datetime import time, date, datetime

# Importa las funciones y clases necesarias de tus otros archivos
from behavioral_fraud_model import HybridFraudDetector
from db import fetch_transactions, get_db_connection

# --- Instancia y configuración de la API ---
app = FastAPI(
    title="Fraud Detection API - Hybrid AI System",
    description="API avanzada para detectar fraude con análisis comportamental y patrones evidentes usando IA híbrida",
    version="2.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Temporalmente permite todos los orígenes para debug
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["*"],
)

# Instancia global del detector híbrido y estado del modelo
detector = HybridFraudDetector()
modelo_entrenado = False

# --- Pydantic Model para una nueva transacción ---
class Transaction(BaseModel):
    """
    Define la estructura de una nueva transacción que se enviará a la API.
    """
    monto: float
    comerciante: str
    ubicacion: str
    tipo_tarjeta: str
    horario_transaccion: str # Se usa un string para recibir la hora (ej: "14:30:00")

# --- Endpoints de la API ---

@app.get("/health")
async def health_check():
    """Health check endpoint for Docker health checks"""
    try:
        return {
            "status": "healthy",
            "service": "fraude-api",
            "timestamp": datetime.now().isoformat(),
            "modelo_entrenado": modelo_entrenado
        }
    except Exception as e:
        return {"status": "unhealthy", "error": str(e)}, 503

# --- Evento de inicio: entrena el modelo automáticamente ---
@app.on_event("startup")
def startup_event():
    """
    🚀 Entrena automáticamente el modelo al iniciar la API.
    Los datos ya fueron generados por el script SQL inicial.
    """
    global modelo_entrenado
    try:
        print("🧠 === INICIANDO SISTEMA DE DETECCIÓN DE FRAUDE ===")
        print("📊 Verificando disponibilidad de datos de entrenamiento...")
        
        # Verificar si hay transacciones en la base de datos
        conn = get_db_connection()
        if not conn:
            print("❌ Error: No se pudo conectar a la base de datos")
            return
        
        try:
            cur = conn.cursor()
            cur.execute("SELECT COUNT(*) FROM transacciones")
            total_transacciones = cur.fetchone()[0]
            
            cur.execute("SELECT COUNT(*) FROM transacciones WHERE es_fraude = TRUE")
            transacciones_fraude = cur.fetchone()[0]
            
            cur.execute("SELECT COUNT(*) FROM transacciones WHERE es_fraude = FALSE")
            transacciones_normales = cur.fetchone()[0]
            
            cur.close()
        except Exception as e:
            print(f"❌ Error verificando datos: {e}")
            return
        finally:
            conn.close()
        
        print(f"📈 Datos disponibles: {total_transacciones} transacciones totales")
        print(f"� Fraudes: {transacciones_fraude} | ✅ Normales: {transacciones_normales}")
        
        if total_transacciones == 0:
            print("⚠️  Advertencia: No hay transacciones en la base de datos")
            print("💡 Asegúrate de que el script SQL 03-fraud-samples.sql se haya ejecutado correctamente")
            return
        
        if total_transacciones < 100:
            print("⚠️  Advertencia: Pocos datos para entrenamiento óptimo")
            print("🎯 Se recomienda tener al menos 1,000 transacciones")
        
        # Entrenar el modelo con los datos disponibles
        print("🤖 Iniciando entrenamiento del modelo híbrido...")
        transactions_data = fetch_transactions()
        
        if transactions_data is not None and not transactions_data.empty:
            detector.train_model(transactions_data)
            modelo_entrenado = True
            print("✅ Modelo híbrido entrenado exitosamente!")
            print(f"🎯 Entrenado con {len(transactions_data)} transacciones")
            print("🚀 API lista para detectar fraude en tiempo real")
        else:
            print("❌ No se pudieron obtener datos de transacciones para entrenamiento")
            modelo_entrenado = False
            
    except Exception as e:
        print(f"❌ Error durante el entrenamiento inicial: {e}")
        modelo_entrenado = False
        
    except Exception as e:
        print(f"❌ Error durante la inicialización: {e}")
        print("🔧 El modelo se puede entrenar manualmente cuando sea necesario.")
        modelo_entrenado = False

@app.get("/")
def root():
    return {"message": "Bienvenido a la API de Detección de Fraude Híbrida con IA. Sistema con análisis comportamental y patrones evidentes listo para predecir."}

@app.post("/retrain")
def retrain_model():
    """
    Re-entrena el modelo con los datos actuales de la base de datos.
    """
    global modelo_entrenado
    try:
        print("� Re-entrenando modelo con datos actuales...")
        
        # Obtener datos de transacciones
        transactions_data = fetch_transactions()
        
        if transactions_data is None or transactions_data.empty:
            raise HTTPException(status_code=404, detail="No se encontraron transacciones en la base de datos")
        
        print(f"📊 Datos encontrados: {len(transactions_data)} transacciones")
        
        # Verificar distribución
        fraud_count = sum(1 for t in transactions_data if t[9])  # Columna es_fraude
        normal_count = len(transactions_data) - fraud_count
        
        # Re-entrenar el modelo
        detector.train_model(transactions_data)
        modelo_entrenado = True
        
        print("✅ Modelo re-entrenado exitosamente!")
        
        return {
            "message": "Modelo re-entrenado exitosamente",
            "total_transacciones": len(transactions_data),
            "transacciones_fraude": fraud_count,
            "transacciones_normales": normal_count,
            "modelo_listo": modelo_entrenado
        }
        
    except Exception as e:
        modelo_entrenado = False
        raise HTTPException(status_code=500, detail=f"Error re-entrenando modelo: {str(e)}")

@app.post("/predict_single_transaction")
def predict_single_transaction(transaction: Transaction):
    """
    Predice si una única transacción es fraudulenta.
    """
    if not modelo_entrenado:
        raise HTTPException(status_code=400, detail="El modelo no ha sido entrenado. Intente más tarde.")

    try:
        # Convertir el Pydantic model a una lista de tuplas con los campos requeridos
        # Usamos valores placeholder para los campos que no se envían
        # Deben coincidir con el orden en fetch_transactions
        transaction_list = [(
            0, # id (placeholder)
            1, # cuenta_origen_id (placeholder)
            2, # cuenta_destino_id (placeholder)
            transaction.monto,
            transaction.comerciante,
            transaction.ubicacion,
            transaction.tipo_tarjeta,
            transaction.horario_transaccion,
            str(date.today()), # fecha_transaccion (placeholder)
            False # es_fraude (placeholder)
        )]

        print(f"🔍 Procesando transacción: {transaction}")
        
        # Usar el modelo para hacer la predicción individual
        is_fraud, fraud_probability = detector.predict_single_transaction(transaction_list)
        
        print(f"📊 Resultado: is_fraud={is_fraud}, fraud_probability={fraud_probability}")
        
        # Asegurar que fraud_probability sea un número válido
        if fraud_probability is None or not isinstance(fraud_probability, (int, float)):
            print(f"⚠️ fraud_probability inválido: {fraud_probability}, usando 0.0")
            fraud_probability = 0.0
        
        response_data = {
            "prediccion": "Fraude detectado" if is_fraud else "Normal",
            "es_fraude": bool(is_fraud),
            "probabilidad_fraude": round(float(fraud_probability), 3),
            "transaccion_enviada": transaction.dict()
        }
        
        print(f"📤 Enviando respuesta: {response_data}")
        return response_data
        
    except Exception as e:
        print(f"❌ Error en predict_single_transaction endpoint: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Error interno del servidor: {str(e)}")


@app.options("/predict_all_from_db")
def options_predict_all():
    """Handle preflight requests for CORS"""
    return {}

@app.get("/predict_all_from_db")
def predict_all_from_db():
    """
    Predice fraude usando todas las transacciones actuales de la base de datos.
    Retorna solo las transacciones identificadas como fraudulentas.
    """
    if not modelo_entrenado:
        raise HTTPException(status_code=400, detail="El modelo no ha sido entrenado.")

    transactions_data = fetch_transactions()
    if transactions_data is None or transactions_data.empty:
        raise HTTPException(status_code=404, detail="No se encontraron transacciones en la base de datos.")

    try:
        print(f"🔍 Procesando {len(transactions_data)} transacciones...")
        
        # Usar el método predict_batch que aplica todas las transformaciones correctamente
        predictions, probabilities = detector.predict_batch(transactions_data)
        
        if not predictions:
            raise HTTPException(status_code=500, detail="Error procesando las transacciones.")
        
        # DEBUG: Verificar las predicciones
        fraud_predictions = sum(predictions)
        max_probability = max([max(p) for p in probabilities])
        min_probability = min([min(p) for p in probabilities])
        
        print(f"🔍 DEBUG - Predicciones de fraude: {fraud_predictions}/{len(predictions)}")
        print(f"🔍 DEBUG - Probabilidad máxima: {max_probability}")
        print(f"🔍 DEBUG - Probabilidad mínima: {min_probability}")
        print(f"🔍 DEBUG - Umbral del modelo: {getattr(detector, 'optimal_threshold', 'No definido')}")
        
        # Procesar resultados
        results = []
        fraud_count_real = 0
        fraud_count_predicted = 0
        
        for i, transaction in enumerate(transactions_data):
            is_fraud_predicted = bool(predictions[i])
            is_fraud_real = bool(transaction[9])  # es_fraude real
            probability = float(probabilities[i][1]) if len(probabilities[i]) > 1 else float(probabilities[i][0])
            
            if is_fraud_real:
                fraud_count_real += 1
            if is_fraud_predicted:
                fraud_count_predicted += 1
            
            # TEMPORAL: Mostrar algunas transacciones fraudulentas reales aunque no las prediga
            if is_fraud_real and len(results) < 50:  # Mostrar las primeras 50 fraudulentas reales
                result = {
                    "id": int(transaction[0]),
                    "monto": float(transaction[3]),
                    "comerciante": transaction[4],
                    "ubicacion": transaction[5],
                    "tipo_tarjeta": transaction[6],
                    "horario_transaccion": str(transaction[7]),
                    "fecha_transaccion": str(transaction[8]),
                    "prediccion": "Fraude detectado" if is_fraud_predicted else "NO DETECTADO por el modelo",
                    "es_fraude_predicho": is_fraud_predicted,
                    "es_fraude_real": is_fraud_real,
                    "probabilidad_fraude": round(probability, 3)
                }
                results.append(result)
        
        print(f"🔍 DEBUG - Fraudes reales en DB: {fraud_count_real}")
        print(f"🔍 DEBUG - Fraudes predichos: {fraud_count_predicted}")
        
        return {
            "transacciones_fraudulentas_encontradas": len(results),
            "total_transacciones_analizadas": len(transactions_data),
            "fraudes_reales_en_db": fraud_count_real,
            "fraudes_predichos_por_modelo": fraud_count_predicted,
            "umbral_modelo": getattr(detector, 'optimal_threshold', 'No definido'),
            "resultados": results
        }
        
    except Exception as e:
        print(f"❌ Error procesando transacciones: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Error procesando transacciones: {str(e)}")

@app.get("/predict_all_transactions")
def predict_all_transactions():
    """
    Predice fraude para todas las transacciones y retorna tanto fraudulentas como normales
    con sus respectivas probabilidades.
    """
    if not modelo_entrenado:
        raise HTTPException(status_code=400, detail="El modelo no ha sido entrenado.")

    transactions_data = fetch_transactions()
    if transactions_data is None or transactions_data.empty:
        raise HTTPException(status_code=404, detail="No se encontraron transacciones en la base de datos.")

    try:
        print(f"🔍 Procesando {len(transactions_data)} transacciones...")
        
        # Usar el método predict_batch que aplica todas las transformaciones correctamente
        predictions, probabilities = detector.predict_batch(transactions_data)
        
        if not predictions:
            raise HTTPException(status_code=500, detail="Error procesando las transacciones.")
        
        # Procesar resultados
        all_results = []
        fraud_count = 0
        
        for i, transaction in enumerate(transactions_data):
            is_fraud = bool(predictions[i])
            probability = float(probabilities[i][1]) if len(probabilities[i]) > 1 else float(probabilities[i][0])
            
            if is_fraud:
                fraud_count += 1
            
            result = {
                "id": int(transaction[0]),  # id
                "monto": float(transaction[3]),  # monto
                "comerciante": transaction[4],  # comerciante
                "ubicacion": transaction[5],  # ubicacion
                "tipo_tarjeta": transaction[6],  # tipo_tarjeta
                "horario_transaccion": str(transaction[7]),  # horario_transaccion
                "fecha_transaccion": str(transaction[8]),  # fecha_transaccion
                "prediccion": "Fraude detectado" if is_fraud else "Transacción normal",
                "es_fraude_predicho": is_fraud,
                "probabilidad_fraude": round(probability, 3),
                "es_fraude_real": bool(transaction[9])  # es_fraude real para comparar
            }
            all_results.append(result)
        
        return {
            "total_transacciones": len(all_results),
            "transacciones_fraudulentas_detectadas": fraud_count,
            "transacciones_normales": len(all_results) - fraud_count,
            "tasa_fraude_detectada": round((fraud_count / len(all_results)) * 100, 2) if all_results else 0,
            "resultados": all_results
        }
        
    except Exception as e:
        print(f"❌ Error procesando transacciones: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Error procesando transacciones: {str(e)}")