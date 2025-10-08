#!/usr/bin/env python3
"""
🧠 GENERADOR DE DATOS SÚPER REALISTA CON IA
Crea transacciones que imitan el comportamiento real del mundo.
"""

import psycopg2
import random
import numpy as np
from datetime import datetime, timedelta
import json
import os
from dotenv import load_dotenv

load_dotenv()

# Configuración de la base de datos usando variables de entorno
DB_NAME = os.getenv("DB_NAME_FRAUDE", "bank_transactions")
DB_USER = os.getenv("DB_USER", "postgres")
DB_PASS = os.getenv("DB_PASSWORD", "root")
DB_HOST = os.getenv("DB_HOST")  # Usar host desde .env
DB_PORT = os.getenv("DB_PORT")

class RealisticFraudGenerator:
    """🧠 Generador inteligente de transacciones súper realistas"""
    
    def __init__(self):
        # 🏪 Comerciantes realistas con probabilidades de fraude variables
        self.legitimate_merchants = [
            "McDonald's", "Starbucks", "Amazon", "Walmart", "Target", "Costco",
            "Shell Gas", "BP Gas Station", "Chevron", "7-Eleven", "Subway",
            "Best Buy", "Home Depot", "Lowe's", "CVS Pharmacy", "Walgreens",
            "Apple Store", "Nike Store", "Adidas", "H&M", "Zara", "Macy's",
            "Whole Foods", "Trader Joe's", "Kroger", "Safeway", "Local Cafe",
            "Pizza Hut", "Domino's Pizza", "KFC", "Taco Bell", "Chipotle",
            "Netflix", "Spotify", "YouTube Premium", "Adobe", "Microsoft",
            "Local Restaurant", "Hotel Booking", "Airbnb", "Uber", "Lyft"
        ]
        
        # 🚨 Comerciantes con patrones sospechosos (no obvios)
        self.suspicious_merchants = [
            "QuickCash ATM", "International Transfer", "Overseas Purchase",
            "Unknown Merchant", "Cash Advance", "Foreign Exchange",
            "Online Casino", "Crypto Exchange", "Wire Transfer Service",
            "Prepaid Card Service", "Money Transfer", "Digital Wallet Top-up"
        ]
        
        # 📍 Ubicaciones realistas
        self.legitimate_locations = [
            "New York, NY", "Los Angeles, CA", "Chicago, IL", "Houston, TX",
            "Phoenix, AZ", "Philadelphia, PA", "San Antonio, TX", "San Diego, CA",
            "Dallas, TX", "San Jose, CA", "Austin, TX", "Jacksonville, FL",
            "Fort Worth, TX", "Columbus, OH", "Charlotte, NC", "Seattle, WA",
            "Denver, CO", "Boston, MA", "El Paso, TX", "Detroit, MI"
        ]
        
        self.suspicious_locations = [
            "Lagos, Nigeria", "Unknown Location", "Moscow, Russia", 
            "Beijing, China", "Mumbai, India", "Istanbul, Turkey",
            "Offshore Location", "Remote Server", "VPN Location",
            "Tor Network", "Anonymous Proxy", "Foreign ATM"
        ]
        
        # 💳 Tipos de tarjeta con probabilidades realistas
        self.card_types = ["Visa", "Mastercard", "American Express", "Discover"]
        
        # 🎯 Patrones de comportamiento realista
        self.user_profiles = self._generate_user_profiles()
        
    def _generate_user_profiles(self):
        """🧠 Genera perfiles de comportamiento de usuario súper realistas"""
        profiles = {}
        
        # Perfil 1: Usuario conservador (bajo riesgo)
        profiles['conservative'] = {
            'avg_transaction': (20, 150),  # rango promedio
            'max_transaction': 1000,
            'preferred_times': [(7, 9), (12, 14), (17, 22)],  # horarios normales
            'fraud_likelihood': 0.001,  # 0.1%
            'merchant_preference': 'mainstream',
            'location_variance': 0.1  # poca variación geográfica
        }
        
        # Perfil 2: Usuario activo (riesgo medio)
        profiles['active'] = {
            'avg_transaction': (50, 500),
            'max_transaction': 3000,
            'preferred_times': [(6, 23)],  # más flexible
            'fraud_likelihood': 0.02,  # 2%
            'merchant_preference': 'mixed',
            'location_variance': 0.3
        }
        
        # Perfil 3: Usuario de alto volumen (riesgo alto pero legítimo)
        profiles['high_volume'] = {
            'avg_transaction': (100, 2000),
            'max_transaction': 10000,
            'preferred_times': [(0, 23)],  # cualquier hora
            'fraud_likelihood': 0.05,  # 5%
            'merchant_preference': 'business',
            'location_variance': 0.5
        }
        
        # Perfil 4: Usuario comprometido (alta probabilidad de fraude)
        profiles['compromised'] = {
            'avg_transaction': (500, 5000),
            'max_transaction': 50000,
            'preferred_times': [(0, 6), (22, 23)],  # horas sospechosas
            'fraud_likelihood': 0.8,  # 80%
            'merchant_preference': 'suspicious',
            'location_variance': 0.9
        }
        
        return profiles
    
    def _get_realistic_merchant(self, profile_type, is_fraud):
        """🧠 Selecciona comerciante basado en perfil y tipo de transacción"""
        if is_fraud:
            if random.random() < 0.7:  # 70% de fraudes en comerciantes sospechosos
                return random.choice(self.suspicious_merchants)
            else:  # 30% de fraudes en comerciantes legítimos (más realista)
                return random.choice(self.legitimate_merchants)
        else:
            if profile_type == 'compromised':
                # Usuario comprometido a veces hace transacciones normales
                return random.choice(self.legitimate_merchants + self.suspicious_merchants[:3])
            else:
                return random.choice(self.legitimate_merchants)
    
    def _get_realistic_location(self, profile_type, is_fraud):
        """🧠 Selecciona ubicación basada en perfil y tipo de transacción"""
        if is_fraud:
            if random.random() < 0.6:  # 60% de fraudes en ubicaciones sospechosas
                return random.choice(self.suspicious_locations)
            else:
                return random.choice(self.legitimate_locations)
        else:
            if profile_type == 'compromised':
                # Usuario comprometido a veces transacciona en ubicaciones raras
                if random.random() < 0.3:
                    return random.choice(self.suspicious_locations)
            return random.choice(self.legitimate_locations)
    
    def _get_realistic_amount(self, profile_type, is_fraud):
        """🧠 Genera monto realista basado en perfil y tipo de transacción"""
        profile = self.user_profiles[profile_type]
        
        if is_fraud:
            # Fraudes tienden a ser más altos, pero no siempre
            if random.random() < 0.6:  # 60% de fraudes son altos
                return round(random.uniform(1000, profile['max_transaction']), 2)
            else:  # 40% de fraudes son pequeños (más realista)
                return round(random.uniform(profile['avg_transaction'][0], 
                                          profile['avg_transaction'][1] * 2), 2)
        else:
            # Transacciones normales siguen distribución normal
            mean = sum(profile['avg_transaction']) / 2
            std = mean * 0.5
            amount = max(1.0, np.random.normal(mean, std))
            return round(min(amount, profile['max_transaction']), 2)
    
    def _get_realistic_time(self, profile_type, is_fraud):
        """🧠 Genera horario realista basado en perfil y comportamiento"""
        profile = self.user_profiles[profile_type]
        
        if is_fraud:
            # Fraudes tienden a ocurrir en horas inusuales
            if random.random() < 0.4:  # 40% en horas sospechosas
                hour = random.choice([1, 2, 3, 4, 5, 23])
            else:
                hour = random.randint(0, 23)
        else:
            # Transacciones normales siguen patrones del perfil
            time_ranges = profile['preferred_times']
            selected_range = random.choice(time_ranges)
            hour = random.randint(selected_range[0], selected_range[1])
        
        minute = random.randint(0, 59)
        second = random.randint(0, 59)
        return f"{hour:02d}:{minute:02d}:{second:02d}"
    
    def generate_realistic_transactions(self, num_transactions=10000):
        """🧠 Genera transacciones súper realistas con patrones complejos"""
        transactions = []
        
        print(f"🧠 Generando {num_transactions} transacciones súper realistas...")
        
        # Distribución de perfiles de usuario
        profile_distribution = {
            'conservative': 0.4,  # 40% usuarios conservadores
            'active': 0.35,       # 35% usuarios activos
            'high_volume': 0.2,   # 20% usuarios de alto volumen
            'compromised': 0.05   # 5% usuarios comprometidos
        }
        
        for i in range(num_transactions):
            # Seleccionar perfil de usuario
            rand = random.random()
            cumulative = 0
            selected_profile = 'conservative'
            
            for profile, prob in profile_distribution.items():
                cumulative += prob
                if rand <= cumulative:
                    selected_profile = profile
                    break
            
            # Determinar si es fraude basado en el perfil
            profile_data = self.user_profiles[selected_profile]
            is_fraud = random.random() < profile_data['fraud_likelihood']
            
            # Aplicar factores adicionales de realismo
            if not is_fraud:
                # Pequeña probabilidad de fraude incluso en perfiles seguros
                is_fraud = random.random() < 0.001
            
            # Generar componentes de la transacción
            merchant = self._get_realistic_merchant(selected_profile, is_fraud)
            location = self._get_realistic_location(selected_profile, is_fraud)
            amount = self._get_realistic_amount(selected_profile, is_fraud)
            time_str = self._get_realistic_time(selected_profile, is_fraud)
            card_type = random.choice(self.card_types)
            
            # Generar fecha realista (últimos 6 meses)
            transaction_date = datetime.now() - timedelta(
                days=random.randint(0, 180)
            )
            
            # Seleccionar cuentas aleatorias
            cuenta_origen = random.randint(1, 50)
            cuenta_destino = random.randint(1, 50)
            
            transactions.append((
                cuenta_origen, cuenta_destino, amount, merchant, location,
                card_type, time_str, transaction_date.date(), is_fraud
            ))
            
            if (i + 1) % 1000 == 0:
                print(f"   Generadas {i + 1}/{num_transactions} transacciones...")
        
        # Estadísticas de generación
        fraud_count = sum(1 for t in transactions if t[8])
        fraud_percentage = (fraud_count / num_transactions) * 100
        
        print(f"✅ Generación completa:")
        print(f"   Total: {num_transactions} transacciones")
        print(f"   Fraudes: {fraud_count} ({fraud_percentage:.2f}%)")
        print(f"   Legítimas: {num_transactions - fraud_count} ({100 - fraud_percentage:.2f}%)")
        
        return transactions

def get_db_connection():
    """Conecta a la base de datos usando variables de entorno"""
    try:
        conn = psycopg2.connect(
            dbname=DB_NAME, user=DB_USER, password=DB_PASS, host=DB_HOST, port=DB_PORT
        )
        return conn
    except psycopg2.OperationalError as e:
        print(f"❌ Error al conectar a la base de datos: {e}")
        return None

def clear_existing_data():
    """Limpia datos existentes para empezar fresh"""
    conn = get_db_connection()
    if not conn:
        return False
    
    try:
        cur = conn.cursor()
        # Limpiar también las secuencias para evitar conflictos
        cur.execute("TRUNCATE TABLE transacciones RESTART IDENTITY CASCADE;")
        conn.commit()
        print("🗑️ Datos existentes eliminados completamente")
        return True
    except Exception as e:
        print(f"❌ Error al limpiar datos: {e}")
        conn.rollback()
        return False
    finally:
        cur.close()
        conn.close()

def insert_realistic_transactions(transactions):
    """Inserta las transacciones realistas en la base de datos"""
    conn = get_db_connection()
    if not conn:
        return False

    cur = conn.cursor()
    
    # Incluir todos los campos necesarios, dejar que numero_transaccion se auto-genere
    sql = """
        INSERT INTO transacciones (
            cuenta_origen_id, cuenta_destino_id, monto, comerciante, ubicacion,
            tipo_tarjeta, horario_transaccion, fecha_transaccion, es_fraude,
            canal, categoria_comerciante, ciudad, pais
        ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, 'pos', 'general', 'Buenos Aires', 'Argentina');
    """
    
    try:
        # Insertar por lotes para mejor rendimiento
        batch_size = 1000
        total_inserted = 0
        
        for i in range(0, len(transactions), batch_size):
            batch = transactions[i:i+batch_size]
            cur.executemany(sql, batch)
            conn.commit()
            total_inserted += len(batch)
            if total_inserted % 2000 == 0 or total_inserted == len(transactions):
                print(f"   ✓ Insertadas {total_inserted}/{len(transactions)} transacciones...")
        
        print(f"✅ Se insertaron {len(transactions)} transacciones realistas exitosamente.")
        return True
        
    except Exception as e:
        print(f"❌ Error al insertar transacciones: {e}")
        print(f"   Tipo de error: {type(e).__name__}")
        
        # Si hay error de duplicado, intentar limpiar y reintentar una vez
        if "duplicate key" in str(e).lower():
            print("🔄 Detectado conflicto de claves, limpiando e intentando nuevamente...")
            conn.rollback()
            cur.close()
            conn.close()
            
            # Limpiar datos y reintentar
            clear_existing_data()
            return insert_realistic_transactions(transactions)
        
        conn.rollback()
        return False
    finally:
        cur.close()
        conn.close()

def main():
    """🧠 Función principal para generar datos súper realistas"""
    print("🧠 INICIANDO GENERADOR DE DATOS SÚPER REALISTA CON IA")
    print("=" * 60)
    
    # Limpiar datos existentes
    print("🧹 Limpiando datos anteriores...")
    if not clear_existing_data():
        print("❌ No se pudieron limpiar los datos existentes")
        return
    
    # Generar nuevos datos realistas
    generator = RealisticFraudGenerator()
    transactions = generator.generate_realistic_transactions(15000)  # Más datos
    
    # Insertar en base de datos
    print("\n💾 Insertando en base de datos...")
    if insert_realistic_transactions(transactions):
        print("\n🎉 ¡DATOS SÚPER REALISTAS GENERADOS EXITOSAMENTE!")
        print("🧠 El modelo ahora tendrá patrones complejos para aprender")
    else:
        print("❌ Error al insertar datos")

if __name__ == "__main__":
    main()
