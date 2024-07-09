#!/bin/bash

LOG_FILE="/var/log/db_init.log"

echo "Starting database initialization" >> $LOG_FILE

# Update MySQL bind address to allow remote connections and restart MySQL
if ! sudo sed -i '/bind-address/s/127.0.0.1/0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf || ! sudo systemctl restart mysql; then
    echo "Failed to restart MySQL" >> $LOG_FILE
    exit 1
fi

# Create the database and grant privileges
if ! sudo mysql -e "CREATE DATABASE IF NOT EXISTS ${db_name};" || \
   ! sudo mysql -e "GRANT ALL PRIVILEGES ON ${db_name}.* TO '${db_user}'@'%' IDENTIFIED BY '${db_password}';"; then
    echo "Failed to create database or grant privileges" >> $LOG_FILE
    exit 1
fi

sudo mysql -e "FLUSH PRIVILEGES;"

# Download the SQL file
echo "Downloading SQL file..." >> $LOG_FILE
if ! wget --no-check-certificate -O /tmp/google-mobility.sql "${sql_file_url}"; then
    echo "Failed to download SQL file" >> $LOG_FILE
    exit 1
fi

# Import the SQL file using db_user and db_password
echo "Importing SQL file..." >> $LOG_FILE
if ! mysql -u"${db_user}" -p"${db_password}" "${db_name}" < /tmp/google-mobility.sql 2>>$LOG_FILE; then
    echo "Failed to import SQL file" >> $LOG_FILE
    exit 1
fi

# Clean up
rm /tmp/google-mobility.sql

echo "Database initialization completed successfully" >> $LOG_FILE