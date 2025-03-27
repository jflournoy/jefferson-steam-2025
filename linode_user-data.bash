#!/bin/bash

githubrepo="https://github.com/jflournoy/jefferson-steam-2025.git"
subdomain="steamnight.johnflournoy.science"

#-----------------------------------------------------------
# 1) System update and install base packages
#-----------------------------------------------------------
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get -y upgrade
apt-get install -y git ufw docker.io nginx certbot python3-certbot-nginx

systemctl enable docker
systemctl start docker

#-----------------------------------------------------------
# 2) Firewall rules
#-----------------------------------------------------------
ufw allow 22/tcp
ufw allow 80/tcp      # HTTP for Let's Encrypt cert validation
ufw allow 443/tcp     # HTTPS for secured site
ufw allow 3838/tcp    # (optional, for direct access)
ufw --force enable

#-----------------------------------------------------------
# 3) Clone Shiny app repo
#-----------------------------------------------------------
cd /root
git clone $githubrepo shinyapp

#-----------------------------------------------------------
# 4) Build Docker container from repo
#-----------------------------------------------------------
cd shinyapp
docker build -t myshinyapp:latest .

#-----------------------------------------------------------
# 5) Run the container on port 3838
#-----------------------------------------------------------
docker run -d \
  --name shiny_container \
  -p 3838:3838 \
  myshinyapp:latest

#-----------------------------------------------------------
# 6) Configure NGINX reverse proxy
#-----------------------------------------------------------
cat <<EOF > /etc/nginx/sites-available/shinyapp
server {
    listen 80;
    server_name $subdomain;

    location / {
        proxy_pass http://localhost:3838/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

ln -s /etc/nginx/sites-available/shinyapp /etc/nginx/sites-enabled/shinyapp
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx

#-----------------------------------------------------------
# 7) Request SSL certificate from Let's Encrypt
#-----------------------------------------------------------
certbot --nginx -d $subdomain --non-interactive --agree-tos -m jocoflo@pm.me

#-----------------------------------------------------------
# 8) Done
#-----------------------------------------------------------
echo "-------------------------------------------------------"
echo " Setup complete. Access your app at:"
echo "   https://$subdomain (with HTTPS!)"
echo "   or http://<YOUR_LINODE_IP>:3838 (direct, dev only)"
echo "-------------------------------------------------------"
