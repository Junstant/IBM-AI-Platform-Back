-- 04-bank-transactions-schema.sql
-- Esquema para la base de datos de detección de fraude

\echo '🔍 Configurando esquema para bank_transactions...'

\c bank_transactions;

-- Crear extensiones útiles
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ===== TABLA PRINCIPAL DE TRANSACCIONES =====
CREATE TABLE IF NOT EXISTS transacciones (
    id SERIAL PRIMARY KEY,
    numero_transaccion VARCHAR(50) UNIQUE NOT NULL DEFAULT 'TXN-' || EXTRACT(EPOCH FROM NOW())::BIGINT,
    cuenta_origen_id INTEGER NOT NULL,
    cuenta_destino_id INTEGER,
    monto DECIMAL(12,2) NOT NULL,
    comerciante VARCHAR(255) NOT NULL,
    categoria_comerciante VARCHAR(100),
    ubicacion VARCHAR(255) NOT NULL,
    ciudad VARCHAR(100),
    pais VARCHAR(50) DEFAULT 'Argentina',
    tipo_tarjeta VARCHAR(50) NOT NULL,
    numero_tarjeta_hash VARCHAR(64), -- Hash de la tarjeta para seguridad
    horario_transaccion TIME NOT NULL,
    fecha_transaccion DATE NOT NULL,
    timestamp_transaccion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    es_fraude BOOLEAN NOT NULL DEFAULT FALSE,
    
    -- Campos adicionales para análisis de fraude
    monto_cuenta_origen DECIMAL(12,2), -- Saldo antes de la transacción
    distancia_ubicacion_usual DECIMAL(8,2), -- Distancia de ubicación usual del usuario
    frecuencia_comerciante INTEGER DEFAULT 0, -- Veces que compró en este comerciante
    tiempo_desde_ultima_transaccion INTEGER, -- Minutos desde última transacción
    
    -- Indicadores de riesgo
    transaccion_internacional BOOLEAN DEFAULT FALSE,
    horario_inusual BOOLEAN DEFAULT FALSE,
    monto_inusual BOOLEAN DEFAULT FALSE,
    ubicacion_inusual BOOLEAN DEFAULT FALSE,
    
    -- Metadatos
    canal VARCHAR(50) DEFAULT 'pos', -- pos, atm, online, mobile
    tipo_autenticacion VARCHAR(50), -- chip, swipe, contactless, pin
    codigo_respuesta VARCHAR(10),
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ===== TABLA PERFILES DE USUARIO =====
CREATE TABLE IF NOT EXISTS perfiles_usuario (
    id SERIAL PRIMARY KEY,
    cuenta_id INTEGER UNIQUE NOT NULL,
    ubicacion_usual VARCHAR(255),
    horario_usual_inicio TIME,
    horario_usual_fin TIME,
    monto_promedio DECIMAL(10,2),
    monto_maximo_historico DECIMAL(12,2),
    comerciantes_frecuentes TEXT[], -- Array de comerciantes frecuentes
    frecuencia_transacciones_diaria DECIMAL(4,2), -- Promedio de transacciones por día
    ultima_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ===== TABLA COMERCIANTES =====
CREATE TABLE IF NOT EXISTS comerciantes (
    id SERIAL PRIMARY KEY,
    codigo_comerciante VARCHAR(50) UNIQUE NOT NULL,
    nombre VARCHAR(255) NOT NULL,
    categoria VARCHAR(100),
    subcategoria VARCHAR(100),
    ubicacion VARCHAR(255),
    ciudad VARCHAR(100),
    pais VARCHAR(50),
    nivel_riesgo VARCHAR(20) DEFAULT 'bajo', -- bajo, medio, alto
    transacciones_fraudulentas INTEGER DEFAULT 0,
    total_transacciones INTEGER DEFAULT 0,
    tasa_fraude DECIMAL(5,4) GENERATED ALWAYS AS 
        (CASE WHEN total_transacciones > 0 
         THEN transacciones_fraudulentas::DECIMAL / total_transacciones 
         ELSE 0 END) STORED,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ===== TABLA ALERTAS DE FRAUDE =====
CREATE TABLE IF NOT EXISTS alertas_fraude (
    id SERIAL PRIMARY KEY,
    transaccion_id INTEGER REFERENCES transacciones(id),
    tipo_alerta VARCHAR(100) NOT NULL,
    nivel_riesgo VARCHAR(20) NOT NULL, -- bajo, medio, alto, crítico
    puntuacion_riesgo DECIMAL(5,2), -- 0.00 a 100.00
    descripcion TEXT,
    reglas_activadas TEXT[], -- Array de reglas que se activaron
    estado VARCHAR(20) DEFAULT 'pendiente', -- pendiente, investigando, resuelto, falso_positivo
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_resolucion TIMESTAMP,
    investigador VARCHAR(100),
    observaciones TEXT
);

-- ===== TABLA REGLAS DE FRAUDE =====
CREATE TABLE IF NOT EXISTS reglas_fraude (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) UNIQUE NOT NULL,
    descripcion TEXT,
    condicion TEXT NOT NULL, -- Condición SQL o descripción lógica
    peso DECIMAL(3,2) DEFAULT 1.00, -- Peso en el cálculo de score
    activa BOOLEAN DEFAULT TRUE,
    categoria VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ===== TABLA HISTORIAL DE MODELOS =====
CREATE TABLE IF NOT EXISTS historial_modelos (
    id SERIAL PRIMARY KEY,
    version_modelo VARCHAR(20) NOT NULL,
    fecha_entrenamiento TIMESTAMP NOT NULL,
    precision_modelo DECIMAL(5,4),
    recall_modelo DECIMAL(5,4),
    f1_score DECIMAL(5,4),
    auc_score DECIMAL(5,4),
    parametros JSONB,
    activo BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ===== FUNCIONES AUXILIARES =====

-- Función para calcular distancia aproximada entre dos ubicaciones
CREATE OR REPLACE FUNCTION calcular_distancia_aprox(
    ubicacion1 VARCHAR(255),
    ubicacion2 VARCHAR(255)
) RETURNS DECIMAL(8,2) AS $$
BEGIN
    -- Implementación simplificada basada en similitud de strings
    -- En producción, usar coordenadas GPS reales
    CASE 
        WHEN ubicacion1 = ubicacion2 THEN RETURN 0.0;
        WHEN POSITION(SPLIT_PART(ubicacion1, ',', 1) IN ubicacion2) > 0 THEN RETURN 5.0;
        ELSE RETURN 50.0;
    END CASE;
END;
$$ LANGUAGE plpgsql;

-- Función para actualizar perfil de usuario
CREATE OR REPLACE FUNCTION actualizar_perfil_usuario(cuenta_id_param INTEGER)
RETURNS VOID AS $$
DECLARE
    ubicacion_freq VARCHAR(255);
    horario_inicio TIME;
    horario_fin TIME;
    monto_avg DECIMAL(10,2);
    monto_max DECIMAL(12,2);
    freq_diaria DECIMAL(4,2);
BEGIN
    -- Calcular estadísticas del usuario
    SELECT 
        MODE() WITHIN GROUP (ORDER BY ubicacion),
        MIN(horario_transaccion),
        MAX(horario_transaccion),
        AVG(monto),
        MAX(monto),
        COUNT(*)::DECIMAL / NULLIF(EXTRACT(DAY FROM MAX(fecha_transaccion) - MIN(fecha_transaccion)), 0)
    INTO ubicacion_freq, horario_inicio, horario_fin, monto_avg, monto_max, freq_diaria
    FROM transacciones 
    WHERE cuenta_origen_id = cuenta_id_param 
      AND es_fraude = FALSE
      AND fecha_transaccion >= CURRENT_DATE - INTERVAL '90 days';

    -- Insertar o actualizar perfil
    INSERT INTO perfiles_usuario (
        cuenta_id, ubicacion_usual, horario_usual_inicio, horario_usual_fin,
        monto_promedio, monto_maximo_historico, frecuencia_transacciones_diaria,
        ultima_actualizacion
    ) VALUES (
        cuenta_id_param, ubicacion_freq, horario_inicio, horario_fin,
        monto_avg, monto_max, COALESCE(freq_diaria, 0), CURRENT_TIMESTAMP
    )
    ON CONFLICT (cuenta_id) DO UPDATE SET
        ubicacion_usual = EXCLUDED.ubicacion_usual,
        horario_usual_inicio = EXCLUDED.horario_usual_inicio,
        horario_usual_fin = EXCLUDED.horario_usual_fin,
        monto_promedio = EXCLUDED.monto_promedio,
        monto_maximo_historico = EXCLUDED.monto_maximo_historico,
        frecuencia_transacciones_diaria = EXCLUDED.frecuencia_transacciones_diaria,
        ultima_actualizacion = EXCLUDED.ultima_actualizacion;
END;
$$ LANGUAGE plpgsql;

-- ===== ÍNDICES PARA OPTIMIZACIÓN =====
CREATE INDEX idx_transacciones_fecha ON transacciones(fecha_transaccion);
CREATE INDEX idx_transacciones_cuenta_origen ON transacciones(cuenta_origen_id);
CREATE INDEX idx_transacciones_fraude ON transacciones(es_fraude);
CREATE INDEX idx_transacciones_comerciante ON transacciones(comerciante);
CREATE INDEX idx_transacciones_ubicacion ON transacciones(ubicacion);
CREATE INDEX idx_transacciones_timestamp ON transacciones(timestamp_transaccion);
CREATE INDEX idx_alertas_nivel_riesgo ON alertas_fraude(nivel_riesgo);
CREATE INDEX idx_alertas_estado ON alertas_fraude(estado);
CREATE INDEX idx_comerciantes_categoria ON comerciantes(categoria);

-- ===== TRIGGERS =====

-- Trigger para actualizar timestamp
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_transacciones_updated_at
    BEFORE UPDATE ON transacciones
    FOR EACH ROW EXECUTE FUNCTION update_timestamp();

\echo '✅ Esquema bank_transactions configurado exitosamente';