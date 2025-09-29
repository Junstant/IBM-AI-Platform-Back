# main.py
from db import fetch_transactions
from model import FraudDetector

def main():
    """
    Función principal para ejecutar la aplicación de ML.
    """
    print("Obteniendo transacciones de la base de datos...")
    transactions_data = fetch_transactions()
    
    if transactions_data:
        print(f"Se encontraron {len(transactions_data)} transacciones.")
        
        detector = FraudDetector()
        
        # Paso 1: Preparar los datos
        processed_data = detector.prepare_data(transactions_data)
        
        # Paso 2: Entrenar el modelo con los datos
        print("\nEntrenando el modelo de Machine Learning...")
        detector.train_model(processed_data)
        
        # Paso 3: Usar el modelo para predecir en los mismos datos (para demostración)
        print("\nUsando el modelo para predecir fraude...")
        fraudulent_df = detector.predict_fraud(transactions_data)
        
        print("\n--- Resultados del Análisis con Machine Learning ---")
        print(f"Transacciones identificadas como fraudulentas: {len(fraudulent_df)}")
        
        if not fraudulent_df.empty:
            print("\nDetalles de las transacciones fraudulentas:")
            # Muestra las columnas más relevantes de los resultados
            print(fraudulent_df[['id', 'monto', 'comerciante', 'ubicacion', 'prediccion_fraude', 'es_fraude']])
    else:
        print("No se pudieron obtener transacciones.")

if __name__ == "__main__":
    main()