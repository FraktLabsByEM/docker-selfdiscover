#!/bin/bash

sleep 5s

rm -f config.json

# Retrieve mac address
MAC_ADDRESS=$(ip link show | awk '/ether/ {print $2; exit}')

# Retrieve ID address
IP_ADDRESS=$(hostname -I | awk '{print $1}')

# Retrieve network prefix
NETWORK_PREFIX=$(echo $IP_ADDRESS | awk -F. '{print $1 "." $2 "." $3}')

# Scan other network devices
SCAN_RESULTS=$(nmap -sn $NETWORK_PREFIX.0/24 | grep "Nmap scan report for" | awk '{print $5}')
IP_ARRAY=($SCAN_RESULTS)

echo "List of devices found in the same network:"

for ip in "${IP_ARRAY[@]}"; do
    echo " - $ip"
done

# Load network password
if [ -f "./network_password.txt" ]; then
    NETWORK_PASSWORD=$(cat ./network_password.txt)
else
    echo "Error: No se encontró el archivo de contraseña en ./network_password.txt"
    exit 1
fi

# Loop through each IP in the array and send the POST request
for ip in "${IP_ARRAY[@]}"; do
    echo "intentando conectar con $ip"
    URL="http://$ip:32100/network/$MAC_ADDRESS/join"
    DATA='{
        "token":  "'$NETWORK_PASSWORD'",
        "req_ip": "'$ip'"
    }'

    # Send POST request with application/json header and the data
    RESPONSE=$(curl -m 5 -s -w "%{http_code}" -o response.json -X POST $URL -H "Content-Type: application/json" -d "$DATA")
    
    # Check if the response code is 200
    if [[ "$RESPONSE" -eq 200 ]]; then
        echo "Solicitud exitosa a $ip"
        
        # Guardar la respuesta en un archivo local
        cp response.json ./config.json
        echo "Respuesta guardada en config.json"

        # Extract token and ip
        swarm_token=$(jq -r '.token' ./config.json)
        ip_port=$(jq -r '.ip' ./config.json)

        # Join network
        sudo docker swarm leave --force
        sleep 2s

        echo "Uniendose a la red docker en la ip: $ip_port"
        sudo docker swarm join --token $swarm_token $ip_port
        
        # Break the loop if the request is successful
        exit 0
    else
        echo "Error al enviar la solicitud a $ip. Código de respuesta: $RESPONSE"
        exit 1
    fi
done
echo "Proceso finalizado."
exit 1