#!/bin/bash

LOG_FILE="/var/log/metabase_init.log"

echo "Starting metabase_init.sh" >> $LOG_FILE

# Function to log messages
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $LOG_FILE
}

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    log "Docker not found, installing Docker..."
    apt-get update && apt-get install -y docker.io
    if [ $? -ne 0 ]; then
        log "Failed to install Docker. Exiting."
        exit 1
    fi
fi

# Ensure Docker service is running
systemctl start docker
systemctl enable docker

# Pull the Metabase Docker image
log "Pulling Metabase Docker image..."
if ! docker pull metabase/metabase; then
    log "Failed to pull Metabase image. Exiting."
    exit 1
fi


# Run Metabase Docker container
log "Starting Metabase container..."
if ! docker run -d -p 3000:3000 --name metabase \
    -v /opt/metabase:/metabase-data \
    metabase/metabase; then
    log "Failed to start Metabase container. Exiting."
    exit 1
fi

# Install jq if not present
if ! command -v jq &> /dev/null; then
    log "Installing jq..."
    apt-get update && apt-get install -y jq
fi

# Function to check if Metabase is ready
wait_for_metabase() {
    log "Waiting for Metabase to start..."
    while ! curl -s http://localhost:3000/api/health | grep -q "ok"; do
        sleep 10
    done
    log "Metabase is ready!"
}

# Wait for Metabase to start
wait_for_metabase

SETUP_TOKEN=$(curl -s -m 5 -X GET \
        -H "Content-Type: application/json" \
        http://localhost:3000/api/session/properties \
        | jq -r '.["setup-token"]'
    )

# Set up admin account
# Set up admin account
log "Setting up admin account..."
SETUP_RESPONSE=$(curl -s -X POST http://localhost:3000/api/setup \
  -H "Content-Type: application/json" \
  -d '{"token":"'$SETUP_TOKEN'","user":{"password_confirm":"'${metabase_password}'","password":"'${metabase_password}'","site_name":"UM","email":"lu.garcia@alumno.um.edu.ar","last_name":"garcia","first_name":"lucas"},"prefs":{"site_name":"UM","site_locale":"en"}}')

log "Setup response: $SETUP_RESPONSE"

# Get session token
log "Getting session token..."
SESSION_TOKEN=$(curl -X POST http://localhost:3000/api/session \
  -H "Content-Type: application/json" \
  -d '{
    "username": "lu.garcia@alumno.um.edu.ar",
    "password": "'"${metabase_password}"'"
  }' | jq -r '.id')

if [ -z "$SESSION_TOKEN" ]; then
    log "Failed to get session token. Exiting."
    exit 1
fi

# Add database connection
log "Adding database connection..."
DB_ID=$(curl -X POST http://localhost:3000/api/database \
  -H "Content-Type: application/json" \
  -H "X-Metabase-Session: $SESSION_TOKEN" \
  -d '{"is_on_demand":false,"is_full_sync":true,"is_sample":false,"cache_ttl":null,"refingerprint":false,"auto_run_queries":true,"schedules":{},"details":{"host":"'${db_host}'","port":3306,"dbname":"'${db_name}'","user":"'${db_user}'","password":"'${db_password}'","ssl":false,"tunnel-enabled":false,"advanced-options":false},"name":"mobility","engine":"mysql"}' | jq -r '.id')

if [ -z "$DB_ID" ]; then
    log "Failed to add database connection. Exiting."
    exit 1
fi

# Create dashboard
log "Creating dashboard..."
DASHBOARD_ID=$(curl -X POST http://localhost:3000/api/dashboard \
  -H "Content-Type: application/json" \
  -H "X-Metabase-Session: $SESSION_TOKEN" \
  -d '{
    "name": "Mobility Dashboard",
    "description": "Mobility data for Mendoza Province, Capital Department"
  }' | jq -r '.id')

if [ -z "$DASHBOARD_ID" ]; then
    log "Failed to create dashboard. Exiting."
    exit 1
fi

# Create question with the provided SQL
log "Creating question..."
QUESTION_ID=$(curl -X POST http://localhost:3000/api/card \
  -H "Content-Type: application/json" \
  -H "X-Metabase-Session: $SESSION_TOKEN" \
  -d '{"name":"average mendoza","type":"question","dataset_query":{"database": '"$DB_ID"',"type":"query","query":{"source-table":9,"aggregation":[["avg",["field",83,{"base-type":"type/Integer"}]],["avg",["field",81,{"base-type":"type/Integer"}]],["avg",["field",72,{"base-type":"type/Integer"}]],["avg",["field",80,{"base-type":"type/Integer"}]],["avg",["field",78,{"base-type":"type/Integer"}]],["avg",["field",86,{"base-type":"type/Integer"}]]],"breakout":[["field",73,{"base-type":"type/DateTime","temporal-unit":"day"}]],"filter":["and",["=",["field",85,{"base-type":"type/Text"}],"Mendoza Province"],["=",["field",75,{"base-type":"type/Text"}],"Capital Department"],["between",["field",73,{"base-type":"type/DateTime"}],"2020-01-01","2020-12-31"]]}},"display":"area","description":null,"visualization_settings":{"stackable.stack_type":null,"graph.dimensions":["date"],"graph.metrics":["avg","avg_2","avg_3","avg_4","avg_5","avg_6"]},"collection_id":null,"collection_position":null,"result_metadata":[{"description":null,"semantic_type":null,"coercion_strategy":null,"unit":"day","name":"date","settings":null,"fk_target_field_id":null,"field_ref":["field",73,{"base-type":"type/DateTime","temporal-unit":"day"}],"effective_type":"type/Date","id":73,"visibility_type":"normal","display_name":"Date","fingerprint":{"global":{"distinct-count":321,"nil%":0},"type":{"type/DateTime":{"earliest":"2020-02-15T00:00:00Z","latest":"2020-12-31T00:00:00Z"}}},"base_type":"type/Date"},{"display_name":"Average of Retail And Recreation Percent Change From Baseline","semantic_type":null,"settings":null,"field_ref":["aggregation",0],"base_type":"type/Decimal","effective_type":"type/Decimal","name":"avg","fingerprint":{"global":{"distinct-count":95,"nil%":0},"type":{"type/Number":{"min":-96,"q1":-69.0857716560905,"q3":-42.84139629549865,"max":41,"sd":27.658547670628238,"avg":-52.29283489096573}}}},{"display_name":"Average of Grocery And Pharmacy Percent Change From Baseline","semantic_type":null,"settings":null,"field_ref":["aggregation",1],"base_type":"type/Decimal","effective_type":"type/Decimal","name":"avg_2","fingerprint":{"global":{"distinct-count":101,"nil%":0},"type":{"type/Number":{"min":-91,"q1":-30.805717884568125,"q3":0.5971624461628744,"max":83,"sd":26.054557250362603,"avg":-16.31152647975078}}}},{"display_name":"Average of Parks Percent Change From Baseline","semantic_type":null,"settings":null,"field_ref":["aggregation",2],"base_type":"type/Decimal","effective_type":"type/Decimal","name":"avg_3","fingerprint":{"global":{"distinct-count":94,"nil%":0},"type":{"type/Number":{"min":-99,"q1":-90.42656981021216,"q3":-50.86001194493218,"max":59,"sd":32.48307885753726,"avg":-60.49844236760124}}}},{"display_name":"Average of Transit Stations Percent Change From Baseline","semantic_type":null,"settings":null,"field_ref":["aggregation",3],"base_type":"type/Decimal","effective_type":"type/Decimal","name":"avg_4","fingerprint":{"global":{"distinct-count":86,"nil%":0},"type":{"type/Number":{"min":-90,"q1":-56.375,"q3":-39.62201759733446,"max":29,"sd":23.83605137258345,"avg":-45.16822429906542}}}},{"display_name":"Average of Workplaces Percent Change From Baseline","semantic_type":null,"settings":null,"field_ref":["aggregation",4],"base_type":"type/Decimal","effective_type":"type/Decimal","name":"avg_5","fingerprint":{"global":{"distinct-count":91,"nil%":0},"type":{"type/Number":{"min":-83,"q1":-29.76356457060072,"q3":-6.708333333333333,"max":33,"sd":24.104273707172357,"avg":-21.40809968847352}}}},{"display_name":"Average of Residential Percent Change From Baseline","semantic_type":null,"settings":null,"field_ref":["aggregation",5],"base_type":"type/Decimal","effective_type":"type/Decimal","name":"avg_6","fingerprint":{"global":{"distinct-count":42,"nil%":0},"type":{"type/Number":{"min":-3,"q1":11.41332798286476,"q3":20.054308789731966,"max":40,"sd":8.746244187259899,"avg":16.009345794392523}}}}]}' | jq -r '.id')

if [ -z "$QUESTION_ID" ]; then
    log "Failed to create question. Exiting."
    exit 1
fi
      



# Add question to dashboard
log "Adding question to dashboard..."
curl -X POST http://localhost:3000/api/dashboard/$DASHBOARD_ID \
  -H "Content-Type: application/json" \
  -H "X-Metabase-Session: $SESSION_TOKEN" \
  -d '{
    "cardId": '"$QUESTION_ID"',
    "sizeX": 24,
    "sizeY": 15,
    "row": 0,
    "col": 0
  }'

log "Setup complete! You can now access your Metabase instance at http://localhost:3000"


curl 'http://192.168.3.156/api/dashboard/3' \
  -X 'PUT' \
  -H 'Accept: application/json' \
  -H 'Accept-Language: en-US,en;q=0.9' \
  -H 'Connection: keep-alive' \
  -H 'Content-Type: application/json' \
  -H 'Cookie: metabase.DEVICE=5753beec-0f00-42ed-b5c6-af2e7d906a62; metabase.TIMEOUT=alive; metabase.SESSION=368e5344-8db6-4b1a-ad2b-57da079a2069' \
  -H 'DNT: 1' \
  -H 'Origin: http://192.168.3.156' \
  -H 'Referer: http://192.168.3.156/dashboard/3-caso-2' \
  -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36' \
  --data-raw '{"description":null,"archived":false,"view_count":0,"collection_position":null,"dashcards":[{"id":-1,"card_id":28,"dashboard_tab_id":null,"row":0,"col":0,"size_x":24,"size_y":15,"visualization_settings":{},"parameter_mappings":[]}],"param_values":null,"initially_published_at":null,"can_write":true,"tabs":[],"enable_embedding":false,"collection_id":null,"show_in_getting_started":false,"name":"caso 2","width":"fixed","caveats":null,"collection_authority_level":null,"creator_id":1,"updated_at":"2024-07-10T03:32:37.258955Z","made_public_by_id":null,"embedding_params":null,"cache_ttl":null,"last_used_param_values":{},"position":null,"entity_id":"ayiQQIP-nTTSCaMlwrpFU","param_fields":null,"last-edit-info":{"id":1,"email":"lu.garcia@alumno.um.edu.ar","first_name":"lucas","last_name":"garcia","timestamp":"2024-07-10T03:32:37.287909Z"},"collection":{"metabase.models.collection.root/is-root?":true,"authority_level":null,"name":"Our analytics","is_personal":false,"id":"root","can_write":true},"parameters":[],"auto_apply_filters":true,"created_at":"2024-07-10T03:32:37.258955Z","public_uuid":null,"points_of_interest":null}' \
  --insecure