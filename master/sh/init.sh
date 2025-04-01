#!/bin/bash

# Activate conda virtual env
source /root/miniconda3/etc/profile.d/conda.sh
conda activate python3.9
echo "Conda environment activated"

# Remove inactive nodes
docker node ls | grep -i Down | awk '{print $1}' | xargs -r docker node rm | tail -n 5 | less -S
echo "Inactive worker nodes have been removed"

# Update token
sudo bash -c 'cat > resources/join.txt <<EOF
EOF'
echo "Join token have been reset"

echo "Server exposed on port 32100"
# Execute flask server
python listener.py