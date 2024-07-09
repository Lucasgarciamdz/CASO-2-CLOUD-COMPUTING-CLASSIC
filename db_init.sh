#!/bin/bash

while IFS= read -r line; do export $line; done < ./.env

sudo sed -i '/bind-address/s/127.0.0.1/0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf
sudo systemctl restart mysql

sudo mysql << EOF
CREATE DATABASE IF NOT EXISTS google;
GRANT ALL PRIVILEGES ON google.* TO 'googleuser'@'%' IDENTIFIED BY '${GOOGLE_DB_PASSWORD}';
FLUSH PRIVILEGES;
EOF

sudo sh -c 'mysql google < ./google-mobility.sql'
