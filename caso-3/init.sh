#!/bin/bash

LOG_FILE="/var/log/init_script.log"


echo "Starting init.sh" | tee -a $LOG_FILE

sudo apt-get update
sudo apt-get install expect

# Paso 1: Inicializar kubectl
echo "Paso 1: Inicializando kubectl" | tee -a $LOG_FILE

rancher login --context "c-6bdnb:p-svfjj" --token ${rancher_token} https://rancher.kube.um.edu.ar/v3
rancher context current
rancher project ls | grep -q LucasGarcia-project || rancher project create LucasGarcia-project
rancher context switch LucasGarcia-project
rancher kubectl config view --raw=true | install -D -m 640 /dev/stdin ~/.kube/config

# Paso 2: Crear NAMESPACE
echo "Paso 2: Creando NAMESPACE" | tee -a $LOG_FILE
rancher namespace create metabase
kubectl ns metabase

echo "Paso 3: encoding 64" | tee -a $LOG_FILE
encoded_metabase_mail=$(echo -n "${METABASE_MAIL}" | base64) | tee -a $LOG_FILE
encoded_metabase_password=$(echo -n "${METABASE_PASSWORD}" | base64) | tee -a $LOG_FILE
encoded_metabase_db_user=$(echo -n "${METABASE_DB_USER}" | base64) | tee -a $LOG_FILE
encoded_metabase_db_password=$(echo -n "${METABASE_DB_PASSWORD}" | base64) | tee -a $LOG_FILE
encoded_mobility_db_user=$(echo -n "${MOBILITY_DB_USER}" | base64) | tee -a $LOG_FILE
encoded_mobility_db_password=$(echo -n "${MOBILITY_DB_PASSWORD}" | base64) | tee -a $LOG_FILE


mkdir -p kube_yamls | tee -a $LOG_FILE

# Echoing variables to files and logging
{
  echo "${configmap_yaml}" >"./kube_yamls/configmap.yaml"
  echo "${deploy_yaml}" >"./kube_yamls/deploy.yaml"
  echo "${ingress_yaml}" >"./kube_yamls/ingress.yaml"
  echo "${network_yaml}" >"./kube_yamls/network.yaml"
  echo "${pvc_yaml}" >"./kube_yamls/pvc.yaml"
  echo "${secret_yaml}" >"./kube_yamls/secret.yaml"
  echo "${service_yaml}" >"./kube_yamls/service.yaml"
} | tee -a $LOG_FILE

sed -i '' "s/METABASE_MAIL: .*/METABASE_MAIL: $encoded_metabase_mail/" ./kube_yamls/secrets.yaml
sed -i '' "s/METABASE_PASSWORD: .*/METABASE_PASSWORD: $encoded_metabase_password/" ./kube_yamls/secrets.yaml
sed -i '' "s/METABASE_DB_USER: .*/METABASE_DB_USER: $encoded_metabase_db_user/" ./kube_yamls/secrets.yaml
sed -i '' "s/METABASE_DB_PASSWORD: .*/METABASE_DB_PASSWORD: $encoded_metabase_db_password/" ./kube_yamls/secrets.yaml
sed -i '' "s/MOBILITY_DB_USER: .*/MOBILITY_DB_USER: $encoded_mobility_db_user/" ./kube_yamls/secrets.yaml
sed -i '' "s/MOBILITY_DB_PASSWORD: .*/MOBILITY_DB_PASSWORD: $encoded_mobility_db_password/" ./kube_yamls/secrets.yaml
# kubectl apply -f tmp/ | tee -a $LOG_FILE

# # Wait for MySQL pod to be ready and log
# {
#   while [[ $(kubectl get pods -l app=mysql -n metabase -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do
#     echo "Waiting for MySQL pod to be ready..."
#     sleep 10
#   done
# } | tee -a $LOG_FILE

# # Download SQL file and log
# wget --no-check-certificate -O /tmp/google-mobility.sql "${sql_file_url}" | tee -a $LOG_FILE

# # Get MySQL pod name and log
# MYSQL_POD=$(kubectl get pods -l app=mysql -n metabase -o jsonpath="{.items[0].metadata.name}") | tee -a $LOG_FILE

# # Copy SQL file to MySQL pod and log
# kubectl cp /tmp/google-mobility.sql metabase/"$MYSQL_POD":/tmp/google-mobility.sql | tee -a $LOG_FILE

# # Execute SQL script and log
# {
#   kubectl exec -it "$MYSQL_POD" -n metabase -- mysql -u root -p"${METABASE_DB_PASSWORD}" <<EOF
# CREATE DATABASE IF NOT EXISTS mobility;
# USE mobility;
# source /tmp/google-mobility.sql;
# EOF
# } | tee -a $LOG_FILE

# echo "Setup completed successfully!" | tee -a $LOG_FILE
