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
gosu mysql mysqld_safe \
  --skip-grant-tables \
  --datadir=/var/lib/mysql &
MYSQL_PID=$!

timeout=30
until mysqladmin ping --silent; do
  ((timeout--)) || { echo "MariaDB failed to start" >&2; kill $MYSQL_PID; exit 1; }
  sleep 1
done

echo "Configuring database and users..."
mysql <<-EOSQL
  FLUSH PRIVILEGES;
  CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
  CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
  GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
  ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
  FLUSH PRIVILEGES;
EOSQL

if kill "$MYSQL_PID" > /dev/null 2>&1; then
  wait "$MYSQL_PID"
fi

echo "Starting MariaDB in foreground..."
exec gosu mysql mysqld --datadir=/var/lib/mysql