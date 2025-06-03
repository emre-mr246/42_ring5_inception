#!/bin/bash

set -e

mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld

rm -f /run/mysqld/mysqld.pid

if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing MariaDB data directory..."
    mysql_install_db --user=mysql --datadir=/var/lib/mysql
fi

echo "Starting MariaDB in safe mode..."
mysqld_safe --skip-networking --skip-grant-tables --datadir=/var/lib/mysql &
MYSQL_PID=$!

timeout=30
while ! mysqladmin ping --silent; do
    timeout=$((timeout - 1))
    if [ $timeout -le 0 ]; then
        echo "MariaDB failed to start!"
        kill $MYSQL_PID
        exit 1
    fi
    sleep 1
done

echo "Running initial SQL commands..."
mysql --skip-password <<-EOSQL
    FLUSH PRIVILEGES;
    CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
    CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
    GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
    ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
    FLUSH PRIVILEGES;
EOSQL

kill $MYSQL_PID
wait $MYSQL_PID

echo "MariaDB setup completed. Starting MariaDB in foreground..."
exec mysqld_safe --datadir=/var/lib/mysql