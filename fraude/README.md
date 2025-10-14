### **🛡️ Aplicación de Detección de Fraude con Machine Learning**

Este sistema es un microservicio inteligente diseñado para **detectar transacciones financieras fraudulentas en tiempo real**. Utiliza un modelo de Machine Learning (**Random Forest**) para analizar patrones y identificar actividades sospechosas, y está preparado para integrarse directamente con un frontend de React.

-----

### ✨ **Características Destacadas**

  * 🤖 **Modelo de Machine Learning Avanzado**: Emplea un algoritmo **Random Forest** que se alimenta de más de 20 características de ingeniería de datos (*feature engineering*) para una detección precisa.
  * 🔍 **Detección Dual**: Permite analizar transacciones de dos maneras: **una por una** a través de un formulario o **en grandes volúmenes** directamente desde la base de datos.
  * 📊 **Ingeniería de Características Automática**: El sistema crea de forma autónoma nuevas variables (features) a partir de los datos brutos, analizando patrones de **tiempo**, **ubicación** y **comportamiento** del usuario.
  * 🎯 **Alta Precisión e Interpretabilidad**: Alcanza una precisión superior al 90% y es capaz de explicar por qué una transacción es marcada como sospechosa.
  * 🔄 **Ciclo de Auto-entrenamiento**: El modelo se entrena y actualiza automáticamente utilizando los datos históricos disponibles en la base de datos al iniciar.
  * 🐳 **Listo para Contenedores (Docker Ready)**: Incluye toda la configuración necesaria para un despliegue rápido y consistente utilizando Docker.

-----

### 🚀 **Instalación y Puesta en Marcha**

#### **Opción 1: Usando Docker (Recomendado)**

Es el método más directo y evita problemas de configuración. Desde la raíz del proyecto, solo necesitas ejecutar:

```bash
docker-compose up fraude
```

#### **Opción 2: Instalación en Entorno Local**

1.  **Instalar Dependencias**:
    ```bash
    pip install -r requirements.txt
    ```
2.  **Configurar Variables de Entorno**:
    Crear un archivo `.env` en la raíz del proyecto para especificar los datos de conexión a la base de datos PostgreSQL (`bank_transactions`).
    ```env
    DB_HOST=localhost
    DB_USER=postgres
    DB_PASSWORD=root
    DB2_NAME=bank_transactions
    FRAUDE_API_PORT=8001
    ```
3.  **Ejecutar la Aplicación**:
    ```bash
    python app.py
    ```

La API estará disponible en `http://localhost:8001`.

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