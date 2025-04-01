#!/bin/bash

echo "Please select a language | Por favor seleccione un idioma (en/es):"
read lang


[ "$lang" = "en" ] && echo "Step 1/8" || echo "Paso 1/8"
[ "$lang" = "en" ] && echo "  Update apt repository" || echo "  Actualizando el repositorio apt"
# Retrieve environment directory
CURRENT_DIR=$(pwd)

# Update apt repository
sudo apt --fix-broken install | tail -n 5 | less -S
sudo apt update | tail -n 5 | less -S
sudo apt upgrade -y | tail -n 5 | less -S


[ "$lang" = "en" ] && echo "Step 2/8" || echo "Paso 2/8"
[ "$lang" = "en" ] && echo "  Configure conda" || echo "  Configurar conda"
# Validate conda is installed
if ! which conda &> /dev/null; then
    [ "$lang" = "en" ] && echo "  conda is not installed, setting up conda" || echo "  conda no está instalado, configurando conda"
    
    # Install conda as root user
    curl -o miniconda.sh https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-aarch64.sh | tail -n 5 | less -S
    bash miniconda.sh -u -b -p /root/miniconda3 | tail -n 5 | less -S
    rm miniconda.sh | tail -n 5 | less -S
    
    # Update PATH environment variable
    export PATH="/root/miniconda3/bin:$PATH"
    
    [ "$lang" = "en" ] && echo "  conda have been installed" || echo "  conda se ha instalado correctamente"
else
    [ "$lang" = "en" ] && echo "  conda is already installed" || echo "  conda ya se encuentra instalado"
fi

# Create virtualenv if not exists
if ! conda info --envs | grep -q "python3.9"; then
    [ "$lang" = "en" ] && echo "  conda environment not created yet" || echo "  El entorno conda no se ha creado aún"
    conda create -n python3.9 python=3.9 -y | tail -n 5 | less -S
    [ "$lang" = "en" ] && echo "  conda environment have been created" || echo "  El entorno conda se ha creado exitosamente"
else
    [ "$lang" = "en" ] && echo "  conda environment is already created" || echo "  El entorno conda ya existe"
fi

# Define conda path
source /root/miniconda3/etc/profile.d/conda.sh
# Activate conda env
conda activate python3.9
[ "$lang" = "en" ] && echo "  conda environment activated" || echo "  El entorno conda se activó"


[ "$lang" = "en" ] && echo "Step 3/8" || echo "Paso 3/8"
[ "$lang" = "en" ] && echo "  Configure docker" || echo "  Configurar docker"

# Validate and install Docker
if ! which docker &> /dev/null; then
    # Install docker
    [ "$lang" = "en" ] && echo "  docker is not installed, setting up docker" || echo "  docker no está instalado, configurando docker"
    curl -fsSL https://get.docker.com -o get-docker.sh | tail -n 5 | less -S
    sudo sh get-docker.sh | tail -n 5 | less -S
    sudo rm -f get-docker.sh
    # Enable docker service
    sudo systemctl enable docker
    sudo systemctl start docker
    # Install docker compose
    pip install docker-compose | tail -n 5 | less -S
    sudo docker swarm init
    [ "$lang" = "en" ] && echo "  docker have been installed correctly" || echo "  docker se instaló correctamente"
else
    [ "$lang" = "en" ] && echo "  docker is already installed" || echo "  docker ya se encuentra instalado"
fi


[ "$lang" = "en" ] && echo "Step 4/8" || echo "Paso 4/8"
[ "$lang" = "en" ] && echo "  Configure flask server" || echo "  Configurar servidor flask"

# Validate and install requirements.txt
if [ -f "$CURRENT_DIR/master/sh/requirements.txt" ]; then
    [ "$lang" = "en" ] && echo "  Installing python dependencies..." || echo "  Instalando dependencias de python"
    pip install -r "$CURRENT_DIR/master/sh/requirements.txt" | tail -n 5 | less -S
else
    [ "$lang" = "en" ] && echo "  Python dependencies not found" || echo "  No se encontraron las dependencias de python"
fi


[ "$lang" = "en" ] && echo "Step 5/8" || echo "Paso 5/8"
[ "$lang" = "en" ] && echo "  Configure service" || echo "  Configurar el servicio"

# Create service (as root) providing conda environment variables
sudo bash -c "cat > /etc/systemd/system/listener.service <<EOF
[Unit]
Description=FraktLabs Listener Service
After=network.target

[Service]
ExecStart=/usr/bin/bash /app/docker-selfdiscover/master/sh/init.sh
WorkingDirectory=/app/docker-selfdiscover/master
Restart=always
User=root
Group=root
Environment=PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/root/miniconda3/bin
Environment=CONDA_EXE=/root/miniconda3/bin/conda
Environment=CONDA_PREFIX=/root/miniconda3
Environment=CONDA_PYTHON_EXE=/root/miniconda3/bin/python

[Install]
WantedBy=multi-user.target
EOF"

# Activate service
sudo systemctl enable listener.service
sudo systemctl start listener.service


[ "$lang" = "en" ] && echo "Step 6/8" || echo "Paso 6/8"
[ "$lang" = "en" ] && echo "  Configure project files" || echo "  Configurar los archivos del proyecto"

# Add files and permisions permissions for resources
# Directorio de resources
RESOURCES_DIR="$CURRENT_DIR/master/resources"

# Create folder if not exists
if [ ! -d "$RESOURCES_DIR" ]; then
    [ "$lang" = "en" ] && echo "  Directory $RESOURCES_DIR not found. Creating directory..." || echo "  El directorio $RESOURCES_DIR no existe. Creando directorio..."
    mkdir -p "$RESOURCES_DIR"
else
    [ "$lang" = "en" ] && echo "  Directory $RESOURCES_DIR have been created before" || echo "  El directorio $RESOURCES_DIR ya habia sido creado"
fi


# Validate and create files
if [ ! -f "$RESOURCES_DIR/join.txt" ]; then
    echo "El archivo join.txt. no existe, generando..."
    sudo bash -c "cat > $RESOURCES_DIR/join.txt <<EOF
my_custom_swarm_token
EOF"
fi

if [ ! -f "$RESOURCES_DIR/whitelist.txt" ]; then
    echo "El archivo whitelist.txt. no existe, generando..."
    sudo bash -c "cat > $RESOURCES_DIR/whitelist.txt <<EOF
20:20:20:20:20:20
EOF"
fi


[ "$lang" = "en" ] && echo "Step 7/8" || echo "Paso 7/8"
[ "$lang" = "en" ] && echo "  Configure swarm password" || echo "  Configurar contraseña swarm"

# Validate and create password
if [ ! -f "$RESOURCES_DIR/token.txt" ]; then
    [ "$lang" = "en" ] && echo "  Password not configured yet" || echo "  La contraseña no ha sido configurada"
    [ "$lang" = "en" ] && echo "  Please configure a new password" || echo "  Por favor configure una nueva contraseña"
    [ "$lang" = "en" ] && echo "  Your password: " || echo " Su contraseña: "
    read pass
    [ "$lang" = "en" ] && echo "  Remember to configure this password in worker nodes." || echo "  Recuerde configurar esta misma conraseña en los nodos workers."
    [ "$lang" = "en" ] && echo "  Press enter to continue..." || echo "  Presione enter para continuar..."
    read doomie
    sudo bash -c "cat > $RESOURCES_DIR/token.txt <<EOF
$pass
EOF"
fi


[ "$lang" = "en" ] && echo "Step 8/8" || echo "Paso 8/8"
[ "$lang" = "en" ] && echo "  Setting up file permissions" || echo "  Configurar los permisos de los archivos"

# Add execution permission
chmod +x "$CURRENT_DIR/master/sh/init.sh"
chmod +x "$CURRENT_DIR/master/listener.py"

# Provide read write permissions for files
chmod 666 "$CURRENT_DIR/master/resources/token.txt"
chmod 666 "$CURRENT_DIR/master/resources/join.txt"
chmod 666 "$CURRENT_DIR/master/resources/whitelist.txt"

[ "$lang" = "en" ] && echo "  Setting up finished on master node, you can now set up worker nodes." || echo "  Configuración finalizada en el nodo master, ahora puedes configurar los nodos worker"

[ "$lang" = "en" ] && echo "  Press enter to exit..." || echo "  Presione enter para salir..."
read doomie
