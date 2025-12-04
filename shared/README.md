# Shared Utilities

Módulos y utilidades compartidas entre los diferentes servicios de la plataforma.

## Contenido

### `stats_reporter.py`
Middleware de FastAPI para reportar métricas automáticamente al Stats API.

**Uso**:
```python
from shared.stats_reporter import StatsReporterMiddleware

app.add_middleware(
    StatsReporterMiddleware,
    service_name="mi-servicio",
    stats_api_url="http://stats-api:8003"
)
```

### `toon_encoder.py`
Utilidad para codificación TOON (si aplica).

## Instalación

Estos módulos se importan directamente desde el directorio `shared/` en cada servicio.
