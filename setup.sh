#!/bin/bash
# Script maestro para desplegar toda la plataforma AI con detección automática de arquitectura
set -e

# Colores para logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "[$(date +'%Y-%m-%d %H:%M:%S')] ${GREEN}$1${NC}"
}

warn() {
    echo -e "[$(date +'%Y-%m-%d %H:%M:%S')] ${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "[$(date +'%Y-%m-%d %H:%M:%S')] ${RED}❌ $1${NC}"
}

info() {
    echo -e "[$(date +'%Y-%m-%d %H:%M:%S')] ${BLUE}ℹ️  $1${NC}"
}

# ===== CARGAR CONFIGURACIÓN DEL .ENV =====
load_env_config() {
    # Verificar si existe .env
    if [ ! -f ".env" ]; then
        error "❌ Archivo .env requerido no encontrado"
        echo ""
        echo "📋 PASOS PARA CONTINUAR:"
        echo "1. Debe existir un archivo .env con la configuración necesaria"
        echo "2. El archivo debe contener al menos:"
        echo "   - PROJECT_DIR"
        echo "   - DB_PASSWORD"
        echo "   - TOKEN_HUGGHINGFACE"
        echo "   - DEFAULT_PORTS"
        echo "   - REPO_BACK_URL y REPO_FRONT_URL"
        echo ""
        echo "3. Ejecute nuevamente el script después de crear el .env"
        exit 1
    fi
    
    # Guardar la ruta absoluta del directorio original donde está el .env
    ORIGINAL_DIR="$(pwd)"
    ORIGINAL_ENV_PATH="$ORIGINAL_DIR/.env"
    
    # Cargar variables del .env
    source .env
    
    # Verificar variables críticas
    local missing_vars=()
    local required_vars=("PROJECT_DIR" "DB_PASSWORD" "TOKEN_HUGGHINGFACE" "DEFAULT_PORTS")
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            missing_vars+=("$var")
        fi
    done
    
    if [ ${#missing_vars[@]} -gt 0 ]; then
        error "Variables críticas faltantes en .env: ${missing_vars[*]}"
        exit 1
    fi
    
    log "✅ Configuración .env cargada correctamente desde: $ORIGINAL_ENV_PATH"
    
    # Configurar variables derivadas
    COMPOSE_FILE="$PROJECT_DIR/docker-compose.yaml"
    
    # Si REPO_BACK_URL y REPO_FRONT_URL no están definidas, usar valores por defecto
    REPO_BACK_URL=${REPO_BACK_URL:-"https://github.com/Junstant/IBM-AI-Platform-Back.git"}
    REPO_FRONT_URL=${REPO_FRONT_URL:-"https://github.com/Junstant/IBM-AI-Platform-Front.git"}
}

# ===== DETECTAR ARQUITECTURA Y SO =====
detect_system() {
    log "🔍 Detectando arquitectura y sistema operativo..."
    
    # Detectar arquitectura
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64)
            ARCH_TYPE="amd64"
            ;;
        aarch64|arm64)
            ARCH_TYPE="arm64"
            ;;
        ppc64le)
            ARCH_TYPE="ppc64le"
            ;;
        s390x)
            ARCH_TYPE="s390x"
            ;;
        *)
            ARCH_TYPE="unknown"
            ;;
    esac
    
    # Detectar distribución
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_NAME="$NAME"
        OS_VERSION="$VERSION_ID"
        OS_ID="$ID"
        OS_ID_LIKE="$ID_LIKE"
    else
        OS_NAME="Unknown"
        OS_VERSION="Unknown"
        OS_ID="unknown"
    fi
    
    # Detectar gestor de paquetes
    if command -v dnf &> /dev/null; then
        PKG_MANAGER="dnf"
    elif command -v yum &> /dev/null; then
        PKG_MANAGER="yum"
    elif command -v apt-get &> /dev/null; then
        PKG_MANAGER="apt"
    elif command -v zypper &> /dev/null; then
        PKG_MANAGER="zypper"
    elif command -v pacman &> /dev/null; then
        PKG_MANAGER="pacman"
    else
        PKG_MANAGER="unknown"
    fi
    
    log "🏗️  Arquitectura: $ARCH ($ARCH_TYPE)"
    log "💻 Sistema: $OS_NAME $OS_VERSION"
    log "📦 Gestor de paquetes: $PKG_MANAGER"
    
    # Configurar optimizaciones específicas
    if [[ "$ARCH_TYPE" == "ppc64le" ]]; then
        export USE_PPC_OPTIMIZATIONS=true
        export DOCKER_BUILDKIT=0  # Mejor compatibilidad en Power
        warn "Sistema Power PC detectado - aplicando optimizaciones específicas"
    fi
}

# ===== VERIFICAR RECURSOS DEL SISTEMA =====
check_system_resources() {
    log "📊 Verificando recursos del sistema..."
    
    # Verificar memoria RAM
    MEMORY_GB=$(free -g | awk 'NR==2{print $2}')
    if [ "$MEMORY_GB" -lt "${MIN_RAM_GB:-4}" ]; then
        warn "Solo ${MEMORY_GB}GB de RAM disponible. Mínimo recomendado: ${MIN_RAM_GB:-4}GB"
        read -p "¿Desea continuar de todos modos? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            error "Instalación cancelada por el usuario"
            exit 1
        fi
    else
        log "✅ Memoria suficiente: ${MEMORY_GB}GB"
    fi
    
    # Verificar espacio en disco
    DISK_AVAIL_GB=$(df -BG "$(dirname "$PROJECT_DIR")" 2>/dev/null | awk 'NR==2 {print $4}' | sed 's/G//' || echo "0")
    if [ "$DISK_AVAIL_GB" -lt "${MIN_DISK_GB:-20}" ]; then
        warn "Solo ${DISK_AVAIL_GB}GB de espacio libre. Mínimo recomendado: ${MIN_DISK_GB:-20}GB"
        read -p "¿Desea continuar de todos modos? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            error "Instalación cancelada por el usuario"
            exit 1
        fi
    else
        log "✅ Espacio en disco suficiente: ${DISK_AVAIL_GB}GB disponibles"
    fi
    
    # Verificar CPU
    CPU_CORES=$(nproc)
    log "🔧 Procesador: $CPU_CORES cores"
    
    # Mostrar información adicional del sistema
    if [ -f /proc/meminfo ]; then
        MEMORY_TOTAL=$(grep MemTotal /proc/meminfo | awk '{print int($2/1024/1024)}')
        MEMORY_FREE=$(grep MemAvailable /proc/meminfo | awk '{print int($2/1024/1024)}')
        info "Memoria: ${MEMORY_FREE}GB libres de ${MEMORY_TOTAL}GB totales"
    fi
}

# ===== INSTALAR DEPENDENCIAS DEL SISTEMA =====
install_system_dependencies() {
    log "📦 Instalando dependencias del sistema..."
    
    # Actualizar repositorios
    case "$PKG_MANAGER" in
        dnf|yum)
            log "🔄 Actualizando repositorios..."
            $PKG_MANAGER update -y --refresh
            
            # Dependencias básicas
            local PACKAGES=(
                "wget" "curl" "git" "vim" "nginx" 
                "python3" "python3-pip" "python3-devel"
                "firewalld" "net-tools" "htop" "unzip"
                "openssl" "ca-certificates" "bind-utils"
                "rsync" "tar" "gzip"
            )
            
            # Dependencias adicionales para desarrollo
            local DEV_PACKAGES=(
                "gcc" "gcc-c++" "make" "cmake"
                "postgresql" "postgresql-client"
                "nodejs" "npm"
            )
            
            # Instalar paquetes esenciales
            for package in "${PACKAGES[@]}"; do
                if $PKG_MANAGER install -y "$package" &>/dev/null; then
                    log "✅ $package instalado"
                else
                    warn "$package no disponible o ya instalado"
                fi
            done
            
            # Instalar EPEL si está disponible
            if $PKG_MANAGER install -y epel-release &>/dev/null; then
                log "✅ EPEL repository habilitado"
                $PKG_MANAGER update -y
            fi
            
            # Instalar paquetes de desarrollo
            for package in "${DEV_PACKAGES[@]}"; do
                if $PKG_MANAGER install -y "$package" &>/dev/null; then
                    log "✅ $package instalado"
                else
                    warn "$package no disponible"
                fi
            done
            ;;
            
        apt)
            log "🔄 Actualizando repositorios..."
            apt-get update -y
            
            local PACKAGES=(
                "wget" "curl" "git" "vim" "nginx"
                "python3" "python3-pip" "python3-dev"
                "ufw" "net-tools" "htop" "unzip"
                "openssl" "ca-certificates" "dnsutils"
                "rsync" "tar" "gzip"
                "build-essential" "cmake"
                "postgresql-client" "nodejs" "npm"
            )
            
            for package in "${PACKAGES[@]}"; do
                if apt-get install -y "$package" &>/dev/null; then
                    log "✅ $package instalado"
                else
                    warn "$package no disponible o ya instalado"
                fi
            done
            ;;
            
        zypper)
            zypper refresh
            zypper install -y wget curl git vim nginx python3 python3-pip \
                firewalld net-tools htop unzip openssl ca-certificates \
                rsync tar gzip gcc gcc-c++ make cmake postgresql nodejs npm
            ;;
            
        pacman)
            pacman -Syu --noconfirm
            pacman -S --noconfirm wget curl git vim nginx python python-pip \
                firewalld net-tools htop unzip openssl ca-certificates \
                rsync tar gzip gcc make cmake postgresql nodejs npm
            ;;
            
        *)
            error "Gestor de paquetes no soportado: $PKG_MANAGER"
            exit 1
            ;;
    esac
    
    log "✅ Dependencias del sistema instaladas"
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
            return 0
        else
            log "🔄 Reiniciando Docker..."
            systemctl restart docker
            sleep 5
        fi
    fi
    
    case "$PKG_MANAGER" in
        dnf|yum)
            log "🧼 Removiendo instalaciones conflictivas (docker, podman)..."
            $PKG_MANAGER remove -y docker docker-client docker-client-latest \
                    docker-common docker-latest docker-latest-logrotate \
                    docker-logrotate docker-engine podman runc &>/dev/null || true
            
            log "🔧 Instalando dependencias para Docker..."
            $PKG_MANAGER install -y dnf-plugins-core
            
            log "➕ Agregando el repositorio oficial de Docker CE..."
            $PKG_MANAGER config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            
            log "📦 Instalando Docker CE (Community Edition)..."
            if $PKG_MANAGER install -y docker-ce docker-ce-cli containerd.io \
                    docker-buildx-plugin docker-compose-plugin; then
                log "✅ Docker CE instalado exitosamente desde el repositorio oficial."
            else
                error "Falló la instalación de Docker CE. Abortando."
                exit 1
            fi
            ;;
            
        apt)
            # Remover conflictos
            apt-get remove -y docker docker-engine docker.io containerd runc &>/dev/null || true
            
            # Instalar dependencias
            apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
            
            # Agregar repo oficial de Docker
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
            
            apt-get update
            apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;
            
        *)
            error "Instalación de Docker no soportada para $PKG_MANAGER"
            exit 1
            ;;
    esac
    
    # Habilitar y iniciar Docker
    systemctl enable docker
    systemctl start docker
    
    # Agregar usuario actual al grupo docker
    usermod -aG docker "$USER" || true
    
    # Verificar instalación
    local retries=0
    while [ $retries -lt 10 ]; do
        if docker --version &> /dev/null && docker info &> /dev/null; then
            log "✅ Docker funcionando: $(docker --version)"
            break
        else
            log "⏳ Esperando que Docker se inicie... ($((retries+1))/10)"
            sleep 3
            retries=$((retries+1))
        fi
    done
    
    if [ $retries -eq 10 ]; then
        error "Docker no está funcionando correctamente después de la instalación"
        exit 1
    fi
}

# ===== INSTALAR DOCKER COMPOSE =====
install_docker_compose() {
    log "🐙 Instalando Docker Compose..."
    
    # Verificar si docker compose (plugin) ya está disponible
    if docker compose version &> /dev/null 2>&1; then
        log "✅ Docker Compose (plugin) ya está instalado: $(docker compose version --short)"
        return 0
    fi
    
    # Verificar docker-compose standalone
    if command -v docker-compose &> /dev/null; then
        log "✅ Docker Compose standalone ya está instalado: $(docker-compose --version)"
        return 0
    fi
    
    case "$ARCH_TYPE" in
        ppc64le)
            log "🔧 Instalando Docker Compose para Power PC..."
            
            # Método 1: Usar pip con repositorio optimizado
            pip3 install --upgrade pip
            
            # Configurar pip para repositorios ppc64le usando variable del .env
            mkdir -p ~/.pip
            cat > ~/.pip/pip.conf << EOF
[global]
extra-index-url = ${POWER_REPO:-https://repo.fury.io/mgiessing}
prefer-binary = true
timeout = 300
break-system-packages = true
EOF
            
            if pip3 install --no-cache-dir \
                --extra-index-url "${POWER_REPO:-https://repo.fury.io/mgiessing}" \
                --prefer-binary \
                --break-system-packages \
                docker-compose; then
                log "✅ Docker Compose instalado con repositorio PPC64LE"
                return 0
            fi
            
            # Método 2: Crear wrapper para docker compose
            log "🔄 Creando wrapper docker-compose..."
            cat > /usr/local/bin/docker-compose << 'EOF'
#!/bin/bash
docker compose "$@"
EOF
            chmod +x /usr/local/bin/docker-compose
            log "✅ Wrapper docker-compose creado"
            ;;
            
        *)
            # Descargar binario oficial
            COMPOSE_VERSION="v2.21.0"
            COMPOSE_URL="https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-linux-${ARCH_TYPE}"
            
            curl -L "$COMPOSE_URL" -o /usr/local/bin/docker-compose
            chmod +x /usr/local/bin/docker-compose
            log "✅ Docker Compose binario instalado: $(docker-compose --version)"
            ;;
    esac
}

# ===== CONFIGURAR FIREWALL =====
configure_firewall() {
    log "🔥 Configurando firewall..."
    
    # Usar puertos del .env
    local PORTS_TO_CONFIGURE=()
    
    # Extraer puertos específicos del .env si están definidos
    if [ -n "$DEFAULT_PORTS" ]; then
        # Convertir string de array a array real
        eval "PORTS_TO_CONFIGURE=($DEFAULT_PORTS)"
        log "📋 Usando puertos del archivo .env: ${PORTS_TO_CONFIGURE[*]}"
    else
        # Fallback a puertos comunes
        PORTS_TO_CONFIGURE=(2012 8000 8001 8070 8085 8086 8087 8088 8089 8090)
        warn "DEFAULT_PORTS no definido en .env, usando puertos por defecto"
    fi
    
    case "$PKG_MANAGER" in
        dnf|yum)
            if command -v firewall-cmd &> /dev/null; then
                # Iniciar firewalld si no está activo
                if ! systemctl is-active firewalld &> /dev/null; then
                    log "🔄 Iniciando firewalld..."
                    systemctl enable firewalld
                    systemctl start firewalld
                    sleep 3
                fi
                
                if systemctl is-active firewalld &> /dev/null; then
                    log "🔧 Configurando puertos en firewalld..."
                    
                    for port in "${PORTS_TO_CONFIGURE[@]}"; do
                        if firewall-cmd --permanent --add-port=${port}/tcp --quiet 2>/dev/null; then
                            log "✅ Puerto $port/tcp agregado"
                        else
                            warn "No se pudo agregar puerto $port/tcp"
                        fi
                    done
                    
                    # Permitir Docker
                    firewall-cmd --permanent --zone=trusted --add-interface=docker0 --quiet 2>/dev/null || true
                    firewall-cmd --permanent --zone=trusted --add-masquerade --quiet 2>/dev/null || true
                    
                    if firewall-cmd --reload 2>/dev/null; then
                        log "✅ Firewall configurado y recargado"
                    else
                        warn "Error al recargar firewall"
                    fi
                else
                    warn "No se pudo iniciar firewalld"
                fi
            fi
            ;;
            
        apt)
            if command -v ufw &> /dev/null; then
                log "🔧 Configurando puertos en UFW..."
                
                # Habilitar UFW si no está activo
                ufw --force enable
                
                for port in "${PORTS_TO_CONFIGURE[@]}"; do
                    ufw allow "$port"/tcp
                    log "✅ Puerto $port/tcp agregado a UFW"
                done
                
                # Permitir Docker
                ufw allow from 172.17.0.0/16
                ufw allow from 172.18.0.0/16
                
                log "✅ UFW configurado"
            fi
            ;;
    esac
    
    log "📝 Puertos configurados: ${PORTS_TO_CONFIGURE[*]}"
}

# ===== DESCARGAR REPOSITORIOS =====
download_repositories() {
    log "📥 Descargando repositorios desde GitHub..."
    
    # Crear directorio padre si no existe
    mkdir -p "$(dirname "$PROJECT_DIR")"
    
    # Descargar repositorio backend
    log "📦 Descargando repositorio backend..."
    if [ -d "$PROJECT_DIR" ]; then
        log "📁 Directorio existente encontrado, creando backup..."
        mv "$PROJECT_DIR" "${PROJECT_DIR}.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    if git clone "$REPO_BACK_URL" "$PROJECT_DIR"; then
        log "✅ Repositorio backend descargado exitosamente"
        cd "$PROJECT_DIR"
        log "📊 Commit actual: $(git rev-parse --short HEAD)"
    else
        error "Error al descargar el repositorio backend"
        exit 1
    fi
    
    # Descargar repositorio frontend
    log "📦 Descargando repositorio frontend..."
    FRONT_DIR="${PROJECT_DIR}/frontend"
    
    if git clone "$REPO_FRONT_URL" "$FRONT_DIR"; then
        log "✅ Repositorio frontend descargado exitosamente"
        
        # Copiar configuración de nginx si existe
        if [ -f "$FRONT_DIR/nginx.conf" ]; then
            mkdir -p "$PROJECT_DIR/nginx/conf.d"
            cp "$FRONT_DIR/nginx.conf" "$PROJECT_DIR/nginx/"
            log "✅ Configuración de nginx copiada desde frontend"
        fi
    else
        warn "No se pudo descargar el repositorio frontend (continuando sin él)"
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
    mkdir -p nginx/{conf.d,certs}
    
    # Copiar .env desde el directorio original donde se ejecutó el script
    if [ ! -f ".env" ] && [ -n "$ORIGINAL_ENV_PATH" ] && [ -f "$ORIGINAL_ENV_PATH" ]; then
        log "📄 Copiando archivo .env desde directorio original..."
        cp "$ORIGINAL_ENV_PATH" ".env"
        log "✅ Archivo .env copiado exitosamente desde: $ORIGINAL_ENV_PATH"
        log "📍 Archivo .env ahora disponible en: $(pwd)/.env"
    elif [ -f ".env" ]; then
        log "✅ Archivo .env ya existe en el proyecto"
    else
        warn "⚠️ No se pudo encontrar archivo .env para copiar"
        if [ -n "$ORIGINAL_ENV_PATH" ]; then
            warn "📍 Ruta original esperada: $ORIGINAL_ENV_PATH"
        fi
        log "💡 Asegúrese de que el archivo .env esté disponible"
    fi
    
    log "✅ Proyecto preparado"
}

# ===== INSTALAR DEPENDENCIAS PYTHON =====
install_python_dependencies() {
    log "🐍 Instalando dependencias Python..."
    
    # Actualizar pip
    python3 -m pip install --upgrade pip
    
    if [[ "$ARCH_TYPE" == "ppc64le" ]]; then
        log "⚡ Configurando repositorios optimizados para Power PC..."
        
        # Configurar pip para usar repositorios de wheels ppc64le
        mkdir -p ~/.pip
        cat > ~/.pip/pip.conf << EOF
[global]
extra-index-url = ${POWER_REPO:-https://repo.fury.io/mgiessing}
prefer-binary = true
timeout = 300
break-system-packages = true
EOF
    fi
    
    # Instalar dependencias básicas
    local PYTHON_PACKAGES=(
        "docker-compose"
        "requests"
        "pyyaml"
        "psutil"
        "colorama"
    )
    
    for package in "${PYTHON_PACKAGES[@]}"; do
        if pip3 install --break-system-packages "$package" &>/dev/null; then
            log "✅ $package instalado"
        else
            warn "No se pudo instalar $package"
        fi
    done
}

# ===== CONSTRUIR E INICIAR SERVICIOS =====
deploy_services() {
    log "🐳 Construyendo e iniciando servicios..."
    
    cd "$PROJECT_DIR"
    
    # Verificar que el archivo .env esté presente antes de continuar
    if [ ! -f ".env" ]; then
        error "❌ Archivo .env no encontrado en $PROJECT_DIR"
        echo ""
        echo "🔍 POSIBLES SOLUCIONES:"
        echo "1. Verificar que el .env original esté en el directorio donde ejecutó el script"
        echo "2. Ejecutar primero: sudo ./setup.sh prepare"
        echo "3. Copiar manualmente el .env: cp /ruta/original/.env $PROJECT_DIR/.env"
        echo ""
        if [ -n "$ORIGINAL_ENV_PATH" ]; then
            echo "📍 Archivo .env original esperado en: $ORIGINAL_ENV_PATH"
            if [ -f "$ORIGINAL_ENV_PATH" ]; then
                log "💡 Copiando archivo .env automáticamente..."
                cp "$ORIGINAL_ENV_PATH" ".env"
                log "✅ Archivo .env copiado exitosamente"
            else
                echo "❌ Archivo .env no encontrado en la ruta original"
            fi
        fi
        
        # Verificar nuevamente después del intento de copia
        if [ ! -f ".env" ]; then
            exit 1
        fi
    else
        log "✅ Archivo .env encontrado en el proyecto"
    fi
    
    # Determinar comando de docker-compose
    if command -v docker-compose &> /dev/null && docker-compose --version &> /dev/null; then
        DOCKER_COMPOSE="docker-compose"
    elif docker compose version &> /dev/null 2>&1; then
        DOCKER_COMPOSE="docker compose"
    else
        error "No se encontró docker-compose ni docker compose"
        exit 1
    fi
    
    log "🔧 Usando comando: $DOCKER_COMPOSE"
    
    # Verificar que docker-compose.yaml existe
    if [ ! -f "docker-compose.yaml" ] && [ ! -f "docker-compose.yml" ]; then
        error "No se encontró docker-compose.yaml en $PROJECT_DIR"
        exit 1
    fi
    
    # Parar servicios existentes
    log "🛑 Deteniendo servicios existentes..."
    $DOCKER_COMPOSE down || true
    
    # Limpiar recursos Docker
    log "🧹 Limpiando recursos Docker..."
    docker system prune -f || true
    
    # Verificar sintaxis
    log "🔍 Verificando sintaxis del docker-compose..."
    if ! $DOCKER_COMPOSE config &> /dev/null; then
        error "Error en la sintaxis del docker-compose.yaml"
        $DOCKER_COMPOSE config
        exit 1
    fi
    
    # Construir e iniciar servicios
    log "🔨 Construyendo imágenes..."
    $DOCKER_COMPOSE build --no-cache
    
    log "🚀 Iniciando servicios..."
    $DOCKER_COMPOSE up -d
    
    log "✅ Servicios iniciados"
}

# ===== VERIFICAR SERVICIOS =====
verify_deployment() {
    log "🔍 Verificando servicios..."
    
    cd "$PROJECT_DIR"
    
    # Determinar comando de docker-compose
    if command -v docker-compose &> /dev/null; then
        DOCKER_COMPOSE="docker-compose"
    elif docker compose version &> /dev/null 2>&1; then
        DOCKER_COMPOSE="docker compose"
    else
        return 1
    fi
    
    # Esperar estabilización
    sleep 15
    
    # Mostrar estado
    log "📊 Estado de los contenedores:"
    $DOCKER_COMPOSE ps
    
    # Health checks básicos
    log "🏥 Verificando servicios..."
    
    local ENDPOINTS=(
        "http://localhost:${NGINX_PORT:-2012}:Nginx Frontend"
        "http://localhost:${FRAUDE_API_PORT:-8000}/docs:API Fraude"
        "http://localhost:${TEXTOSQL_API_PORT:-8001}/docs:API TextoSQL"
    )
    
    for endpoint_info in "${ENDPOINTS[@]}"; do
        IFS=':' read -r endpoint name <<< "$endpoint_info"
        
        if curl -s --connect-timeout 10 "$endpoint" > /dev/null 2>&1; then
            log "✅ $name respondiendo"
        else
            warn "$name no responde o aún iniciando"
        fi
    done
}

# ===== MOSTRAR INFORMACIÓN FINAL =====
show_final_info() {
    local IP=$(hostname -I | awk '{print $1}' || echo "localhost")
    
    echo ""
    echo "======================================================"
    log "🎉 ¡INSTALACIÓN COMPLETADA EXITOSAMENTE!"
    echo "======================================================"
    echo ""
    echo "🌐 ACCESO PRINCIPAL:"
    echo "   Frontend: http://$IP:${NGINX_PORT:-2012}"
    echo "   Health Check: http://$IP:${NGINX_PORT:-2012}/health"
    echo ""
    echo "🔌 APIs DISPONIBLES:"
    echo "   Fraude API: http://$IP:${FRAUDE_API_PORT:-8000}/docs"
    echo "   TextoSQL API: http://$IP:${TEXTOSQL_API_PORT:-8001}/docs"
    echo ""
    echo "🗄️ BASE DE DATOS:"
    echo "   PostgreSQL: $IP:${DB_PORT:-8070}"
    echo "   Usuario: ${DB_USER:-postgres} / Contraseña: [Ver archivo .env]"
    echo ""
    echo "🧠 MODELOS LLM:"
    echo "   Gemma 2B: http://$IP:${GEMMA_2B_PORT:-8085}"
    echo "   Gemma 4B: http://$IP:${GEMMA_4B_PORT:-8086}"
    echo "   Gemma 12B: http://$IP:${GEMMA_12B_PORT:-8087}"
    echo "   Mistral: http://$IP:${MISTRAL_PORT:-8088}"
    echo "   DeepSeek 8B: http://$IP:${DEEPSEEK_8B_PORT:-8089}"
    echo "   DeepSeek 14B: http://$IP:${DEEPSEEK_14B_PORT:-8090}"
    echo ""
    echo "📁 UBICACIÓN DEL PROYECTO:"
    echo "   $PROJECT_DIR"
    echo ""
    echo "⚙️ CONFIGURACIÓN:"
    echo "   ✅ Archivo .env configurado desde: $(pwd)/.env"
    echo ""
    echo "📝 COMANDOS ÚTILES:"
    echo "   Ver logs: docker-compose logs -f [servicio]"
    echo "   Reiniciar: docker-compose restart [servicio]"
    echo "   Parar todo: docker-compose down"
    echo "   Ver estado: docker-compose ps"
    echo ""
    echo "======================================================"
}

# ===== FUNCIÓN PRINCIPAL =====
main() {
    log "🚀 Iniciando instalación completa de AI Platform..."
    
    # Verificar si se ejecuta como root
    if [ "$EUID" -ne 0 ]; then
        error "Este script debe ejecutarse como root (use sudo)"
        exit 1
    fi
    
    # Cargar configuración del .env como primer paso
    if [[ "${1:-full}" == "full" ]] || [[ "${1:-full}" == "prepare" ]] || [[ "${1:-full}" == "deploy" ]]; then
        load_env_config
    fi
    
    case "${1:-full}" in
        "detect")
            detect_system
            ;;
        "deps")
            detect_system
            install_system_dependencies
            ;;
        "docker")
            install_docker
            install_docker_compose
            ;;
        "firewall")
            if [ -f ".env" ]; then
                load_env_config
            fi
            configure_firewall
            ;;
        "download")
            if [ -f ".env" ]; then
                load_env_config
            fi
            download_repositories
            ;;
        "prepare")
            prepare_project
            ;;
        "deploy")
            deploy_services
            ;;
        "verify")
            if [ -f ".env" ]; then
                load_env_config
            fi
            verify_deployment
            ;;
        "full")
            detect_system
            check_system_resources
            install_system_dependencies
            install_docker
            install_docker_compose
            configure_firewall
            download_repositories
            prepare_project
            install_python_dependencies
            deploy_services
            verify_deployment
            show_final_info
            ;;
        *)
            echo "Uso: $0 [detect|deps|docker|firewall|download|prepare|deploy|verify|full]"
            echo ""
            echo "Opciones:"
            echo "  detect   - Solo detectar sistema y arquitectura"
            echo "  deps     - Solo instalar dependencias del sistema"
            echo "  docker   - Solo instalar Docker y Docker Compose"
            echo "  firewall - Solo configurar firewall"
            echo "  download - Solo descargar repositorios"
            echo "  prepare  - Solo preparar proyecto"
            echo "  deploy   - Solo desplegar servicios"
            echo "  verify   - Solo verificar servicios"
            echo "  full     - Hacer instalación completa (por defecto)"
            echo ""
            echo "NOTA: El archivo .env debe estar presente en el directorio actual"
            echo "      para las operaciones que requieren configuración."
            exit 1
            ;;
    esac
    
    log "✅ Operación completada exitosamente!"
}

# Verificar conexión a internet
if ! ping -c 1 google.com &> /dev/null; then
    warn "Sin conexión a internet detectada. Algunas operaciones pueden fallar."
fi

# Ejecutar función principal
main "$@"