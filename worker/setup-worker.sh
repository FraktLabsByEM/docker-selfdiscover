#!/bin/bash

# Update apt repository
echo "Updating apt repository"
sudo apt --fix-broken install
sudo apt update -y
sudo apt upgrade -y
sudo apt install -y jq

echo "Setting up conda"
# Validate conda is installed
if ! which conda &> /dev/null; then
    echo "Conda no está instalado. Instalando Conda..."
    
    # Install conda as root user
    curl -o miniconda.sh https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-aarch64.sh
    bash miniconda.sh -u -b -p /root/miniconda3
    rm miniconda.sh
    
    # Update PATH environment variable
    export PATH="/root/miniconda3/bin:$PATH"
    
    echo "Conda instalado correctamente."
else
    echo "Conda ya está instalado."
fi

# Create virtualenv if not exists
if ! conda info --envs | grep -q "python3.9"; then
    echo "Entorno Conda 'python3.9' no encontrado. Creando el entorno..."
    conda create -n python3.9 python=3.9 -y
    echo "Entorno 'python3.9' creado."
else
    echo "El entorno Conda 'python3.9' ya existe."
fi

# Define conda path
source /root/miniconda3/etc/profile.d/conda.sh
# Activate conda env
conda activate python3.9

echo "Entorno 'python3.9' activado."


# Validate and install Docker
if ! which docker &> /dev/null; then
    # Install docker
    echo "Docker no esta instalado. Instalando docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo rm -f get-docker.sh
    # Enable docker service
    sudo systemctl enable docker
    sudo systemctl start docker
    # Install docker compose
    pip install docker-compose
    sudo docker init
else
    echo "Docker instalado correctamente"
fi


# Variables
SCRIPT_NAME="search-parent.sh"
SERVICE_NAME="search-parent.service"
SERVICE_PATH="/etc/systemd/system/$SERVICE_NAME"
SCRIPT_PATH="$(pwd)/worker/$SCRIPT_NAME"

NMAP_LOCATION=$(which nmap)
CURL_LOCATION=$(which curl)

# Verificar si el script existe
if [[ ! -f "$SCRIPT_PATH" ]]; then
    echo "El script $SCRIPT_NAME no se encuentra en el directorio actual."
    exit 1
fi

# Asegurarse de que el script tenga permisos de ejecución
chmod +x "$SCRIPT_PATH"
echo "Permisos de ejecución otorgados a $SCRIPT_NAME."

# Crear archivo de servicio systemd
echo "Creando el servicio $SERVICE_NAME..."

cat > "$SERVICE_PATH" <<EOL
[Unit]
Description=Servicio de búsqueda en la red utilizando $SCRIPT_NAME
After=network.target

[Service]
ExecStart=/usr/bin/bash $SCRIPT_PATH
WorkingDirectory=$(pwd)/worker
Restart=always
User=root
Group=root
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=$SERVICE_NAME
Environment=PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/root/miniconda3/bin:$NMAP_LOCATION:$CURL_LOCATION


[Install]
WantedBy=multi-user.target
EOL

# Recargar el daemon systemd y habilitar el servicio
echo "Configuracion finalizada, por favor reinicie el dispositivo."
# systemctl daemon-reload
sudo systemctl enable $SERVICE_NAME
sudo systemctl start $SERVICE_NAME