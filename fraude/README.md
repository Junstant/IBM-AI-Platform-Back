# Fraude API

Detección de fraude en transacciones financieras con Machine Learning.

## Características

- Modelo Random Forest con 20+ features
- Precisión >90% en detección de fraude
- Análisis individual y masivo
- Auto-entrenamiento con datos históricos

## Endpoints

**Puerto**: `http://localhost:8001/docs`

- `POST /predict` - Analizar transacción individual
- `POST /batch-predict` - Analizar múltiples transacciones
- `GET /model-info` - Información del modelo

## Uso

```bash
# Ejemplo de predicción
curl -X POST http://localhost:8001/predict \
  -H "Content-Type: application/json" \
  -d '{"monto": 5000, "ubicacion": "extranjero", "hora": 3}'
```

-----

### 📋 **Endpoints Principales de la API**

Puedes explorar todos los endpoints de forma interactiva en la documentación de Swagger: `http://localhost:8001/docs`.

  * `POST /predict_single_transaction`

      * **Función**: Analiza una única transacción enviada en formato JSON y devuelve un veredicto de fraude (Alto, Medio o Bajo riesgo).
      * **Ejemplo de Petición**:
        ```json
        {
          "monto": 1500.00,
          "comerciante": "COM001",
          "ubicacion": "Buenos Aires, Argentina"
        }
        ```

  * `GET /api/fraude/predict_all_from_db`

      * **Función**: Procesa todas las transacciones de la base de datos y devuelve una lista con las predicciones de fraude para cada una.

  * `POST /train_model?force=true`

      * **Función**: Fuerza el re-entrenamiento del modelo de Machine Learning utilizando los datos más recientes de la base de datos.

  * `GET /model_info`

      * **Función**: Devuelve información y métricas sobre el modelo actualmente cargado (precisión, fecha de entrenamiento, etc.).