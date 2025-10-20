#!/bin/bash
# ---
# SCRIPT SEGURO PARA INSTALAR Y ACTUALIZAR DEMOS
# ---
# Idempotente y no-destructivo.
#
# CÓMO USAR:
# 1. Coloca este script (ej: setup_demo.sh) en un directorio en tu servidor (ej: /home/usuario/).
# 2. Coloca tu archivo .env con las contraseñas en ESE MISMO DIRECTORIO.
# 3. Edita las 4 variables en la sección "CONFIGURACIÓN REQUERIDA" de abajo.
# 4. Dale permisos: chmod +x setup_demo.sh
# 5. Ejecútalo como root: sudo ./setup_demo.sh
# ---

set -e

# --- CONFIGURACIÓN REQUERIDA ---
# ❗️ Edita estas 4 líneas
REPO_BACK_URL="https://github.com/Junstant/IBM-AI-Platform-Back.git"
REPO_FRONT_URL="https://github.com/Junstant/IBM-AI-Platform-Front.git"
BACK_END_DIR="/opt/ai-platform/backend"
FRONT_END_DIR="/opt/ai-platform/frontend"
# -------------------------------

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "[$(date +'%Y-%m-%d %H:%M:%S')] ${GREEN}$1${NC}"; }
warn() { echo -e "[$(date +'%Y-%m-%d %H:%M:%S')] ${YELLOW}⚠️  $1${NC}"; }
error() { echo -e "[$(date +'%Y-%m-%d %H:%M:%S')] ${RED}❌ $1${NC}"; }
info() { echo -e "[$(date +'%Y-%m-%d %H:%M:%S')] ${BLUE}ℹ️  $1${NC}"; }

# Variables globales
PKG_MANAGER=""
ORIGINAL_ENV_PATH=""
DOCKER_COMPOSE=""

# ===== 1. DETECTAR SISTEMA Y VERIFICAR ROOT =====
detect_system() {
    if [ "$EUID" -ne 0 ]; then
        error "Este script debe ejecutarse como root (use sudo)"
        exit 1
    fi
    info "Detección de sistema..."
    if command -v dnf &> /dev/null; then PKG_MANAGER="dnf";
    elif command -v yum &> /dev/null; then PKG_MANAGER="yum";
    elif command -v apt-get &> /dev/null; then PKG_MANAGER="apt";
    else
        error "Gestor de paquetes no soportado (se necesita dnf, yum, o apt)"
        exit 1
    fi
    info "📦 Gestor de paquetes detectado: $PKG_MANAGER"
}

# ===== 2. CARGAR Y VERIFICAR .ENV DE ORIGEN =====
load_env_config() {
    info "Buscando archivo .env de origen..."
    
    # Guarda la ruta absoluta del .env que debe estar JUNTO a este script
    ORIGINAL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
    ORIGINAL_ENV_PATH="$ORIGINAL_DIR/.env"
    
    if [ ! -f "$ORIGINAL_ENV_PATH" ]; then
        error "Archivo .env no encontrado en $ORIGINAL_DIR"
        error "Por favor, crea un archivo .env en el mismo directorio que este script."
        exit 1
    fi
    
    # Cargar variables para usarlas en este script (ej: puertos para el firewall)
    set -a
    source "$ORIGINAL_ENV_PATH"
    set +a
    
    log "✅ Configuración .env cargada desde: $ORIGINAL_ENV_PATH"
}

# ===== 3. INSTALAR DEPENDENCIAS MÍNIMAS (IDEMPOTENTE) =====
install_prerequisites() {
    info "Verificando dependencias mínimas (Git y Docker)..."
    
    # --- Instalar Git (solo si falta) ---
    if ! command -v git &> /dev/null; then
        log "Instalando Git..."
        case "$PKG_MANAGER" in
            dnf|yum) $PKG_MANAGER install -y git ;;
            apt) apt-get install -y git ;;
        esac
        log "✅ Git instalado."
    else
        log "✅ Git ya está instalado."
    fi

    # --- Instalar Docker (solo si falta) ---
    if ! command -v docker &> /dev/null; then
        log "Instalando Docker..."
        if [ "$PKG_MANAGER" == "apt" ]; {
            apt-get update -y
            apt-get install -y ca-certificates curl
            install -m 0755 -d /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
            chmod a+r /etc/apt/keyrings/docker.asc
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
            apt-get update -y
            apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        } else { # dnf/yum
            $PKG_MANAGER install -y dnf-plugins-core
            $PKG_MANAGER config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            # Nota: No removemos podman. Si hay conflicto, la instalación fallará y requerirá intervención manual (esto es más seguro).
            $PKG_MANAGER install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin --allowerasing || warn "No se pudo instalar Docker. ¿Conflicto con Podman?"
        } fi
        
        systemctl enable docker
        systemctl start docker
        log "✅ Docker instalado y activado."
    else
        log "✅ Docker ya está instalado."
    fi
    
    # --- Verificar Docker Compose ---
    if docker compose version &> /dev/null 2>&1; then
        DOCKER_COMPOSE="docker compose"
        log "✅ Docker Compose (plugin) encontrado."
    elif command -v docker-compose &> /dev/null; then
        DOCKER_COMPOSE="docker-compose"
        log "✅ Docker Compose (standalone) encontrado."
    else
        error "No se pudo encontrar 'docker compose' ni 'docker-compose'."
        error "La instalación de Docker pudo haber fallado."
        exit 1
    fi
}

# ===== 4. CONFIGURAR FIREWALL (IDEMPOTENTE) =====
setup_firewall() {
    info "🔥 Configurando firewall..."
    
    # Extraer puertos del .env (cargado en paso 2)
    local PORTS_TO_CONFIGURE=()
    eval "PORTS_TO_CONFIGURE=($DEFAULT_PORTS)"
    
    if [ ${#PORTS_TO_CONFIGURE[@]} -eq 0 ]; then
        warn "No se encontraron DEFAULT_PORTS en el .env. Omitiendo firewall."
        return
    fi
    info "Abriendo puertos: ${PORTS_TO_CONFIGURE[*]}"

    if command -v firewall-cmd &> /dev/null; then
        # --- firewalld (CentOS/RHEL) ---
        if ! systemctl is-active firewalld &> /dev/null; then
            log "Iniciando firewalld..."
            systemctl enable firewalld
            systemctl start firewalld
        fi
        
        for port in "${PORTS_TO_CONFIGURE[@]}"; do
            if ! firewall-cmd --permanent --query-port=${port}/tcp &> /dev/null; then
                firewall-cmd --permanent --add-port=${port}/tcp
                log "Puerto $port/tcp abierto en firewalld."
            else
                log "Puerto $port/tcp ya estaba abierto."
            fi
        done
        firewall-cmd --reload
        log "✅ firewalld configurado."

    elif command -v ufw &> /dev/null; then
        # --- ufw (Ubuntu) ---
        for port in "${PORTS_TO_CONFIGURE[@]}"; do
            ufw allow "$port"/tcp
        done
        ufw --force enable
        log "✅ UFW configurado."
    else
        warn "No se encontró firewalld ni ufw. Omita este paso si el firewall se gestiona externamente."
    fi
}

# ===== 5. OBTENER REPOSITORIOS (NO-DESTRUCTIVO) =====
setup_repositories() {
    info "📥 Sincronizando repositorios..."
    
    # --- Sincronizar Backend ---
    if [ -d "$BACK_END_DIR/.git" ]; then
        log "Directorio backend encontrado. Actualizando (git pull)..."
        cd "$BACK_END_DIR"
        git pull
    else
        log "Directorio backend no encontrado. Clonando..."
        git clone "$REPO_BACK_URL" "$BACK_END_DIR"
    fi
    log "✅ Backend sincronizado en $BACK_END_DIR"

    # --- Sincronizar Frontend ---
    if [ -d "$FRONT_END_DIR/.git" ]; then
        log "Directorio frontend encontrado. Actualizando (git pull)..."
        cd "$FRONT_END_DIR"
        git pull
    else
        log "Directorio frontend no encontrado. Clonando..."
        git clone "$REPO_FRONT_URL" "$FRONT_END_DIR"
    fi
    log "✅ Frontend sincronizado en $FRONT_END_DIR"
}

# ===== 6. PREPARAR PROYECTO (COPIAR .ENV) =====
prepare_project() {
    info "📁 Preparando estructura del proyecto..."
    
    # --- Backend ---
    cd "$BACK_END_DIR"
    log "Copiando .env a $BACK_END_DIR/.env"
    cp "$ORIGINAL_ENV_PATH" ".env"
    
    # Crear directorios necesarios (seguro si ya existen)
    mkdir -p {models,logs,backups,data}
    mkdir -p database/{data,backups}
    mkdir -p {fraude,textoSql}/logs
    mkdir -p nginx/{conf.d,certs}
    log "✅ Estructura de backend preparada."

    # --- Frontend ---
    if [ -d "$FRONT_END_DIR" ]; then
        cd "$FRONT_END_DIR"
        log "Copiando .env a $FRONT_END_DIR/.env"
        cp "$ORIGINAL_ENV_PATH" ".env"
        
        # Crear directorios
        mkdir -p {logs,dist,build}
        mkdir -p public/assets
        log "✅ Estructura de frontend preparada."
    fi
}

# ===== 7. DESPLEGAR SERVICIOS (SEGURO) =====
deploy_services() {
    info "🚀 Desplegando servicios con Docker Compose..."
    cd "$BACK_END_DIR"
    
    if [ ! -f "docker-compose.yaml" ] && [ ! -f "docker-compose.yml" ]; then
        error "No se encontró docker-compose.yaml en $BACK_END_DIR"
        exit 1
    fi

    log "Verificando sintaxis de Docker Compose..."
    $DOCKER_COMPOSE config
    
    log "Deteniendo servicios anteriores (down)..."
    $DOCKER_COMPOSE down
    
    log "Construyendo imágenes nuevas (build)..."
    $DOCKER_COMPOSE build
    
    log "Iniciando servicios nuevos (up -d)..."
    $DOCKER_COMPOSE up -d
    
    log "🧹 Limpiando imágenes 'dangling' (antiguas)..."
    docker image prune -f
    
    log "✅ Servicios desplegados."
}

# ===== 8. VERIFICAR DESPLIEGUE =====
verify_deployment() {
    info "🔍 Verificando servicios (esperando 15 segundos)..."
    sleep 15
    
    cd "$BACK_END_DIR"
    log "📊 Estado de los contenedores:"
    $DOCKER_COMPOSE ps
    
    log "🏥 Verificando endpoints (usando puertos del .env)..."
    local all_ok=true
    
    # Lista de puertos a verificar (basado en el .env)
    local ENDPOINTS_TO_CHECK=(
        "http://localhost:${NGINX_PORT:-2012}:Nginx"
        "http://localhost:${FRAUDE_API_PORT:-8001}/docs:API Fraude"
        "http://localhost:${TEXTOSQL_API_PORT:-8000}/docs:API TextoSQL"
    )

    for item in "${ENDPOINTS_TO_CHECK[@]}"; do
        IFS=':' read -r endpoint name <<< "$item"
        if curl -s --fail --connect-timeout 10 "$endpoint" > /dev/null 2>&1; then
            log "✅ $name responde en $endpoint"
        else
            warn "$name NO responde o está fallando en $endpoint"
            all_ok=false
        fi
    done

    if [ "$all_ok" = true ]; then
        log "🎉 ¡Todos los servicios principales están respondiendo!"
    else
        warn "Algunos servicios no están respondiendo. Revisa los logs:"
        echo -e "   ${YELLOW}cd $BACK_END_DIR && $DOCKER_COMPOSE logs -f${NC}"
    fi
}

# ===== FUNCIÓN PRINCIPAL =====
main() {
    log "🚀 Iniciando script de instalación/actualización de Demo AI Platform..."
    
    detect_system
    load_env_config
    install_prerequisites
    setup_firewall
    setup_repositories
    prepare_project
    deploy_services
    verify_deployment
    
    echo ""
    log "🎉 --- DESPLIEGUE COMPLETADO --- 🎉"
    echo -e "${BLUE}ℹ️  Accede a la plataforma en: http://$(hostname -I | awk '{print $1}')${NC}"
}

# Ejecutar
main "$@"