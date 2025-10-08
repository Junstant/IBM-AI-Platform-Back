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
        
        # Múltiples modelos de IA
        self.models = {
            'random_forest': RandomForestClassifier(
                n_estimators=200,
                max_depth=15,
                min_samples_split=5,
                min_samples_leaf=2,
                class_weight='balanced',
                random_state=42
            ),
            'gradient_boosting': GradientBoostingClassifier(
                n_estimators=100,
                learning_rate=0.1,
                max_depth=8,
                random_state=42
            )
        }
        
        self.best_model = None
        self.model_name = None
        self.train_columns = None
        self.label_encoders = {}
        self.scaler = StandardScaler()
        self.feature_selector = SelectKBest(f_classif, k=25)
        
        # Mapas de riesgo dinámicos
        self.merchant_risk_scores = {}
        self.location_risk_scores = {}
        self.time_risk_patterns = {}
        
        # Umbrales inteligentes
        self.optimal_threshold = 0.5
        self.confidence_levels = {
            'very_high': 0.9,
            'high': 0.7,
            'medium': 0.5,
            'low': 0.3
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
        df['is_weekend_hours'] = ((df['hour'] >= 18) | (df['hour'] <= 8)).astype(int)
        
        # === 2. ANÁLISIS DE MONTOS CON IA ===
        df['monto'] = pd.to_numeric(df['monto'], errors='coerce').fillna(0)
        df['monto_log'] = np.log1p(df['monto'])
        df['monto_sqrt'] = np.sqrt(df['monto'])
        
        # Categorías inteligentes de monto
        monto_percentiles = df['monto'].quantile([0.25, 0.5, 0.75, 0.9, 0.95, 0.99])
        df['is_micro_transaction'] = (df['monto'] <= 10).astype(int)
        df['is_small_transaction'] = ((df['monto'] > 10) & (df['monto'] <= monto_percentiles[0.5])).astype(int)
        df['is_medium_transaction'] = ((df['monto'] > monto_percentiles[0.5]) & (df['monto'] <= monto_percentiles[0.9])).astype(int)
        df['is_large_transaction'] = ((df['monto'] > monto_percentiles[0.9]) & (df['monto'] <= monto_percentiles[0.99])).astype(int)
        df['is_huge_transaction'] = (df['monto'] > monto_percentiles[0.99]).astype(int)
        
        # === 3. ANÁLISIS DE COMERCIANTES CON IA ===
        # Calcular scores de riesgo dinámicos
        if 'cuenta_origen_id' in original_df.columns and 'es_fraude' in original_df.columns:
            merchant_fraud_rates = original_df.groupby('comerciante')['es_fraude'].agg(['mean', 'count'])
            for merchant in merchant_fraud_rates.index:
                fraud_rate = merchant_fraud_rates.loc[merchant, 'mean']
                transaction_count = merchant_fraud_rates.loc[merchant, 'count']
                # Score ponderado por cantidad de transacciones
                confidence = min(transaction_count / 10, 1.0)  # máximo confidence = 1
                self.merchant_risk_scores[merchant] = fraud_rate * confidence
        
        # Características de comerciantes
        df['merchant_risk_score'] = df['comerciante'].map(self.merchant_risk_scores).fillna(0.1)
        df['is_high_risk_merchant'] = (df['merchant_risk_score'] > 0.5).astype(int)
        df['is_unknown_merchant'] = df['comerciante'].str.contains('Unknown|unknown|desconocido|Desconocido', case=False, na=False).astype(int)
        df['is_cash_merchant'] = df['comerciante'].str.contains('Cash|ATM|crypto|casino', case=False, na=False).astype(int)
        df['is_international_merchant'] = df['comerciante'].str.contains('International|Foreign|Overseas', case=False, na=False).astype(int)
        
        # === 4. ANÁLISIS GEOGRÁFICO CON IA ===
        # Calcular scores de riesgo por ubicación
        if 'ubicacion' in original_df.columns and 'es_fraude' in original_df.columns:
            location_fraud_rates = original_df.groupby('ubicacion')['es_fraude'].agg(['mean', 'count'])
            for location in location_fraud_rates.index:
                fraud_rate = location_fraud_rates.loc[location, 'mean']
                transaction_count = location_fraud_rates.loc[location, 'count']
                confidence = min(transaction_count / 5, 1.0)
                self.location_risk_scores[location] = fraud_rate * confidence
        
        df['location_risk_score'] = df['ubicacion'].map(self.location_risk_scores).fillna(0.1)
        df['is_high_risk_location'] = (df['location_risk_score'] > 0.5).astype(int)
        df['is_foreign_location'] = df['ubicacion'].str.contains('Nigeria|Russia|China|Unknown|Offshore|VPN|Tor', case=False, na=False).astype(int)
        df['is_domestic_location'] = df['ubicacion'].str.contains('NY|CA|TX|FL|IL|PA|OH|GA|NC|MI', case=False, na=False).astype(int)
        
        # === 5. ANÁLISIS DE TARJETAS ===
        # Encoding inteligente de tipos de tarjeta
        card_risk_map = {
            'Visa': 0.1,
            'Mastercard': 0.1,
            'American Express': 0.15,
            'Discover': 0.2,
            'Unknown': 0.8
        }
        df['card_risk_score'] = df['tipo_tarjeta'].map(card_risk_map).fillna(0.5)
        
        # === 6. CARACTERÍSTICAS COMBINADAS CON IA ===
        df['risk_score_combined'] = (
            df['merchant_risk_score'] * 0.4 +
            df['location_risk_score'] * 0.3 +
            df['card_risk_score'] * 0.1 +
            df['is_night'] * 0.2
        )
        
        df['anomaly_score'] = (
            df['is_huge_transaction'] * 0.3 +
            df['is_high_risk_merchant'] * 0.3 +
            df['is_foreign_location'] * 0.2 +
            df['is_night'] * 0.2
        )
        
        # === 7. ESTADÍSTICAS AVANZADAS ===
        df['monto_zscore'] = np.abs((df['monto'] - df['monto'].mean()) / df['monto'].std())
        df['is_outlier_amount'] = (df['monto_zscore'] > 2).astype(int)
        
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
        columns_to_drop = ['comerciante', 'ubicacion', 'tipo_tarjeta', 'horario_transaccion', 'cuenta_origen_id', 'cuenta_destino_id']
        df = df.drop(columns=[col for col in columns_to_drop if col in df.columns])
        
        print(f"✅ Características generadas: {len(df.columns)} features avanzadas")
        
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
        
        # Preparar características
        X = self._advanced_feature_engineering(data)
        y = data['es_fraude'].astype(int)
        
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
            cv_scores = cross_val_score(model, X_train_scaled, y_train, cv=5, scoring='roc_auc')
            
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
        f1_scores = 2 * (precision * recall) / (precision + recall + 1e-8)
        
        # Encontrar umbral que maximiza F1-score
        optimal_idx = np.argmax(f1_scores)
        optimal_threshold = thresholds[optimal_idx] if optimal_idx < len(thresholds) else 0.5
        
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
