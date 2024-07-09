#!/bin/bash

sudo rm -f /etc/nginx/sites-enabled/default

sudo tee /etc/nginx/conf.d/lb.conf << EOF
server {
  listen ${http_port};
  location / {
    proxy_pass http://${app_ip}:${app_port};
  }
}
EOF
sudo service nginx restart