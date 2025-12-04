# 🤖 IBM AI Platform Backend

Plataforma de inteligencia artificial con múltiples modelos LLM, PostgreSQL y APIs especializadas.

## ⚡ Instalación

```bash
# Clonar repositorio
git clone https://github.com/Junstant/IBM-AI-Platform-Back.git
cd IBM-AI-Platform-Back

# Crear archivo .env con configuración requerida
# (FRONT_DIR, BACK_DIR, DB_PASSWORD, TOKEN_HUGGHINGFACE, DEFAULT_PORTS)

# Ejecutar instalación automática
chmod +x setup.sh
sudo ./setup.sh full
```

## 🎯 Servicios

- **Frontend**: `http://localhost:2012`
- **API Fraude**: `http://localhost:8001/docs`
- **API TextoSQL**: `http://localhost:8000/docs`
- **API Stats**: `http://localhost:8003/docs`
- **API RAG**: `http://localhost:8004/docs`
- **PostgreSQL**: `localhost:8070`
- **Milvus**: `localhost:19530`

## 🧠 Modelos LLM

| Modelo | Puerto | Tamaño | Especialidad |
|--------|--------|---------|--------------|
| **Gemma 2B** | 8085 | ~1.5GB | Respuestas rápidas |
| **Gemma 4B** | 8086 | ~3GB | Equilibrio velocidad/calidad |
| **Gemma 12B** | 8087 | ~8GB | Alta precisión |
| **Mistral 7B** | 8088 | ~5GB | Tareas generales |
| **DeepSeek 8B** | 8089 | ~6GB | Razonamiento lógico |

## 📝 Comandos Útiles

```bash
# Ver logs de servicios
docker-compose logs -f [servicio]

# Reiniciar servicios
docker-compose restart

# Ver estado
docker-compose ps

# Parar servicios
docker-compose down

# Ver uso de recursos
docker stats
```

## 🤝 Contribuir

Lee [CONTRIBUTING.md](CONTRIBUTING.md) para conocer las guías de contribución.

## 📄 Licencia

Este proyecto está bajo la licencia MIT - ver [LICENSE](LICENSE) para más detalles.