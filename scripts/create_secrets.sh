#!/bin/bash

generate_password() {
    openssl rand -base64 100 | tr -dc 'a-zA-Z0-9' | head -c 70
}

PASSWORDS_FILE=".passwords"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INCEPTION_ROOT="$(dirname "$SCRIPT_DIR")"
SSL_DIR="$INCEPTION_ROOT/srcs/certificates/nginx"
FTP_CERT_DIR="$INCEPTION_ROOT/srcs/certificates/ftp"

if [ -f "$PASSWORDS_FILE" ]; then
    source "$PASSWORDS_FILE"
else
    echo "Creating new passwords..."
    MYSQL_ROOT_PASSWORD=$(generate_password)
    MYSQL_PASSWORD=$(generate_password)
    WORDPRESS_DB_PASSWORD="$MYSQL_PASSWORD"
    WORDPRESS_ADMIN_PASSWORD=$(generate_password)
    WORDPRESS_USER_PASSWORD=$(generate_password)
    REDIS_PASSWORD=$(generate_password)
    FTP_PASSWORD=$(generate_password)
    SPLUNK_FORWARDER_PASS=$(generate_password)
    SPLUNK_SERVER_IP=$(grep SPLUNK_SERVER srcs/env/.env_splunk_forwarder | cut -d'=' -f2)
    
    cat > "$PASSWORDS_FILE" << EOF
MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD
MYSQL_PASSWORD=$MYSQL_PASSWORD
WORDPRESS_DB_PASSWORD=$WORDPRESS_DB_PASSWORD
WORDPRESS_ADMIN_PASSWORD=$WORDPRESS_ADMIN_PASSWORD
WORDPRESS_USER_PASSWORD=$WORDPRESS_USER_PASSWORD
REDIS_PASSWORD=$REDIS_PASSWORD
FTP_PASSWORD=$FTP_PASSWORD
SPLUNK_FORWARDER_PASS=$SPLUNK_FORWARDER_PASS
SPLUNK_SERVER_IP=$SPLUNK_SERVER_IP
EOF
    chmod 600 "$PASSWORDS_FILE"
fi

create_secret() {
    local name=$1
    local value=$2
    local file=$3
    
    if docker secret inspect "$name" >/dev/null 2>&1; then
        echo "Secret $name already exists, skipping..."
        return 0
    fi
    
    if [ -n "$file" ] && [ -f "$file" ]; then
        docker secret create "$name" "$file"
    elif [ -n "$value" ]; then
        echo "$value" | docker secret create "$name" -
    else
        echo "Warning: Cannot create secret $name - no value or file provided"
        return 1
    fi
}

echo "Creating Docker Swarm secrets..."

create_secret "mysql_root_password" "$MYSQL_ROOT_PASSWORD"
create_secret "mysql_password" "$MYSQL_PASSWORD"
create_secret "wordpress_db_password" "$WORDPRESS_DB_PASSWORD"
create_secret "wordpress_admin_password" "$WORDPRESS_ADMIN_PASSWORD"
create_secret "wordpress_user_password" "$WORDPRESS_USER_PASSWORD"
create_secret "redis_password" "$REDIS_PASSWORD"
create_secret "ftp_password" "$FTP_PASSWORD"
create_secret "splunk_forwarder_pass" "$SPLUNK_FORWARDER_PASS"
create_secret "splunk_server_ip" "$SPLUNK_SERVER_IP"

create_secret "nginx_ssl_cert" "" "$SSL_DIR/emgul.42.fr.crt"
create_secret "nginx_ssl_key" "" "$SSL_DIR/emgul.42.fr.key"
create_secret "nginx_ssl_fullchain" "" "$SSL_DIR/emgul.42.fr.fullchain.pem"
create_secret "nginx_ssl_dhparam" "" "$SSL_DIR/dhparam.pem"
create_secret "ftp_ssl_cert" "" "$FTP_CERT_DIR/vsftpd.pem"
create_secret "ftp_ssl_key" "" "$FTP_CERT_DIR/vsftpd.key"

echo "Secrets creation completed!"
