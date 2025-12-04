# 🗄️ PostgreSQL Database Configuration

## Descripción

PostgreSQL 17-alpine personalizado con:
- ✅ **pgvector v0.8.1** - Extensión para embeddings vectoriales (RAG)
- ✅ **Inicialización automática** - Scripts SQL ejecutados en primer despliegue
- ✅ **4 bases de datos** - banco_global, bank_transactions, ai_platform_stats, ai_platform_rag

## 🚀 Comportamiento de Inicialización

### Primera vez (volumen nuevo)
Cuando PostgreSQL inicia con un directorio de datos vacío:
1. ✅ Ejecuta TODOS los scripts en `/docker-entrypoint-initdb.d/` en orden alfabético
2. ✅ Crea las 4 bases de datos
3. ✅ Carga esquemas y datos iniciales
4. ✅ Inserta 17,507 transacciones para ML

### Reinicios posteriores (volumen existente)
Cuando PostgreSQL encuentra un directorio de datos con bases de datos:
1. ⚠️ **SALTA completamente** la carpeta `/docker-entrypoint-initdb.d/`
2. ⚠️ NO ejecuta ningún script de inicialización
3. ⚠️ Usa los datos existentes del volumen

**CRÍTICO**: Este es el comportamiento estándar de PostgreSQL y NO es un bug.

## 🔧 Solución Automática en setup.sh

El script `setup.sh` **destruye automáticamente** los volúmenes viejos antes de recrear PostgreSQL:

```bash
# setup.sh hace esto automáticamente:
1. Detener PostgreSQL
2. Eliminar contenedor postgres_db
3. Eliminar TODOS los volúmenes de PostgreSQL
4. Recrear PostgreSQL desde cero
5. Los init scripts se ejecutan automáticamente
```

## 📁 Estructura de Scripts de Inicialización

```
database/init-scripts/
├── 01-create-databases.sql          # ⭐ SCRIPT MAESTRO
│   ├── Crea 4 databases
│   ├── Se conecta a cada una
│   └── Ejecuta sus scripts específicos
│
└── databases/
    ├── banco_global/
    │   ├── 01-schema.sql             # Esquema TextoSQL
    │   └── 02-seed-data.sql          # Datos iniciales
    │
    ├── bank_transactions/
    │   ├── 01-schema.sql             # Esquema Fraude
    │   ├── 02-seed-data.sql          # Datos básicos
    │   └── 03-fraud-samples.sql      # 17,507 transacciones ML
    │
    ├── ai_platform_stats/
    │   └── 01-schema.sql             # Esquema Stats API
    │
    └── ai_platform_rag/
        └── 01-schema.sql             # Esquema RAG + pgvector
```

## 🛠️ Comandos Manuales (Troubleshooting)

### Verificar si init scripts se ejecutaron

```bash
# Ver logs de inicialización
docker logs postgres_db 2>&1 | grep -E '(🚀|📊|🏦|🔍|✅|PASO)'

# Si NO ves estos emojis → Los scripts NUNCA se ejecutaron
```

### Verificar bases de datos creadas

```bash
# Listar bases de datos
docker exec -i postgres_db psql -U postgres -l

# Debe mostrar:
# - banco_global
# - bank_transactions  
# - ai_platform_stats
# - ai_platform_rag
```

### Verificar tablas en cada base de datos

```bash
# Stats API
docker exec -i postgres_db psql -U postgres -d ai_platform_stats -c '\dt'
# Debe mostrar: ai_models_metrics, ai_queries_log, api_endpoints_metrics, etc.

# Fraude API
docker exec -i postgres_db psql -U postgres -d bank_transactions -c 'SELECT COUNT(*) FROM transacciones;'
# Debe mostrar: 17507 filas

# TextoSQL API
docker exec -i postgres_db psql -U postgres -d banco_global -c '\dt'
# Debe mostrar: clientes, cuentas, transacciones, etc.

# RAG API
docker exec -i postgres_db psql -U postgres -d ai_platform_rag -c '\dx'
# Debe mostrar extensión: vector (pgvector)
```

### Forzar recreación COMPLETA (DESTRUYE DATOS)

```bash
cd /root/BackAI

# Detener TODO
docker compose down

# Eliminar contenedor y volumen
docker rm -f postgres_db
docker volume rm aipl_postgres_data

# Recrear desde cero
docker compose up -d postgres

# Esperar inicialización
sleep 60

# Verificar logs
docker logs postgres_db 2>&1 | grep "✅ CONFIGURACIÓN COMPLETA"
```

## ⚠️ Problemas Comunes

### 1. "relation does not exist"

**Causa**: Volumen viejo encontrado, init scripts no ejecutados

**Solución automática**: `./setup.sh` elimina volúmenes antes de recrear

**Solución manual**: Ver sección "Forzar recreación COMPLETA"

### 2. "Skipping initialization" en logs

**Causa**: PostgreSQL detectó un directorio de datos existente

**Solución**: Los init scripts SOLO se ejecutan en inicialización limpia

### 3. Bases de datos existen pero sin tablas

**Causa**: Bases de datos creadas manualmente sin ejecutar schemas

**Solución**: Destruir volumen y recrear (setup.sh hace esto)

## 📊 Tablas Críticas por Servicio

| Servicio | Base de Datos | Tabla Principal | Propósito |
|----------|---------------|-----------------|-----------|
| Stats API | ai_platform_stats | ai_models_metrics | Métricas de modelos LLM |
| Stats API | ai_platform_stats | ai_queries_log | Log de queries a APIs |
| Fraude API | bank_transactions | transacciones | 17K+ transacciones para ML |
| Fraude API | bank_transactions | comerciantes | Comerciantes con nivel de riesgo |
| TextoSQL API | banco_global | clientes | Clientes del banco |
| TextoSQL API | banco_global | cuentas | Cuentas bancarias |
| RAG API | ai_platform_rag | documents | Metadata de documentos |
| RAG API | ai_platform_rag | (Milvus) | Vectores en Milvus externo |

## 🔐 Configuración de Acceso

```env
DB_HOST=postgres              # Nombre del servicio Docker
DB_PORT=5432                  # Puerto interno
DB_USER=postgres              # Usuario
DB_PASSWORD=root              # Contraseña
PGDATA=/var/lib/postgresql/data
```

## 🏗️ Arquitectura

```
┌─────────────────────────────────────────────┐
│  Docker Volume: aipl_postgres_data          │
│  └─ /var/lib/postgresql/data                │
│     ├─ base/                                 │
│     │  ├─ banco_global/                      │
│     │  ├─ bank_transactions/                 │
│     │  ├─ ai_platform_stats/                 │
│     │  └─ ai_platform_rag/                   │
│     └─ pg_wal/ (Write-Ahead Log)             │
└─────────────────────────────────────────────┘
                    ↑
                    │ Montado en
                    │
┌─────────────────────────────────────────────┐
│  Contenedor: postgres_db                    │
│  ├─ PostgreSQL 17-alpine                    │
│  ├─ pgvector v0.8.1                         │
│  └─ /docker-entrypoint-initdb.d/            │
│     └─ init-scripts/ (solo 1ra vez)         │
└─────────────────────────────────────────────┘
```

## 📝 Notas de Compatibilidad

- ✅ **Arquitectura**: Compatible con PPC64le (Power S1022)
- ✅ **OS**: CentOS 9 Stream
- ✅ **Compilación**: pgvector compilado sin bitcode (clang-19 no disponible)
- ✅ **Red Docker**: Usa red `ai_platform_network`
- ✅ **Puerto publicado**: 8070 (configurable vía .env)

## 🔄 Actualización de Esquemas

Si necesitas agregar/modificar esquemas en un deployment existente:

1. **NO RECOMENDADO**: Ejecutar SQL manualmente en contenedor
2. **RECOMENDADO**: Modificar scripts, destruir volumen, redeployar con `./setup.sh`

```bash
# Modificar schema en database/init-scripts/databases/*/01-schema.sql
vim database/init-scripts/databases/ai_platform_stats/01-schema.sql

# Redeployar (setup.sh destruye volúmenes automáticamente)
./setup.sh
```

---

**Mantenido por**: IBM AI Platform Backend Team  
**Última actualización**: 2025-12-04  
**Versión**: 1.0
