#!/bin/bash

set -e

echo "Starting MariaDB service..."
/usr/bin/mysqld_safe --datadir=/var/lib/mysql > /var/log/mysql/mysqld_safe.log 2>&1 &

echo "Waiting for MariaDB to be ready..."
timeout=30
while ! mysqladmin ping --user=root --password="${MYSQL_ROOT_PASSWORD}" --socket=/run/mysqld/mysqld.sock --silent; do
  timeout=$((timeout - 1))
  if [ $timeout -le 0 ]; then
    echo "MariaDB failed to start. Check logs at /var/log/mysql/mysqld_safe.log"
    cat /var/log/mysql/mysqld_safe.log
    exit 1
  fi
  echo -n "."; sleep 1;
done
echo " MariaDB is up and running!"

if [ ! -f /var/lib/mysql/.initialized ]; then
  echo "Initializing database..."
  mysql < /tmp/initial_db.sql
  touch /var/lib/mysql/.initialized
  echo "Database initialized successfully!"
else
  echo "Database already initialized."
fi

echo "Stopping temporary MariaDB instance..."
mysqladmin shutdown -uroot -p"${MYSQL_ROOT_PASSWORD}" --socket=/run/mysqld/mysqld.sock --silent

echo "Starting MariaDB in the foreground..."
exec mysqld