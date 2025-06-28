#!/bin/bash

./install_splunk.sh

PERSISTENT_LOG_DIR=${PERSISTENT_LOG_DIR}
STACK_NAME=${STACK_NAME}
COLLECTION_INTERVAL=${LOG_COLLECTION_INTERVAL}
INDIVIDUAL_LOGS_SUBDIR=${INDIVIDUAL_LOGS_SUBDIR}

mkdir -p "$PERSISTENT_LOG_DIR/$INDIVIDUAL_LOGS_SUBDIR" || exit 1

collect_logs() {
    local START_TIME=$(date +%s)
    
    while true; do
        SERVICES=$(curl -s --unix-socket /var/run/docker.sock "http://localhost/v1.50/services" | grep -o '"Name":"[^"]*' | cut -d'"' -f4 | grep "^${STACK_NAME}")

        if [ -z "$SERVICES" ]; then
            sleep 60
            continue
        fi

        CURRENT_TIME=$(date +%s)
        TIME_DIFF=$((CURRENT_TIME - START_TIME))

        for SERVICE_FULL_NAME in $SERVICES; do
            SERVICE_SHORT_NAME=$(echo "$SERVICE_FULL_NAME" | sed "s/^${STACK_NAME}_//")
            INDIVIDUAL_LOG_FILE="$PERSISTENT_LOG_DIR/$INDIVIDUAL_LOGS_SUBDIR/${SERVICE_SHORT_NAME}.log"

            curl -s --unix-socket /var/run/docker.sock \
                "http://localhost/v1.50/services/${SERVICE_FULL_NAME}/logs?stdout=true&stderr=true&timestamps=true&since=${TIME_DIFF}" | \
                sed 's/^.\{8\}//' | \
                grep -a '^[0-9]' >> "$INDIVIDUAL_LOG_FILE" 2>/dev/null
        done

        find "$PERSISTENT_LOG_DIR/$INDIVIDUAL_LOGS_SUBDIR" -name "*.log" -type f -size +102400k -exec tail -n 50000 {} \; -exec sh -c 'tail -n 50000 "$1" > "$1.tmp" && mv "$1.tmp" "$1"' _ {} \;

        START_TIME=$CURRENT_TIME
        sleep "$COLLECTION_INTERVAL"
    done
}

echo "Starting Docker log collection in background..."
collect_logs &
LOG_COLLECTOR_PID=$!

cleanup() {
    echo "Shutting down log collector..."
    kill $LOG_COLLECTOR_PID 2>/dev/null
    /opt/splunkforwarder/bin/splunk stop
    exit 0
}

trap cleanup SIGTERM SIGINT

echo "Starting Splunk Universal Forwarder in foreground..."
cd /opt/splunkforwarder/bin

exec ./splunk start --accept-license --answer-yes --no-prompt --nodaemon