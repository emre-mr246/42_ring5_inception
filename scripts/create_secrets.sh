#!/bin/bash

generate_password() {
    openssl rand -base64 100 | tr -dc 'a-zA-Z0-9' | head -c 70
}

PASSWORDS_FILE=".passwords"

if [ -f "$PASSWORDS_FILE" ]; then
    echo "Passwords file exists. Reading passwords..."
    source "$PASSWORDS_FILE"
else
    echo "Creating new passwords..."
    MYSQL_ROOT_PASSWORD=$(generate_password)
    MYSQL_PASSWORD=$(generate_password)
    WORDPRESS_DB_PASSWORD="$MYSQL_PASSWORD"
    REDIS_PASSWORD=$(generate_password)
    FTP_PASSWORD=$(generate_password)

    {
        echo "MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD"
        echo "MYSQL_PASSWORD=$MYSQL_PASSWORD"
        echo "WORDPRESS_DB_PASSWORD=$WORDPRESS_DB_PASSWORD"
        echo "REDIS_PASSWORD=$REDIS_PASSWORD"
        echo "FTP_PASSWORD=$FTP_PASSWORD"
    } > "$PASSWORDS_FILE"
    chmod 600 "$PASSWORDS_FILE"
fi

echo "Creating Docker Swarm secrets..."

docker secret rm mysql_root_password mysql_password wordpress_db_password redis_password ftp_password 2>/dev/null || true

echo "$MYSQL_ROOT_PASSWORD" | docker secret create mysql_root_password -
echo "$MYSQL_PASSWORD" | docker secret create mysql_password -
echo "$MYSQL_PASSWORD" | docker secret create wordpress_db_password -
echo "$REDIS_PASSWORD" | docker secret create redis_password -
echo "$FTP_PASSWORD" | docker secret create ftp_password -

echo "Secrets created successfully!"
if [ ! -f "$PASSWORDS_FILE" ]; then
    echo "Passwords have been saved to $PASSWORDS_FILE"
fi
