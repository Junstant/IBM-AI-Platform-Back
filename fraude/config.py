"""
Configuración adicional para la aplicación de fraude
"""
import os
from dotenv import load_dotenv

# Cargar variables de entorno desde el archivo .env en el directorio raíz
load_dotenv(dotenv_path=os.path.join(os.path.dirname(__file__), '..', '.env'))

# Verificar que las variables críticas estén configuradas
required_vars = ['DB_HOST', 'DB_PORT', 'DB_USER', 'DB_PASSWORD', 'DB2_NAME']
missing_vars = [var for var in required_vars if not os.getenv(var)]

if missing_vars:
    print(f"⚠️ Variables de entorno faltantes: {', '.join(missing_vars)}")
    print("Por favor, configure estas variables en el archivo .env")
else:
    print("✅ Variables de entorno configuradas correctamente")