-- databases/bank_transactions/01-schema.sql
-- Esquema para detección de fraude - VERSIÓN CORREGIDA

\echo '🔍 Configurando esquema para bank_transactions (detección de fraude)...'

\c bank_transactions;

-- Crear extensiones útiles
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ===== TABLA PRINCIPAL DE TRANSACCIONES =====
CREATE TABLE IF NOT EXISTS transacciones (
    id SERIAL PRIMARY KEY,
    numero_transaccion VARCHAR(50) UNIQUE NOT NULL DEFAULT ('TXN-' || EXTRACT(epoch FROM CURRENT_TIMESTAMP)::bigint || '-' || FLOOR(RANDOM() * 10000)::int),
    cuenta_origen_id INTEGER NOT NULL,
    cuenta_destino_id INTEGER,
    monto DECIMAL(15,2) NOT NULL,
    comerciante VARCHAR(100),
    categoria_comerciante VARCHAR(100),
    ubicacion VARCHAR(255),
    ciudad VARCHAR(100),
    pais VARCHAR(100) DEFAULT 'Argentina',
    tipo_tarjeta VARCHAR(20) CHECK (tipo_tarjeta IN ('Débito', 'Crédito', 'Prepaga')),
    horario_transaccion TIME NOT NULL,
    fecha_transaccion DATE NOT NULL DEFAULT CURRENT_DATE,
    es_fraude BOOLEAN NOT NULL DEFAULT FALSE,
    canal VARCHAR(20) DEFAULT 'pos' CHECK (canal IN ('online', 'pos', 'atm', 'telefono', 'mobile')),
    monto_cuenta_origen DECIMAL(15,2),
    distancia_ubicacion_usual DECIMAL(8,2) DEFAULT 0,
    ip_address INET,
    dispositivo VARCHAR(100),
    autenticacion_exitosa BOOLEAN DEFAULT TRUE,
    intentos_fallidos INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_monto_positivo CHECK (monto > 0),
    CONSTRAINT chk_distancia_positiva CHECK (distancia_ubicacion_usual >= 0)
);

-- ===== TABLA COMERCIANTES =====
CREATE TABLE IF NOT EXISTS comerciantes (
    id SERIAL PRIMARY KEY,
    codigo_comerciante VARCHAR(20) UNIQUE NOT NULL,
    nombre VARCHAR(200) NOT NULL,
    categoria VARCHAR(100) NOT NULL,
    subcategoria VARCHAR(100),
    ubicacion VARCHAR(255),
    ciudad VARCHAR(100),
    pais VARCHAR(100) DEFAULT 'Argentina',
    nivel_riesgo VARCHAR(20) DEFAULT 'bajo' CHECK (nivel_riesgo IN ('bajo', 'medio', 'alto', 'crítico')),
    total_transacciones INTEGER DEFAULT 0,
    transacciones_fraudulentas INTEGER DEFAULT 0,
    tasa_fraude DECIMAL(5,4) DEFAULT 0.0000,
    activo BOOLEAN DEFAULT TRUE,
    fecha_registro DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ===== TABLA PERFILES DE USUARIO =====
CREATE TABLE IF NOT EXISTS perfiles_usuario (
    id SERIAL PRIMARY KEY,
    cuenta_id INTEGER UNIQUE NOT NULL,
    ubicacion_frecuente VARCHAR(255),
    comerciante_frecuente VARCHAR(100),
    horario_preferido_inicio TIME DEFAULT '08:00:00',
    horario_preferido_fin TIME DEFAULT '20:00:00',
    monto_promedio DECIMAL(15,2) DEFAULT 0,
    frecuencia_transaccional DECIMAL(4,2) DEFAULT 0,
    ratio_fin_semana DECIMAL(4,3) DEFAULT 0,
    ratio_noche DECIMAL(4,3) DEFAULT 0,
    max_transacciones_diarias INTEGER DEFAULT 0,
    total_transacciones INTEGER DEFAULT 0,
    fecha_primera_transaccion DATE,
    fecha_ultima_transaccion DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ===== TABLA ALERTAS DE FRAUDE =====
CREATE TABLE IF NOT EXISTS alertas_fraude (
    id SERIAL PRIMARY KEY,
    transaccion_id INTEGER NOT NULL REFERENCES transacciones(id),
    tipo_alerta VARCHAR(100) NOT NULL,
    nivel_riesgo VARCHAR(20) DEFAULT 'medio' CHECK (nivel_riesgo IN ('bajo', 'medio', 'alto', 'crítico')),
    puntuacion_riesgo DECIMAL(5,2) DEFAULT 0.50,
    descripcion TEXT,
    estado VARCHAR(20) DEFAULT 'pendiente' CHECK (estado IN ('pendiente', 'investigando', 'confirmado', 'falso_positivo', 'resuelto')),
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
    condicion JSONB NOT NULL,
    peso DECIMAL(3,2) DEFAULT 0.50,
    activa BOOLEAN DEFAULT TRUE,
    tipo_regla VARCHAR(50) DEFAULT 'automatica',
    umbral_activacion DECIMAL(5,2) DEFAULT 0.70,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ===== FUNCIONES AUXILIARES =====

-- Función para actualizar perfil de usuario
CREATE OR REPLACE FUNCTION actualizar_perfil_usuario(cuenta_id_param INTEGER)
RETURNS VOID AS $$
DECLARE
    ubicacion_freq VARCHAR(255);
    comerciante_freq VARCHAR(100);
    monto_prom DECIMAL(15,2);
    freq_diaria DECIMAL(4,2);
    ratio_weekend DECIMAL(4,3);
    ratio_night DECIMAL(4,3);
    max_daily_txn INTEGER;
    total_txn INTEGER;
    primera_fecha DATE;
    ultima_fecha DATE;
BEGIN
    -- Calcular estadísticas del usuario
    SELECT 
        mode() WITHIN GROUP (ORDER BY ubicacion),
        mode() WITHIN GROUP (ORDER BY comerciante),
        AVG(monto),
        COUNT(*)::DECIMAL / GREATEST(DATE_PART('days', MAX(fecha_transaccion) - MIN(fecha_transaccion)), 1),
        AVG(CASE WHEN EXTRACT(DOW FROM fecha_transaccion) IN (0,6) THEN 1.0 ELSE 0.0 END),
        AVG(CASE WHEN horario_transaccion BETWEEN '22:00:00' AND '06:00:00' THEN 1.0 ELSE 0.0 END),
        MAX(daily_count),
        COUNT(*),
        MIN(fecha_transaccion),
        MAX(fecha_transaccion)
    INTO ubicacion_freq, comerciante_freq, monto_prom, freq_diaria, ratio_weekend, ratio_night, max_daily_txn, total_txn, primera_fecha, ultima_fecha
    FROM (
        SELECT 
            *,
            COUNT(*) OVER (PARTITION BY fecha_transaccion) as daily_count
        FROM transacciones 
        WHERE cuenta_origen_id = cuenta_id_param
    ) t;
    
    -- Insertar o actualizar perfil
    INSERT INTO perfiles_usuario (
        cuenta_id, ubicacion_frecuente, comerciante_frecuente, monto_promedio,
        frecuencia_transaccional, ratio_fin_semana, ratio_noche, max_transacciones_diarias,
        total_transacciones, fecha_primera_transaccion, fecha_ultima_transaccion
    ) VALUES (
        cuenta_id_param, ubicacion_freq, comerciante_freq, monto_prom,
        freq_diaria, ratio_weekend, ratio_night, max_daily_txn,
        total_txn, primera_fecha, ultima_fecha
    )
    ON CONFLICT (cuenta_id) DO UPDATE SET
        ubicacion_frecuente = EXCLUDED.ubicacion_frecuente,
        comerciante_frecuente = EXCLUDED.comerciante_frecuente,
        monto_promedio = EXCLUDED.monto_promedio,
        frecuencia_transaccional = EXCLUDED.frecuencia_transaccional,
        ratio_fin_semana = EXCLUDED.ratio_fin_semana,
        ratio_noche = EXCLUDED.ratio_noche,
        max_transacciones_diarias = EXCLUDED.max_transacciones_diarias,
        total_transacciones = EXCLUDED.total_transacciones,
        fecha_ultima_transaccion = EXCLUDED.fecha_ultima_transaccion,
        fecha_actualizacion = CURRENT_TIMESTAMP;
END;
$$ LANGUAGE plpgsql;

-- Función para calcular riesgo de comerciante
CREATE OR REPLACE FUNCTION calcular_riesgo_comerciante()
RETURNS TRIGGER AS $$
BEGIN
    -- Actualizar estadísticas del comerciante
    UPDATE comerciantes SET
        total_transacciones = (
            SELECT COUNT(*) FROM transacciones 
            WHERE comerciante = comerciantes.codigo_comerciante
        ),
        transacciones_fraudulentas = (
            SELECT COUNT(*) FROM transacciones 
            WHERE comerciante = comerciantes.codigo_comerciante AND es_fraude = TRUE
        )
    WHERE codigo_comerciante = NEW.comerciante;
    
    -- Actualizar tasa de fraude
    UPDATE comerciantes SET
        tasa_fraude = CASE 
            WHEN total_transacciones > 0 THEN 
                transacciones_fraudulentas::DECIMAL / total_transacciones::DECIMAL
            ELSE 0
        END,
        nivel_riesgo = CASE
            WHEN tasa_fraude > 0.10 THEN 'crítico'
            WHEN tasa_fraude > 0.05 THEN 'alto'
            WHEN tasa_fraude > 0.02 THEN 'medio'
            ELSE 'bajo'
        END
    WHERE codigo_comerciante = NEW.comerciante;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ===== TRIGGERS =====
CREATE TRIGGER trigger_actualizar_comerciante
    AFTER INSERT OR UPDATE ON transacciones
    FOR EACH ROW
    EXECUTE FUNCTION calcular_riesgo_comerciante();

-- ===== ÍNDICES PARA OPTIMIZACIÓN =====
CREATE INDEX IF NOT EXISTS idx_transacciones_fecha ON transacciones(fecha_transaccion);
CREATE INDEX IF NOT EXISTS idx_transacciones_cuenta_origen ON transacciones(cuenta_origen_id);
CREATE INDEX IF NOT EXISTS idx_transacciones_fraude ON transacciones(es_fraude);
CREATE INDEX IF NOT EXISTS idx_transacciones_comerciante ON transacciones(comerciante);
CREATE INDEX IF NOT EXISTS idx_transacciones_ubicacion ON transacciones(ubicacion);
CREATE INDEX IF NOT EXISTS idx_transacciones_monto ON transacciones(monto);
CREATE INDEX IF NOT EXISTS idx_transacciones_canal ON transacciones(canal);
CREATE INDEX IF NOT EXISTS idx_transacciones_numero ON transacciones(numero_transaccion);
CREATE INDEX IF NOT EXISTS idx_comerciantes_codigo ON comerciantes(codigo_comerciante);
CREATE INDEX IF NOT EXISTS idx_comerciantes_riesgo ON comerciantes(nivel_riesgo);
CREATE INDEX IF NOT EXISTS idx_alertas_transaccion ON alertas_fraude(transaccion_id);
CREATE INDEX IF NOT EXISTS idx_alertas_nivel ON alertas_fraude(nivel_riesgo);
CREATE INDEX IF NOT EXISTS idx_perfiles_cuenta ON perfiles_usuario(cuenta_id);

\echo '✅ Esquema bank_transactions configurado exitosamente';