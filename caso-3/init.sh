#!/bin/bash

LOG_FILE="/var/log/init_script.log"

log_and_run() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Running: $*" | tee -a "$LOG_FILE"
    if ! eval "$@" >> "$LOG_FILE" 2>&1; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Error: Command failed: $*" | tee -a "$LOG_FILE"
        return 1
    fi
}

echo "$(date '+%Y-%m-%d %H:%M:%S') - Starting init.sh" | tee -a "$LOG_FILE"



# Set up Rancher context
log_and_run "rancher login --context 'c-6bdnb:p-svfjj' --token '${rancher_token}' https://rancher.kube.um.edu.ar/v3"
log_and_run "rancher context current"
log_and_run "rancher project ls | grep -q LucasGarcia-project || rancher project create LucasGarcia-project"
log_and_run "rancher context switch LucasGarcia-project"
log_and_run "rancher kubectl config view --raw=true | install -D -m 640 /dev/stdin ~/.kube/config"

# Create namespace
echo "$(date '+%Y-%m-%d %H:%M:%S') - Creating namespace" | tee -a "$LOG_FILE"
log_and_run "rancher namespace create metabase"

log_and_run "kubectl config set-context cluster-01 --namespace=metabase"


# Agregar comandos de Rancher a .bashrc
echo "Añadiendo comandos de Rancher a .bashrc" | tee -a $LOG_FILE
{
  echo "rancher login --context 'c-6bdnb:p-svfjj' --token \${rancher_token} https://rancher.kube.um.edu.ar/v3"
  echo "rancher context current"
  echo "rancher project ls | grep -q LucasGarcia-project || rancher project create LucasGarcia-project"
  echo "rancher context switch LucasGarcia-project"
  echo "rancher kubectl config view --raw=true | install -D -m 640 /dev/stdin ~/.kube/config"
  echo "rancher namespace create metabase"
  echo "kubectl config set-context cluster-01 --namespace=metabase"
} >> /home/ubuntu/.bashrc

# Base64 encode secrets
echo "$(date '+%Y-%m-%d %H:%M:%S') - Encoding secrets" | tee -a "$LOG_FILE"
encoded_metabase_mail=$(echo -n "${METABASE_MAIL}" | base64 -w 0)
encoded_metabase_password=$(echo -n "${METABASE_PASSWORD}" | base64 -w 0)
encoded_metabase_db_user=$(echo -n "${METABASE_DB_USER}" | base64 -w 0)
encoded_metabase_db_password=$(echo -n "${METABASE_DB_PASSWORD}" | base64 -w 0)
encoded_mobility_db_user=$(echo -n "${MOBILITY_DB_USER}" | base64 -w 0)
encoded_mobility_db_password=$(echo -n "${MOBILITY_DB_PASSWORD}" | base64 -w 0)

# Create directory for Kubernetes YAML files
log_and_run "mkdir -p /home/ubuntu/kube_yamls"

# Write Kubernetes YAML files
echo "$(date '+%Y-%m-%d %H:%M:%S') - Writing Kubernetes YAML files" | tee -a "$LOG_FILE"
echo "${configmap_yaml}" > "/home/ubuntu/kube_yamls/configmap.yaml"
echo "${deploy_yaml}" > "/home/ubuntu/kube_yamls/deploy.yaml"
echo "${ingress_yaml}" > "/home/ubuntu/kube_yamls/ingress.yaml"
echo "${network_yaml}" > "/home/ubuntu/kube_yamls/network.yaml"
echo "${pvc_yaml}" > "/home/ubuntu/kube_yamls/pvc.yaml"
echo "${secret_yaml}" > "/home/ubuntu/kube_yamls/secrets.yaml"

# Update secrets in YAML file
echo "$(date '+%Y-%m-%d %H:%M:%S') - Updating secrets in YAML file" | tee -a "$LOG_FILE"
sed -i "s|METABASE_MAIL:.*|METABASE_MAIL: $encoded_metabase_mail|" /home/ubuntu/kube_yamls/secrets.yaml
sed -i "s|METABASE_PASSWORD:.*|METABASE_PASSWORD: $encoded_metabase_password|" /home/ubuntu/kube_yamls/secrets.yaml
sed -i "s|METABASE_DB_USER:.*|METABASE_DB_USER: $encoded_metabase_db_user|" /home/ubuntu/kube_yamls/secrets.yaml
sed -i "s|METABASE_DB_PASSWORD:.*|METABASE_DB_PASSWORD: $encoded_metabase_db_password|" /home/ubuntu/kube_yamls/secrets.yaml
sed -i "s|MOBILITY_DB_USER:.*|MOBILITY_DB_USER: $encoded_mobility_db_user|" /home/ubuntu/kube_yamls/secrets.yaml
sed -i "s|MOBILITY_DB_PASSWORD:.*|MOBILITY_DB_PASSWORD: $encoded_mobility_db_password|" /home/ubuntu/kube_yamls/secrets.yaml

# Apply Kubernetes configurations
echo "$(date '+%Y-%m-%d %H:%M:%S') - Applying Kubernetes configurations" | tee -a "$LOG_FILE"
sleep 5
export KUBECONFIG=~/.kube/config
log_and_run "kubectl -n metabase apply -f /home/ubuntu/kube_yamls/"


# # Wait for MySQL pod to be ready
# echo "$(date '+%Y-%m-%d %H:%M:%S') - Waiting for MySQL pod to be ready" | tee -a "$LOG_FILE"
# log_and_run "kubectl wait --for=condition=ready pod -l app=mysql -n metabase --timeout=300s"

# # Download SQL file
# echo "$(date '+%Y-%m-%d %H:%M:%S') - Downloading SQL file" | tee -a "$LOG_FILE"
# log_and_run "wget --no-check-certificate -O /tmp/google-mobility.sql '${sql_file_url}'"

# # Get MySQL pod name
# MYSQL_POD=$(kubectl get pods -l app=mysql -n metabase -o jsonpath="{.items[0].metadata.name}")

# # Copy SQL file to MySQL pod
# echo "$(date '+%Y-%m-%d %H:%M:%S') - Copying SQL file to MySQL pod" | tee -a "$LOG_FILE"
# log_and_run "kubectl cp /tmp/google-mobility.sql metabase/$MYSQL_POD:/tmp/google-mobility.sql"

# # Execute SQL script
# echo "$(date '+%Y-%m-%d %H:%M:%S') - Executing SQL script" | tee -a "$LOG_FILE"
# log_and_run "kubectl exec -i '$MYSQL_POD' -n metabase -- mysql -u root -p'${METABASE_DB_PASSWORD}' <<EOF
# CREATE DATABASE IF NOT EXISTS mobility;
# USE mobility;
# source /tmp/google-mobility.sql;
# EOF"

echo "$(date '+%Y-%m-%d %H:%M:%S') - Setup completed successfully!" | tee -a "$LOG_FILE"