#!/bin/bash
#

echo "Please select a language | Por favor seleccione un idioma (en/es):"
read lang

[ "$lang" = "en" ] && echo "Step 1/6" || echo "Paso 1/6"
[ "$lang" = "en" ] && echo "  Update apt repository" || echo "  Actualizando el repositorio apt"

# Update apt repository
sudo apt --fix-broken install
sudo apt update -y
sudo apt upgrade -y
sudo apt install -y jq nmap curl


[ "$lang" = "en" ] && echo "Step 2/6" || echo "Paso 2/6"
[ "$lang" = "en" ] && echo "  Configure conda" || echo "  Configurar conda"
# Validate conda is installed
if ! which conda &> /dev/null; then
    [ "$lang" = "en" ] && echo "  conda is not installed, setting up conda" || echo "  conda no está instalado, configurando conda"
    
    # Install conda as root user
    curl -o miniconda.sh https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-aarch64.sh
    bash miniconda.sh -u -b -p /root/miniconda3
    rm miniconda.sh
    
    # Update PATH environment variable
    export PATH="/root/miniconda3/bin:$PATH"
    
    [ "$lang" = "en" ] && echo "  conda have been installed" || echo "  conda se ha instalado correctamente"
else
    [ "$lang" = "en" ] && echo "  conda is already installed" || echo "  conda ya se encuentra instalado"
fi

# Create virtualenv if not exists
if ! conda info --envs | grep -q "python3.9"; then
    [ "$lang" = "en" ] && echo "  conda environment not created yet" || echo "  El entorno conda no se ha creado aún"
    conda create -n python3.9 python=3.9 -y
    [ "$lang" = "en" ] && echo "  conda environment have been created" || echo "  El entorno conda se ha creado exitosamente"
else
    [ "$lang" = "en" ] && echo "  conda environment is already created" || echo "  El entorno conda ya existe"
fi


# Define conda path
source /root/miniconda3/etc/profile.d/conda.sh
# Activate conda env
conda activate python3.9
[ "$lang" = "en" ] && echo "  conda environment activated" || echo "  El entorno conda se activó"


[ "$lang" = "en" ] && echo "Step 3/6" || echo "Paso 3/6"
[ "$lang" = "en" ] && echo "  Configure docker" || echo "  Configurar docker"

# Validate and install Docker
if ! which docker &> /dev/null; then
    # Install docker
    [ "$lang" = "en" ] && echo "  docker is not installed, setting up docker" || echo "  docker no está instalado, configurando docker"
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo rm -f get-docker.sh
    # Enable docker service
    sudo systemctl enable docker
    sudo systemctl start docker
    # Install docker compose
    pip install docker-compose
    [ "$lang" = "en" ] && echo "  docker have been installed correctly" || echo "  docker se instaló correctamente"
else
    [ "$lang" = "en" ] && echo "  docker is already installed" || echo "  docker ya se encuentra instalado"
fi


[ "$lang" = "en" ] && echo "Step 4/6" || echo "Paso 4/6"
[ "$lang" = "en" ] && echo "  Setting up file permissions" || echo "  Configurar los permisos de los archivos"

# Variables
SCRIPT_NAME="search-parent.sh"
SERVICE_NAME="search-parent.service"
SERVICE_PATH="/etc/systemd/system/$SERVICE_NAME"
SCRIPT_PATH="$(pwd)/worker/$SCRIPT_NAME"

NMAP_LOCATION=$(which nmap)
CURL_LOCATION=$(which curl)

# Give script permissions
chmod +x "$SCRIPT_PATH"
echo "Permisos de ejecución otorgados a $SCRIPT_NAME."

# Create service

[ "$lang" = "en" ] && echo "Step 5/6" || echo "Paso 5/6"
[ "$lang" = "en" ] && echo "  Configure service" || echo "  Configurar el servicio"

cat > "$SERVICE_PATH" <<EOL
[Unit]
Description=Servicio de búsqueda en la red utilizando $SCRIPT_NAME
After=network.target

[Service]
ExecStart=/usr/bin/bash $SCRIPT_PATH
WorkingDirectory=$(pwd)/worker
Restart=on-failure
RestartSec=20
User=root
Group=root
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=$SERVICE_NAME
Environment=PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/root/miniconda3/bin:$NMAP_LOCATION:$CURL_LOCATION

[Install]
WantedBy=multi-user.target
EOL

# systemctl daemon-reload
sudo systemctl enable $SERVICE_NAME
sudo systemctl start $SERVICE_NAME

# Request password setup
[ "$lang" = "en" ] && echo "Step 6/6" || echo "Paso 6/6"
[ "$lang" = "en" ] && echo "  Set up network authentication" || echo "  Configurar autenticación de red"

echo ""
[ "$lang" = "en" ] && echo "Enter the configured password in the master node setup:" || echo "Ingrese la contraseña configurada en la instalación del nodo master:"
read network_password

# Save password securely
echo "$network_password" > "$(pwd)/worker/network_password.txt"
chmod 600 "$(pwd)/worker/network_password.txt"

[ "$lang" = "en" ] && echo "  Password has been set and saved" || echo "  La contraseña ha sido configurada y guardada"

echo ""
echo ""

[ "$lang" = "en" ] && echo "  Setting up finished on this worker node, you can continue setting up other worker nodes." || echo "  Configuración finalizada en este nodo worker, puedes continuar configurando más nodos worker"

[ "$lang" = "en" ] && echo "  Press enter to exit..." || echo "  Presione enter para salir..."
read doomie

sudo systemctl daemon-reload
sudo systemctl restart $SERVICE_NAME