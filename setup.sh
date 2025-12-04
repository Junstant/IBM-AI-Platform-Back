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
        echo "   - FRONT_DIR y BACK_DIR"
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
    local required_vars=("FRONT_DIR" "BACK_DIR" "DB_PASSWORD" "TOKEN_HUGGHINGFACE" "DEFAULT_PORTS")
    
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
    COMPOSE_FILE="$BACK_DIR/docker-compose.yaml"
    
    # Si REPO_BACK_URL y REPO_FRONT_URL no están definidas, usar valores por defecto
    REPO_BACK_URL=${REPO_BACK_URL:-"https://github.com/Junstant/IBM-AI-Platform-Back.git"}
    REPO_FRONT_URL=${REPO_FRONT_URL:-"https://github.com/Junstant/IBM-AI-Platform-Front.git"}
    
    log "📁 Directorios configurados:"
    log "   Backend: $BACK_DIR"
    log "   Frontend: $FRONT_DIR"
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
    DISK_AVAIL_GB=$(df -BG "$(dirname "$BACK_DIR")" 2>/dev/null | awk 'NR==2 {print $4}' | sed 's/G//' || echo "0")
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
                    
                    # Configurar zona docker para evitar conflictos
                    # NO agregar docker0 a trusted, Docker debe manejar su propia zona
                    log "🐳 Configurando zona docker en firewalld..."
                    firewall-cmd --permanent --new-zone=docker --quiet 2>/dev/null || true
                    firewall-cmd --permanent --zone=docker --set-target=ACCEPT --quiet 2>/dev/null || true
                    
                    # Agregar redes Docker a la zona docker (no las interfaces)
                    firewall-cmd --permanent --zone=docker --add-source=172.17.0.0/16 --quiet 2>/dev/null || true
                    firewall-cmd --permanent --zone=docker --add-source=172.18.0.0/16 --quiet 2>/dev/null || true
                    
                    # Habilitar masquerading en la zona pública para que Docker pueda acceder a internet
                    firewall-cmd --permanent --zone=public --add-masquerade --quiet 2>/dev/null || true
                    
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
    
    # Crear directorios padre si no existen
    mkdir -p "$(dirname "$BACK_DIR")"
    mkdir -p "$(dirname "$FRONT_DIR")"
    
    # Descargar repositorio backend
    log "📦 Descargando repositorio backend a $BACK_DIR..."
    if [ -d "$BACK_DIR" ]; then
        log "📁 Directorio backend existente encontrado, creando backup..."
        mv "$BACK_DIR" "${BACK_DIR}.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    if git clone "$REPO_BACK_URL" "$BACK_DIR"; then
        log "✅ Repositorio backend descargado exitosamente"
        cd "$BACK_DIR"
        log "📊 Commit actual backend: $(git rev-parse --short HEAD)"
    else
        error "Error al descargar el repositorio backend"
        exit 1
    fi
    
    # Descargar repositorio frontend
    log "📦 Descargando repositorio frontend a $FRONT_DIR..."
    if [ -d "$FRONT_DIR" ]; then
        log "📁 Directorio frontend existente encontrado, creando backup..."
        mv "$FRONT_DIR" "${FRONT_DIR}.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    if git clone "$REPO_FRONT_URL" "$FRONT_DIR"; then
        log "✅ Repositorio frontend descargado exitosamente"
        cd "$FRONT_DIR"
        log "📊 Commit actual frontend: $(git rev-parse --short HEAD)"
    else
        warn "No se pudo descargar el repositorio frontend (continuando sin él)"
    fi
    
    log "📍 Estructura final:"
    log "   Backend: $BACK_DIR"
    log "   Frontend: $FRONT_DIR"
}

# ===== PREPARAR PROYECTO =====
prepare_project() {
    log "📁 Preparando estructura del proyecto..."
    
    # Preparar directorio backend
    cd "$BACK_DIR"
    log "🔧 Configurando directorio backend: $BACK_DIR"
    
    # Hacer ejecutables los scripts en backend
    find . -name "*.sh" -type f -exec chmod +x {} \;
    
    # Crear directorios necesarios en backend
    mkdir -p {models,logs,backups,data}
    mkdir -p database/{data,backups}
    mkdir -p {fraude,textoSql}/logs
    mkdir -p nginx/{conf.d,certs}
    
    # Copiar .env desde el directorio original al backend
    if [ ! -f ".env" ] && [ -n "$ORIGINAL_ENV_PATH" ] && [ -f "$ORIGINAL_ENV_PATH" ]; then
        log "📄 Copiando archivo .env al directorio backend..."
        cp "$ORIGINAL_ENV_PATH" ".env"
        log "✅ Archivo .env copiado exitosamente al backend desde: $ORIGINAL_ENV_PATH"
        log "📍 Archivo .env backend disponible en: $(pwd)/.env"
    elif [ -f ".env" ]; then
        log "✅ Archivo .env ya existe en el backend"
    else
        warn "⚠️ No se pudo encontrar archivo .env para copiar al backend"
    fi
    
    # Preparar directorio frontend si existe
    if [ -d "$FRONT_DIR" ]; then
        cd "$FRONT_DIR"
        log "🔧 Configurando directorio frontend: $FRONT_DIR"
        
        # Hacer ejecutables los scripts en frontend
        find . -name "*.sh" -type f -exec chmod +x {} \; 2>/dev/null || true
        
        # Crear directorios necesarios en frontend
        mkdir -p {logs,dist,build}
        mkdir -p public/assets
        
        # Copiar .env al frontend también (para variables específicas del frontend)
        if [ ! -f ".env" ] && [ -n "$ORIGINAL_ENV_PATH" ] && [ -f "$ORIGINAL_ENV_PATH" ]; then
            log "� Copiando archivo .env al directorio frontend..."
            cp "$ORIGINAL_ENV_PATH" ".env"
            log "✅ Archivo .env copiado exitosamente al frontend"
            log "� Archivo .env frontend disponible en: $(pwd)/.env"
        elif [ -f ".env" ]; then
            log "✅ Archivo .env ya existe en el frontend"
        fi
    fi
    
    log "✅ Proyecto preparado con estructura separada"
    log "📁 Backend: $BACK_DIR"
    log "📁 Frontend: $FRONT_DIR"
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
    
    # Cambiar al directorio backend donde está el docker-compose
    cd "$BACK_DIR"
    
    # Verificar que el archivo .env esté presente en el backend
    if [ ! -f ".env" ]; then
        error "❌ Archivo .env no encontrado en $BACK_DIR"
        echo ""
        echo "🔍 POSIBLES SOLUCIONES:"
        echo "1. Verificar que el .env original esté en el directorio donde ejecutó el script"
        echo "2. Ejecutar primero: sudo ./setup.sh prepare"
        echo "3. Copiar manualmente el .env: cp /ruta/original/.env $BACK_DIR/.env"
        echo ""
        if [ -n "$ORIGINAL_ENV_PATH" ]; then
            echo "📍 Archivo .env original esperado en: $ORIGINAL_ENV_PATH"
            if [ -f "$ORIGINAL_ENV_PATH" ]; then
                log "💡 Copiando archivo .env automáticamente al backend..."
                cp "$ORIGINAL_ENV_PATH" ".env"
                log "✅ Archivo .env copiado exitosamente al backend"
            else
                echo "❌ Archivo .env no encontrado en la ruta original"
            fi
        fi
        
        # Verificar nuevamente después del intento de copia
        if [ ! -f ".env" ]; then
            exit 1
        fi
    else
        log "✅ Archivo .env encontrado en el directorio backend"
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
    
    log "🔧 Usando comando: $DOCKER_COMPOSE desde $BACK_DIR"
    
    # Verificar que docker-compose.yaml existe
    if [ ! -f "docker-compose.yaml" ] && [ ! -f "docker-compose.yml" ]; then
        error "No se encontró docker-compose.yaml en $BACK_DIR"
        exit 1
    fi
    
    # Parar servicios existentes (incluyendo perfil full)
    log "🛑 Deteniendo servicios existentes..."
    $DOCKER_COMPOSE --profile full down -v || true
    
    # Limpiar recursos Docker COMPLETAMENTE (imágenes, contenedores, volúmenes, redes)
    log "🧹 Limpieza profunda de recursos Docker..."
    log "   ⚠️  Eliminando: contenedores, imágenes no usadas, volúmenes y redes"
    docker system prune -a --volumes --force || true
    
    # Verificar sintaxis
    log "🔍 Verificando sintaxis del docker-compose..."
    if ! $DOCKER_COMPOSE config &> /dev/null; then
        error "Error en la sintaxis del docker-compose.yaml"
        $DOCKER_COMPOSE config
        exit 1
    fi
    
    # ✅ CONSTRUIR E INICIAR SERVICIOS CON PERFIL FULL (TODOS LOS MODELOS)
    log "🚀 Construyendo y levantando TODOS los servicios (perfil full)..."
    log "📊 Esto incluye:"
    log "   • Gemma 2B (siempre activo)"
    log "   • Gemma 4B"
    log "   • Gemma 12B"
    log "   • Mistral 7B"
    log "   • DeepSeek 8B"
    log "   • APIs (Fraude, TextoSQL, Stats, RAG)"
    log "   • Frontend (Nginx)"
    log "   • PostgreSQL"
    log "   • Milvus Stack (etcd + MinIO + Milvus)"
    echo ""
    warn "⚠️  IMPORTANTE: Levantar todos los modelos requiere ~50GB RAM"
    warn "⏱️  El inicio completo puede tomar 10-15 minutos"
    echo ""
    
    # Paso 1: FORZAR RECREACIÓN COMPLETA DE LA BASE DE DATOS
    log "🔄 Forzando recreación completa de la base de datos PostgreSQL..."
    log "⚠️  Esto eliminará todos los datos existentes y aplicará el esquema desde cero"
    
    # Detener PostgreSQL si está corriendo
    $DOCKER_COMPOSE stop postgres || true
    
    # Obtener el nombre del contenedor de PostgreSQL del docker-compose
    POSTGRES_CONTAINER=$($DOCKER_COMPOSE ps -q postgres 2>/dev/null || echo "")
    if [ -z "$POSTGRES_CONTAINER" ]; then
        # Si no está corriendo, buscar por nombre común
        POSTGRES_CONTAINER=$(docker ps -a --filter "name=postgres" --format "{{.Names}}" | head -n1)
    fi
    
    # Si encontramos el contenedor, obtener su nombre real
    if [ -n "$POSTGRES_CONTAINER" ]; then
        log "📦 Contenedor PostgreSQL encontrado: $POSTGRES_CONTAINER"
        # Detener y eliminar el contenedor
        docker stop "$POSTGRES_CONTAINER" 2>/dev/null || true
        docker rm "$POSTGRES_CONTAINER" 2>/dev/null || true
    fi
    
    # Eliminar el volumen de datos de PostgreSQL para forzar reinicio limpio
    log "🗑️ Eliminando volúmenes de PostgreSQL (forzar init scripts)..."
    
    # Buscar y eliminar TODOS los volúmenes de postgres (incluye prefijos de proyecto)
    POSTGRES_VOLUMES=$(docker volume ls --format "{{.Name}}" | grep -E "(postgres|aipl_postgres)" || true)
    
    if [ -n "$POSTGRES_VOLUMES" ]; then
        echo "$POSTGRES_VOLUMES" | while read -r vol; do
            log "  🗑️ Eliminando volumen: $vol"
            docker volume rm "$vol" 2>/dev/null || warn "    ⚠️ No se pudo eliminar $vol (puede estar en uso)"
        done
    else
        log "  ℹ️ No se encontraron volúmenes de PostgreSQL para eliminar"
    fi
    
    # Forzar eliminación con prune si aún existen
    log "🧹 Limpieza adicional de volúmenes..."
    docker volume prune -f 2>/dev/null || true
    
    # Verificar que se eliminaron correctamente
    REMAINING=$(docker volume ls --format "{{.Name}}" | grep -E "(postgres|aipl_postgres)" | wc -l)
    if [ "$REMAINING" -eq 0 ]; then
        log "✅ Todos los volúmenes de PostgreSQL eliminados correctamente"
    else
        warn "⚠️ Aún quedan $REMAINING volúmenes de PostgreSQL"
        docker volume ls --format "table {{.Name}}\t{{.Driver}}\t{{.Mountpoint}}" | grep -E "(postgres|aipl_postgres)" || true
        
        # Intentar eliminación forzada
        log "🔨 Intentando eliminación forzada..."
        docker volume ls --format "{{.Name}}" | grep -E "(postgres|aipl_postgres)" | xargs -r docker volume rm -f 2>/dev/null || true
    fi
    
    # Levantar infraestructura base (PostgreSQL y Milvus)
    log "🗄️ Iniciando bases de datos (PostgreSQL y Milvus Stack)..."
    PGDATA=/var/lib/postgresql/data $DOCKER_COMPOSE up -d postgres etcd minio
    
    # Esperar a que el contenedor esté completamente iniciado
    log "⏳ Esperando que PostgreSQL inicie (puede tardar 2-3 minutos para init scripts)..."
    sleep 30
    
    # Obtener el nombre real del contenedor de forma más simple
    POSTGRES_CONTAINER=$(docker ps --filter "name=postgres" --format "{{.Names}}" | head -n1)
    
    # Si no se encontró, usar nombre por defecto
    if [ -z "$POSTGRES_CONTAINER" ]; then
        POSTGRES_CONTAINER="postgres_db"
    fi
    
    # Verificar que PostgreSQL esté respondiendo con reintentos extendidos
    log "🔍 Verificando conectividad de PostgreSQL (contenedor: $POSTGRES_CONTAINER)..."
    local retries=0
    local max_retries=36  # 3 minutos máximo (36 * 5s) para init scripts
    
    until docker exec "$POSTGRES_CONTAINER" pg_isready -U postgres > /dev/null 2>&1; do
        retries=$((retries+1))
        if [ $retries -ge $max_retries ]; then
            error "PostgreSQL no respondió después de $max_retries intentos"
            log "📋 Últimos logs de PostgreSQL:"
            docker logs "$POSTGRES_CONTAINER" --tail 50 2>&1 || echo "No se pudieron obtener los logs"
            log "📋 Contenedores en ejecución:"
            docker ps -a
            exit 1
        fi
        
        # Mostrar progreso de init scripts cada 4 intentos
        if [ $((retries % 4)) -eq 0 ]; then
            log "⏳ PostgreSQL iniciando... ($((retries * 5))s transcurridos)"
            docker exec "$POSTGRES_CONTAINER" ls -la /var/lib/postgresql/data/ 2>/dev/null | grep -q "PG_VERSION" && log "   ✓ PGDATA inicializado" || log "   ⧗ Esperando PGDATA..."
        fi
        
        sleep 5
    done
    log "✅ PostgreSQL respondiendo"
    
    # CRÍTICO: Esperar a que init scripts terminen de ejecutarse
    log "⏳ Esperando finalización de init scripts (monitoreando procesos)..."
    local init_wait=0
    local max_init_wait=24  # 2 minutos adicionales (24 * 5s)
    
    while [ $init_wait -lt $max_init_wait ]; do
        # Verificar si hay procesos psql activos (indicaría que init scripts están corriendo)
        PSQL_PROCS=$(docker exec "$POSTGRES_CONTAINER" sh -c "ps aux | grep -E 'psql|postgres.*initdb' | grep -v grep" || echo "")
        
        if [ -z "$PSQL_PROCS" ]; then
            log "✅ Init scripts completados (no hay procesos psql activos)"
            break
        fi
        
        init_wait=$((init_wait+1))
        if [ $((init_wait % 3)) -eq 0 ]; then
            log "   ⧗ Init scripts en ejecución... ($((init_wait * 5))s)"
        fi
        sleep 5
    done
    
    # Espera adicional de seguridad
    log "⏳ Espera de seguridad (15s)..."
    sleep 15
    
    log "✅ PostgreSQL completamente inicializado"
    
    # Verificar que las bases de datos existan y esquemas se hayan aplicado
    log "🔍 Verificando bases de datos y esquemas..."
    
    # Verificar bases de datos
    DB_COUNT=$(docker exec "$POSTGRES_CONTAINER" psql -U postgres -tAc "SELECT COUNT(*) FROM pg_database WHERE datname IN ('banco_global', 'bank_transactions', 'ai_platform_stats', 'ai_platform_rag')" 2>/dev/null || echo "0")
    
    if [ "$DB_COUNT" -ne 4 ]; then
        error "❌ Solo se encontraron $DB_COUNT/4 bases de datos"
        log "📋 Bases de datos existentes:"
        docker exec "$POSTGRES_CONTAINER" psql -U postgres -c '\l'
        log "📋 Logs de PostgreSQL (init scripts):"
        docker logs "$POSTGRES_CONTAINER" 2>&1 | tail -100
        exit 1
    fi
    
    log "✅ Bases de datos encontradas: $DB_COUNT/4"
    
    # Verificar esquemas (tabla crítica en cada BD)
    log "🔍 Verificando esquemas aplicados..."
    
    STATS_TABLES=$(docker exec "$POSTGRES_CONTAINER" psql -U postgres -d ai_platform_stats -tAc "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public'" 2>/dev/null || echo "0")
    BANCO_TABLES=$(docker exec "$POSTGRES_CONTAINER" psql -U postgres -d banco_global -tAc "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public'" 2>/dev/null || echo "0")
    TRANS_TABLES=$(docker exec "$POSTGRES_CONTAINER" psql -U postgres -d bank_transactions -tAc "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public'" 2>/dev/null || echo "0")
    RAG_TABLES=$(docker exec "$POSTGRES_CONTAINER" psql -U postgres -d ai_platform_rag -tAc "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public'" 2>/dev/null || echo "0")
    
    log "   📊 ai_platform_stats: $STATS_TABLES tablas"
    log "   🏦 banco_global: $BANCO_TABLES tablas"
    log "   💳 bank_transactions: $TRANS_TABLES tablas"
    log "   🧠 ai_platform_rag: $RAG_TABLES tablas"
    
    # Validar que se crearon las tablas
    local schema_failed=0
    
    if [ "$STATS_TABLES" -eq 0 ]; then
        error "❌ No se crearon tablas en ai_platform_stats"
        schema_failed=1
    fi
    
    if [ "$BANCO_TABLES" -eq 0 ]; then
        warn "⚠️ No se crearon tablas en banco_global"
    fi
    
    if [ "$TRANS_TABLES" -eq 0 ]; then
        warn "⚠️ No se crearon tablas en bank_transactions"
    fi
    
    if [ "$RAG_TABLES" -eq 0 ]; then
        warn "⚠️ No se crearon tablas en ai_platform_rag"
    fi
    
    if [ $schema_failed -eq 1 ]; then
        error "❌ Fallo crítico: ai_platform_stats sin esquema"
        log "📋 Logs de inicialización de PostgreSQL:"
        docker logs "$POSTGRES_CONTAINER" --tail 100 2>&1 | grep -A5 -B5 "init"
        log ""
        log "🔧 SOLUCIÓN MANUAL:"
        log "   1. Ejecutar: cd $BACK_DIR/database"
        log "   2. Ejecutar: ./force-init-schemas.sh"
        exit 1
    fi
    
    log "✅ Todos los esquemas verificados correctamente"
    
    # Iniciar Milvus
    $DOCKER_COMPOSE up -d milvus
    log "⏳ Esperando que Milvus esté listo (30s)..."
    sleep 30
    
    # Paso 2: Levantar modelos LLM (con perfil full)
    log "🤖 Iniciando modelos LLM (esto puede tomar varios minutos)..."
    $DOCKER_COMPOSE --profile full up --build -d
    
    if [ $? -eq 0 ]; then
        log "✅ Servicios iniciados exitosamente con perfil full desde $BACK_DIR"
    else
        error "❌ Error al iniciar servicios"
        log "📋 Mostrando logs de error:"
        $DOCKER_COMPOSE --profile full logs --tail=50
        exit 1
    fi
}

# ===== VERIFICAR SERVICIOS =====
verify_deployment() {
    log "🔍 Verificando servicios..."
    
    cd "$BACK_DIR"
    
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
        "http://localhost:${FRAUDE_API_PORT:-8001}/docs:API Fraude"
        "http://localhost:${TEXTOSQL_API_PORT:-8000}/docs:API TextoSQL"
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
    echo "📁 ESTRUCTURA DE DIRECTORIOS:"
    echo "   Backend: $BACK_DIR"
    echo "   Frontend: $FRONT_DIR"
    echo ""
    echo "🌐 ACCESO PRINCIPAL:"
    echo "   Frontend: http://$IP:${NGINX_PORT:-2012}"
    echo "   Health Check: http://$IP:${NGINX_PORT:-2012}/health"
    echo ""
    echo "🔌 APIs DISPONIBLES:"
    echo "   TextoSQL API: http://$IP:${TEXTOSQL_API_PORT:-8000}/docs"
    echo "   Fraude API: http://$IP:${FRAUDE_API_PORT:-8001}/docs"
    echo "   Stats API: http://$IP:${STATS_PORT:-8003}/docs"
    echo "   RAG API (Milvus): http://$IP:${RAG_API_PORT:-8004}/docs"
    echo ""
    echo "🗄️ BASES DE DATOS:"
    echo "   PostgreSQL: $IP:${DB_PORT:-8070}"
    echo "   Usuario: ${DB_USER:-postgres} / Contraseña: [Ver archivo .env]"
    echo "   pgvector: v0.8.1 (compilado automáticamente)"
    echo ""
    echo "   Milvus Vector DB: $IP:${MILVUS_PORT:-19530} (gRPC)"
    echo "   MinIO Console: http://$IP:${MINIO_CONSOLE_PORT:-9001}"
    echo "   MinIO Usuario: minioadmin / minioadmin"
    echo ""
    echo "🧠 MODELOS LLM:"
    echo "   Gemma 2B: http://$IP:${GEMMA_2B_PORT:-8085}"
    echo "   Gemma 4B: http://$IP:${GEMMA_4B_PORT:-8086}"
    echo "   Gemma 12B: http://$IP:${GEMMA_12B_PORT:-8087}"
    echo "   Mistral: http://$IP:${MISTRAL_PORT:-8088}"
    echo "   DeepSeek 8B: http://$IP:${DEEPSEEK_8B_PORT:-8089}"
    echo ""
    echo "⚙️ CONFIGURACIÓN:"
    echo "   ✅ Backend configurado en: $BACK_DIR/.env"
    echo "   ✅ Frontend configurado en: $FRONT_DIR/.env"
    echo ""
    echo "📝 COMANDOS ÚTILES:"
    echo "   Ir al backend: cd $BACK_DIR"
    echo "   Ir al frontend: cd $FRONT_DIR"
    echo "   Ver logs: cd $BACK_DIR && docker-compose logs -f [servicio]"
    echo "   Reiniciar: cd $BACK_DIR && docker-compose restart [servicio]"
    echo "   Parar todo: cd $BACK_DIR && docker-compose down"
    echo "   Ver estado: cd $BACK_DIR && docker-compose ps"
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
            # Cargar configuración para obtener rutas
            if [ -f ".env" ]; then
                load_env_config
            fi
            
            # Actualizar backend
            log "📥 Actualizando código del backend desde repositorio..."
            if [ -d "$BACK_DIR/.git" ]; then
                cd "$BACK_DIR"
                git pull origin main || warn "No se pudo hacer git pull en backend (continuando con código local)"
            else
                warn "Backend no es un repositorio git, usando código local"
            fi
            
            # Actualizar frontend
            log "📥 Actualizando código del frontend desde repositorio..."
            if [ -d "$FRONT_DIR/.git" ]; then
                cd "$FRONT_DIR"
                git pull origin main || warn "No se pudo hacer git pull en frontend (continuando con código local)"
            else
                warn "Frontend no es un repositorio git, usando código local"
            fi
            
            # Desplegar servicios
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