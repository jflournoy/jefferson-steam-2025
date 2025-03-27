#!/bin/bash

# <UDF name="hostname" Label="Hostname" default="shiny-docker" />
# <UDF name="githubrepo" Label="GitHub repository URL" default="https://github.com/jflournoy/jefferson-steam-2025.git" />

#-----------------------------------------------------------
# 1) System update and basic tools
#-----------------------------------------------------------
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get -y upgrade
apt-get install -y git ufw docker.io

# Enable Docker service
systemctl enable docker
systemctl start docker

#-----------------------------------------------------------
# 2) Firewall: open port 22 for SSH and 3838 for Shiny
#-----------------------------------------------------------
ufw allow 22/tcp
ufw allow 3838/tcp
ufw --force enable

#-----------------------------------------------------------
# 3) Clone your Shiny app repo from GitHub
#    (Replace $githubrepo with your actual GitHub repo or pass it in as UDF)
#-----------------------------------------------------------
cd /root
git clone https://github.com/jflournoy/jefferson-steam-2025.git shinyapp

#-----------------------------------------------------------
# 4) Build the Docker image
#    The Dockerfile in your repo must install any needed R packages
#-----------------------------------------------------------
cd shinyapp
docker build -t myshinyapp:latest .

#-----------------------------------------------------------
# 5) Run the Docker container
#    Map host port 3838 to container port 3838
#-----------------------------------------------------------
docker run -d \
  --name shiny_container \
  -p 3838:3838 \
  myshinyapp:latest

#-----------------------------------------------------------
# 6) Done! 
#    You can check logs with 'docker logs shiny_container'
#    Access your app at http://<YOUR_LINODE_IP>:3838
#-----------------------------------------------------------

echo "-------------------------------------------------------"
echo " Setup complete. Your Shiny app is running on port 3838."
echo " Clone path: /root/shinyapp"
echo "-------------------------------------------------------"
