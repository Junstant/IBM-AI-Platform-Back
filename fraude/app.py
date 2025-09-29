# app.py
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
import pandas as pd
from datetime import time, date

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

# --- Evento de inicio: entrena el modelo automáticamente ---
@app.on_event("startup")
def startup_event():
    """
    Entrena el modelo al iniciar la API.
    """
    global modelo_entrenado
    print("Cargando transacciones y entrenando modelo...")
    transactions_data = fetch_transactions()

    if not transactions_data:
        print("⚠ No se encontraron transacciones en la base de datos para entrenar.")
        return

    processed_data = detector.prepare_data(transactions_data)
    detector.train_model(processed_data)
    modelo_entrenado = True
    print("✅ Modelo entrenado y listo para usarse.")

# --- Endpoints de la API ---

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

    fraudulent_df = detector.predict_fraud(transactions_data)
    
    # Convertir el DataFrame a un formato más amigable con probabilidades redondeadas
    results = []
    for _, row in fraudulent_df.iterrows():
        result = {
            "id": int(row['id']),
            "monto": float(row['monto']),
            "comerciante": row['comerciante'],
            "ubicacion": row['ubicacion'],
            "tipo_tarjeta": row['tipo_tarjeta'],
            "horario_transaccion": str(row['horario_transaccion']),
            "fecha_transaccion": str(row['fecha_transaccion']),
            "prediccion": "Fraude detectado",
            "es_fraude": True,
            "probabilidad_fraude": round(float(row['probabilidad_fraude']), 3),
            "es_fraude_real": bool(row['es_fraude'])  # Para comparar con la realidad
        }
        results.append(result)
    
    return {
        "transacciones_fraudulentas_encontradas": len(fraudulent_df),
        "resultados": results
    }

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

    # Crear DataFrame con todas las transacciones
    columns = [
        'id', 'cuenta_origen_id', 'cuenta_destino_id', 'monto', 'comerciante',
        'ubicacion', 'tipo_tarjeta', 'horario_transaccion', 'fecha_transaccion', 'es_fraude'
    ]
    df = pd.DataFrame(transactions_data, columns=columns)
    
    # Procesar datos para predicción
    df_processed = detector._preprocess_data(df.copy())
    df_processed = df_processed.reindex(columns=detector.train_columns, fill_value=0)
    
    # Obtener predicciones y probabilidades
    predictions = detector.model.predict(df_processed)
    probabilities = detector.model.predict_proba(df_processed)
    
    # Agregar resultados al DataFrame original
    df['prediccion_fraude'] = predictions
    df['probabilidad_fraude'] = probabilities[:, 1] if probabilities.shape[1] > 1 else probabilities[:, 0]
    
    # Convertir a formato de respuesta
    results = []
    for _, row in df.iterrows():
        is_fraud_prediction = bool(row['prediccion_fraude'])
        result = {
            "id": int(row['id']),
            "monto": float(row['monto']),
            "comerciante": row['comerciante'],
            "ubicacion": row['ubicacion'],
            "tipo_tarjeta": row['tipo_tarjeta'],
            "horario_transaccion": str(row['horario_transaccion']),
            "fecha_transaccion": str(row['fecha_transaccion']),
            "prediccion": "Fraude detectado" if is_fraud_prediction else "Normal",
            "es_fraude": is_fraud_prediction,
            "probabilidad_fraude": round(float(row['probabilidad_fraude']), 3),
            "es_fraude_real": bool(row['es_fraude'])  # Para comparar con la realidad
        }
        results.append(result)
    
    fraudulent_count = sum(1 for r in results if r['es_fraude'])
    
    return {
        "total_transacciones": len(results),
        "transacciones_fraudulentas_detectadas": fraudulent_count,
        "transacciones_normales": len(results) - fraudulent_count,
        "resultados": results
    }