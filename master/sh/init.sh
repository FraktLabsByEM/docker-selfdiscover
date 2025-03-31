#!/bin/bash

# Activate conda virtual env
source /root/miniconda3/etc/profile.d/conda.sh
conda activate python3.9
echo "Entorno 'python3.9' activado. Ejecutando el servidor..."

# Execute flask server
python listener.py