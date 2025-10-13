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
        print(f"🔍 Procesando transacción: {transaction}")
        
        # 🔥 MAPEAR VALORES CONOCIDOS PARA EVITAR ERRORES
        # Mapear comerciante a uno conocido si es necesario
        comerciante_mapeado = transaction.comerciante
        comerciantes_conocidos = [
            'COM001', 'COM002', 'COM003', 'COM004', 'COM005', 
            'COM008', 'COM014', 'COM016', 'COM017', 'COM019', 'COM021'
        ]
        if comerciante_mapeado not in comerciantes_conocidos:
            # Mapear comerciantes comunes a códigos conocidos
            if 'amazon' in comerciante_mapeado.lower():
                comerciante_mapeado = 'COM021'  # E-commerce conocido
            elif any(term in comerciante_mapeado.lower() for term in ['online', 'web', 'internet']):
                comerciante_mapeado = 'COM016'  # Coto Digital (online)
            elif any(term in comerciante_mapeado.lower() for term in ['super', 'market']):
                comerciante_mapeado = 'COM001'  # Supermercado Disco
            else:
                comerciante_mapeado = 'COM001'  # Default a comerciante conocido
        
        # Mapear ubicación a una conocida si es necesario
        ubicacion_mapeada = transaction.ubicacion
        ubicaciones_conocidas = [
            'Buenos Aires Centro', 'Palermo, CABA', 'Recoleta',
            'Puerto Madero', 'Villa Crespo', 'San Telmo', 'Online'
        ]
        if ubicacion_mapeada not in ubicaciones_conocidas:
            if 'usa' in ubicacion_mapeada.lower() or 'united' in ubicacion_mapeada.lower():
                ubicacion_mapeada = 'Online'  # Transacciones internacionales como Online
            elif any(term in ubicacion_mapeada.lower() for term in ['online', 'web', 'internet']):
                ubicacion_mapeada = 'Online'
            else:
                ubicacion_mapeada = 'Buenos Aires Centro'  # Default
        
        # Mapear tipo de tarjeta a uno conocido si es necesario
        tipo_tarjeta_mapeado = transaction.tipo_tarjeta
        tipos_conocidos = ['Débito', 'Crédito', 'Prepaga']
        if tipo_tarjeta_mapeado not in tipos_conocidos:
            if 'visa' in tipo_tarjeta_mapeado.lower():
                tipo_tarjeta_mapeado = 'Crédito'
            elif 'master' in tipo_tarjeta_mapeado.lower():
                tipo_tarjeta_mapeado = 'Crédito'
            elif 'amex' in tipo_tarjeta_mapeado.lower() or 'american' in tipo_tarjeta_mapeado.lower():
                tipo_tarjeta_mapeado = 'Crédito'
            else:
                tipo_tarjeta_mapeado = 'Débito'  # Default
        
        # Crear un DataFrame con la transacción individual usando valores mapeados
        transaction_data = pd.DataFrame([{
            'id': 0,  # placeholder
            'cuenta_origen_id': 1001,  # placeholder realista
            'cuenta_destino_id': None,
            'monto': transaction.monto,
            'comerciante': comerciante_mapeado,  # Usar valor mapeado
            'ubicacion': ubicacion_mapeada,      # Usar valor mapeado
            'tipo_tarjeta': tipo_tarjeta_mapeado, # Usar valor mapeado
            'horario_transaccion': transaction.horario_transaccion,
            'fecha_transaccion': str(date.today()),
            'es_fraude': False  # placeholder
        }])

        print(f"🔄 Transacción mapeada: comerciante={comerciante_mapeado}, ubicacion={ubicacion_mapeada}, tipo_tarjeta={tipo_tarjeta_mapeado}")
        
        # Usar el método predict_batch con el DataFrame
        predictions, probabilities = detector.predict_batch(transaction_data.values.tolist())
        
        if not predictions or not probabilities:
            raise HTTPException(status_code=500, detail="Error procesando la transacción")
        
        is_fraud = bool(predictions[0])
        fraud_probability = float(probabilities[0][1]) if len(probabilities[0]) > 1 else float(probabilities[0][0])
        
        print(f"📊 Resultado: is_fraud={is_fraud}, fraud_probability={fraud_probability}")
        
        # 🔥 AÑADIR INFORMACIÓN DE MAPEO EN LA RESPUESTA
        response_data = {
            "prediccion": "Fraude detectado" if is_fraud else "Transacción normal",
            "es_fraude": is_fraud,
            "probabilidad_fraude": round(fraud_probability, 3),
            "nivel_confianza": "Alta" if fraud_probability > 0.8 else "Media" if fraud_probability > 0.5 else "Baja",
            "transaccion_enviada": transaction.dict(),
            "transaccion_procesada": {
                "comerciante_mapeado": comerciante_mapeado,
                "ubicacion_mapeada": ubicacion_mapeada,
                "tipo_tarjeta_mapeado": tipo_tarjeta_mapeado,
                "nota": "Valores mapeados a equivalentes conocidos por el modelo"
            }
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
    Predice el fraude usando todas las transacciones actuales de la base de datos.
    Retorna solo las transacciones identificadas como fraudulentas.
    """
    if not modelo_entrenado:
        raise HTTPException(status_code=400, detail="El modelo no ha sido entrenado.")

    transactions_df = fetch_transactions()  # ← Cambiar nombre para claridad
    if transactions_df is None or transactions_df.empty:
        raise HTTPException(status_code=404, detail="No se encontraron transacciones en la base de datos.")

    try:
        print(f"🔍 Procesando {len(transactions_df)} transacciones...")
        
        # Convertir DataFrame a lista de listas para el modelo
        transactions_data = transactions_df.values.tolist()
        
        # Usar el método predict_batch
        predictions, probabilities = detector.predict_batch(transactions_data)
        
        if not predictions:
            raise HTTPException(status_code=500, detail="Error procesando las transacciones.")
        
        # DEBUG: Verificar las predicciones
        fraud_predictions = sum(predictions)
        max_probability = max([max(p) for p in probabilities]) if probabilities else 0
        min_probability = min([min(p) for p in probabilities]) if probabilities else 0
        
        print(f"🔍 DEBUG - Predicciones de fraude: {fraud_predictions}/{len(predictions)}")
        print(f"🔍 DEBUG - Probabilidad máxima: {max_probability}")
        print(f"🔍 DEBUG - Probabilidad mínima: {min_probability}")
        print(f"🔍 DEBUG - Umbral del modelo: {getattr(detector, 'optimal_threshold', 'No definido')}")
        
        # Procesar resultados usando el DataFrame
        results = []
        fraud_count_real = 0
        fraud_count_predicted = 0
        
        for i in range(len(transactions_df)):
            # Acceder a los datos usando iloc (pandas)
            transaction_row = transactions_df.iloc[i]
            
            is_fraud_predicted = bool(predictions[i])
            is_fraud_real = bool(transaction_row['es_fraude'])  # ← Usar nombre de columna
            probability = float(probabilities[i][1]) if len(probabilities[i]) > 1 else float(probabilities[i][0])
            
            if is_fraud_real:
                fraud_count_real += 1
            if is_fraud_predicted:
                fraud_count_predicted += 1
            
            # Mostrar las transacciones predichas como fraudulentas
            if is_fraud_predicted:
                result = {
                    "id": int(transaction_row['id']),
                    "monto": float(transaction_row['monto']),
                    "comerciante": transaction_row['comerciante'],
                    "ubicacion": transaction_row['ubicacion'],
                    "tipo_tarjeta": transaction_row['tipo_tarjeta'],
                    "horario_transaccion": str(transaction_row['horario_transaccion']),
                    "fecha_transaccion": str(transaction_row['fecha_transaccion']),
                    "prediccion": "Fraude detectado",
                    "es_fraude_predicho": is_fraud_predicted,
                    "es_fraude_real": is_fraud_real,
                    "probabilidad_fraude": round(probability, 3)
                }
                results.append(result)
        
        print(f"🔍 DEBUG - Fraudes reales en DB: {fraud_count_real}")
        print(f"🔍 DEBUG - Fraudes predichos: {fraud_count_predicted}")
        
        return {
            "transacciones_fraudulentas_encontradas": len(results),
            "total_transacciones_analizadas": len(transactions_df),
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