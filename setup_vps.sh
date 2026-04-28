#!/bin/bash

# =================================================================
# 🚀 ULTRA-SETUP VPS PREMIUM - TALLER AI
# =================================================================
# Versión: 3.0 (PostgreSQL Admin Integration)
# =================================================================

# --- CONFIGURACIÓN ---
PYTHON_VER="3.12.3"
DB_PACKAGE="postgresql-16" # Cambiado a 16 por estabilidad, o usar la solicitada si está en repo
DB_VERSION_REQ="18.3-1.pgdg24.04+1" 
VENV_NAME=".venv"
ENV_FILE=".env"

# Colores Premium
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'
BOLD='\033[1m'

# --- ANIMACIONES Y UI ---

spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

progress_bar() {
    local duration=$1
    local width=40
    local progress=0
    while [ $progress -le 100 ]; do
        local filled=$((progress * width / 100))
        local empty=$((width - filled))
        printf "\r${CYAN} Progreso: [${GREEN}"
        printf "%${filled}s" | tr ' ' '█'
        printf "${NC}"
        printf "%${empty}s" | tr ' ' '░'
        printf "${CYAN}] %d%%${NC}" "$progress"
        progress=$((progress + 5))
        sleep 0.1
    done
    echo ""
}

show_banner() {
    clear
    echo -e "${MAGENTA}${BOLD}"
    echo "  ██████╗ ███████╗████████╗██╗   ██╗██████╗ "
    echo "  ██╔══██╗██╔════╝╚══██╔══╝██║   ██║██╔══██╗"
    echo "  ██████╔╝█████╗     ██║   ██║   ██║██████╔╝"
    echo "  ██╔═══╝ ██╔══╝     ██║   ██║   ██║██╔═══╝ "
    echo "  ██║     ███████╗   ██║   ╚██████╔╝██║     "
    echo "  ╚═╝     ╚══════╝   ╚═╝    ╚═════╝ ╚═╝     "
    echo -e "         ${CYAN}ADMIN DEPLOYMENT v3.0${NC}\n"
}

# --- INICIO DEL SCRIPT ---

show_banner
echo -e "${YELLOW}${BOLD}>>> INICIANDO CONFIGURACIÓN NIVEL ADMINISTRADOR${NC}"
progress_bar

# 1. CAPTURA DE DATOS INTERACTIVA
echo -e "\n${BLUE}${BOLD}[ CONFIGURACIÓN DE BASE DE DATOS ]${NC}"
read -p "  👤 Ingrese Nuevo Usuario de DB: " DB_USER
if [ -z "$DB_USER" ]; then DB_USER="admin_taller"; fi

while true; do
    read -s -p "  🔑 Ingrese Contraseña para $DB_USER: " DB_PASS
    echo ""
    read -s -p "  🔄 Repita la Contraseña: " DB_PASS_CONF
    echo ""
    if [ "$DB_PASS" == "$DB_PASS_CONF" ]; then
        echo -e "  ${GREEN}✅ Contraseñas listas.${NC}"
        break
    else
        echo -e "  ${RED}❌ Las contraseñas no coinciden. Intente de nuevo.${NC}"
    fi
done

echo -e "\n${BLUE}${BOLD}[ CONFIGURACIÓN DE RED ]${NC}"
echo -e "  1) Localhost (127.0.0.1)"
echo -e "  2) IP del VPS (Detección automática)"
read -p "  Seleccione opción [1]: " HOST_CHOICE

if [ "$HOST_CHOICE" == "2" ]; then
    echo -ne "  🔍 Detectando IP pública..."
    VPS_IP=$(curl -s ifconfig.me)
    DB_HOST=$VPS_IP
    echo -e " ${GREEN}Detectada: $DB_HOST${NC}"
else
    DB_HOST="127.0.0.1"
fi

# 2. ACTUALIZACIÓN DEL SISTEMA
echo -e "\n${YELLOW}>>> 1. Actualizando sistema y repositorios...${NC}"
(sudo apt update && sudo apt upgrade -y) > /dev/null 2>&1 &
spinner $!
echo -e "${GREEN}   ✅ Sistema al día.${NC}"

# 3. INSTALAR POSTGRESQL Y CONFIGURAR SUPERUSER
echo -e "\n${YELLOW}>>> 2. Instalando y Configurando PostgreSQL ($DB_VERSION_REQ)...${NC}"
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt update > /dev/null 2>&1

# Instalación de servidor y cliente
(sudo apt install -y postgresql postgresql-contrib postgresql-client build-essential jq) > /dev/null 2>&1 &
spinner $!

echo -e "   🐘 Creando usuario administrador '$DB_USER' en PostgreSQL..."
sudo systemctl start postgresql
# Crear usuario con permisos de SUPERUSER (Administrador total)
sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';" > /dev/null 2>&1
sudo -u postgres psql -c "ALTER USER $DB_USER WITH SUPERUSER;" > /dev/null 2>&1

# Crear base de datos por defecto si no existe
DB_NAME_VAL="taller_db"
sudo -u postgres psql -c "CREATE DATABASE $DB_NAME_VAL OWNER $DB_USER;" > /dev/null 2>&1
echo -e "${GREEN}   ✅ Usuario '$DB_USER' creado con permisos de SUPERUSER.${NC}"

# 4. INSTALAR PYTHON 3.12.3
echo -e "\n${YELLOW}>>> 3. Instalando Python $PYTHON_VER vía pyenv...${NC}"
if [ ! -d "$HOME/.pyenv" ]; then
    (curl https://pyenv.run | bash) > /dev/null 2>&1 &
    spinner $!
fi

export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

if ! grep -q "pyenv" "$HOME/.bashrc"; then
    echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
    echo '[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
    echo 'eval "$(pyenv init -)"' >> ~/.bashrc
fi

echo -e "   ⚙️  Compilando Python $PYTHON_VER (paciencia...)"
(pyenv install $PYTHON_VER -s) > /dev/null 2>&1 &
spinner $!
pyenv global $PYTHON_VER

# 5. ENTORNO VIRTUAL Y DEPENDENCIAS
echo -e "\n${YELLOW}>>> 4. Configurando Entorno Virtual y Reqs...${NC}"
python -m venv $VENV_NAME
source $VENV_NAME/bin/activate

(pip install --upgrade pip && pip install -r backend/requirements.txt rich questionary) > /dev/null 2>&1 &
spinner $!
echo -e "${GREEN}   ✅ Entorno listo.${NC}"

# 6. CONFIGURAR .ENV
echo -e "\n${YELLOW}>>> 5. Sincronizando credenciales en $ENV_FILE...${NC}"
if [ ! -f $ENV_FILE ]; then
    cp backend/.env.example $ENV_FILE 2>/dev/null || touch $ENV_FILE
fi

# Actualizar el .env con sed
sed -i "s/^DB_USER=.*/DB_USER=$DB_USER/" $ENV_FILE
sed -i "s/^DB_PASSWORD=.*/DB_PASSWORD=$DB_PASS/" $ENV_FILE
sed -i "s/^DB_HOST=.*/DB_HOST=$DB_HOST/" $ENV_FILE
sed -i "s/^DB_NAME=.*/DB_NAME=$DB_NAME_VAL/" $ENV_FILE
echo -e "${GREEN}   ✅ Archivo .env configurado.${NC}"

# 7. FINALIZACIÓN Y LANZAMIENTO
echo -e "\n${MAGENTA}${BOLD}=================================================${NC}"
echo -e "${GREEN}${BOLD}   SISTEMA LISTO Y AUTORIZADO${NC}"
echo -e "${MAGENTA}${BOLD}=================================================${NC}"
progress_bar

echo -e "${CYAN}🚀 Lanzando Navaja Suiza (taller.py)...${NC}"
sleep 1
python taller.py
