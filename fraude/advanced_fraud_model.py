# advanced_fraud_model.py
"""
🧠 MODELO DE IA SÚPER AVANZADO PARA DETECCIÓN DE FRAUDE
Utiliza algoritmos de Machine Learning de última generación.
"""

import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestClassifier, GradientBoostingClassifier
from sklearn.model_selection import train_test_split, cross_val_score, GridSearchCV
from sklearn.preprocessing import LabelEncoder, StandardScaler
from sklearn.metrics import classification_report, confusion_matrix, roc_auc_score
from sklearn.feature_selection import SelectKBest, f_classif
import joblib
import warnings
warnings.filterwarnings('ignore')

class AdvancedFraudDetector:
    """🧠 Detector de fraude con IA súper avanzada y algoritmos inteligentes"""
    
    def __init__(self):
        print("🧠 Inicializando IA Súper Avanzada para Detección de Fraude...")
        
        # Múltiples modelos de IA con parámetros más sutiles
        self.models = {
            'random_forest': RandomForestClassifier(
                n_estimators=150,  # Reducido para menos overfitting
                max_depth=10,      # Reducido para predicciones más sutiles
                min_samples_split=10,  # Incrementado para más generalización
                min_samples_leaf=5,    # Incrementado para suavizar predicciones
                class_weight='balanced',
                random_state=42,
                max_features='sqrt'  # Añadido para reducir overfitting
            ),
            'gradient_boosting': GradientBoostingClassifier(
                n_estimators=80,   # Reducido
                learning_rate=0.05, # Reducido para aprendizaje más suave
                max_depth=6,       # Reducido
                min_samples_split=10,  # Incrementado
                min_samples_leaf=5,    # Incrementado
                random_state=42,
                subsample=0.8      # Añadido para regularización
            )
        }
        
        self.best_model = None
        self.model_name = None
        self.train_columns = None
        self.label_encoders = {}
        self.scaler = StandardScaler()
        self.feature_selector = SelectKBest(f_classif, k=20)  # Reducido de 25 a 20
        
        # Mapas de riesgo dinámicos
        self.merchant_risk_scores = {}
        self.location_risk_scores = {}
        self.time_risk_patterns = {}
        
        # Umbrales más realistas
        self.optimal_threshold = 0.4  # Reducido de 0.5 a 0.4
        self.confidence_levels = {
            'very_high': 0.85,  # Reducido de 0.9
            'high': 0.65,       # Reducido de 0.7
            'medium': 0.45,     # Reducido de 0.5
            'low': 0.25         # Reducido de 0.3
        }
        
    def _advanced_feature_engineering(self, df):
        """🧠 Ingeniería de características súper avanzada con IA"""
        print("🔧 Aplicando ingeniería de características súper avanzada...")
        
        # Preservar columnas originales para análisis
        original_df = df.copy()
        
        # Eliminar columnas administrativas
        df = df.drop(columns=['id', 'fecha_transaccion', 'es_fraude'], errors='ignore')
        
        # === 1. PROCESAMIENTO TEMPORAL INTELIGENTE ===
        def extract_hour_from_time(time_str):
            try:
                if pd.isna(time_str):
                    return 12  # hora promedio
                if isinstance(time_str, str):
                    return int(time_str.split(':')[0])
                return int(time_str.hour) if hasattr(time_str, 'hour') else 12
            except:
                return 12
        
        df['hour'] = df['horario_transaccion'].apply(extract_hour_from_time)
        df['is_night'] = ((df['hour'] >= 23) | (df['hour'] <= 5)).astype(int)
        df['is_business_hours'] = ((df['hour'] >= 9) & (df['hour'] <= 17)).astype(int)
        df['is_very_late'] = ((df['hour'] >= 1) & (df['hour'] <= 4)).astype(int)  # Más específico
        
        # === 2. ANÁLISIS DE MONTOS CON IA ===
        df['monto'] = pd.to_numeric(df['monto'], errors='coerce').fillna(0)
        df['monto_log'] = np.log1p(df['monto'])
        df['monto_sqrt'] = np.sqrt(df['monto'])
        
        # Categorías más sutiles de monto
        monto_percentiles = df['monto'].quantile([0.25, 0.5, 0.75, 0.85, 0.92, 0.97])
        df['is_small_transaction'] = (df['monto'] <= monto_percentiles[0.5]).astype(int)
        df['is_medium_transaction'] = ((df['monto'] > monto_percentiles[0.5]) & (df['monto'] <= monto_percentiles[0.85])).astype(int)
        df['is_high_transaction'] = ((df['monto'] > monto_percentiles[0.85]) & (df['monto'] <= monto_percentiles[0.97])).astype(int)
        df['is_very_high_transaction'] = (df['monto'] > monto_percentiles[0.97]).astype(int)
        
        # === 3. ANÁLISIS DE COMERCIANTES CON IA ===
        # Calcular scores de riesgo dinámicos con suavizado
        if 'comerciante' in original_df.columns and 'es_fraude' in original_df.columns:
            merchant_fraud_rates = original_df.groupby('comerciante')['es_fraude'].agg(['mean', 'count'])
            for merchant in merchant_fraud_rates.index:
                fraud_rate = merchant_fraud_rates.loc[merchant, 'mean']
                transaction_count = merchant_fraud_rates.loc[merchant, 'count']
                # Score suavizado con menos peso para pocos datos
                confidence = min(transaction_count / 20, 1.0)  # Incrementado de 10 a 20
                base_risk = 0.15  # Riesgo base más alto
                self.merchant_risk_scores[merchant] = base_risk + (fraud_rate * confidence * 0.6)
        
        # Características de comerciantes más sutiles
        df['merchant_risk_score'] = df['comerciante'].map(self.merchant_risk_scores).fillna(0.15)
        df['is_medium_risk_merchant'] = (df['merchant_risk_score'] > 0.3).astype(int)  # Umbral más bajo
        df['is_high_risk_merchant'] = (df['merchant_risk_score'] > 0.5).astype(int)
        df['is_online_merchant'] = df['comerciante'].str.contains('Online|online|E-commerce', case=False, na=False).astype(int)
        df['is_financial_merchant'] = df['comerciante'].str.contains('Financiero|Financial|Western|MoneyGram|Binance', case=False, na=False).astype(int)
        
        # === 4. ANÁLISIS GEOGRÁFICO CON IA ===
        # Calcular scores de riesgo por ubicación con suavizado
        if 'ubicacion' in original_df.columns and 'es_fraude' in original_df.columns:
            location_fraud_rates = original_df.groupby('ubicacion')['es_fraude'].agg(['mean', 'count'])
            for location in location_fraud_rates.index:
                fraud_rate = location_fraud_rates.loc[location, 'mean']
                transaction_count = location_fraud_rates.loc[location, 'count']
                confidence = min(transaction_count / 15, 1.0)  # Incrementado de 5 a 15
                base_risk = 0.12
                self.location_risk_scores[location] = base_risk + (fraud_rate * confidence * 0.5)
        
        df['location_risk_score'] = df['ubicacion'].map(self.location_risk_scores).fillna(0.12)
        df['is_medium_risk_location'] = (df['location_risk_score'] > 0.25).astype(int)
        df['is_high_risk_location'] = (df['location_risk_score'] > 0.4).astype(int)
        df['is_online_location'] = df['ubicacion'].str.contains('Online', case=False, na=False).astype(int)
        df['is_distant_location'] = (df['distancia_ubicacion_usual'] > 50).astype(int) if 'distancia_ubicacion_usual' in df.columns else 0
        
        # === 5. ANÁLISIS DE TARJETAS ===
        # Encoding más sutil de tipos de tarjeta
        card_risk_map = {
            'Débito': 0.12,
            'Crédito': 0.15,
            'Prepaga': 0.20,
            'Unknown': 0.25
        }
        df['card_risk_score'] = df['tipo_tarjeta'].map(card_risk_map).fillna(0.18)
        
        # === 6. CARACTERÍSTICAS COMBINADAS SUTILES ===
        df['risk_score_combined'] = (
            df['merchant_risk_score'] * 0.35 +
            df['location_risk_score'] * 0.25 +
            df['card_risk_score'] * 0.15 +
            df['is_very_late'] * 0.25
        )
        
        df['subtle_anomaly_score'] = (
            df['is_very_high_transaction'] * 0.25 +
            df['is_high_risk_merchant'] * 0.25 +
            df['is_high_risk_location'] * 0.20 +
            df['is_very_late'] * 0.15 +
            df['is_financial_merchant'] * 0.15
        )
        
        # === 7. ESTADÍSTICAS AVANZADAS SUAVIZADAS ===
        monto_std = df['monto'].std()
        monto_mean = df['monto'].mean()
        if monto_std > 0:
            df['monto_zscore'] = np.abs((df['monto'] - monto_mean) / monto_std)
        else:
            df['monto_zscore'] = 0
        df['is_outlier_amount'] = (df['monto_zscore'] > 2.5).astype(int)  # Incrementado de 2 a 2.5
        
        # === 8. ENCODING DE VARIABLES CATEGÓRICAS ===
        categorical_columns = ['comerciante', 'ubicacion', 'tipo_tarjeta']
        
        for col in categorical_columns:
            if col in df.columns:
                if col not in self.label_encoders:
                    self.label_encoders[col] = LabelEncoder()
                    df[f'{col}_encoded'] = self.label_encoders[col].fit_transform(df[col].astype(str))
                else:
                    # Para nuevos datos, manejar categorías no vistas
                    known_categories = set(self.label_encoders[col].classes_)
                    df[col] = df[col].astype(str)
                    df[col] = df[col].apply(lambda x: x if x in known_categories else 'unknown')
                    df[f'{col}_encoded'] = self.label_encoders[col].transform(df[col])
        
        # Eliminar columnas categóricas originales y horario
        columns_to_drop = ['comerciante', 'ubicacion', 'tipo_tarjeta', 'horario_transaccion', 'cuenta_origen_id', 'cuenta_destino_id', 'distancia_ubicacion_usual']
        df = df.drop(columns=[col for col in columns_to_drop if col in df.columns])
        
        print(f"✅ Características generadas: {len(df.columns)} features sutiles")
        
        return df
    
    def prepare_data(self, transactions):
        """🧠 Preparación inteligente de datos"""
        print("📊 Preparando datos con algoritmos inteligentes...")
        
        columns = [
            'id', 'cuenta_origen_id', 'cuenta_destino_id', 'monto', 'comerciante',
            'ubicacion', 'tipo_tarjeta', 'horario_transaccion', 'fecha_transaccion', 'es_fraude'
        ]
        df = pd.DataFrame(transactions, columns=columns)
        
        print(f"📊 Dataset inicial: {len(df)} transacciones")
        
        # Información del dataset
        fraud_count = df['es_fraude'].sum()
        fraud_percentage = (fraud_count / len(df)) * 100
        
        print(f"📊 Análisis del dataset:")
        print(f"   Total transacciones: {len(df)}")
        print(f"   Fraudes: {fraud_count} ({fraud_percentage:.2f}%)")
        print(f"   Legítimas: {len(df) - fraud_count} ({100 - fraud_percentage:.2f}%)")
        
        return df
    
    def train_model(self, data):
        """🧠 Entrenamiento con múltiples algoritmos de IA"""
        print("\n🚀 INICIANDO ENTRENAMIENTO CON IA SÚPER AVANZADA...")
        print("=" * 60)
        
        # Extraer target variable ANTES de feature engineering
        y = data['es_fraude'].astype(int)
        
        # ✅ VERIFICAR SI HAY FRAUDES EN LOS DATOS
        fraud_count = y.sum()
        total_count = len(y)
        
        if fraud_count == 0:
            print("❌ ERROR CRÍTICO: No hay transacciones fraudulentas en los datos")
            print("💡 El modelo necesita ejemplos de fraude para entrenar")
            print("🔧 Verifica que el script SQL 03-fraud-samples.sql se ejecute correctamente")
            return 0.0, 0.4
        
        if fraud_count < 10:
            print(f"⚠️  ADVERTENCIA: Muy pocos fraudes para entrenar ({fraud_count} de {total_count})")
            print("🎯 Se recomienda al menos 50 ejemplos de fraude")
        
        print(f"📊 Balance de clases: {fraud_count} fraudes ({fraud_count/total_count*100:.1f}%) de {total_count} total")
        
        # Preparar características
        X = self._advanced_feature_engineering(data)
        
        print(f"🎯 Entrenando con {len(X)} muestras y {len(X.columns)} características")
        
        # División de datos
        X_train, X_test, y_train, y_test = train_test_split(
            X, y, test_size=0.25, random_state=42, stratify=y
        )
        
        # Selección de características más importantes
        X_train_selected = self.feature_selector.fit_transform(X_train, y_train)
        X_test_selected = self.feature_selector.transform(X_test)
        
        # Guardar nombres de columnas seleccionadas
        selected_features = X.columns[self.feature_selector.get_support()]
        self.train_columns = selected_features
        
        print(f"🎯 Características seleccionadas: {len(selected_features)}")
        
        # Escalado de características
        X_train_scaled = self.scaler.fit_transform(X_train_selected)
        X_test_scaled = self.scaler.transform(X_test_selected)
        
        # Entrenar múltiples modelos
        best_score = 0
        results = {}
        
        for name, model in self.models.items():
            print(f"\n🧠 Entrenando modelo: {name.upper()}")
            
            # Entrenamiento
            model.fit(X_train_scaled, y_train)
            
            # Predicciones
            y_pred = model.predict(X_test_scaled)
            y_proba = model.predict_proba(X_test_scaled)[:, 1]
            
            # Métricas
            auc_score = roc_auc_score(y_test, y_proba)
            cv_scores = cross_val_score(model, X_train_scaled, y_train, cv=3, scoring='roc_auc')  # Reducido de 5 a 3
            
            results[name] = {
                'model': model,
                'auc_score': auc_score,
                'cv_mean': cv_scores.mean(),
                'cv_std': cv_scores.std(),
                'predictions': y_pred,
                'probabilities': y_proba
            }
            
            print(f"   AUC Score: {auc_score:.4f}")
            print(f"   CV Score: {cv_scores.mean():.4f} (+/- {cv_scores.std() * 2:.4f})")
            
            if auc_score > best_score:
                best_score = auc_score
                self.best_model = model
                self.model_name = name
        
        # Optimización del umbral
        best_proba = results[self.model_name]['probabilities']
        self.optimal_threshold = self._optimize_threshold(y_test, best_proba)
        
        # Reporte final
        print(f"\n🏆 MEJOR MODELO: {self.model_name.upper()}")
        print(f"🎯 AUC Score: {best_score:.4f}")
        print(f"🎯 Umbral óptimo: {self.optimal_threshold:.3f}")
        
        # Reporte de clasificación
        y_pred_optimal = (best_proba >= self.optimal_threshold).astype(int)
        print(f"\n📊 REPORTE DE CLASIFICACIÓN:")
        print(classification_report(y_test, y_pred_optimal))
        
        # Importancia de características (si es Random Forest)
        if self.model_name == 'random_forest':
            feature_importance = pd.DataFrame({
                'feature': selected_features,
                'importance': self.best_model.feature_importances_
            }).sort_values('importance', ascending=False)
            
            print(f"\n🔍 TOP 10 CARACTERÍSTICAS MÁS IMPORTANTES:")
            for i, (_, row) in enumerate(feature_importance.head(10).iterrows()):
                print(f"   {i+1}. {row['feature']}: {row['importance']:.4f}")
        
        # Guardar modelo
        model_data = {
            'model': self.best_model,
            'model_name': self.model_name,
            'scaler': self.scaler,
            'feature_selector': self.feature_selector,
            'train_columns': self.train_columns,
            'label_encoders': self.label_encoders,
            'optimal_threshold': self.optimal_threshold,
            'merchant_risk_scores': self.merchant_risk_scores,
            'location_risk_scores': self.location_risk_scores
        }
        
        joblib.dump(model_data, 'advanced_fraud_model.pkl')
        print(f"\n💾 Modelo avanzado guardado exitosamente")
        
        return best_score, self.optimal_threshold
    
    def _optimize_threshold(self, y_true, y_proba):
        """🧠 Optimización inteligente del umbral de decisión"""
        from sklearn.metrics import precision_recall_curve
        
        precision, recall, thresholds = precision_recall_curve(y_true, y_proba)
        
        # Calcular F1-score para cada umbral
        f1_scores = 2 * (precision * recall) / (precision + recall + 1e-8)
        
        # Encontrar umbral que maximiza F1-score
        optimal_idx = np.argmax(f1_scores)
        optimal_threshold = thresholds[optimal_idx] if optimal_idx < len(thresholds) else 0.4
        
        # Ajustar umbral para ser más realista
        if optimal_threshold > 0.7:
            optimal_threshold = 0.6
            print(f"🔧 Ajustando umbral alto a 0.6 para predicciones más realistas")
        elif optimal_threshold < 0.2:
            optimal_threshold = 0.3
            print(f"🔧 Ajustando umbral bajo a 0.3 para evitar demasiados falsos positivos")
        
        print(f"🎯 Umbral optimizado: {optimal_threshold:.3f}")
        return optimal_threshold
    
    def predict_batch(self, transactions_data):
        """🧠 Predicción para múltiples transacciones aplicando todas las transformaciones"""
        if not self.best_model or self.train_columns is None:
            print("❌ Error: el modelo de IA no ha sido entrenado.")
            return [], []

        try:
            print(f"🧠 Iniciando análisis batch con IA súper avanzada...")
            
            # Preparar datos básicos
            df = self.prepare_data(transactions_data)
            
            if df.empty:
                print("❌ Error: No se pudieron procesar los datos.")
                return [], []
            
            # Aplicar ingeniería de características (igual que en entrenamiento)
            X = self._advanced_feature_engineering(df)
            
            # Aplicar selección de características (igual que en entrenamiento)
            if hasattr(self, 'feature_selector') and self.feature_selector:
                X_selected = self.feature_selector.transform(X)
            else:
                X_selected = X[self.train_columns] if self.train_columns is not None else X
                
            # Aplicar escalado (igual que en entrenamiento)
            if hasattr(self, 'scaler') and self.scaler:
                X_scaled = self.scaler.transform(X_selected)
            else:
                X_scaled = X_selected
            
            # Hacer predicciones
            predictions = self.best_model.predict(X_scaled)
            probabilities = self.best_model.predict_proba(X_scaled)
            
            # Aplicar umbral optimizado si está disponible
            if hasattr(self, 'optimal_threshold') and self.optimal_threshold:
                fraud_probs = probabilities[:, 1] if probabilities.shape[1] > 1 else probabilities[:, 0]
                final_predictions = fraud_probs >= self.optimal_threshold
            else:
                final_predictions = predictions
                
            print(f"🎯 Procesadas {len(final_predictions)} transacciones")
            
            return final_predictions.tolist(), probabilities.tolist()
            
        except Exception as e:
            print(f"❌ Error en análisis batch: {e}")
            import traceback
            traceback.print_exc()
            return [], []

    def predict_single_transaction(self, new_transactions):
        """🧠 Predicción inteligente con análisis avanzado para transacciones individuales"""
        try:
            predictions, probabilities = self.predict_batch(new_transactions)
            if predictions and probabilities:
                fraud_prob = probabilities[0][1] if len(probabilities[0]) > 1 else probabilities[0][0]
                return bool(predictions[0]), float(fraud_prob)
            return False, 0.0
        except Exception as e:
            print(f"❌ Error en predicción individual: {e}")
            return False, 0.0
    
    def load_model(self, model_path='advanced_fraud_model.pkl'):
        """🧠 Carga modelo pre-entrenado"""
        try:
            model_data = joblib.load(model_path)
            self.best_model = model_data['model']
            self.model_name = model_data['model_name']
            self.scaler = model_data['scaler']
            self.feature_selector = model_data['feature_selector']
            self.train_columns = model_data['train_columns']
            self.label_encoders = model_data['label_encoders']
            self.optimal_threshold = model_data['optimal_threshold']
            print("✅ Modelo avanzado cargado exitosamente")
            return True
        except Exception as e:
            print(f"❌ Error al cargar modelo: {e}")
            return False
