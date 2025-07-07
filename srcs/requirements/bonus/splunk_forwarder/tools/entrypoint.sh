#!/bin/bash

if [ -f "/run/secrets/splunk_forwarder_pass" ]; then
    export SPLUNK_FORWARDER_PASS=$(cat /run/secrets/splunk_forwarder_pass)
fi
if [ -f "/run/secrets/splunk_server_ip" ]; then
    export SPLUNK_SERVER_IP=$(cat /run/secrets/splunk_server_ip)
fi

./install_splunk.sh

LOG_DIR=${LOG_DIR}
COLLECTION_INTERVAL=${LOG_COLLECTION_INTERVAL}

mkdir -p "$LOG_DIR" || exit 1

collect_logs() {
    while true; do
        echo "$(date): Starting collection cycle" >&2

        CONTAINERS_JSON=$(curl -s --unix-socket /var/run/docker.sock "http://localhost/v1.50/containers/json")

        CONTAINERS=$(echo "$CONTAINERS_JSON" | grep -o '"Names":\["[^"]*"' | cut -d'"' -f4 | sed 's/^\///' | grep -v "splunk-forwarder")

        for CONTAINER_NAME in $CONTAINERS; do
            echo "Processing $CONTAINER_NAME..." >&2

            CONTAINER_ID=$(echo "$CONTAINERS_JSON" | sed 's/},{/}\n{/g' | grep "\"Names\":\[\"/$CONTAINER_NAME\"" | sed 's/.*"Id":"\([^"]*\)".*/\1/')

            if [ -z "$CONTAINER_ID" ]; then
                echo "Could not find container ID for $CONTAINER_NAME" >&2
                continue
            fi

            LOG_FILE="$LOG_DIR/${CONTAINER_NAME}.log"
            
            if [ -f "$LOG_FILE" ] && [ -s "$LOG_FILE" ]; then
                LAST_TS=$(tail -1 "$LOG_FILE" | grep -o '^[0-9T:.-]*Z' | head -1 | xargs -I {} date -d {} +%s 2>/dev/null || echo "0")
                [ "$LAST_TS" = "0" ] && LAST_TS=$(($(date +%s) - 60))
            else
                LAST_TS=$(($(date +%s) - 300))
            fi

            TEMP_FILE=$(mktemp)
            curl -s --unix-socket /var/run/docker.sock \
                "http://localhost/v1.50/containers/${CONTAINER_ID}/logs?stdout=true&stderr=true&timestamps=true&since=${LAST_TS}" \
                > "$TEMP_FILE"

            NEW_LOGS=$(sed 's/^.\{8\}//' "$TEMP_FILE" | grep '^[0-9]' || true)

            if [ -n "$NEW_LOGS" ]; then
                echo "$NEW_LOGS" >> "$LOG_FILE"
                echo "Added new logs for $CONTAINER_NAME" >&2
            else
                echo "No new logs for $CONTAINER_NAME" >&2
            fi

            rm -f "$TEMP_FILE"
        done

        echo "$(date): Cycle completed, sleeping..." >&2

        find "$LOG_DIR" -name "*.log" -type f -size +100M -exec sh -c '
            echo "Rotating log file: $1" >&2
            tail -n 50000 "$1" > "$1.tmp" && mv "$1.tmp" "$1"
        ' _ {} \;

        sleep "$COLLECTION_INTERVAL"
    done
}

collect_logs &
LOG_COLLECTOR_PID=$!

cleanup() {
    echo "Shutting down log collector..." >&2
    kill $LOG_COLLECTOR_PID 2>/dev/null || true
    /opt/splunkforwarder/bin/splunk stop
    exit 0
}

trap cleanup SIGTERM SIGINT

echo "Starting Splunk Universal Forwarder..." >&2
cd /opt/splunkforwarder/bin
exec ./splunk start --accept-license --answer-yes --no-prompt --nodaemon