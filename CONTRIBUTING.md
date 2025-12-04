# Contribuyendo a IBM AI Platform Backend

¡Gracias por tu interés en contribuir! Este documento proporciona guías para contribuir al proyecto.

## 🚀 Proceso de Contribución

1. **Fork** del repositorio
2. **Clonar** tu fork localmente
3. **Crear rama** para tu feature: `git checkout -b feature/nombre-feature`
4. **Desarrollar** siguiendo las convenciones del proyecto
5. **Probar** exhaustivamente tus cambios
6. **Commit** con mensajes descriptivos
7. **Push** a tu fork: `git push origin feature/nombre-feature`
8. **Pull Request** al repositorio principal

## 📝 Convenciones de Código

### Python
- Seguir **PEP 8** para estilo de código
- Usar **type hints** cuando sea posible
- Docstrings en formato **Google Style**
- Máximo 100 caracteres por línea

### Commits
Usar **Conventional Commits**:
- `feat:` - Nueva funcionalidad
- `fix:` - Corrección de bug
- `docs:` - Cambios en documentación
- `refactor:` - Refactorización de código
- `test:` - Agregar o modificar tests
- `chore:` - Tareas de mantenimiento

Ejemplo: `feat: agregar soporte para modelo Llama 3`

## 🧪 Testing

Antes de crear un PR, asegúrate de:
- [ ] Ejecutar `docker-compose up -d` sin errores
- [ ] Verificar que todas las APIs respondan correctamente
- [ ] Probar endpoints modificados con requests de ejemplo
- [ ] Revisar logs en busca de errores

## 🏗️ Arquitectura

### Compatibilidad PPC64le
- **CRÍTICO**: Todas las soluciones deben ser compatibles con arquitectura Power PC (ppc64le)
- Usar repositorio de wheels: `https://repo.fury.io/mgiessing`
- Evitar dependencias que no tengan builds para ppc64le
- Probar en entorno CentOS 9 cuando sea posible

### Docker
- Todo debe funcionar con `./setup.sh full`
- No crear soluciones temporales o manuales
- Documentar cambios en docker-compose.yaml
- Optimizar uso de recursos (CPU/RAM limitados)

## 📚 Documentación

Al agregar nuevas features:
- Actualizar README.md relevante
- Agregar docstrings a funciones/clases
- Documentar variables de entorno en `.env`
- Incluir ejemplos de uso

## ⚠️ Importante

- **NO** commitear archivos `.env`
- **NO** commitear archivos de modelos (*.gguf, *.bin)
- **NO** commitear logs o dumps de bases de datos
- **SÍ** probar en ambiente limpio antes del PR

## 🤝 Código de Conducta

- Ser respetuoso y profesional
- Aceptar críticas constructivas
- Enfocarse en lo mejor para el proyecto
- Ayudar a otros colaboradores

## 📞 Contacto

Para preguntas o discusiones:
- Abrir un **Issue** en GitHub
- Etiquetar apropiadamente (bug, enhancement, question)
- Proporcionar contexto detallado

---

¡Gracias por contribuir a IBM AI Platform Backend! 🚀
