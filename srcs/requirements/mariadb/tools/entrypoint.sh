#!/bin/bash

set -e

if [ ! -f "/run/secrets/mysql_password" ] || [ ! -f "/run/secrets/mysql_root_password" ]; then
    echo "ERROR: Secret files not found!"
    exit 1
fi

MYSQL_PASSWORD=$(cat /run/secrets/mysql_password)
MYSQL_ROOT_PASSWORD=$(cat /run/secrets/mysql_root_password)
echo "Secrets loaded successfully."

if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing MariaDB data directory..."
    mysqld --initialize-insecure --user=mysql --datadir=/var/lib/mysql
fi

echo "Starting MariaDB in safe mode..."
mysqld --datadir=/var/lib/mysql --user=mysql & MYSQL_PID=$!

echo "Waiting for MariaDB to start..."
for i in {1..60}; do
    if mysqladmin ping --silent 2>/dev/null; then
        break
    fi
    if [ $i -eq 60 ]; then
        echo "ERROR: MariaDB failed to start within 60 seconds"
        kill $MYSQL_PID 2>/dev/null || true
        exit 1
    fi
    sleep 1
done

echo "MariaDB is running. Configuring database and users..."
mysql --silent <<EOSQL
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOSQL

echo "Stopping MariaDB safe mode..."
kill "$MYSQL_PID" && wait "$MYSQL_PID"

sleep 2

echo "Starting MariaDB in foreground mode..."
exec mysqld --datadir=/var/lib/mysql --user=mysql
