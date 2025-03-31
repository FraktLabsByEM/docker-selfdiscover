#!/bin/bash

# Retrieve environment directory
CURRENT_DIR=$(pwd) # /usr/local/bin/docker-selfdiscover

# Validate conda is installed
if ! command -v conda &> /dev/null; then
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

# Activate conda env
source /root/miniconda3/etc/profile.d/conda.sh
conda activate python3.9

echo "Entorno 'python3.9' activado."

# Validate and install requirements.txt
if [ -f "$CURRENT_DIR/master/sh/requirements.txt" ]; then
    echo "Instalando dependencias desde requirements.txt..."
    pip install -r "$CURRENT_DIR/master/sh/requirements.txt"
else
    echo "No se encontró el archivo requirements.txt."
fi

# Create service (as root) providing conda environment variables
sudo bash -c 'cat > /etc/systemd/system/listener.service <<EOF
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
EOF'
sudo systemctl enable listener.service
sudo systemctl start listener.service

echo "Configuración completada. El servidor se ejecutará automáticamente al iniciar el dispositivo."

# Add file permissions for resources

# Add execution permission
chmod +x "$CURRENT_DIR/master/sh/init.sh"
chmod +x "$CURRENT_DIR/master/listener.py"

# Provide read write permissions for files
chmod 666 "$CURRENT_DIR/master/resources/token.txt"
chmod 666 "$CURRENT_DIR/master/resources/join.txt"
chmod 666 "$CURRENT_DIR/master/resources/whitelist.txt"


