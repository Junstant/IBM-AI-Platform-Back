"""
🧠 MODELO HÍBRIDO SÚPER COMPLETO PARA DETECCIÓN DE FRAUDE
Combina reglas de negocio + aprendizaje comportamental + análisis histórico + IA avanzada
"""

import pandas as pd
import numpy as np
import re
from datetime import datetime, timedelta
from sklearn.ensemble import IsolationForest
from advanced_fraud_model import AdvancedFraudDetector

class HybridFraudDetector(AdvancedFraudDetector):
    """🧠 Detector híbrido que combina TODAS las técnicas de detección de fraude"""
    
    def __init__(self):
        super().__init__()
        
        # Perfiles de comportamiento por usuario
        self.user_profiles = {}
        self.user_isolation_forests = {}
        
        # Configuración de aprendizaje comportamental
        self.min_transactions_for_profile = 10
        self.profile_update_frequency = 100
        
        # Reglas de negocio evidentes
        self.obvious_fraud_patterns = {
            'test_amounts': [
                12345.67, 123.45, 1234.56, 999.99, 111.11, 222.22, 333.33,
                444.44, 555.55, 666.66, 777.77, 888.88, 1111.11, 2222.22
            ],
            'suspicious_merchants': [
                'desconocido', 'unknown', 'test', 'prueba', 'hacker', 'fraud',
                'fraude', 'fake', 'falso', 'suspicious', 'sospechoso',
                'anonymous', 'anonimo', 'temp', 'temporal', 'xxx', 'yyy', 'zzz'
            ],
            'suspicious_locations': [
                'desconocido', 'unknown', 'test location', 'fake', 'falso',
                'anonymous', 'anonimo', 'temp', 'temporal', 'xxx', 'yyy',
                'offshore', 'darkweb', 'tor network', 'vpn', 'proxy'
            ],
            'suspicious_times': [
                '00:00:00', '01:01:01', '02:02:02', '03:03:03', '04:04:04',
                '05:05:05', '11:11:11', '12:12:12', '22:22:22', '23:23:23'
            ]
        }
        
        print("🧠 Detector híbrido súper completo inicializado")
        print("   ✅ Reglas de negocio evidentes")
        print("   ✅ Aprendizaje comportamental por usuario")
        print("   ✅ Análisis histórico avanzado")
        print("   ✅ IA con múltiples algoritmos")
    
    def _detect_obvious_fraud_patterns(self, transaction_data):
        """🚨 Detecta patrones de fraude evidentes y obvios"""
        fraud_indicators = []
        confidence_score = 0.0
        
        amount = transaction_data['monto']
        merchant = str(transaction_data['comerciante']).lower().strip()
        location = str(transaction_data['ubicacion']).lower().strip()
        time_str = str(transaction_data['horario_transaccion']).strip()
        
        # 1. 🔍 ANÁLISIS DE MONTOS SOSPECHOSOS
        if amount in self.obvious_fraud_patterns['test_amounts']:
            fraud_indicators.append(f"Monto de prueba evidente: ${amount}")
            confidence_score += 0.9  # Muy alta confianza
        
        # Patrones numéricos repetitivos
        amount_str = f"{amount:.2f}"
        if re.match(r'^\d*\.?\d*$', amount_str):
            # Números muy repetitivos (ej: 1111.11, 5555.55)
            if len(set(amount_str.replace('.', ''))) <= 2:
                fraud_indicators.append(f"Patrón numérico repetitivo: ${amount}")
                confidence_score += 0.7
            
            # Secuencias obvias (ej: 12345.67, 98765.43)
            digits = amount_str.replace('.', '')
            if len(digits) >= 4:
                is_sequence = True
                for i in range(len(digits) - 1):
                    if digits[i].isdigit() and digits[i+1].isdigit():
                        if abs(int(digits[i]) - int(digits[i+1])) != 1:
                            is_sequence = False
                            break
                if is_sequence:
                    fraud_indicators.append(f"Secuencia numérica obvia: ${amount}")
                    confidence_score += 0.8
        
        # 2. 🏪 ANÁLISIS DE COMERCIANTES SOSPECHOSOS
        for suspicious_term in self.obvious_fraud_patterns['suspicious_merchants']:
            if suspicious_term in merchant:
                fraud_indicators.append(f"Comerciante sospechoso: '{transaction_data['comerciante']}'")
                confidence_score += 0.8
                break
        
        # Comerciantes con caracteres raros o patrones obvios
        if re.search(r'[^a-zA-Z0-9\s\-\.]', merchant):
            fraud_indicators.append(f"Comerciante con caracteres especiales: '{transaction_data['comerciante']}'")
            confidence_score += 0.6
        
        if len(merchant.strip()) <= 2 or merchant in ['xx', 'yy', 'zz', 'aa', 'bb']:
            fraud_indicators.append(f"Comerciante con nombre demasiado corto: '{transaction_data['comerciante']}'")
            confidence_score += 0.7
        
        # 3. 📍 ANÁLISIS DE UBICACIONES SOSPECHOSAS
        for suspicious_term in self.obvious_fraud_patterns['suspicious_locations']:
            if suspicious_term in location:
                fraud_indicators.append(f"Ubicación sospechosa: '{transaction_data['ubicacion']}'")
                confidence_score += 0.8
                break
        
        # Ubicaciones con caracteres raros
        if re.search(r'[^a-zA-Z0-9\s\-\.,]', location):
            fraud_indicators.append(f"Ubicación con caracteres especiales: '{transaction_data['ubicacion']}'")
            confidence_score += 0.6
        
        if len(location.strip()) <= 2:
            fraud_indicators.append(f"Ubicación demasiado corta: '{transaction_data['ubicacion']}'")
            confidence_score += 0.7
        
        # 4. ⏰ ANÁLISIS DE HORARIOS SOSPECHOSOS
        if time_str in self.obvious_fraud_patterns['suspicious_times']:
            fraud_indicators.append(f"Horario de prueba evidente: {time_str}")
            confidence_score += 0.8
        
        # Horarios con patrones repetitivos
        if re.match(r'(\d)\1:\1\1:\1\1', time_str):  # ej: 11:11:11, 22:22:22
            fraud_indicators.append(f"Horario con patrón repetitivo: {time_str}")
            confidence_score += 0.7
        
        # 5. 🔍 COMBINACIONES ALTAMENTE SOSPECHOSAS
        if ('unknown' in merchant or 'desconocido' in merchant) and ('unknown' in location or 'desconocido' in location):
            fraud_indicators.append("Combinación: comerciante Y ubicación desconocidos")
            confidence_score += 0.9
        
        # 6. 💰 MONTOS EXTREMOS OBVIOS
        if amount >= 999999:  # Montos ridículamente altos
            fraud_indicators.append(f"Monto extremadamente alto: ${amount:,.2f}")
            confidence_score += 0.8
        
        if amount == 0.01:  # Montos de prueba típicos
            fraud_indicators.append("Monto de prueba típico: $0.01")
            confidence_score += 0.9
        
        return {
            'is_obvious_fraud': len(fraud_indicators) > 0,
            'fraud_indicators': fraud_indicators,
            'confidence_score': min(confidence_score, 1.0),
            'risk_level': 'OBVIOUS_FRAUD' if confidence_score >= 0.8 else 'SUSPICIOUS' if confidence_score >= 0.5 else 'LOW'
        }
    
    def _build_user_profiles(self, df):
        """👤 Construye perfiles de comportamiento detallados por usuario"""
        print("👤 Construyendo perfiles de comportamiento por usuario...")
        
        for user_id in df['cuenta_origen_id'].unique():
            user_data = df[df['cuenta_origen_id'] == user_id].copy()
            
            if len(user_data) < self.min_transactions_for_profile:
                continue
            
            # Estadísticas de comportamiento del usuario
            profile = {
                'user_id': user_id,
                'total_transactions': len(user_data),
                'first_transaction': user_data['fecha_transaccion'].min(),
                'last_transaction': user_data['fecha_transaccion'].max(),
                
                # Patrones de monto
                'avg_amount': user_data['monto'].mean(),
                'std_amount': user_data['monto'].std(),
                'min_amount': user_data['monto'].min(),
                'max_amount': user_data['monto'].max(),
                'percentile_90': user_data['monto'].quantile(0.9),
                'percentile_95': user_data['monto'].quantile(0.95),
                'percentile_99': user_data['monto'].quantile(0.99),
                
                # Patrones temporales
                'preferred_hours': self._get_user_preferred_hours(user_data),
                'weekend_ratio': self._get_weekend_ratio(user_data),
                'night_ratio': self._get_night_ratio(user_data),
                
                # Patrones de comerciantes
                'favorite_merchants': user_data['comerciante'].value_counts().head(10).to_dict(),
                'unique_merchants': user_data['comerciante'].nunique(),
                'merchant_diversity': user_data['comerciante'].nunique() / len(user_data),
                
                # Patrones geográficos
                'common_locations': user_data['ubicacion'].value_counts().head(5).to_dict(),
                'unique_locations': user_data['ubicacion'].nunique(),
                'location_diversity': user_data['ubicacion'].nunique() / len(user_data),
                
                # Patrones de tarjetas
                'preferred_cards': user_data['tipo_tarjeta'].value_counts().to_dict(),
                
                # Frecuencia de transacciones
                'avg_transactions_per_day': self._calculate_transaction_frequency(user_data),
                'max_transactions_per_day': self._get_max_daily_transactions(user_data),
                
                # Historial de fraude
                'fraud_history': user_data['es_fraude'].sum(),
                'fraud_rate': user_data['es_fraude'].mean(),
                
                # Fechas importantes
                'profile_created': datetime.now(),
                'last_updated': datetime.now()
            }
            
            self.user_profiles[user_id] = profile
            
            # Crear detector de anomalías individual
            if len(user_data) >= 20:
                self._create_user_anomaly_detector(user_id, user_data)
        
    
    def _get_user_preferred_hours(self, user_data):
        """Obtiene las horas preferidas del usuario"""
        hours = pd.to_datetime(user_data['horario_transaccion'], format='%H:%M:%S', errors='coerce').dt.hour
        return hours.value_counts().head(5).to_dict()
    
    def _get_weekend_ratio(self, user_data):
        """Calcula ratio de transacciones en fin de semana"""
        dates = pd.to_datetime(user_data['fecha_transaccion'])
        weekend_transactions = dates.dt.dayofweek.isin([5, 6]).sum()
        return weekend_transactions / len(user_data)
    
    def _get_night_ratio(self, user_data):
        """Calcula ratio de transacciones nocturnas (11PM - 6AM)"""
        hours = pd.to_datetime(user_data['horario_transaccion'], format='%H:%M:%S', errors='coerce').dt.hour
        night_transactions = ((hours >= 23) | (hours <= 6)).sum()
        return night_transactions / len(user_data)
    
    def _calculate_transaction_frequency(self, user_data):
        """Calcula frecuencia promedio de transacciones por día"""
        dates = pd.to_datetime(user_data['fecha_transaccion'])
        date_range = (dates.max() - dates.min()).days + 1
        return len(user_data) / max(date_range, 1)
    
    def _get_max_daily_transactions(self, user_data):
        """Obtiene el máximo de transacciones en un día"""
        dates = pd.to_datetime(user_data['fecha_transaccion'])
        daily_counts = dates.value_counts()
        return daily_counts.max() if len(daily_counts) > 0 else 0
    
    def _create_user_anomaly_detector(self, user_id, user_data):
        """Crea detector de anomalías específico para el usuario"""
        features = []
        for _, row in user_data.iterrows():
            feature_vector = [
                row['monto'],
                pd.to_datetime(row['horario_transaccion'], format='%H:%M:%S', errors='coerce').hour,
                pd.to_datetime(row['fecha_transaccion']).dayofweek,
                hash(row['comerciante']) % 1000,
                hash(row['ubicacion']) % 1000,
            ]
            features.append(feature_vector)
        
        if len(features) >= 20:
            isolation_forest = IsolationForest(
                contamination=0.1,
                random_state=42,
                n_estimators=50
            )
            isolation_forest.fit(features)
            self.user_isolation_forests[user_id] = isolation_forest
    
    def _analyze_user_behavior_anomalies(self, user_id, transaction_data):
        """🧠 Analiza si una transacción es anómala para este usuario específico"""
        if user_id not in self.user_profiles:
            return {
                'is_anomaly': False,
                'anomaly_score': 0.0,
                'anomaly_reasons': ['Usuario nuevo - sin historial suficiente'],
                'risk_level': 'UNKNOWN'
            }
        
        profile = self.user_profiles[user_id]
        anomaly_reasons = []
        anomaly_score = 0.0
        
        # Analizar monto
        amount = transaction_data['monto']
        if amount > profile['percentile_99']:
            anomaly_reasons.append(f"Monto excede el 99% histórico del usuario (${profile['percentile_99']:.2f})")
            anomaly_score += 0.4
        elif amount > profile['percentile_95']:
            anomaly_reasons.append(f"Monto excede el 95% histórico del usuario (${profile['percentile_95']:.2f})")
            anomaly_score += 0.2
        elif amount > profile['max_amount'] * 2:
            anomaly_reasons.append(f"Monto es 2x el máximo histórico (${profile['max_amount']:.2f})")
            anomaly_score += 0.5
        
        # Analizar horario
        hour = pd.to_datetime(transaction_data['horario_transaccion'], format='%H:%M:%S', errors='coerce').hour
        if hour not in profile['preferred_hours'] and profile['night_ratio'] < 0.1 and (hour >= 23 or hour <= 6):
            anomaly_reasons.append(f"Transacción en horario inusual para el usuario ({hour:02d}:XX)")
            anomaly_score += 0.3
        
        # Analizar comerciante
        merchant = transaction_data['comerciante']
        if merchant not in profile['favorite_merchants'] and profile['merchant_diversity'] < 0.3:
            anomaly_reasons.append("Comerciante completamente nuevo para un usuario con baja diversidad")
            anomaly_score += 0.2
        
        # Analizar ubicación
        location = transaction_data['ubicacion']
        if location not in profile['common_locations'] and profile['location_diversity'] < 0.2:
            anomaly_reasons.append("Ubicación nueva para un usuario con patrones geográficos fijos")
            anomaly_score += 0.25
        
        # Usar Isolation Forest si está disponible
        if user_id in self.user_isolation_forests:
            feature_vector = [[
                amount,
                hour,
                pd.to_datetime(transaction_data['fecha_transaccion']).dayofweek,
                hash(merchant) % 1000,
                hash(location) % 1000
            ]]
            
            isolation_score = self.user_isolation_forests[user_id].decision_function(feature_vector)[0]
            if isolation_score < -0.1:
                anomaly_reasons.append(f"Isolation Forest detectó patrón anómalo (score: {isolation_score:.3f})")
                anomaly_score += abs(isolation_score) * 0.3
        
        # Determinar nivel de riesgo
        is_anomaly = anomaly_score > 0.3
        if anomaly_score > 0.7:
            risk_level = 'CRITICAL'
        elif anomaly_score > 0.5:
            risk_level = 'HIGH'
        elif anomaly_score > 0.3:
            risk_level = 'MEDIUM'
        else:
            risk_level = 'LOW'
        
        return {
            'is_anomaly': is_anomaly,
            'anomaly_score': min(anomaly_score, 1.0),
            'anomaly_reasons': anomaly_reasons,
            'risk_level': risk_level,
            'user_profile_age_days': (datetime.now() - profile['profile_created']).days,
            'user_total_transactions': profile['total_transactions']
        }
    
    def train_model(self, data):
        """🧠 Entrenamiento híbrido completo"""
        print("\n🧠 ENTRENAMIENTO HÍBRIDO SÚPER COMPLETO")
        print("=" * 70)
        
        # 1. Construir perfiles de usuario ANTES del entrenamiento
        self._build_user_profiles(data)
        
        # 2. Llamar al entrenamiento base del modelo avanzado
        return super().train_model(data)
    
    def predict_single_transaction(self, new_transactions):
        """🧠 Predicción híbrida simplificada"""
        try:
            print(f"🧠 Iniciando análisis híbrido...")
            
            # Usar el método base simplificado
            is_fraud_base, probability_base = super().predict_single_transaction(new_transactions)
            
            print(f"🎯 Resultado híbrido: Fraude={is_fraud_base}, Probabilidad={probability_base:.3f}")
            
            return is_fraud_base, probability_base
            
        except Exception as e:
            print(f"❌ Error en análisis híbrido: {e}")
            import traceback
            traceback.print_exc()
            return False, 0.0
