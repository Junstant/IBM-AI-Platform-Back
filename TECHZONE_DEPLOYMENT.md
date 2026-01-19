# 🚀 IBM TechZone Deployment Guide / Guía de Despliegue

---

## Versión en Español

### Paso 1: Acceder a TechZone
1. Abre tu navegador
2. Ve a: https://techzone.ibm.com/collection/ibm-ai-demos-platform-automated-power-vs-deployment/environments
3. Haz clic en **"Create a reservation"**

### Paso 2: Completar el Formulario
Completa estos campos:

**Información Básica:**
- **Name**: `IBM AI Platform - PowerVS S1022` (o el nombre que prefieras)
- **Purpose**: Selecciona `Test` (o `Demo` si es para presentación a cliente)
- **Purpose description**: Escribe algo como `Testing IBM AI Platform`

**Recursos (Selecciona el máximo que necesites):**
- **CPU**: De `8` a `50` núcleos (recomendado: 25+)
- **Memory**: De `64 GB` a `120 GB` (recomendado: 120 GB)
- **Boot volume**: `50 GB` mínimo
- **Network**: Selecciona `Public network interface only`
- **Region**: Elige el más cercano (ej: `us-south`)

**Duración:**
- **Start date**: Selecciona la fecha de hoy
- **End date**: Selecciona 2 días después (puedes extender luego)

Haz clic en **"Submit"**

### Paso 3: Esperar el Despliegue
1. Verás el estado: `Provisioning` → Espera 30-45 minutos
2. Cuando el estado cambie a `Ready`, ¡está listo!

### Paso 4: Obtener Información de Acceso
En los detalles de la reserva, verás:

- **Virtual machine host name**: `itzpvs-xxxxxxx`
- **Public IP address**: `XX.XX.XX.XX` ← **COPIA ESTO**
- **Generic user**: `UUXXXXX`

### Paso 5: Acceder a la Plataforma
1. Abre tu navegador
2. Ve a: `http://XX.XX.XX.XX:2012` (reemplaza XX con tu IP pública)
3. **¡Listo!** La plataforma está lista para usar

**Ejemplo**: Si tu IP pública es `52.118.31.198`, abre:
```
http://52.118.31.198:2012
```

---
## English Version

### Step 1: Access TechZone
1. Open your browser
2. Go to: https://techzone.ibm.com/collection/ibm-ai-demos-platform-automated-power-vs-deployment/environments
3. Click **"Create a reservation"**

### Step 2: Fill the Form
Fill out these fields:

**Basic Information:**
- **Name**: `IBM AI Platform - PowerVS S1022` (or any name you prefer)
- **Purpose**: Select `Test` (or `Demo` if for client presentation)
- **Purpose description**: Write something like `Testing IBM AI Platform`

**Resources (Select maximum you need):**
- **CPU**: `8` to `50` cores (recommended: 25+)
- **Memory**: `64 GB` to `120 GB` (recommended: 120 GB)
- **Boot volume**: `50 GB` minimum
- **Network**: Select `Public network interface only`
- **Region**: Choose closest to you (e.g., `us-south`)

**Duration:**
- **Start date**: Select today's date
- **End date**: Select 2 days later (you can extend later)

Click **"Submit"**

### Step 3: Wait for Deployment
1. You'll see status: `Provisioning` → Wait 30-45 minutes
2. When status changes to `Ready`, you're done!

### Step 4: Get Access Information
In the reservation details, you'll see:

- **Virtual machine host name**: `itzpvs-xxxxxxx`
- **Public IP address**: `XX.XX.XX.XX` ← **COPY THIS**
- **Generic user**: `UUXXXXX`

### Step 5: Access the Platform
1. Open your browser
2. Go to: `http://XX.XX.XX.XX:2012` (replace XX with your public IP)
3. **Done!** The platform is ready to use

**Example**: If your public IP is `52.118.31.198`, open:
```
http://52.118.31.198:2012
```
