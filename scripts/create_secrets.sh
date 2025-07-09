#!/bin/bash

generate_password() {
    openssl rand -base64 100 | tr -dc 'a-zA-Z0-9' | head -c 70
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INCEPTION_ROOT="$(dirname "$SCRIPT_DIR")"
SSL_DIR="$INCEPTION_ROOT/srcs/certificates"
SECRETS_DIR="$INCEPTION_ROOT/srcs/secrets"

mkdir -p "$SECRETS_DIR"

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

create_secret_file() {
    local name=$1
    local value=$2
    local source_file=$3
    local target_file="$SECRETS_DIR/$name"
    
    if [ -f "$target_file" ]; then
        echo "Secret file $name already exists, skipping..."
        return 0
    fi
    
    if [ -n "$source_file" ] && [ -f "$source_file" ]; then
        cp "$source_file" "$target_file"
        echo "Created secret file: $name from $source_file"
    elif [ -n "$value" ]; then
        echo "$value" > "$target_file"
        echo "Created secret file: $name"
    else
        echo "Warning: Cannot create secret file $name - no value or source file provided"
        return 1
    fi
    
    chmod 644 "$target_file"
}

echo "Creating secrets..."

create_secret_file "mysql_root_password.txt" "$MYSQL_ROOT_PASSWORD"
create_secret_file "mysql_password.txt" "$MYSQL_PASSWORD"
create_secret_file "wordpress_db_password.txt" "$WORDPRESS_DB_PASSWORD"
create_secret_file "wordpress_admin_password.txt" "$WORDPRESS_ADMIN_PASSWORD"
create_secret_file "wordpress_user_password.txt" "$WORDPRESS_USER_PASSWORD"
create_secret_file "redis_password.txt" "$REDIS_PASSWORD"
create_secret_file "ftp_password.txt" "$FTP_PASSWORD"
create_secret_file "splunk_forwarder_pass.txt" "$SPLUNK_FORWARDER_PASS"
create_secret_file "splunk_server_ip.txt" "$SPLUNK_SERVER_IP"

create_secret_file "nginx_ssl_cert.pem" "" "$SSL_DIR/emgul.42.fr.crt"
create_secret_file "nginx_ssl_key.pem" "" "$SSL_DIR/emgul.42.fr.key"
create_secret_file "nginx_ssl_fullchain.pem" "" "$SSL_DIR/emgul.42.fr.fullchain.pem"
create_secret_file "nginx_ssl_dhparam.pem" "" "$SSL_DIR/dhparam.pem"

echo "Secrets creation completed!"
