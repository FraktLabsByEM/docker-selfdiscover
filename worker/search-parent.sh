#!/bin/bash

sleep 5s

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


# Loop through each IP in the array and send the POST request
for ip in "${IP_ARRAY[@]}"; do
    echo "intentando conectar con $ip"
    URL="http://$ip:32100/network/$MAC_ADDRESS/join"
    DATA='{
        "token": "my_custom_password",
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
        echo "Uniendose a la red docker"

        # Extract token
        response=$(jq -r '.token' ./config.json)
        echo "response: $response"

        # Swarm join token
        swarm_token=$(echo "$token_field" | sed -n 's/.*docker swarm join --token \([^ ]*\).*/\1/p')
        # Master IP
        ip_port=$(echo "$token_field" | sed -n 's/.*docker swarm join --token [^ ]* \([^ ]*\).*/\1/p')

        echo "Extracted data is: $swarm_token $ip_port"
        
        # Break the loop if the request is successful
        break
    else
        echo "Error al enviar la solicitud a $ip. Código de respuesta: $RESPONSE"
    fi
done
echo "Proceso finalizado."