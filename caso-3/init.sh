#!/bin/bash

LOG_FILE="/var/log/init_script.log"

log_and_run() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - Running: $*" | tee -a "$LOG_FILE"
  if ! eval "$@" >>"$LOG_FILE" 2>&1; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Error: Command failed: $*" | tee -a "$LOG_FILE"
    return 1
  fi
}

echo "$(date '+%Y-%m-%d %H:%M:%S') - Starting init.sh" | tee -a "$LOG_FILE"

# Set up Rancher context
log_and_run "rancher login --context 'c-6bdnb:p-svfjj' --token '${rancher_token}' https://rancher.kube.um.edu.ar/v3"
log_and_run "rancher context current"
log_and_run "rancher project ls | grep -q '${project_name}'-project || rancher project create '${project_name}'-project"
log_and_run "rancher context switch '${project_name}'-project"
log_and_run "rancher kubectl config view --raw=true | install -D -m 640 /dev/stdin ~/.kube/config"

# Create namespace
echo "$(date '+%Y-%m-%d %H:%M:%S') - Creating namespace" | tee -a "$LOG_FILE"
log_and_run "rancher namespace create '${namespace}'"

log_and_run "kubectl config set-context cluster-01 --namespace='${namespace}'"

# Agregar comandos de Rancher a .bashrc
echo "Añadiendo comandos de Rancher a .bashrc" | tee -a $LOG_FILE
{
  echo "rancher login --context 'c-6bdnb:p-svfjj' --token \${rancher_token} https://rancher.kube.um.edu.ar/v3"
  echo "rancher context current"
  echo "rancher project ls | grep -q '${project_name}'-project || rancher project create '${project_name}'-project"
  echo "rancher context switch '${project_name}'-project"
  echo "rancher kubectl config view --raw=true | install -D -m 640 /dev/stdin ~/.kube/config"
  echo "kubectl config set-context cluster-01 --namespace='${namespace}'"
} >>/home/ubuntu/.bashrc

# Base64 encode secrets
echo "$(date '+%Y-%m-%d %H:%M:%S') - Encoding secrets" | tee -a "$LOG_FILE"
encoded_metabase_mail=$(echo -n "${METABASE_MAIL}" | base64 -w 0)
encoded_metabase_password=$(echo -n "${METABASE_PASSWORD}" | base64 -w 0)
encoded_metabase_db_user=$(echo -n "${METABASE_DB_USER}" | base64 -w 0)
encoded_metabase_db_password=$(echo -n "${METABASE_DB_PASSWORD}" | base64 -w 0)
encoded_mobility_db_user=$(echo -n "${MOBILITY_DB_USER}" | base64 -w 0)
encoded_mobility_db_password=$(echo -n "${MYSQL_ROOT_PASSWORD}" | base64 -w 0)
encoded_mysql_root_password=$(echo -n "${MYSQL_ROOT_PASSWORD}" | base64 -w 0)
encoded_mysql_user=$(echo -n "${MYSQL_USER}" | base64 -w 0)

# Create directory for Kubernetes YAML files
log_and_run "mkdir -p /home/ubuntu/kube_yamls"

# Write Kubernetes YAML files
echo "$(date '+%Y-%m-%d %H:%M:%S') - Writing Kubernetes YAML files" | tee -a "$LOG_FILE"
echo "${configmap_yaml}" >"/home/ubuntu/kube_yamls/configmap.yaml"
echo "${deploy_yaml}" >"/home/ubuntu/kube_yamls/deploy.yaml"
echo "${ingress_yaml}" >"/home/ubuntu/kube_yamls/ingress.yaml"
echo "${pvc_yaml}" >"/home/ubuntu/kube_yamls/pvc.yaml"
echo "${secret_yaml}" >"/home/ubuntu/kube_yamls/secrets.yaml"
echo "${service_yaml}" >"/home/ubuntu/kube_yamls/services.yaml"

# Update secrets in YAML file
echo "$(date '+%Y-%m-%d %H:%M:%S') - Updating secrets in YAML file" | tee -a "$LOG_FILE"
sed -i "s|METABASE_MAIL:.*|METABASE_MAIL: $encoded_metabase_mail|" /home/ubuntu/kube_yamls/secrets.yaml
sed -i "s|METABASE_PASSWORD:.*|METABASE_PASSWORD: $encoded_metabase_password|" /home/ubuntu/kube_yamls/secrets.yaml
sed -i "s|METABASE_DB_USER:.*|METABASE_DB_USER: $encoded_metabase_db_user|" /home/ubuntu/kube_yamls/secrets.yaml
sed -i "s|METABASE_DB_PASSWORD:.*|METABASE_DB_PASSWORD: $encoded_metabase_db_password|" /home/ubuntu/kube_yamls/secrets.yaml
sed -i "s|MOBILITY_DB_USER:.*|MOBILITY_DB_USER: $encoded_mobility_db_user|" /home/ubuntu/kube_yamls/secrets.yaml
sed -i "s|MOBILITY_DB_PASSWORD:.*|MOBILITY_DB_PASSWORD: $encoded_mobility_db_password|" /home/ubuntu/kube_yamls/secrets.yaml
sed -i "s|MYSQL_ROOT_PASSWORD:.*|MYSQL_ROOT_PASSWORD: $encoded_mysql_root_password|" /home/ubuntu/kube_yamls/secrets.yaml
sed -i "s|MYSQL_USER:.*|MYSQL_USER: $encoded_mysql_user|" /home/ubuntu/kube_yamls/secrets.yaml

# Apply Kubernetes configurations
echo "$(date '+%Y-%m-%d %H:%M:%S') - Applying Kubernetes configurations" | tee -a "$LOG_FILE"
sleep 5
export KUBECONFIG=~/.kube/config
log_and_run "kubectl -n '${namespace}' apply -f /home/ubuntu/kube_yamls/"

# Wait for MySQL pod to be ready
echo "$(date '+%Y-%m-%d %H:%M:%S') - Waiting for MySQL pod to be ready" | tee -a "$LOG_FILE"
while ! kubectl get po -l app=mysql -n ${namespace} | grep -q '1/1'; do
  echo "$(date '+%Y-%m-%d %H:%M:%S') - MySQL pod not ready yet, waiting..." | tee -a "$LOG_FILE"
  sleep 5
done
echo "$(date '+%Y-%m-%d %H:%M:%S') - MySQL pod is ready" | tee -a "$LOG_FILE"

# Download SQL file
echo "$(date '+%Y-%m-%d %H:%M:%S') - Downloading SQL file" | tee -a "$LOG_FILE"
wget --no-check-certificate -O /tmp/google-mobility.sql '${sql_file_url}'

# Get MySQL pod name
MYSQL_POD=$(kubectl get pods -l app=mysql -n ${namespace} -o jsonpath="{.items[0].metadata.name}")

# Copy SQL file to MySQL pod
echo "$(date '+%Y-%m-%d %H:%M:%S') - Copying SQL file to MySQL pod" | tee -a "$LOG_FILE"
log_and_run "kubectl cp /tmp/google-mobility.sql '${namespace}'/$MYSQL_POD:/tmp/google-mobility.sql"

# Execute SQL script
echo "$(date '+%Y-%m-%d %H:%M:%S') - Executing SQL script" | tee -a "$LOG_FILE"
log_and_run "kubectl exec -i '$MYSQL_POD' -n '${namespace}' -- mysql -u root -p'${MYSQL_ROOT_PASSWORD}' <<EOF
CREATE DATABASE IF NOT EXISTS ${mobility_db_name};
CREATE DATABASE IF NOT EXISTS ${metabase_db_name};
CREATE USER IF NOT EXISTS '${METABASE_DB_USER}'@'%' IDENTIFIED WITH mysql_native_password BY '${METABASE_DB_PASSWORD}';
CREATE USER IF NOT EXISTS '${MOBILITY_DB_USER}'@'%' IDENTIFIED WITH mysql_native_password BY '${MOBILITY_DB_PASSWORD}';
GRANT ALL PRIVILEGES ON ${metabase_db_name}.* TO '${METABASE_DB_USER}'@'%';
GRANT ALL PRIVILEGES ON ${mobility_db_name}.* TO '${MOBILITY_DB_USER}'@'%';
FLUSH PRIVILEGES;
USE ${mobility_db_name};
source /tmp/google-mobility.sql;
EOF"

# Wait for Metabase to start
wait_for_metabase() {
  log_and_run "echo 'Waiting for Metabase to start...'"
  while ! kubectl get po -l app=metabase -n ${namespace} | grep -q '1/1'; do
    log_and_run "echo 'Metabase pod not ready yet, waiting...'"
    sleep 10
  done
  log_and_run "echo 'Metabase pod is ready'"
}

wait_for_metabase

# Use kubectl port-forward to access Metabase service
kubectl port-forward svc/metabase 3000:80 -n ${namespace} &
PORTFORWARD_PID=$!

# Wait for port-forward to be ready
sleep 5

# Get setup token
SETUP_TOKEN=$(curl -s -m 5 -X GET \
  -H "Content-Type: application/json" \
  http://localhost:3000/api/session/properties |
  jq -r '.["setup-token"]')

# Set up admin account
log_and_run "echo 'Setting up admin account...'"
SETUP_RESPONSE=$(curl -s -X POST http://localhost:3000/api/setup \
  -H "Content-Type: application/json" \
  -d '{
    "token":"'$SETUP_TOKEN'",
    "user":{
      "password_confirm":"'${METABASE_PASSWORD}'",
      "password":"'${METABASE_PASSWORD}'",
      "site_name":"UM",
      "email":"'${METABASE_MAIL}'",
      "last_name":"garcia",
      "first_name":"lucas"
    },
    "prefs":{
      "site_name":"UM",
      "site_locale":"en"
    }
  }')

log_and_run "echo 'Setup response: $SETUP_RESPONSE'"

# Get session token
log_and_run "echo 'Getting session token...'"
SESSION_TOKEN=$(curl -X POST http://localhost:3000/api/session \
  -H "Content-Type: application/json" \
  -d '{
    "username": "'${METABASE_MAIL}'",
    "password": "'${METABASE_PASSWORD}'"
  }' | jq -r '.id')

if [ -z "$SESSION_TOKEN" ]; then
  log_and_run "echo 'Failed to get session token. Exiting.'"
  kill $PORTFORWARD_PID
  exit 1
fi

log "Adding database connection..."
DB_ID=$(curl -X POST http://localhost:3000/api/database \
  -H "Content-Type: application/json" \
  -H "X-Metabase-Session: $SESSION_TOKEN" \
  -d '{"is_on_demand":false,"is_full_sync":true,"is_sample":false,"cache_ttl":null,"refingerprint":false,"auto_run_queries":true,"schedules":{},"details":{"host":"mysql","port":3306,"dbname":"'${mobility_db_name}'","user":"'${MOBILITY_DB_USER}'","password":"'${MOBILITY_DB_PASSWORD}'","ssl":false,"tunnel-enabled":false,"advanced-options":false},"name":"mobility","engine":"mysql"}' | jq -r '.id')

if [ -z "$DB_ID" ]; then
  log "Failed to add database connection. Exiting."
  exit 1
fi

# Create dashboard
log_and_run "echo 'Creating dashboard...'"
DASHBOARD_ID=$(curl -X POST http://localhost:3000/api/dashboard \
  -H "Content-Type: application/json" \
  -H "X-Metabase-Session: $SESSION_TOKEN" \
  -d '{
    "name": "Mobility Dashboard",
    "description": "Mobility data for Mendoza Province, Capital Department"
  }' | jq -r '.id')

if [ -z "$DASHBOARD_ID" ]; then
  log_and_run "echo 'Failed to create dashboard. Exiting.'"
  kill $PORTFORWARD_PID
  exit 1
fi

log "Creating question..."
QUESTION_ID=$(curl -X POST http://localhost:3000/api/card \
  -H "Content-Type: application/json" \
  -H "X-Metabase-Session: $SESSION_TOKEN" \
  -d '{
  "cache_invalidated_at": null,
  "description": null,
  "archived": false,
  "view_count": 0,
  "collection_position": null,
  "table_id": 9,
  "can_run_adhoc_query": true,
  "result_metadata": [
    {
      "description": null,
      "semantic_type": null,
      "coercion_strategy": null,
      "unit": "day",
      "name": "date",
      "settings": null,
      "fk_target_field_id": null,
      "field_ref": [
        "field",
        73,
        {
          "base-type": "type/DateTime",
          "temporal-unit": "day"
        }
      ],
      "effective_type": "type/Date",
      "id": 73,
      "visibility_type": "normal",
      "display_name": "Date",
      "fingerprint": {
        "global": {
          "distinct-count": 321,
          "nil%": 0
        },
        "type": {
          "type/DateTime": {
            "earliest": "2020-02-15T00:00:00Z",
            "latest": "2020-12-31T00:00:00Z"
          }
        }
      },
      "base_type": "type/Date"
    },
    {
      "display_name": "Average of Retail And Recreation Percent Change From Baseline",
      "semantic_type": null,
      "settings": null,
      "field_ref": [
        "aggregation",
        0
      ],
      "base_type": "type/Decimal",
      "effective_type": "type/Decimal",
      "name": "avg",
      "fingerprint": {
        "global": {
          "distinct-count": 95,
          "nil%": 0
        },
        "type": {
          "type/Number": {
            "min": -96,
            "q1": -69.0857716560905,
            "q3": -42.84139629549865,
            "max": 41,
            "sd": 27.658547670628238,
            "avg": -52.29283489096573
          }
        }
      }
    },
    {
      "display_name": "Average of Grocery And Pharmacy Percent Change From Baseline",
      "semantic_type": null,
      "settings": null,
      "field_ref": [
        "aggregation",
        1
      ],
      "base_type": "type/Decimal",
      "effective_type": "type/Decimal",
      "name": "avg_2",
      "fingerprint": {
        "global": {
          "distinct-count": 101,
          "nil%": 0
        },
        "type": {
          "type/Number": {
            "min": -91,
            "q1": -30.805717884568125,
            "q3": 0.5971624461628744,
            "max": 83,
            "sd": 26.054557250362603,
            "avg": -16.31152647975078
          }
        }
      }
    },
    {
      "display_name": "Average of Parks Percent Change From Baseline",
      "semantic_type": null,
      "settings": null,
      "field_ref": [
        "aggregation",
        2
      ],
      "base_type": "type/Decimal",
      "effective_type": "type/Decimal",
      "name": "avg_3",
      "fingerprint": {
        "global": {
          "distinct-count": 94,
          "nil%": 0
        },
        "type": {
          "type/Number": {
            "min": -99,
            "q1": -90.42656981021216,
            "q3": -50.86001194493218,
            "max": 59,
            "sd": 32.48307885753726,
            "avg": -60.49844236760124
          }
        }
      }
    },
    {
      "display_name": "Average of Transit Stations Percent Change From Baseline",
      "semantic_type": null,
      "settings": null,
      "field_ref": [
        "aggregation",
        3
      ],
      "base_type": "type/Decimal",
      "effective_type": "type/Decimal",
      "name": "avg_4",
      "fingerprint": {
        "global": {
          "distinct-count": 86,
          "nil%": 0
        },
        "type": {
          "type/Number": {
            "min": -90,
            "q1": -56.375,
            "q3": -39.62201759733446,
            "max": 29,
            "sd": 23.83605137258345,
            "avg": -45.16822429906542
          }
        }
      }
    },
    {
      "display_name": "Average of Workplaces Percent Change From Baseline",
      "semantic_type": null,
      "settings": null,
      "field_ref": [
        "aggregation",
        4
      ],
      "base_type": "type/Decimal",
      "effective_type": "type/Decimal",
      "name": "avg_5",
      "fingerprint": {
        "global": {
          "distinct-count": 91,
          "nil%": 0
        },
        "type": {
          "type/Number": {
            "min": -83,
            "q1": -29.76356457060072,
            "q3": -6.708333333333333,
            "max": 33,
            "sd": 24.104273707172357,
            "avg": -21.40809968847352
          }
        }
      }
    },
    {
      "display_name": "Average of Residential Percent Change From Baseline",
      "semantic_type": null,
      "settings": null,
      "field_ref": [
        "aggregation",
        5
      ],
      "base_type": "type/Decimal",
      "effective_type": "type/Decimal",
      "name": "avg_6",
      "fingerprint": {
        "global": {
          "distinct-count": 42,
          "nil%": 0
        },
        "type": {
          "type/Number": {
            "min": -3,
            "q1": 11.41332798286476,
            "q3": 20.054308789731966,
            "max": 40,
            "sd": 8.746244187259899,
            "avg": 16.009345794392523
          }
        }
      }
    }
  ],
  "creator": {
    "email": "lu.garcia@alumno.um.edu.ar",
    "first_name": "lucas",
    "last_login": "2024-07-13T00:22:36Z",
    "is_qbnewb": false,
    "is_superuser": true,
    "id": 13371339,
    "last_name": "garcia",
    "date_joined": "2024-07-13T00:09:02Z",
    "common_name": "lucas garcia"
  },
  "initially_published_at": null,
  "can_write": true,
  "database_id": '"$DB_ID"',
  "enable_embedding": false,
  "collection_id": null,
  "query_type": "query",
  "name": "Average COVID mobility mendoza",
  "last_query_start": null,
  "dashboard_count": 0,
  "last_used_at": null,
  "type": "question",
  "average_query_time": null,
  "creator_id": 13371339,
  "moderation_reviews": [],
  "updated_at": "2024-07-13T00:28:30.139153Z",
  "made_public_by_id": null,
  "embedding_params": null,
  "cache_ttl": null,
  "dataset_query": {
    "database": 2,
    "type": "query",
    "query": {
      "source-table": 9,
      "aggregation": [
        [
          "avg",
          [
            "field",
            83,
            {
              "base-type": "type/Integer"
            }
          ]
        ],
        [
          "avg",
          [
            "field",
            81,
            {
              "base-type": "type/Integer"
            }
          ]
        ],
        [
          "avg",
          [
            "field",
            72,
            {
              "base-type": "type/Integer"
            }
          ]
        ],
        [
          "avg",
          [
            "field",
            80,
            {
              "base-type": "type/Integer"
            }
          ]
        ],
        [
          "avg",
          [
            "field",
            78,
            {
              "base-type": "type/Integer"
            }
          ]
        ],
        [
          "avg",
          [
            "field",
            86,
            {
              "base-type": "type/Integer"
            }
          ]
        ]
      ],
      "breakout": [
        [
          "field",
          73,
          {
            "base-type": "type/DateTime",
            "temporal-unit": "day"
          }
        ]
      ],
      "filter": [
        "and",
        [
          "=",
          [
            "field",
            85,
            {
              "base-type": "type/Text"
            }
          ],
          "Mendoza Province"
        ],
        [
          "=",
          [
            "field",
            75,
            {
              "base-type": "type/Text"
            }
          ],
          "Capital Department"
        ],
        [
          "between",
          [
            "field",
            73,
            {
              "base-type": "type/DateTime"
            }
          ],
          "2020-01-01",
          "2020-12-31"
        ]
      ]
    }
  },
  "id": 29,
  "parameter_mappings": [],
  "display": "area",
  "entity_id": "ZazxsmpoQJz8BpqREEbXT",
  "collection_preview": true,
  "last-edit-info": {
    "timestamp": "2024-07-13T00:28:30.262Z",
    "id": 13371339,
    "first_name": "lucas",
    "last_name": "garcia",
    "email": "lu.garcia@alumno.um.edu.ar"
  },
  "visualization_settings": {
    "stackable.stack_type": null,
    "graph.dimensions": [
      "date"
    ],
    "graph.metrics": [
      "avg",
      "avg_2",
      "avg_3",
      "avg_4",
      "avg_5",
      "avg_6"
    ]
  },
  "collection": null,
  "metabase_version": "v0.50.12 (86d4671)",
  "parameters": [],
  "created_at": "2024-07-13T00:28:30.139153Z",
  "parameter_usage_count": 0,
  "public_uuid": null
}' | jq -r '.id')

log "Adding question to dashboard..."
curl -X PUT http://localhost:3000/api/dashboard/$DASHBOARD_ID \
  -H "Content-Type: application/json" \
  -H "X-Metabase-Session: $SESSION_TOKEN" \
  -d '{"description":"Mobility data for Mendoza Province, Capital Department","archived":false,"view_count":0,"collection_position":null,"dashcards":[{
    "id": -3,
    "cardId": '"$QUESTION_ID"',
    "sizeX": 24,
    "sizeY": 15,
    "row": 0,
    "col": 0
  }]'

# Add question to dashboard
# Add question to dashboard
log "Adding question to dashboard..."
curl -X PUT http://localhost:3000/api/dashboard/$DASHBOARD_ID/cards \
  -H "Content-Type: application/json" \
  -H "X-Metabase-Session: $SESSION_TOKEN" \
  -d '{
    "cards": [{
      "id": -3,
      "card_id": '"$QUESTION_ID"',
      "row": 0,
      "col": 0,
      "size_x": 12,
      "size_y": 8
    }]
  }'

log_and_run "echo 'Init script completed successfully'"

# Clean up port-forward
kill $PORTFORWARD_PID
