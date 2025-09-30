#!/bin/bash
# filepath: ssh://demoai2/mnt/cont/LucasAI/setup.sh

# Script maestro para desplegar toda la plataforma AI
set -e

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# ===== CONFIGURACIÓN =====
PROJECT_DIR="/mnt/cont/LucasAI"
REPO_URL="https://github.com/Junstant/IBM-AI-Platform-Back.git"
COMPOSE_FILE="$PROJECT_DIR/docker-compose.yaml"

# ===== DESCARGAR REPOSITORIO =====
download_repository() {
    log "📥 Descargando repositorio desde GitHub..."
    
    # Crear directorio padre si no existe
    mkdir -p "$(dirname "$PROJECT_DIR")"
    
    # Si el directorio ya existe, hacer backup
    if [ -d "$PROJECT_DIR" ]; then
        log "📁 Directorio existente encontrado, creando backup..."
        mv "$PROJECT_DIR" "${PROJECT_DIR}.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # Clonar repositorio
    if git clone "$REPO_URL" "$PROJECT_DIR"; then
        log "✅ Repositorio descargado exitosamente"
        cd "$PROJECT_DIR"
        log "📊 Commit actual: $(git rev-parse --short HEAD)"
        log "📝 Última actualización: $(git log -1 --format='%cd' --date=format:'%Y-%m-%d %H:%M:%S')"
    else
        log "❌ Error al descargar el repositorio"
        exit 1
    fi
}

# ===== INSTALAR DEPENDENCIAS PYTHON PARA PPC64LE =====
install_python_deps() {
    log "🐍 Instalando dependencias Python optimizadas para Power PC..."
    
    local ARCH=$(uname -m)
    
    if [[ "$ARCH" == "ppc64le" ]]; then
        log "⚡ Detectada arquitectura Power PC - usando repositorios optimizados"
        
        # Actualizar pip primero
        pip3 install --upgrade pip
        
        # Configurar pip para usar repositorios de wheels ppc64le
        mkdir -p ~/.pip
        cat > ~/.pip/pip.conf << 'EOF'
[global]
extra-index-url = https://repo.fury.io/mgiessing
prefer-binary = true
timeout = 300
break-system-packages = true
EOF
        
        # Si existe requirements.txt en el proyecto, instalarlo
        if [ -f "$PROJECT_DIR/requirements.txt" ]; then
            log "📦 Instalando requirements.txt con repositorios PPC64LE..."
            cd "$PROJECT_DIR"
            
            # Intentar primero con el repositorio optimizado para PPC64LE
            if pip3 install --no-cache-dir \
                --extra-index-url https://repo.fury.io/mgiessing \
                --prefer-binary \
                --break-system-packages \
                -r requirements.txt; then
                log "✅ Requirements instalados con repositorio PPC64LE"
            else
                log "⚠️ Fallback: instalando con método estándar..."
                pip3 install --no-cache-dir --break-system-packages -r requirements.txt
            fi
        fi
        
        # Instalar Docker Compose - Priorizar el plugin oficial
        install_docker_compose_ppc
        
    else
        log "📦 Arquitectura estándar detectada - usando pip normal"
        pip3 install --upgrade pip
        
        if [ -f "$PROJECT_DIR/requirements.txt" ]; then
            cd "$PROJECT_DIR"
            pip3 install --no-cache-dir -r requirements.txt
        fi
        
        install_docker_compose_standard
    fi
}

# ===== INSTALAR DOCKER COMPOSE PARA PPC64LE =====
install_docker_compose_ppc() {
    log "🐙 Configurando Docker Compose para Power PC..."
    
    # Verificar si docker compose (plugin) ya está disponible
    if docker compose version &> /dev/null 2>&1; then
        log "✅ Docker Compose (plugin) ya está instalado: $(docker compose version --short)"
        
        # Crear alias para compatibilidad si no existe docker-compose comando
        if ! command -v docker-compose &> /dev/null; then
            log "🔗 Creando alias docker-compose -> docker compose"
            echo 'alias docker-compose="docker compose"' >> ~/.bashrc
            # Crear enlace simbólico para scripts
            ln -sf /usr/bin/docker /usr/local/bin/docker-compose-real
            cat > /usr/local/bin/docker-compose << 'EOF'
#!/bin/bash
docker compose "$@"
EOF
            chmod +x /usr/local/bin/docker-compose
            log "✅ Alias y enlace simbólico creados"
        fi
        return 0
    fi
    
    # Si no hay plugin, intentar instalar docker-compose standalone
    log "📦 Plugin no disponible, instalando docker-compose standalone..."
    
    # Método 1: Intentar con repositorio PPC64LE evitando conflictos
    log "🔄 Intentando instalación con repositorio PPC64LE (evitando conflictos)..."
    if pip3 install --no-cache-dir \
        --extra-index-url https://repo.fury.io/mgiessing \
        --prefer-binary \
        --break-system-packages \
        --no-deps \
        docker-compose; then
        
        # Instalar dependencias manualmente para evitar conflictos
        log "📦 Instalando dependencias compatibles..."
        pip3 install --no-cache-dir --break-system-packages --no-deps \
            docker \
            dockerpty \
            docopt \
            python-dotenv \
            texttable \
            websocket-client \
            PyYAML \
            distro \
            jsonschema \
            paramiko \
            bcrypt \
            cryptography \
            pynacl \
            cffi \
            invoke \
            typing-extensions \
            pycparser \
            charset-normalizer \
            certifi 2>/dev/null || true
        
        log "✅ Docker Compose instalado con repositorio PPC64LE"
        return 0
    fi
    
    # Método 2: Instalar usando el binario directo
    log "🔄 Descargando binario de Docker Compose..."
    COMPOSE_VERSION="1.29.2"
    COMPOSE_URL="https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-Linux-ppc64le"
    
    if curl -L "$COMPOSE_URL" -o /usr/local/bin/docker-compose 2>/dev/null; then
        chmod +x /usr/local/bin/docker-compose
        log "✅ Docker Compose binario instalado: $(/usr/local/bin/docker-compose --version)"
        return 0
    fi
    
    # Método 3: Fallback - usar solo docker compose plugin
    log "⚠️ Usando solo 'docker compose' - creando wrapper..."
    cat > /usr/local/bin/docker-compose << 'EOF'
#!/bin/bash
docker compose "$@"
EOF
    chmod +x /usr/local/bin/docker-compose
    log "✅ Wrapper docker-compose creado"
}

# ===== INSTALAR DOCKER COMPOSE ESTÁNDAR =====
install_docker_compose_standard() {
    log "🐙 Instalando Docker Compose (arquitectura estándar)..."
    
    if command -v docker-compose &> /dev/null; then
        log "✅ Docker Compose ya está instalado: $(docker-compose --version)"
        return 0
    fi
    
    if docker compose version &> /dev/null 2>&1; then
        log "✅ Docker Compose (plugin) disponible: $(docker compose version --short)"
        echo 'alias docker-compose="docker compose"' >> ~/.bashrc
        return 0
    fi
    
    pip3 install docker-compose
}

# ===== PREPARAR HOST MEJORADO =====
prepare_host() {
    log "🔧 Preparando host..."
    
    # Instalar dependencias básicas del sistema
    log "📦 Instalando dependencias del sistema..."
    if command -v dnf &> /dev/null; then
        # Instalar dependencias una por una para manejar las que fallan
        local PACKAGES=(wget curl git python3 python3-pip vim net-tools firewalld)
        local OPTIONAL_PACKAGES=(htop)
        
        # Instalar paquetes esenciales
        for package in "${PACKAGES[@]}"; do
            if dnf install -y "$package" 2>/dev/null; then
                log "✅ $package instalado"
            else
                log "⚠️ $package ya está instalado o no disponible"
            fi
        done
        
        # Instalar paquetes opcionales
        for package in "${OPTIONAL_PACKAGES[@]}"; do
            if dnf install -y "$package" 2>/dev/null; then
                log "✅ $package instalado"
            else
                log "⚠️ $package no disponible en repos, intentando con EPEL..."
                # Intentar habilitar EPEL para htop
                if dnf install -y epel-release 2>/dev/null; then
                    log "✅ EPEL habilitado"
                    if dnf install -y "$package" 2>/dev/null; then
                        log "✅ $package instalado desde EPEL"
                    else
                        log "⚠️ $package no disponible en EPEL, omitiendo..."
                    fi
                else
                    log "⚠️ No se pudo habilitar EPEL"
                fi
            fi
        done
        
        # Instalar cliente PostgreSQL
        if dnf install -y postgresql 2>/dev/null; then
            log "✅ Cliente PostgreSQL instalado"
        elif dnf install -y postgresql-client 2>/dev/null; then
            log "✅ Cliente PostgreSQL instalado"
        else
            log "⚠️ Cliente PostgreSQL no disponible"
        fi
        
    elif command -v yum &> /dev/null; then
        yum install -y wget curl git python3 python3-pip vim net-tools
        yum install -y epel-release || true
        yum install -y htop || true
        yum install -y postgresql || true
    elif command -v apt-get &> /dev/null; then
        apt-get update
        apt-get install -y wget curl git python3 python3-pip postgresql-client htop vim net-tools ufw
    fi
    
    # Instalar Docker
    install_docker
    
    # Instalar dependencias Python optimizadas
    install_python_deps
    
    # Configurar firewall para los puertos necesarios
    configure_firewall
    
    log "✅ Host preparado"
}

# ===== INSTALAR DOCKER =====
install_docker() {
    log "🐳 Instalando Docker..."
    
    # Verificar si Docker ya está instalado
    if command -v docker &> /dev/null; then
        log "✅ Docker ya está instalado: $(docker --version)"
        
        # Verificar que el servicio esté activo
        if ! systemctl is-active docker &> /dev/null; then
            log "🔄 Iniciando servicio Docker..."
            systemctl enable docker
            systemctl start docker
        fi
        
        # Verificar que funcione
        if docker info &> /dev/null; then
            log "✅ Docker funcionando correctamente"
        else
            log "🔄 Reiniciando Docker..."
            systemctl restart docker
            sleep 5
        fi
        
        return 0
    fi
    
    log "📦 Instalando Docker..."
    
    # Para CentOS Stream 9 en Power PC
    if command -v dnf &> /dev/null; then
        log "📦 Instalando Docker desde repositorios del sistema..."
        
        # Remover conflictos
        dnf remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine podman runc 2>/dev/null || true
        
        # Instalar dependencias
        dnf install -y dnf-plugins-core device-mapper-persistent-data lvm2
        
        # Intentar instalar Docker CE desde repo oficial
        if dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo 2>/dev/null; then
            log "✅ Repositorio Docker CE agregado"
            
            if dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 2>/dev/null; then
                log "✅ Docker CE instalado desde repo oficial"
            else
                log "⚠️ Docker CE no disponible para ppc64le, usando Docker del sistema..."
                dnf install -y docker
            fi
        else
            log "⚠️ No se pudo agregar repo oficial, usando Docker del sistema..."
            dnf install -y docker
        fi
        
    elif command -v yum &> /dev/null; then
        # Para sistemas más antiguos
        yum install -y yum-utils device-mapper-persistent-data lvm2
        yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo 2>/dev/null || true
        
        if ! yum install -y docker-ce docker-ce-cli containerd.io 2>/dev/null; then
            yum install -y docker
        fi
    fi
    
    # Habilitar y iniciar Docker
    systemctl enable docker
    systemctl start docker
    
    # Verificar que Docker funcione
    local retries=0
    while [ $retries -lt 5 ]; do
        if docker --version &> /dev/null && docker info &> /dev/null; then
            log "✅ Docker funcionando: $(docker --version)"
            break
        else
            log "⏳ Esperando que Docker se inicie... ($((retries+1))/5)"
            sleep 5
            retries=$((retries+1))
        fi
    done
    
    if [ $retries -eq 5 ]; then
        log "❌ Error: Docker no está funcionando correctamente"
        exit 1
    fi
}

# ===== CONFIGURAR FIREWALL =====
configure_firewall() {
    log "🔥 Configurando firewall..."
    
    # Puertos necesarios para la plataforma
    PORTS=(2012 8000 8001 8070 8090 8091 8092 8094 8095 8096 8099 9470 9476 2005 2007 2010 5433)
    
    if command -v firewall-cmd &> /dev/null; then
        # Red Hat/CentOS/Fedora
        if ! systemctl is-active firewalld &> /dev/null; then
            log "🔄 Iniciando firewalld..."
            systemctl enable firewalld || true
            systemctl start firewalld || true
            sleep 2
        fi
        
        if systemctl is-active firewalld &> /dev/null; then
            for port in "${PORTS[@]}"; do
                if firewall-cmd --permanent --add-port=${port}/tcp --quiet 2>/dev/null; then
                    log "✅ Puerto $port/tcp abierto"
                else
                    log "⚠️ No se pudo abrir puerto $port/tcp"
                fi
            done
            
            if firewall-cmd --reload 2>/dev/null; then
                log "✅ Firewall configurado y recargado"
            else
                log "⚠️ Error al recargar firewall"
            fi
        else
            log "⚠️ Firewalld no está activo"
        fi
        
    else
        log "⚠️ Firewall no detectado, asegúrate de abrir los puertos manualmente"
        log "📝 Puertos necesarios: ${PORTS[*]}"
    fi
}

# ===== VERIFICAR RECURSOS DEL SISTEMA =====
check_system_resources() {
    log "🔍 Verificando recursos del sistema..."
    
    # Arquitectura
    ARCH=$(uname -m)
    log "🏗️ Arquitectura: $ARCH"
    
    if [[ "$ARCH" == "ppc64le" ]]; then
        log "⚡ Sistema Power PC detectado - aplicando optimizaciones"
        export USE_PPC_OPTIMIZATIONS=true
    fi
    
    # Información del sistema operativo
    if [ -f /etc/os-release ]; then
        local OS_NAME=$(grep '^NAME=' /etc/os-release | cut -d'"' -f2)
        local OS_VERSION=$(grep '^VERSION=' /etc/os-release | cut -d'"' -f2)
        log "💻 Sistema: $OS_NAME $OS_VERSION"
    fi
    
    # Memoria
    MEMORY_GB=$(free -g | awk 'NR==2{print $2}')
    if [ "$MEMORY_GB" -lt 8 ]; then
        log "⚠️ Advertencia: Solo ${MEMORY_GB}GB de RAM disponible. Recomendado: 8GB+"
    else
        log "✅ Memoria suficiente: ${MEMORY_GB}GB"
    fi
    
    # Espacio en disco
    DISK_GB=$(df -BG "$PROJECT_DIR" 2>/dev/null | awk 'NR==2 {print $4}' | sed 's/G//' || echo "50")
    if [ "$DISK_GB" -lt 20 ]; then
        log "⚠️ Advertencia: Solo ${DISK_GB}GB de espacio libre. Recomendado: 20GB+"
    else
        log "✅ Espacio en disco suficiente: ${DISK_GB}GB"
    fi
    
    # Verificar Docker
    if ! command -v docker &> /dev/null; then
        log "📝 Docker no está instalado, se instalará en el paso de preparación del host"
    elif ! systemctl is-active docker &> /dev/null; then
        log "📝 Docker está instalado pero no activo, se iniciará en el paso de preparación del host"
    else
        log "✅ Docker está instalado y activo"
    fi
}

# ===== PREPARAR PROYECTO =====
prepare_project() {
    log "📁 Preparando estructura del proyecto..."
    
    cd "$PROJECT_DIR"
    
    # Hacer ejecutables los scripts
    find . -name "*.sh" -type f -exec chmod +x {} \;
    
    # Crear directorios necesarios
    mkdir -p {models,logs,backups,data}
    mkdir -p database/{data,backups}
    mkdir -p {fraude,textoSql}/logs
    
    # Crear o actualizar .env
    if [ ! -f .env ] || [ "$FORCE_ENV_UPDATE" = "true" ]; then
        log "📝 Creando archivo .env..."
        cat > .env << EOF
# === CONFIGURACIÓN GENERAL ===
COMPOSE_PROJECT_NAME=platform_ai_lj

# === BASE DE DATOS ===
DB_HOST=postgres
DB_PORT=8070
DB_USER=postgres
DB_PASSWORD=postgres
DB_NAME=postgres

# === APIS ===
FRAUDE_API_PORT=8000
TEXTOSQL_API_PORT=8001

# === LLM SERVERS ===
MISTRAL_PORT=8096
GRANITE_PORT=8095
GEMMA2B_PORT=9470
GEMMA_TEST_PORT=8099

# === NGINX ===
NGINX_PORT=2012
ENABLE_NGINX=true
START_NGINX=true

# === OPTIMIZACIONES ===
USE_PPC_OPTIMIZATIONS=true

# === MODELOS (opcional) ===
# MODEL_PATH=/models/modelo.gguf
# MODEL_URL=https://...
EOF
    else
        log "✅ Archivo .env ya existe"
    fi
    
    log "✅ Proyecto preparado"
}

# ===== CONSTRUIR E INICIAR SERVICIOS =====
deploy_services() {
    log "🐳 Construyendo e iniciando servicios..."
    
    cd "$PROJECT_DIR"
    
    # Determinar comando de docker-compose
    if command -v docker-compose &> /dev/null && docker-compose --version &> /dev/null; then
        DOCKER_COMPOSE="docker-compose"
    elif docker compose version &> /dev/null 2>&1; then
        DOCKER_COMPOSE="docker compose"
    else
        log "❌ Error: No se encontró docker-compose ni docker compose"
        exit 1
    fi
    
    log "🔧 Usando comando: $DOCKER_COMPOSE"
    
    # Verificar que docker-compose.yaml existe
    if [ ! -f "docker-compose.yaml" ] && [ ! -f "docker-compose.yml" ]; then
        log "❌ Error: No se encontró docker-compose.yaml en $PROJECT_DIR"
        log "📁 Archivos disponibles:"
        ls -la
        exit 1
    fi
    
    # Parar servicios existentes si están corriendo
    log "🛑 Deteniendo servicios existentes..."
    $DOCKER_COMPOSE down || true
    
    # Limpiar contenedores y volúmenes huérfanos
    log "🧹 Limpiando recursos Docker..."
    docker system prune -f --volumes || true
    
    # Verificar sintaxis del docker-compose
    log "🔍 Verificando sintaxis del docker-compose..."
    if ! $DOCKER_COMPOSE config &> /dev/null; then
        log "❌ Error en la sintaxis del docker-compose.yaml"
        $DOCKER_COMPOSE config
        exit 1
    fi
    
    # Construir imágenes
    log "🔨 Construyendo imágenes..."
    $DOCKER_COMPOSE build --no-cache
    
    # Iniciar servicios de manera escalonada
    log "🚀 Iniciando base de datos..."
    $DOCKER_COMPOSE up -d postgres
    
    # Esperar a que PostgreSQL esté listo
    log "⏳ Esperando PostgreSQL (30s)..."
    sleep 30
    
    # Verificar que PostgreSQL esté respondiendo
    for i in $(seq 1 10); do
        if docker exec $($DOCKER_COMPOSE ps -q postgres) pg_isready -U postgres &> /dev/null; then
            log "✅ PostgreSQL está listo"
            break
        else
            log "⏳ PostgreSQL no está listo, esperando... ($i/10)"
            sleep 3
        fi
    done
    
    log "🚀 Iniciando APIs..."
    $DOCKER_COMPOSE up -d fraude-api textosql-api || true
    
    log "🚀 Iniciando servidores LLM..."
    $DOCKER_COMPOSE up -d mistral-td-server granite-td-server gemma2b-td-server gemma-test || true
    
    log "✅ Todos los servicios iniciados"
}

# ===== VERIFICAR SERVICIOS =====
verify_deployment() {
    log "🔍 Verificando servicios..."
    
    cd "$PROJECT_DIR"
    
    # Determinar comando de docker-compose
    if command -v docker-compose &> /dev/null && docker-compose --version &> /dev/null; then
        DOCKER_COMPOSE="docker-compose"
    elif docker compose version &> /dev/null 2>&1; then
        DOCKER_COMPOSE="docker compose"
    else
        log "❌ Error: No se encontró docker-compose ni docker compose"
        return 1
    fi
    
    # Esperar un poco para que los servicios se estabilicen
    sleep 10
    
    # Mostrar estado de los contenedores
    log "📊 Estado de los contenedores:"
    $DOCKER_COMPOSE ps
    
    # Health checks básicos
    log "🏥 Verificando health checks..."
    
    ENDPOINTS=(
        "http://localhost:8070:PostgreSQL"
        "http://localhost:8000/docs:API Fraude"
        "http://localhost:8001/docs:API TextoSQL"
        "http://localhost:8096/health:Mistral LLM"
    )
    
    for endpoint_info in "${ENDPOINTS[@]}"; do
        IFS=':' read -r endpoint name <<< "$endpoint_info"
        
        if curl -s --connect-timeout 5 "$endpoint" > /dev/null 2>&1; then
            log "✅ $name respondiendo"
        else
            log "⚠️ $name no responde o aún iniciando"
        fi
    done
}

# ===== MOSTRAR INFORMACIÓN =====
show_info() {
    local IP=$(hostname -I | awk '{print $1}' || echo "localhost")
    
    log "📋 Información del despliegue:"
    echo ""
    echo "🌐 ACCESO WEB:"
    echo "   Dashboard: http://$IP:2012"
    echo "   Health Check: http://$IP:2012/health"
    echo ""
    echo "🔌 APIs:"
    echo "   Fraude API: http://$IP:8000/docs"
    echo "   TextoSQL API: http://$IP:8001/docs"
    echo ""
    echo "🧠 MODELOS LLM:"
    echo "   Mistral: http://$IP:8096"
    echo "   Granite: http://$IP:8095"
    echo "   Gemma 2B: http://$IP:9470"
    echo "   Gemma Test: http://$IP:8099"
    echo ""
    echo "🗄️ BASE DE DATOS:"
    echo "   PostgreSQL: $IP:8070"
    echo "   Usuario: postgres / Contraseña: postgres"
    echo ""
    echo "📝 COMANDOS ÚTILES:"
    echo "   Ver logs: docker-compose logs -f [servicio]"
    echo "   Reiniciar: docker-compose restart [servicio]"
    echo "   Parar todo: docker-compose down"
    echo "   Ver estado: docker-compose ps"
    echo ""
    echo "📁 UBICACIÓN DEL PROYECTO:"
    echo "   $PROJECT_DIR"
    echo ""
}

# ===== FUNCIÓN PRINCIPAL =====
main() {
    log "🚀 Iniciando despliegue completo de AI Platform..."
    
    case "${1:-full}" in
        "download")
            download_repository
            ;;
        "host")
            prepare_host
            ;;
        "project")
            prepare_project
            ;;
        "deploy")
            deploy_services
            ;;
        "verify")
            verify_deployment
            ;;
        "full")
            download_repository
            check_system_resources
            prepare_host
            prepare_project
            deploy_services
            verify_deployment
            show_info
            ;;
        *)
            echo "Uso: $0 [download|host|project|deploy|verify|full]"
            echo "  download - Solo descargar el repositorio"
            echo "  host     - Solo preparar el host"
            echo "  project  - Solo preparar el proyecto"
            echo "  deploy   - Solo desplegar servicios"
            echo "  verify   - Solo verificar servicios"
            echo "  full     - Hacer todo (por defecto)"
            exit 1
            ;;
    esac
    
    log "✅ Operación completada exitosamente!"
}

# Ejecutar función principal
main "$@"