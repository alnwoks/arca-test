#!/bin/bash


#start deployment
echo "Installing dependencies..."
sudo apt-get -y update

#install docker
#run docker compose
sudo docker-compose up > logfile
#update nginx confg and restart server
#sudo cp -r nginx.conf 

