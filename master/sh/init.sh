#!/bin/bash

# Activate conda virtual env
source /root/miniconda3/etc/profile.d/conda.sh
conda activate python3.9
echo "Entorno 'python3.9' activado. Ejecutando el servidor..."

# Remove inactive nodes
docker node ls | grep -i Down | awk '{print $1}' | xargs -r docker node rm

# Update token
sudo bash -c 'cat > resources/join.txt <<EOF
EOF'

# Execute flask server
python listener.py