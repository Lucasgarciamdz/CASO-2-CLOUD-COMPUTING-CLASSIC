#!/bin/bash

echo "Starting init.sh"

encoded_metabase_mail=$(echo -n "${METABASE_MAIL}" | base64)
encoded_metabase_password=$(echo -n "${METABASE_PASSWORD}" | base64)
encoded_metabase_db_user=$(echo -n "${METABASE_DB_USER}" | base64)
encoded_metabase_db_password=$(echo -n "${METABASE_DB_PASSWORD}" | base64)
encoded_mobility_db_user=$(echo -n "${MOBILITY_DB_USER}" | base64)
encoded_mobility_db_password=$(echo -n "${MOBILITY_DB_PASSWORD}" | base64)

sed -i '' "s/METABASE_MAIL: .*/METABASE_MAIL: $encoded_metabase_mail/" secrets.yaml
sed -i '' "s/METABASE_PASSWORD: .*/METABASE_PASSWORD: $encoded_metabase_password/" secrets.yaml
sed -i '' "s/METABASE_DB_USER: .*/METABASE_DB_USER: $encoded_metabase_db_user/" secrets.yaml
sed -i '' "s/METABASE_DB_PASSWORD: .*/METABASE_DB_PASSWORD: $encoded_metabase_db_password/" secrets.yaml
sed -i '' "s/MOBILITY_DB_USER: .*/MOBILITY_DB_USER: $encoded_mobility_db_user/" secrets.yaml
sed -i '' "s/MOBILITY_DB_PASSWORD: .*/MOBILITY_DB_PASSWORD: $encoded_mobility_db_password/" secrets.yaml

kubectl apply -f "${all_yaml}"


# Wait for MySQL pod to be ready
while [[ $(kubectl get pods -l app=mysql -n metabase -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do 
  echo "Waiting for MySQL pod to be ready..."
  sleep 10
done

# Download SQL file
wget --no-check-certificate -O /tmp/google-mobility.sql "${sql_file_url}"

# Get MySQL pod name
MYSQL_POD=$(kubectl get pods -l app=mysql -n metabase -o jsonpath="{.items[0].metadata.name}")

# Copy SQL file to MySQL pod
kubectl cp /tmp/google-mobility.sql metabase/"$MYSQL_POD":/tmp/google-mobility.sql

# Execute SQL script
kubectl exec -it "$MYSQL_POD" -n metabase -- mysql -u root -p"${metabase_db_password}" <<EOF
CREATE DATABASE IF NOT EXISTS mobility;
USE mobility;
source /tmp/google-mobility.sql;
EOF

echo "Setup completed successfully!"