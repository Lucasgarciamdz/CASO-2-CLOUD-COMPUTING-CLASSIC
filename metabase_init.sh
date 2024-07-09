#!/bin/bash

echo "Starting metabase_init.sh" >> /var/log/metabase_init.log

# Check if Docker is installed
if ! command -v docker &> /dev/null
then
  echo "Docker not found, installing Docker..." >> /var/log/metabase_init.log
  apt-get update >> /var/log/metabase_init.log 2>&1
  apt-get install -y docker.io >> /var/log/metabase_init.log 2>&1
fi

# Ensure Docker service is running
systemctl start docker
systemctl enable docker

# Pull the Metabase Docker image
docker pull metabase/metabase >> /var/log/metabase_init.log 2>&1
if [ $? -ne 0 ]; then
  echo "Failed to pull Metabase image" >> /var/log/metabase_init.log
  exit 1
fi

# Run Metabase Docker container
docker run -d -p 3000:3000 --name metabase metabase/metabase >> /var/log/metabase_init.log 2>&1
if [ $? -eq 0 ]; then
  echo "Metabase started successfully" >> /var/log/metabase_init.log
else
  echo "Failed to start Metabase" >> /var/log/metabase_init.log
fi
