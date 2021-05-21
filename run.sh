#!/bin/bash

#start deployment
echo "Installing Dependencies..."
sudo apt-get -y update
sudo apt install -y libssl-dev python3-dev sshpass apt-transport-https jq moreutils ca-certificates curl gnupg2 software-properties-common python3-pip rsync

#install docker
echo "Removing legacy Docker Dependencies (if any)..."
sudo apt-get remove docker docker-engine docker.io containerd runc -y

echo "Update done. Preparing the environment..."
sudo apt-get install apt-transport-https ca-certificates curl gnupg-agent software-properties-common -y
echo "Configuring..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
echo "Finalizing System Update.."
sudo apt-get update -y
echo "Installing recommended docker packages..."
sudo apt-get install docker-ce docker-ce-cli containerd.io -y
echo "Install completed!"

#run docker compose
sudo docker-compose up > logfile
