# 🛡️ API de Detección de Fraude - Documentación

## Descripción General

Esta API utiliza **Machine Learning (Random Forest)** para detectar fraudes en transacciones financieras. Puede analizar transacciones individuales o procesar masivamente toda la base de datos.

## 🚀 Características Principales

- **ML Inteligente**: Modelo Random Forest entrenado con patrones de fraude reales
- **Detección Dual**: Análisis individual y masivo de transacciones  
- **Feature Engineering**: Más de 20 características derivadas automáticamente
- **Interpretabilidad**: Razones específicas de por qué se detectó fraude
- **Auto-entrenamiento**: Se entrena automáticamente con datos existentes

## 📋 Endpoints Disponibles

### 1. **POST /predict_single_transaction**
Analiza una transacción individual para detectar fraude.

**Request Body:**
```json
{
  "monto": 1500.00,
  "comerciante": "COM001", 
  "ubicacion": "Buenos Aires, Argentina",
  "tipo_tarjeta": "Débito",
  "horario_transaccion": "14:30:00",
  "cuenta_origen_id": 1001,
  "categoria_comerciante": "Alimentación",
  "ciudad": "Buenos Aires", 
  "pais": "Argentina",
  "canal": "pos"
}
```

**Response:**
```json
{
  "prediccion_fraude": false,
  "probabilidad_fraude": 0.23,
  "nivel_riesgo": "LOW",
  "prediccion": "TRANSACCIÓN NORMAL",
  "transaccion_enviada": { /* datos enviados */ },
  "timestamp": "2025-10-13T10:30:00",
  "razones_deteccion": ["Monto dentro del rango normal"],
  "confianza_modelo": 0.77
}
```

### 2. **GET /api/fraude/predict_all_from_db**  
Analiza todas las transacciones en la base de datos y devuelve solo las fraudulentas.

**Response:**
```json
{
  "transacciones_fraudulentas_encontradas": 156,
  "total_transacciones_analizadas": 10000,
  "tiempo_procesamiento": 2.45,
  "timestamp": "2025-10-13T10:35:00",
  "resultados": [
    {
      "id": 12345,
      "cuenta_origen_id": 1001,
      "cuenta_destino_id": 2002,
      "monto": 75000.00,
      "comerciante": "SUSP001",
      "ubicacion": "Online",
      "tipo_tarjeta": "Crédito",
      "fecha_transaccion": "2025-10-12",
      "horario_transaccion": "02:30:00",
      "probabilidad_fraude": 0.89,
      "nivel_riesgo": "HIGH",
      "prediccion": "FRAUDE",
      "es_fraude_real": true
    }
  ],
  "resumen_estadisticas": {
    "fraudes_reales_en_db": 145,
    "fraudes_detectados": 156,
    "precision_estimada": "92.3%",
    "tasa_deteccion": "1.56%"
  }
}
```

### 3. **GET /health**
Verificación del estado de la API.

**Response:**
```json
{
  "status": "healthy",
  "database_connection": "ok", 
  "model_status": "trained",
  "timestamp": "2025-10-13T10:30:00"
}
```

### 4. **POST /train_model**
Reentrenar el modelo con nuevos datos.

**Query Parameters:**
- `force`: boolean (default: false) - Forzar reentrenamiento

### 5. **GET /model_info**
Información del modelo actual.

## 🔧 Configuración de Base de Datos

La API se conecta automáticamente a PostgreSQL usando las variables de entorno:

```env
DB_HOST=localhost
DB_PORT=8070
DB_USER=postgres  
DB_PASSWORD=root
DB2_NAME=bank_transactions
```

## 🧠 Características del Modelo ML

### Características Automáticas Generadas:
1. **Monto**: Log, Z-score, percentiles
2. **Tiempo**: Hora, día semana, horarios de negocio
3. **Comerciante**: Nivel riesgo, categoría
4. **Geográfico**: País de riesgo, ubicaciones online
5. **Comportamental**: Ratios de saldo, patrones inusuales

### Umbrales de Detección:
- **HIGH RISK**: ≥ 70% probabilidad
- **MEDIUM RISK**: 30% - 70% probabilidad  
- **LOW RISK**: < 30% probabilidad

## 📊 Interpretación de Resultados

### Campos de Respuesta Importantes:

| Campo | Descripción | Ejemplo |
|-------|-------------|---------|
| `prediccion_fraude` | Predicción binaria | `true`/`false` |
| `probabilidad_fraude` | Probabilidad 0-1 | `0.85` (85%) |
| `nivel_riesgo` | Categoría de riesgo | `"HIGH"` |
| `razones_deteccion` | Lista de motivos | `["Monto muy alto", "Horario inusual"]` |

### Niveles de Riesgo:

- 🔴 **HIGH** (≥70%): Muy probable fraude, bloquear inmediatamente
- 🟡 **MEDIUM** (30-70%): Posible fraude, revisar manualmente  
- 🟢 **LOW** (<30%): Transacción normal, proceder

## 🚨 Patrones de Fraude Detectados

### Patrones Simples:
1. **Montos extremos** (>$75,000)
2. **Horarios inusuales** (1 AM - 6 AM) 
3. **Países de riesgo** (Nigeria, Rusia, Malta)
4. **Comerciantes sospechosos** (Crypto, Casinos online)

### Patrones Complejos:
1. **Secuencias rápidas** de transacciones pequeñas
2. **Desviación del comportamiento** histórico del usuario
3. **Combinación de factores** de riesgo medio
4. **Anomalías geográficas** (ubicaciones muy distantes)

## 🔄 Ciclo de Vida del Modelo

1. **Startup**: Carga modelo existente o entrena uno nuevo
2. **Predicción**: Procesa transacciones en tiempo real  
3. **Reentrenamiento**: Puede actualizar con nuevos datos
4. **Persistencia**: Guarda modelo en `/models/`

## 📁 Estructura de Archivos del Modelo

```
models/
├── fraud_detection_model.pkl    # Modelo Random Forest
├── label_encoders.pkl           # Codificadores categóricos
├── feature_scaler.pkl           # Escalador de características  
└── feature_names.pkl            # Nombres de características
```

## 🌐 Integración con Frontend

### Para el formulario individual:
```javascript
const response = await fetch('/predict_single_transaction', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    monto: parseFloat(monto),
    comerciante: comerciante,
    ubicacion: ubicacion,
    tipo_tarjeta: tipo_tarjeta,
    horario_transaccion: horario_transaccion
  })
});
```

### Para análisis masivo:
```javascript  
const response = await fetch('/api/fraude/predict_all_from_db');
const data = await response.json();
```

## ⚡ Rendimiento

- **Transacción individual**: < 50ms
- **Análisis masivo**: ~1000 transacciones/segundo
- **Precisión**: >90% en datos de prueba
- **Memoria**: ~200MB con modelo cargado

## 🐛 Manejo de Errores

La API devuelve errores HTTP estándar:

- **500**: Error interno (modelo no entrenado, DB desconectada)
- **422**: Datos de entrada inválidos
- **404**: Endpoint no encontrado

Ejemplo de error:
```json
{
  "detail": "Error interno: Modelo no entrenado. Ejecute train_model() primero."
}
```

## 📈 Métricas de Monitoreo

Consulte `/model_info` para obtener:
- Estado del modelo
- Número de características  
- Umbrales configurados
- Última actualización

## 🔐 Consideraciones de Seguridad

- La API no almacena datos sensibles de transacciones
- Todas las predicciones son stateless
- Los modelos se guardan localmente sin datos personales
- Logs no incluyen información financiera sensible