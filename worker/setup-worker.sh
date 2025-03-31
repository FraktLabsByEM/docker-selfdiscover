#!/bin/bash

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
User=root    # Running the service as root
Group=root   # Running the service as root group
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