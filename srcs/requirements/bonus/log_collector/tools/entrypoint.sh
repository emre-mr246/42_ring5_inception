#!/bin/bash

PERSISTENT_LOG_DIR=${PERSISTENT_LOG_DIR}
STACK_NAME="${STACK_NAME}"
COLLECTION_INTERVAL=${LOG_COLLECTION_INTERVAL}
ARCHIVED_TARBALLS_SUBDIR=${ARCHIVED_TARBALLS_SUBDIR}
INDIVIDUAL_LOGS_SUBDIR=${INDIVIDUAL_LOGS_SUBDIR}

mkdir -p "$PERSISTENT_LOG_DIR/$INDIVIDUAL_LOGS_SUBDIR"
mkdir -p "$PERSISTENT_LOG_DIR/$ARCHIVED_TARBALLS_SUBDIR"

echo "Log Collector started. Stack: '$STACK_NAME'. Collection interval: $COLLECTION_INTERVAL seconds."
echo "Individual logs will be written to '$PERSISTENT_LOG_DIR/$INDIVIDUAL_LOGS_SUBDIR'."
echo "Archived logs will be saved to '$PERSISTENT_LOG_DIR/$ARCHIVED_TARBALLS_SUBDIR'."

while true; do
	CURRENT_TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
	echo "--- Log collection cycle started: $CURRENT_TIMESTAMP ---"

	SERVICES=$(docker service ls --filter "label=com.docker.stack.namespace=$STACK_NAME" --format "{{.Name}}")

	if [ -z "$SERVICES" ]; then
		echo "No services found for stack '$STACK_NAME'. Retrying in 60 seconds."
		sleep 60
		continue
	fi

	TEMP_LOG_CYCLE_DIR=$(mktemp -d -p "$PERSISTENT_LOG_DIR")

	for SERVICE_FULL_NAME in $SERVICES; do
		SERVICE_SHORT_NAME=$(echo "$SERVICE_FULL_NAME" | sed "s/^${STACK_NAME}_//")
		
		INDIVIDUAL_LOG_FILE="$PERSISTENT_LOG_DIR/$INDIVIDUAL_LOGS_SUBDIR/${SERVICE_SHORT_NAME}.log"
		CURRENT_LOG_FILE_FOR_TARBALL="$TEMP_LOG_CYCLE_DIR/${SERVICE_SHORT_NAME}.log"

		echo "Collecting logs: $SERVICE_FULL_NAME ..."

		{
			echo "--- $SERVICE_FULL_NAME logs appended: $CURRENT_TIMESTAMP ---"
			docker service logs "$SERVICE_FULL_NAME" --raw --timestamps --no-trunc
			echo "--- $SERVICE_FULL_NAME log end: $CURRENT_TIMESTAMP ---"
		} >> "$INDIVIDUAL_LOG_FILE" 2>&1

		docker service logs "$SERVICE_FULL_NAME" --raw --timestamps --no-trunc > "$CURRENT_LOG_FILE_FOR_TARBALL" 2>&1
		
		echo "Logs processed: $SERVICE_FULL_NAME."
	done

	TARBALL_NAME="inception_logs_${CURRENT_TIMESTAMP}.tar.gz"
	TARBALL_PATH="$PERSISTENT_LOG_DIR/$ARCHIVED_TARBALLS_SUBDIR/$TARBALL_NAME"

	echo "Creating tarball backup: $TARBALL_PATH (source: $TEMP_LOG_CYCLE_DIR)"
	if [ -n "$(ls -A "$TEMP_LOG_CYCLE_DIR" 2>/dev/null)" ]; then
		tar -czf "$TARBALL_PATH" -C "$TEMP_LOG_CYCLE_DIR" .
		echo "Tarball backup created: $TARBALL_PATH"
	else
		echo "No logs found to create tarball in this cycle (temporary directory was empty)."
	fi

	rm -rf "$TEMP_LOG_CYCLE_DIR"

	find "$PERSISTENT_LOG_DIR/$INDIVIDUAL_LOGS_SUBDIR" -name "*.log" -type f -size +102400k -exec truncate -s 0 {} \;

	find "$PERSISTENT_LOG_DIR/$ARCHIVED_TARBALLS_SUBDIR" -name "inception_logs_*.tar.gz" -type f -mtime +14 -exec echo "deleting old archives: {}" \; -exec rm {} \;

	echo "--- Log collection cycle finished: $(date). Waiting $COLLECTION_INTERVAL seconds. ---"
	sleep "$COLLECTION_INTERVAL"
done
