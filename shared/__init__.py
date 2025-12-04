"""
Módulos compartidos entre servicios de la plataforma AI.

Este paquete contiene utilidades y middlewares reutilizables:
- stats_reporter: Middleware para reportar métricas al Stats API
- toon_encoder: Utilidad para codificación TOON (si se usa)
"""

__version__ = "1.0.0"
__all__ = ['stats_reporter', 'toon_encoder']
