#!/bin/sh

set -eu

echo "Adminer default server: ${ADMINER_DEFAULT_SERVER:-not set}"

echo "Waiting for database server to be ready..."
if [ -n "${ADMINER_DEFAULT_SERVER:-}" ]; then
    until nc -z "$ADMINER_DEFAULT_SERVER" 3306 2>/dev/null; do
        echo "Waiting for $ADMINER_DEFAULT_SERVER:3306..."
        sleep 2
    done
    echo "Database server is ready!"
fi

echo "Starting Adminer on port 8080..."
exec php -S 0.0.0.0:8080 -t /var/www/html
