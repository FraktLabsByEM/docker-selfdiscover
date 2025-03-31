#!/bin/bash

# Activate conda virtual env
source /root/miniconda3/etc/profile.d/conda.sh
conda activate python3.9
echo "Entorno 'python3.9' activado. Ejecutando el servidor..."

# sudo docker swarm init

# # retrieve token
# WORKER_TOKEN=$(docker swarm join-token worker -q)

# Update token
sudo bash -c 'cat > resources/join.txt <<EOF
EOF'

# Execute flask server
python listener.py