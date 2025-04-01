
echo "******************************************************************"
echo "**           ---Docker Self Discover---                         **"
echo "** This bash app allows you to configure swarm nodes to perform **"
echo "** an automated self search once the nodes are turned on.       **"
echo "******************************************************************"
echo ""
echo "First select what kind of node do you want to configure:"
echo " 1. Master node"
echo " 2. Worker node"
read option

path=$(pwd)

if [ "$option" = "1" ]; then
    sudo bash "$path/master/sh/setup.sh"
elif [ "$option" = "2" ]; then
    sudo bash "$path/worker/setup.sh"
else
    echo "  Press enter to exit..."
    read doomie
    exit 1
fi