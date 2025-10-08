# app.py
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
import pandas as pd
from datetime import time, date, datetime

# Importa las funciones y clases necesarias de tus otros archivos
from behavioral_fraud_model import HybridFraudDetector
from db import fetch_transactions

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
    Entrena el modelo al iniciar la API.
    """
    global modelo_entrenado
    try:
        print("🚀 Iniciando entrenamiento del modelo de detección de fraude...")
        transactions_data = fetch_transactions()

        if not transactions_data:
            print("⚠ No se encontraron transacciones en la base de datos para entrenar.")
            print("📝 Nota: El modelo se puede entrenar cuando haya datos disponibles.")
            return

        print(f"📊 Encontradas {len(transactions_data)} transacciones para entrenar.")
        processed_data = detector.prepare_data(transactions_data)
        detector.train_model(processed_data)
        modelo_entrenado = True
        print("✅ Modelo entrenado exitosamente y listo para usar.")
        
    except Exception as e:
        print(f"❌ Error durante el entrenamiento inicial: {e}")
        print("🔧 El modelo se puede entrenar manualmente cuando sea necesario.")
        modelo_entrenado = False

@app.get("/")
def root():
    return {"message": "Bienvenido a la API de Detección de Fraude Híbrida con IA. Sistema con análisis comportamental y patrones evidentes listo para predecir."}

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
    if not transactions_data:
        raise HTTPException(status_code=404, detail="No se encontraron transacciones en la base de datos.")

    # Procesar todas las transacciones de una vez usando el método prepare_data
    try:
        print(f"🔍 Procesando {len(transactions_data)} transacciones...")
        
        # Usar el método prepare_data que ya maneja DataFrames correctamente
        processed_data = detector.prepare_data(transactions_data)
        
        # Hacer predicciones con el modelo entrenado
        if not detector.best_model:
            raise HTTPException(status_code=500, detail="Modelo no está disponible para predicciones.")
        
        predictions = detector.best_model.predict(processed_data)
        probabilities = detector.best_model.predict_proba(processed_data)
        
        # Procesar resultados
        results = []
        for i, transaction in enumerate(transactions_data):
            is_fraud = bool(predictions[i])
            probability = float(probabilities[i][1]) if probabilities.shape[1] > 1 else float(probabilities[i][0])
            
            if is_fraud:  # Solo incluir transacciones fraudulentas
                result = {
                    "id": int(transaction[0]),  # id
                    "monto": float(transaction[3]),  # monto
                    "comerciante": transaction[4],  # comerciante
                    "ubicacion": transaction[5],  # ubicacion
                    "tipo_tarjeta": transaction[6],  # tipo_tarjeta
                    "horario_transaccion": str(transaction[7]),  # horario_transaccion
                    "fecha_transaccion": str(transaction[8]),  # fecha_transaccion
                    "prediccion": "Fraude detectado",
                    "es_fraude": True,
                    "probabilidad_fraude": round(probability, 3),
                    "es_fraude_real": bool(transaction[9])  # es_fraude real para comparar
                }
                results.append(result)
        
        return {
            "transacciones_fraudulentas_encontradas": len(results),
            "total_transacciones_analizadas": len(transactions_data),
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
    if not transactions_data:
        raise HTTPException(status_code=404, detail="No se encontraron transacciones en la base de datos.")

    try:
        print(f"🔍 Procesando {len(transactions_data)} transacciones...")
        
        # Usar el método prepare_data que ya maneja DataFrames correctamente
        processed_data = detector.prepare_data(transactions_data)
        
        # Hacer predicciones con el modelo entrenado
        if not detector.best_model:
            raise HTTPException(status_code=500, detail="Modelo no está disponible para predicciones.")
        
        predictions = detector.best_model.predict(processed_data)
        probabilities = detector.best_model.predict_proba(processed_data)
        
        # Procesar resultados
        all_results = []
        fraud_count = 0
        
        for i, transaction in enumerate(transactions_data):
            is_fraud = bool(predictions[i])
            probability = float(probabilities[i][1]) if probabilities.shape[1] > 1 else float(probabilities[i][0])
            
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