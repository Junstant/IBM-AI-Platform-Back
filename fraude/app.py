"""
🚀 APLICACIÓN DE DETECCIÓN DE FRAUDE CON MACHINE LEARNING
=======================================================
Sistema avanzado de ML para detectar fraudes financieros usando Random Forest
Optimizado para trabajar con la base de datos PostgreSQL existente

Características principales:
- Entrenamiento automático con datos existentes
- Detección de transacciones individuales y masivas
- Feature engineering inteligente
- Análisis de patrones comportamentales
- API REST compatible con el frontend React
"""

import os
import sys
import logging
import numpy as np
import pandas as pd
import joblib
import warnings
from datetime import datetime, time, date
from typing import Dict, List, Optional, Tuple, Any
import json
from pathlib import Path

# Importar TOON encoder
sys.path.append(str(Path(__file__).parent.parent))
from shared.toon_encoder import encode, estimate_token_savings

# FastAPI y dependencias web
from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
import uvicorn

# Machine Learning
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.preprocessing import LabelEncoder, StandardScaler
from sklearn.metrics import classification_report, confusion_matrix, roc_auc_score, precision_recall_curve
from sklearn.impute import SimpleImputer

# Base de datos
import psycopg2
from psycopg2.extras import RealDictCursor
from sqlalchemy import create_engine
import sqlalchemy

# Configuración
warnings.filterwarnings('ignore')
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# =====================================================
# CONFIGURACIÓN DE LA APLICACIÓN
# =====================================================

class Config:
    """Configuración centralizada de la aplicación"""
    
    # Base de datos
    DB_HOST = os.getenv('DB_HOST', 'localhost')
    DB_PORT = os.getenv('DB_PORT', '8070')
    DB_USER = os.getenv('DB_USER', 'postgres')
    DB_PASSWORD = os.getenv('DB_PASSWORD', 'root')
    DB_NAME = os.getenv('DB2_NAME', 'bank_transactions')  # Base de datos de fraude
    
    # ML Models
    MODEL_PATH = 'models/'
    FRAUD_MODEL_FILE = 'fraud_detection_model.pkl'
    ENCODERS_FILE = 'label_encoders.pkl'
    SCALER_FILE = 'feature_scaler.pkl'
    FEATURES_FILE = 'feature_names.pkl'
    
    # Configuración del modelo
    RANDOM_STATE = 42
    TEST_SIZE = 0.2
    MIN_SAMPLES_FOR_TRAINING = 100
    
    # Umbrales de detección
    HIGH_RISK_THRESHOLD = 0.7
    MEDIUM_RISK_THRESHOLD = 0.3

# Instancia de configuración
config = Config()

# =====================================================
# MODELOS PYDANTIC PARA LA API
# =====================================================

class TransactionInput(BaseModel):
    """Modelo para recibir datos de una transacción individual"""
    monto: float = Field(..., description="Monto de la transacción")
    comerciante: str = Field(..., description="Código o nombre del comerciante")
    ubicacion: str = Field(..., description="Ubicación de la transacción")
    tipo_tarjeta: str = Field(..., description="Tipo de tarjeta: Débito, Crédito, Prepaga")
    horario_transaccion: str = Field(..., description="Horario en formato HH:MM:SS")
    cuenta_origen_id: Optional[int] = Field(1001, description="ID de cuenta origen (opcional)")
    categoria_comerciante: Optional[str] = Field("Varios", description="Categoría del comerciante")
    ciudad: Optional[str] = Field("Buenos Aires", description="Ciudad")
    pais: Optional[str] = Field("Argentina", description="País")
    canal: Optional[str] = Field("online", description="Canal de la transacción")

class PredictionResponse(BaseModel):
    """Respuesta para predicción individual"""
    prediccion_fraude: bool
    probabilidad_fraude: float
    nivel_riesgo: str
    prediccion: str
    transaccion_enviada: Dict
    timestamp: str
    razones_deteccion: List[str]
    confianza_modelo: float

class DatabaseAnalysisResponse(BaseModel):
    """Respuesta para análisis de base de datos"""
    transacciones_fraudulentas_encontradas: int
    total_transacciones_analizadas: int
    tiempo_procesamiento: float
    timestamp: str
    resultados: List[Dict]
    resumen_estadisticas: Dict

# =====================================================
# GESTOR DE BASE DE DATOS
# =====================================================

class DatabaseManager:
    """Gestor para todas las operaciones de base de datos"""
    
    def __init__(self, config: Config):
        self.config = config
        self.connection_string = (
            f"postgresql://{config.DB_USER}:{config.DB_PASSWORD}@"
            f"{config.DB_HOST}:{config.DB_PORT}/{config.DB_NAME}"
        )
        self.engine = create_engine(self.connection_string)
    
    def test_connection(self) -> bool:
        """Probar conexión a la base de datos"""
        try:
            with self.engine.connect() as conn:
                result = conn.execute(sqlalchemy.text("SELECT 1")).fetchone()
                logger.info("✅ Conexión a base de datos exitosa")
                return True
        except Exception as e:
            logger.error(f"❌ Error conectando a base de datos: {e}")
            return False
    
    def get_all_transactions(self) -> pd.DataFrame:
        """Obtener todas las transacciones para entrenamiento"""
        query = """
        SELECT 
            t.*,
            c.nivel_riesgo as comerciante_nivel_riesgo,
            c.categoria as comerciante_categoria_real,
            c.tasa_fraude as comerciante_tasa_fraude
        FROM transacciones t
        LEFT JOIN comerciantes c ON t.comerciante = c.codigo_comerciante
        ORDER BY t.fecha_transaccion DESC, t.horario_transaccion DESC
        """
        
        try:
            df = pd.read_sql(query, self.engine)
            logger.info(f"📊 Cargadas {len(df)} transacciones de la base de datos")
            return df
        except Exception as e:
            logger.error(f"❌ Error cargando transacciones: {e}")
            raise
    
    def get_user_profile(self, cuenta_id: int) -> Optional[Dict]:
        """Obtener perfil de comportamiento del usuario"""
        query = """
        SELECT * FROM perfiles_usuario WHERE cuenta_id = %s
        """
        
        try:
            with self.engine.connect() as conn:
                result = conn.execute(sqlalchemy.text(query), {"cuenta_id": cuenta_id}).fetchone()
                if result:
                    return dict(result._mapping)
                return None
        except Exception as e:
            logger.warning(f"⚠️ No se pudo obtener perfil del usuario {cuenta_id}: {e}")
            return None

# =====================================================
# INGENIERO DE CARACTERÍSTICAS (FEATURE ENGINEERING)
# =====================================================

class FeatureEngineer:
    """Clase para crear y transformar características para el modelo ML"""
    
    def __init__(self):
        self.label_encoders = {}
        self.scaler = StandardScaler()
        self.fitted = False
    
    def create_time_features(self, df: pd.DataFrame) -> pd.DataFrame:
        """Crear características basadas en tiempo"""
        df = df.copy()
        
        # Convertir horario a datetime para extraer características
        if 'horario_transaccion' in df.columns:
            # Manejar diferentes formatos de tiempo
            def parse_time(time_str):
                if pd.isna(time_str):
                    return time(14, 30)  # Tiempo por defecto
                
                if isinstance(time_str, time):
                    return time_str
                
                try:
                    # Si es string, intentar parsear
                    time_str = str(time_str).strip()
                    if '.' in time_str:
                        time_str = time_str.split('.')[0]  # Remover microsegundos
                    
                    parts = time_str.split(':')
                    hour = int(parts[0]) if len(parts) > 0 else 14
                    minute = int(parts[1]) if len(parts) > 1 else 30
                    second = int(parts[2]) if len(parts) > 2 else 0
                    
                    return time(hour, minute, second)
                except:
                    return time(14, 30)  # Tiempo por defecto en caso de error
            
            df['horario_parsed'] = df['horario_transaccion'].apply(parse_time)
            df['hour'] = df['horario_parsed'].apply(lambda x: x.hour)
            df['minute'] = df['horario_parsed'].apply(lambda x: x.minute)
        else:
            df['hour'] = 14  # Hora por defecto
            df['minute'] = 30
        
        # Características de tiempo
        df['is_weekend'] = pd.to_datetime(df['fecha_transaccion']).dt.dayofweek >= 5
        df['is_night'] = (df['hour'] >= 22) | (df['hour'] <= 6)
        df['is_business_hours'] = (df['hour'] >= 9) & (df['hour'] <= 18)
        df['hour_sin'] = np.sin(2 * np.pi * df['hour'] / 24)
        df['hour_cos'] = np.cos(2 * np.pi * df['hour'] / 24)
        
        return df
    
    def create_amount_features(self, df: pd.DataFrame) -> pd.DataFrame:
        """Crear características basadas en montos"""
        df = df.copy()
        
        # Características de monto
        df['monto_log'] = np.log1p(df['monto'])
        df['is_high_amount'] = df['monto'] > df['monto'].quantile(0.95)
        df['is_low_amount'] = df['monto'] < df['monto'].quantile(0.05)
        df['amount_zscore'] = (df['monto'] - df['monto'].mean()) / df['monto'].std()
        
        # Relación con saldo de cuenta
        if 'monto_cuenta_origen' in df.columns:
            df['monto_cuenta_origen'] = df['monto_cuenta_origen'].fillna(df['monto'] * 2)  # Estimación conservadora
            df['amount_to_balance_ratio'] = df['monto'] / (df['monto_cuenta_origen'] + 1)
            df['is_large_portion_balance'] = df['amount_to_balance_ratio'] > 0.5
        else:
            df['amount_to_balance_ratio'] = 0.1  # Ratio por defecto
            df['is_large_portion_balance'] = False
        
        return df
    
    def create_merchant_features(self, df: pd.DataFrame) -> pd.DataFrame:
        """Crear características basadas en comerciantes"""
        df = df.copy()
        
        # Características de comerciante
        df['merchant_risk_encoded'] = df['comerciante_nivel_riesgo'].map({
            'bajo': 0, 'medio': 1, 'alto': 2, 'crítico': 3
        }).fillna(1)  # Medio por defecto
        
        # Características de categoría
        risk_categories = ['Financiero', 'E-commerce', 'Criptomonedas', 'Casinos']
        df['is_risk_category'] = df['categoria_comerciante'].isin(risk_categories)
        
        # Características geográficas
        risk_countries = ['Nigeria', 'Rusia', 'Malta', 'USA']
        df['is_risk_country'] = df['pais'].isin(risk_countries)
        
        risk_locations = ['Online', 'Desconocida']
        df['is_online_transaction'] = df['ubicacion'].isin(risk_locations)
        
        return df
    
    def encode_categorical_features(self, df: pd.DataFrame, fit: bool = False) -> pd.DataFrame:
        """Codificar características categóricas"""
        df = df.copy()
        
        categorical_columns = ['tipo_tarjeta', 'canal', 'categoria_comerciante', 'pais', 'ciudad']
        
        for col in categorical_columns:
            if col in df.columns:
                if fit:
                    # Ajustar el encoder durante entrenamiento
                    if col not in self.label_encoders:
                        self.label_encoders[col] = LabelEncoder()
                    
                    # Asegurar que hay valores no nulos
                    df[col] = df[col].fillna('unknown')
                    self.label_encoders[col].fit(df[col].astype(str))
                
                # Transformar
                df[col] = df[col].fillna('unknown')
                
                if col in self.label_encoders:
                    # Manejar valores no vistos durante entrenamiento
                    def safe_transform(value):
                        try:
                            return self.label_encoders[col].transform([str(value)])[0]
                        except ValueError:
                            # Valor no visto, usar el primer valor conocido
                            return 0
                    
                    df[f'{col}_encoded'] = df[col].astype(str).apply(safe_transform)
                else:
                    df[f'{col}_encoded'] = 0  # Valor por defecto
        
        return df
    
    def prepare_features(self, df: pd.DataFrame, fit: bool = False) -> Tuple[np.ndarray, List[str]]:
        """Preparar todas las características para el modelo"""
        
        # Aplicar todas las transformaciones
        df = self.create_time_features(df)
        df = self.create_amount_features(df)
        df = self.create_merchant_features(df)
        df = self.encode_categorical_features(df, fit=fit)
        
        # Seleccionar características finales
        feature_columns = [
            # Características de monto
            'monto', 'monto_log', 'is_high_amount', 'is_low_amount', 'amount_zscore',
            'amount_to_balance_ratio', 'is_large_portion_balance',
            
            # Características de tiempo
            'hour', 'minute', 'is_weekend', 'is_night', 'is_business_hours',
            'hour_sin', 'hour_cos',
            
            # Características de comerciante
            'merchant_risk_encoded', 'is_risk_category', 'is_risk_country', 'is_online_transaction',
            
            # Características categóricas codificadas
            'tipo_tarjeta_encoded', 'canal_encoded', 'categoria_comerciante_encoded',
            'pais_encoded', 'ciudad_encoded',
            
            # Características adicionales si están disponibles
            'distancia_ubicacion_usual'
        ]
        
        # Filtrar columnas que existen
        available_features = [col for col in feature_columns if col in df.columns]
        
        # Llenar valores faltantes
        feature_df = df[available_features].copy()
        
        # Rellenar NaN con valores apropiados
        for col in feature_df.columns:
            if feature_df[col].dtype in ['int64', 'float64']:
                feature_df[col] = feature_df[col].fillna(feature_df[col].median())
            else:
                feature_df[col] = feature_df[col].fillna(0)
        
        # Escalar características numéricas si es necesario
        if fit:
            features_scaled = self.scaler.fit_transform(feature_df)
            self.fitted = True
        else:
            if self.fitted:
                features_scaled = self.scaler.transform(feature_df)
            else:
                features_scaled = feature_df.values  # No escalar si no se ha ajustado
        
        return features_scaled, available_features

# =====================================================
# DETECTOR DE FRAUDE PRINCIPAL
# =====================================================

class FraudDetector:
    """Detector principal de fraude con ML"""
    
    def __init__(self, config: Config):
        self.config = config
        self.db_manager = DatabaseManager(config)
        self.feature_engineer = FeatureEngineer()
        self.model = None
        self.feature_names = []
        self.is_trained = False
        
        # Crear directorio de modelos
        os.makedirs(config.MODEL_PATH, exist_ok=True)
    
    def train_model(self, force_retrain: bool = False) -> Dict[str, Any]:
        """Entrenar el modelo de detección de fraude"""
        
        model_path = os.path.join(self.config.MODEL_PATH, self.config.FRAUD_MODEL_FILE)
        
        # Verificar si el modelo ya existe y no se fuerza reentrenamiento
        if os.path.exists(model_path) and not force_retrain:
            logger.info("🔄 Cargando modelo existente...")
            return self.load_model()
        
        logger.info("🤖 Iniciando entrenamiento del modelo de ML...")
        
        # Cargar datos
        df = self.db_manager.get_all_transactions()
        
        if len(df) < self.config.MIN_SAMPLES_FOR_TRAINING:
            raise ValueError(f"Insuficientes datos para entrenar. Mínimo: {self.config.MIN_SAMPLES_FOR_TRAINING}, actual: {len(df)}")
        
        # Preparar características
        X, feature_names = self.feature_engineer.prepare_features(df, fit=True)
        y = df['es_fraude'].astype(int)
        
        self.feature_names = feature_names
        
        logger.info(f"📊 Preparadas {X.shape[0]} muestras con {X.shape[1]} características")
        logger.info(f"🏷️ Distribución de clases: {y.value_counts().to_dict()}")
        
        # Dividir datos
        X_train, X_test, y_train, y_test = train_test_split(
            X, y, test_size=self.config.TEST_SIZE, 
            random_state=self.config.RANDOM_STATE, 
            stratify=y
        )
        
        # Entrenar modelo Random Forest
        self.model = RandomForestClassifier(
            n_estimators=100,
            max_depth=10,
            min_samples_split=5,
            min_samples_leaf=2,
            random_state=self.config.RANDOM_STATE,
            class_weight='balanced',  # Importante para datos desbalanceados
            n_jobs=-1
        )
        
        logger.info("🔧 Entrenando modelo Random Forest...")
        self.model.fit(X_train, y_train)
        
        # Evaluar modelo
        y_pred = self.model.predict(X_test)
        y_pred_proba = self.model.predict_proba(X_test)[:, 1]
        
        # Métricas
        auc_score = roc_auc_score(y_test, y_pred_proba)
        report = classification_report(y_test, y_pred, output_dict=True)
        
        training_results = {
            'auc_score': auc_score,
            'classification_report': report,
            'feature_importance': dict(zip(feature_names, self.model.feature_importances_)),
            'training_samples': len(X_train),
            'test_samples': len(X_test),
            'fraud_rate': y.mean()
        }
        
        logger.info(f"✅ Modelo entrenado - AUC: {auc_score:.3f}")
        
        # Guardar modelo
        self.save_model()
        self.is_trained = True
        
        return training_results
    
    def save_model(self):
        """Guardar modelo y componentes"""
        try:
            # Guardar modelo principal
            joblib.dump(self.model, os.path.join(self.config.MODEL_PATH, self.config.FRAUD_MODEL_FILE))
            
            # Guardar encoders y scaler
            joblib.dump(self.feature_engineer.label_encoders, os.path.join(self.config.MODEL_PATH, self.config.ENCODERS_FILE))
            joblib.dump(self.feature_engineer.scaler, os.path.join(self.config.MODEL_PATH, self.config.SCALER_FILE))
            joblib.dump(self.feature_names, os.path.join(self.config.MODEL_PATH, self.config.FEATURES_FILE))
            
            logger.info("💾 Modelo guardado exitosamente")
        except Exception as e:
            logger.error(f"❌ Error guardando modelo: {e}")
            raise
    
    def load_model(self) -> Dict[str, Any]:
        """Cargar modelo existente"""
        try:
            # Cargar modelo principal
            model_path = os.path.join(self.config.MODEL_PATH, self.config.FRAUD_MODEL_FILE)
            self.model = joblib.load(model_path)
            
            # Cargar componentes auxiliares
            self.feature_engineer.label_encoders = joblib.load(os.path.join(self.config.MODEL_PATH, self.config.ENCODERS_FILE))
            self.feature_engineer.scaler = joblib.load(os.path.join(self.config.MODEL_PATH, self.config.SCALER_FILE))
            self.feature_engineer.fitted = True
            self.feature_names = joblib.load(os.path.join(self.config.MODEL_PATH, self.config.FEATURES_FILE))
            
            self.is_trained = True
            logger.info("✅ Modelo cargado exitosamente")
            
            return {
                'model_loaded': True,
                'feature_count': len(self.feature_names),
                'model_type': str(type(self.model).__name__)
            }
        except Exception as e:
            logger.error(f"❌ Error cargando modelo: {e}")
            raise
    
    def predict_single(self, transaction_data: Dict) -> Dict[str, Any]:
        """Predecir fraude para una transacción individual"""
        
        if not self.is_trained:
            raise ValueError("Modelo no entrenado. Ejecute train_model() primero.")
        
        # Convertir a DataFrame
        df = pd.DataFrame([transaction_data])
        
        # Agregar campos faltantes con valores por defecto
        default_values = {
            'fecha_transaccion': date.today(),
            'comerciante_nivel_riesgo': 'medio',
            'comerciante_categoria_real': transaction_data.get('categoria_comerciante', 'Varios'),
            'comerciante_tasa_fraude': 0.05,
            'distancia_ubicacion_usual': 10.0,
            'monto_cuenta_origen': transaction_data.get('monto', 0) * 5  # Estimación
        }
        
        for key, value in default_values.items():
            if key not in df.columns:
                df[key] = value
        
        # Preparar características
        X, _ = self.feature_engineer.prepare_features(df, fit=False)
        
        # Predecir
        fraud_probability = float(self.model.predict_proba(X)[0][1])
        is_fraud = fraud_probability >= 0.5
        
        # Determinar nivel de riesgo
        if fraud_probability >= self.config.HIGH_RISK_THRESHOLD:
            risk_level = "HIGH"
        elif fraud_probability >= self.config.MEDIUM_RISK_THRESHOLD:
            risk_level = "MEDIUM"
        else:
            risk_level = "LOW"
        
        # Generar razones de detección
        reasons = self._generate_detection_reasons(transaction_data, fraud_probability)
        
        return {
            'prediccion_fraude': is_fraud,
            'probabilidad_fraude': fraud_probability,
            'nivel_riesgo': risk_level,
            'prediccion': "FRAUDE DETECTADO" if is_fraud else "TRANSACCIÓN NORMAL",
            'transaccion_enviada': transaction_data,
            'timestamp': datetime.now().isoformat(),
            'razones_deteccion': reasons,
            'confianza_modelo': float(max(fraud_probability, 1 - fraud_probability))
        }
    
    def predict_database(self) -> Dict[str, Any]:
        """Analizar todas las transacciones en la base de datos"""
        
        if not self.is_trained:
            raise ValueError("Modelo no entrenado. Ejecute train_model() primero.")
        
        start_time = datetime.now()
        
        # Cargar todas las transacciones
        df = self.db_manager.get_all_transactions()
        
        # Preparar características
        X, _ = self.feature_engineer.prepare_features(df, fit=False)
        
        # Predecir en lotes
        predictions = self.model.predict_proba(X)[:, 1]
        
        # Agregar predicciones al DataFrame
        df['probabilidad_fraude'] = predictions
        df['prediccion_fraude'] = predictions >= 0.5
        df['nivel_riesgo'] = pd.cut(predictions, 
                                   bins=[0, self.config.MEDIUM_RISK_THRESHOLD, self.config.HIGH_RISK_THRESHOLD, 1],
                                   labels=['LOW', 'MEDIUM', 'HIGH'])
        df['prediccion'] = df['prediccion_fraude'].map({True: 'FRAUDE', False: 'NORMAL'})
        
        # Filtrar solo transacciones fraudulentas detectadas
        fraudulent_df = df[df['prediccion_fraude'] == True].copy()
        
        # Convertir a formato JSON serializable
        results = []
        for _, row in fraudulent_df.iterrows():
            result = {
                'id': int(row['id']),
                'cuenta_origen_id': int(row['cuenta_origen_id']) if pd.notna(row['cuenta_origen_id']) else None,
                'cuenta_destino_id': int(row['cuenta_destino_id']) if pd.notna(row['cuenta_destino_id']) else None,
                'monto': float(row['monto']),
                'comerciante': str(row['comerciante']),
                'ubicacion': str(row['ubicacion']),
                'tipo_tarjeta': str(row['tipo_tarjeta']),
                'fecha_transaccion': str(row['fecha_transaccion']),
                'horario_transaccion': str(row['horario_transaccion']),
                'probabilidad_fraude': float(row['probabilidad_fraude']),
                'nivel_riesgo': str(row['nivel_riesgo']),
                'prediccion': str(row['prediccion']),
                'es_fraude_real': bool(row['es_fraude'])  # Para comparación
            }
            results.append(result)
        
        end_time = datetime.now()
        processing_time = (end_time - start_time).total_seconds()
        
        # Estadísticas
        total_analyzed = len(df)
        fraudulent_detected = len(fraudulent_df)
        actual_frauds = df['es_fraude'].sum()
        
        return {
            'transacciones_fraudulentas_encontradas': fraudulent_detected,
            'total_transacciones_analizadas': total_analyzed,
            'tiempo_procesamiento': processing_time,
            'timestamp': end_time.isoformat(),
            'resultados': results,
            'resumen_estadisticas': {
                'fraudes_reales_en_db': int(actual_frauds),
                'fraudes_detectados': fraudulent_detected,
                'precision_estimada': f"{(fraudulent_detected / max(actual_frauds, 1) * 100):.1f}%" if actual_frauds > 0 else "N/A",
                'tasa_deteccion': f"{(fraudulent_detected / total_analyzed * 100):.2f}%"
            }
        }
    
    def _generate_detection_reasons(self, transaction_data: Dict, probability: float) -> List[str]:
        """Generar razones legibles de por qué se detectó como fraude"""
        reasons = []
        
        monto = transaction_data.get('monto', 0)
        ubicacion = transaction_data.get('ubicacion', '')
        comerciante = transaction_data.get('comerciante', '')
        
        if monto > 50000:
            reasons.append(f"Monto muy alto: ${monto:,.2f}")
        
        if 'Online' in ubicacion or 'Desconocida' in ubicacion:
            reasons.append("Ubicación sospechosa: transacción online o ubicación desconocida")
        
        if any(keyword in comerciante.lower() for keyword in ['susp', 'unknown', 'crypto', 'casino']):
            reasons.append("Comerciante de alto riesgo")
        
        # Análisis de horario
        try:
            hour = int(transaction_data.get('horario_transaccion', '14:00:00').split(':')[0])
            if hour <= 6 or hour >= 22:
                reasons.append(f"Horario inusual: {hour:02d}:xx")
        except:
            pass
        
        if probability > 0.8:
            reasons.append("Patrón altamente sospechoso detectado por IA")
        
        if not reasons:
            reasons.append("Combinación de factores de riesgo menores")
        
        return reasons

# =====================================================
# APLICACIÓN FASTAPI
# =====================================================

# Inicializar FastAPI
app = FastAPI(
    title="🛡️ API de Detección de Fraude con ML",
    description="Sistema inteligente de detección de fraude financiero usando Random Forest",
    version="1.0.0"
)

# Configurar CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # En producción, especificar dominios exactos
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ✅ Agregar middleware de reporte de métricas a Stats API
import os
from stats_reporter import StatsReporterMiddleware

STATS_API_URL = os.getenv("STATS_API_URL", "http://stats-api:8003")
app.add_middleware(
    StatsReporterMiddleware,
    service_name="fraude",
    stats_api_url=STATS_API_URL,
    timeout=2.0,
    excluded_paths={'/health', '/docs', '/redoc', '/openapi.json', '/'}
)
logger.info(f"✅ Stats reporter middleware configurado: fraude → {STATS_API_URL}")

# Instancia global del detector
fraud_detector = FraudDetector(config)

# =====================================================
# ENDPOINTS DE LA API
# =====================================================

@app.on_event("startup")
async def startup_event():
    """Inicialización al arrancar la aplicación"""
    logger.info("🚀 Iniciando API de Detección de Fraude...")
    
    # Verificar conexión a base de datos
    if not fraud_detector.db_manager.test_connection():
        raise Exception("No se pudo conectar a la base de datos")
    
    # Cargar o entrenar modelo
    try:
        fraud_detector.load_model()
        logger.info("✅ Modelo cargado desde archivo")
    except:
        logger.info("🔄 Modelo no encontrado, entrenando nuevo modelo...")
        try:
            training_results = fraud_detector.train_model()
            logger.info(f"✅ Modelo entrenado exitosamente - AUC: {training_results['auc_score']:.3f}")
        except Exception as e:
            logger.error(f"❌ Error entrenando modelo: {e}")
            raise
    
    logger.info("🎯 API lista para detectar fraudes!")

@app.get("/")
async def root():
    """Endpoint raíz con información de la API"""
    return {
        "message": "🛡️ API de Detección de Fraude con ML",
        "version": "1.0.0",
        "status": "active",
        "model_trained": fraud_detector.is_trained,
        "endpoints": {
            "predict_single": "/predict_single_transaction (POST)",
            "predict_database": "/api/fraude/predict_all_from_db (GET)",
            "train_model": "/train_model (POST)",
            "health": "/health (GET)"
        }
    }

@app.get("/health")
async def health_check():
    """Verificación de estado de salud"""
    db_ok = fraud_detector.db_manager.test_connection()
    
    return {
        "status": "healthy" if db_ok and fraud_detector.is_trained else "unhealthy",
        "database_connection": "ok" if db_ok else "error",
        "model_status": "trained" if fraud_detector.is_trained else "not_trained",
        "timestamp": datetime.now().isoformat()
    }

@app.post("/predict_single_transaction", response_model=PredictionResponse)
async def predict_single_transaction(transaction: TransactionInput):
    """
    🔍 Analizar una transacción individual para detectar fraude
    
    Recibe los datos de una transacción y devuelve:
    - Probabilidad de fraude (0.0 a 1.0)
    - Clasificación de riesgo (LOW/MEDIUM/HIGH)  
    - Razones de la detección
    """
    try:
        # Convertir modelo Pydantic a dict
        transaction_dict = transaction.dict()
        
        # Predecir
        result = fraud_detector.predict_single(transaction_dict)
        
        logger.info(f"🔍 Transacción analizada: ${transaction.monto} - Fraude: {result['prediccion_fraude']} ({result['probabilidad_fraude']:.1%})")
        
        return PredictionResponse(**result)
        
    except Exception as e:
        logger.error(f"❌ Error prediciendo transacción individual: {e}")
        raise HTTPException(status_code=500, detail=f"Error interno: {str(e)}")

@app.get("/predict_all_from_db", response_model=DatabaseAnalysisResponse)
async def predict_all_from_database():
    """
    🗄️ Analizar todas las transacciones en la base de datos
    
    Procesa masivamente todas las transacciones y devuelve:
    - Lista de transacciones fraudulentas detectadas
    - Estadísticas del análisis
    - Tiempo de procesamiento
    """
    try:
        logger.info("📊 Iniciando análisis masivo de base de datos...")
        
        result = fraud_detector.predict_database()
        
        logger.info(f"✅ Análisis completado: {result['transacciones_fraudulentas_encontradas']} fraudes detectados de {result['total_transacciones_analizadas']} transacciones")
        
        return DatabaseAnalysisResponse(**result)
        
    except Exception as e:
        logger.error(f"❌ Error analizando base de datos: {e}")
        raise HTTPException(status_code=500, detail=f"Error interno: {str(e)}")

@app.post("/train_model")
async def retrain_model(force: bool = False):
    """
    🤖 Reentrenar el modelo de detección de fraude
    
    Parámetros:
    - force: Si es True, fuerza el reentrenamiento aunque ya exista un modelo
    """
    try:
        logger.info("🔄 Iniciando reentrenamiento del modelo...")
        
        training_results = fraud_detector.train_model(force_retrain=force)
        
        return {
            "message": "✅ Modelo reentrenado exitosamente",
            "training_results": training_results,
            "timestamp": datetime.now().isoformat()
        }
        
    except Exception as e:
        logger.error(f"❌ Error reentrenando modelo: {e}")
        raise HTTPException(status_code=500, detail=f"Error interno: {str(e)}")

@app.get("/model_info")
async def get_model_info():
    """Obtener información del modelo actual"""
    if not fraud_detector.is_trained:
        return {"error": "Modelo no entrenado"}
    
    return {
        "model_type": "RandomForestClassifier",
        "is_trained": fraud_detector.is_trained,
        "feature_count": len(fraud_detector.feature_names),
        "feature_names": fraud_detector.feature_names,
        "thresholds": {
            "high_risk": config.HIGH_RISK_THRESHOLD,
            "medium_risk": config.MEDIUM_RISK_THRESHOLD
        }
    }

@app.get("/fraud_report_toon")
async def get_fraud_report_toon(limit: int = 100):
    """
    📊 Obtener reporte de fraudes en formato TOON (token-efficient)
    
    Útil para enviar a LLMs para análisis o generación de reportes.
    Ahorra significativamente tokens comparado con JSON.
    
    Args:
        limit: Número máximo de transacciones fraudulentas a incluir
    """
    try:
        logger.info(f"📊 Generando reporte TOON de fraudes (limit={limit})...")
        
        # Obtener transacciones fraudulentas de la base de datos
        result = fraud_detector.predict_database(limit=limit)
        
        if not result['transacciones_fraudulentas']:
            return {
                "toon_report": "fraud_transactions[0]: (no fraud detected)",
                "statistics": result,
                "format": "TOON"
            }
        
        # Convertir a TOON
        fraud_transactions = result['transacciones_fraudulentas']
        
        # Preparar datos para TOON
        toon_data = {
            "fraud_transactions": fraud_transactions
        }
        
        # Generar TOON
        toon_report = encode(toon_data, delimiter=",", length_marker=True)
        
        # Calcular ahorro vs JSON
        json_report = json.dumps(toon_data, indent=2)
        savings = estimate_token_savings(json_report, toon_report)
        
        logger.info(f"💾 Reporte TOON generado: {savings['tokens_saved']} tokens ahorrados ({savings['savings_percent']}%)")
        
        return {
            "toon_report": toon_report,
            "statistics": {
                "total_analyzed": result['total_transacciones_analizadas'],
                "fraud_detected": result['transacciones_fraudulentas_encontradas'],
                "fraud_rate": f"{result['tasa_fraude_detectado']:.2%}",
                "processing_time": result['tiempo_procesamiento']
            },
            "token_savings": {
                "json_tokens": savings['json_tokens_approx'],
                "toon_tokens": savings['toon_tokens_approx'],
                "tokens_saved": savings['tokens_saved'],
                "savings_percent": f"{savings['savings_percent']}%",
                "compression_ratio": f"{savings['compression_ratio']}x"
            },
            "format": "TOON",
            "usage_note": "Send this TOON report directly to LLMs. Format: fraud_transactions[N]{field1,field2,...}: ..."
        }
        
    except Exception as e:
        logger.error(f"❌ Error generando reporte TOON: {e}")
        raise HTTPException(status_code=500, detail=f"Error interno: {str(e)}")

# =====================================================
# EJECUCIÓN PRINCIPAL
# =====================================================

if __name__ == "__main__":
    # Ejecutar servidor
    uvicorn.run(
        "app:app",
        host="0.0.0.0",
        port=8001,  # Puerto definido en .env para FRAUDE_API_PORT
        reload=True,
        log_level="info"
    )
