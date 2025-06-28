#!/bin/sh

set -eu

echo "Waiting for $ADMINER_SERVER to be ready..."
if [ -n "${ADMINER_SERVER}" ]; then
    until nc -z "$ADMINER_SERVER" 3306 2>/dev/null; do
        echo "Waiting for $ADMINER_SERVER to be ready..."
        sleep 1
    done
    echo "$ADMINER_SERVER is ready!"
fi

echo "Starting Adminer on port 8080..."
exec php -S 0.0.0.0:8080 -t /var/www/html
