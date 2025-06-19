#!/bin/bash

set -e

generate_password() {
    openssl rand -base64 100 | tr -dc 'a-zA-Z0-9' | head -c 70
}

PASSWORDS_FILE=".passwords"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INCEPTION_ROOT="$(dirname "$SCRIPT_DIR")"
SSL_DIR="$INCEPTION_ROOT/srcs/certificates/nginx"
FTP_CERT_DIR="$INCEPTION_ROOT/srcs/certificates/ftp"

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

echo "Removing existing secrets..."
docker secret rm mysql_root_password mysql_password wordpress_db_password redis_password ftp_password 2>/dev/null || true
docker secret rm nginx_ssl_cert nginx_ssl_key nginx_ssl_dhparam nginx_ssl_fullchain ftp_ssl_cert ftp_ssl_key 2>/dev/null || true

echo "Creating password secrets..."
echo "$MYSQL_ROOT_PASSWORD" | docker secret create mysql_root_password - || { echo "Failed to create mysql_root_password"; exit 1; }
echo "$MYSQL_PASSWORD" | docker secret create mysql_password - || { echo "Failed to create mysql_password"; exit 1; }
echo "$MYSQL_PASSWORD" | docker secret create wordpress_db_password - || { echo "Failed to create wordpress_db_password"; exit 1; }
echo "$REDIS_PASSWORD" | docker secret create redis_password - || { echo "Failed to create redis_password"; exit 1; }
echo "$FTP_PASSWORD" | docker secret create ftp_password - || { echo "Failed to create ftp_password"; exit 1; }

echo "Creating nginx SSL secrets..."
if [ -f "$SSL_DIR/emgul.42.fr.crt" ]; then
    docker secret create nginx_ssl_cert "$SSL_DIR/emgul.42.fr.crt" || { echo "Failed to create nginx_ssl_cert"; exit 1; }
    echo "nginx_ssl_cert secret created"
else
    echo "Warning: nginx SSL certificate not found at $SSL_DIR/emgul.42.fr.crt"
fi

if [ -f "$SSL_DIR/emgul.42.fr.key" ]; then
    docker secret create nginx_ssl_key "$SSL_DIR/emgul.42.fr.key" || { echo "Failed to create nginx_ssl_key"; exit 1; }
    echo "nginx_ssl_key secret created"
else
    echo "Warning: nginx SSL key not found at $SSL_DIR/emgul.42.fr.key"
fi

if [ -f "$SSL_DIR/emgul.42.fr.fullchain.pem" ]; then
    docker secret create nginx_ssl_fullchain "$SSL_DIR/emgul.42.fr.fullchain.pem" || { echo "Failed to create nginx_ssl_fullchain"; exit 1; }
    echo "nginx_ssl_fullchain secret created"
else
    echo "Warning: nginx SSL fullchain not found at $SSL_DIR/emgul.42.fr.fullchain.pem"
fi

if [ -f "$SSL_DIR/dhparam.pem" ]; then
    docker secret create nginx_ssl_dhparam "$SSL_DIR/dhparam.pem" || { echo "Failed to create nginx_ssl_dhparam"; exit 1; }
    echo "nginx_ssl_dhparam secret created"
else
    echo "Warning: nginx dhparam not found at $SSL_DIR/dhparam.pem"
fi

echo "Creating FTP SSL secrets..."
if [ -f "$FTP_CERT_DIR/vsftpd.pem" ]; then
    docker secret create ftp_ssl_cert "$FTP_CERT_DIR/vsftpd.pem" || { echo "Failed to create ftp_ssl_cert"; exit 1; }
    echo "ftp_ssl_cert secret created"
else
    echo "Warning: FTP SSL certificate not found at $FTP_CERT_DIR/vsftpd.pem"
fi

if [ -f "$FTP_CERT_DIR/vsftpd.key" ]; then
    docker secret create ftp_ssl_key "$FTP_CERT_DIR/vsftpd.key" || { echo "Failed to create ftp_ssl_key"; exit 1; }
    echo "ftp_ssl_key secret created"
else
    echo "Warning: FTP SSL key not found at $FTP_CERT_DIR/vsftpd.key"
fi

echo "Secrets created successfully!"
if [ ! -f "$PASSWORDS_FILE" ]; then
    echo "Passwords have been saved to $PASSWORDS_FILE"
fi
