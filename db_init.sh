#!/bin/bash

# Reading environment variables from .env file (ensure .env file exists in the correct location)
while IFS= read -r line; do export $line; done < ./.env

# Update MySQL bind address to allow remote connections
sudo sed -i '/bind-address/s/127.0.0.1/0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf
sudo systemctl restart mysql

# Create the database and grant privileges
sudo mysql << EOF
CREATE DATABASE IF NOT EXISTS google;
GRANT ALL PRIVILEGES ON google.* TO 'googleuser'@'%' IDENTIFIED BY '${GOOGLE_DB_PASSWORD}';
FLUSH PRIVILEGES;
EOF

# Import the SQL file into the newly created database
sudo sh -c 'mysql google < ./google-mobility.sql'
