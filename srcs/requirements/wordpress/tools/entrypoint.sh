#!/bin/sh

set -eu

export WORDPRESS_DB_PASSWORD=$(cat /run/secrets/wordpress_db_password)

until mysql -h"$WORDPRESS_DB_HOST" -u"$WORDPRESS_DB_USER" -p"$WORDPRESS_DB_PASSWORD" -e "SELECT 1;" 2>/dev/null; do
  echo "Waiting for MariaDB to be ready..."
  sleep 2
done

until nc -z redis 6379; do
  echo "Waiting for Redis to be ready..."
  sleep 2
done

until nc -z ftp-server 21; do
  echo "Waiting for FTP server to be ready..."
  sleep 2
done

umask 027

WORDPRESS_ARCHIVE="wordpress-6.8.1.tar.gz"
WORDPRESS_DIR="wordpress"
CONFIG_FILE="wp-config.php"

log()    { echo "[INFO] $*"; }
error()  { echo "[ERROR] $*" >&2; }
cleanup() { rm -rf "$WORDPRESS_ARCHIVE" "$WORDPRESS_DIR"; [ -n "${TMP_ARGS:-}" ] && rm -f "$TMP_ARGS"; }
trap cleanup EXIT INT TERM

run_wp() {
    TMP_ARGS="$(mktemp /tmp/wp_args.XXXXXX)"
    printf '%s\0' "$@" > "$TMP_ARGS"
    chown www-data:www-data "$TMP_ARGS"
    gosu www-data sh -c "cd /var/www/html && HTTP_HOST='${DOMAIN_NAME}' SERVER_NAME='${DOMAIN_NAME}' xargs -0 -a '$TMP_ARGS' -- wp"
    local status=$?
    rm -f "$TMP_ARGS"
    return $status
}

export WP_CLI_CACHE_DIR="/tmp/wp-cli-cache"
mkdir -p "$WP_CLI_CACHE_DIR"
chown www-data:www-data "$WP_CLI_CACHE_DIR"

chown -R www-data:www-data /var/www/html /run/php

if [ -f "./$CONFIG_FILE" ]; then
    log "WordPress already exists. Skipping download."
else
    log "Downloading and configuring WordPress..."

    wget -q "https://wordpress.org/${WORDPRESS_ARCHIVE}"
    tar -xzf "$WORDPRESS_ARCHIVE"
    
    mv "$WORDPRESS_DIR"/* ./
    chown -R www-data:www-data .

    log "Creating WordPress configuration..."
    cat > "$CONFIG_FILE" << EOF
<?php

define( 'DB_NAME', '${WORDPRESS_DB_NAME}' );
define( 'DB_USER', '${WORDPRESS_DB_USER}' );
define( 'DB_PASSWORD', '${WORDPRESS_DB_PASSWORD}' );
define( 'DB_HOST', '${WORDPRESS_DB_HOST}' );
define( 'DB_CHARSET', 'utf8mb4' );
define( 'DB_COLLATE', '' );

define( 'AUTH_KEY',         '$(openssl rand -base64 48)' );
define( 'SECURE_AUTH_KEY',  '$(openssl rand -base64 48)' );
define( 'LOGGED_IN_KEY',    '$(openssl rand -base64 48)' );
define( 'NONCE_KEY',        '$(openssl rand -base64 48)' );
define( 'AUTH_SALT',        '$(openssl rand -base64 48)' );
define( 'SECURE_AUTH_SALT', '$(openssl rand -base64 48)' );
define( 'LOGGED_IN_SALT',   '$(openssl rand -base64 48)' );
define( 'NONCE_SALT',       '$(openssl rand -base64 48)' );

\$table_prefix = 'wp_';

define( 'WP_DEBUG', false );
EOF

    if [ -f /run/secrets/ftp_password ]; then
        FTP_PASS="$(cat /run/secrets/ftp_password)"
        log "Adding FTP configuration to WordPress..."
        cat >> "$CONFIG_FILE" << EOF

define( 'FTP_HOST', 'ftp-server' );
define( 'FTP_USER', 'ftpuser' );
define( 'FTP_PASS', '${FTP_PASS}' );
define( 'FTP_SSL', true );
define( 'FTP_TIMEOUT', 120 );
EOF
        log "FTP configuration added to WordPress."
    else
        log "Warning: FTP password secret not found, skipping FTP configuration."
    fi

    if [ -f /run/secrets/redis_password ]; then
        REDIS_PASS="$(cat /run/secrets/redis_password)"
        log "Adding Redis configuration to WordPress..."
        cat >> "$CONFIG_FILE" << EOF

define( 'WP_REDIS_HOST', 'redis' );
define( 'WP_REDIS_PORT', 6379 );
define( 'WP_REDIS_PASSWORD', '${REDIS_PASS}' );
define( 'WP_REDIS_DATABASE', 0 );
define( 'WP_REDIS_TIMEOUT', 1 );
define( 'WP_REDIS_READ_TIMEOUT', 1 );
define( 'WP_CACHE', true );
EOF
        log "Redis configuration added to WordPress."
    else
        log "Warning: Redis password secret not found, skipping Redis configuration."
    fi

    cat >> "$CONFIG_FILE" << EOF

if ( ! defined( 'ABSPATH' ) ) {
    define( 'ABSPATH', __DIR__ . '/' );
}

require_once ABSPATH . 'wp-settings.php';
EOF

    log "WordPress configuration complete."
fi

chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html
chmod 644 "$CONFIG_FILE" || true
mkdir -p wp-content
chown -R www-data:www-data wp-content
chmod -R 775 wp-content

until mysql -h "$WORDPRESS_DB_HOST" -u "$WORDPRESS_DB_USER" -p"$WORDPRESS_DB_PASSWORD" -e ";" 2>/dev/null; do
    log "Waiting for database connection..."
    sleep 3
done
log "Database connection established."

log "Checking if WordPress is installed..."
MAX_INSTALL_ATTEMPTS=5
INSTALL_ATTEMPT=1

while :; do
    if run_wp core is-installed; then
        log "WordPress core already installed. Skipping installation."
        break
    fi

    log "WordPress not installed (attempt $INSTALL_ATTEMPT), attempting installation..."
    if run_wp core install \
        --url="${DOMAIN_NAME}" \
        --title="Inception - emgul" \
        --admin_user="${WORDPRESS_DB_USER}" \
        --admin_password="${WORDPRESS_DB_PASSWORD}" \
        --admin_email="admin@${DOMAIN_NAME}" \
        --skip-email; then

        log "WordPress installation successful."
        run_wp post create \
            --post_type=page \
            --post_title="42" \
            --post_content="Hello from 42 Istanbul!" \
            --post_status=publish || {
                error "Failed to create initial post."
                exit 1
            }

        log "Configuring Redis cache..."
        if [ -f /run/secrets/redis_password ]; then
            run_wp plugin install redis-cache --activate --allow-root
            run_wp redis enable --allow-root
            log "Redis cache enabled."
        fi
        break
    fi

    error "WordPress installation failed (attempt $INSTALL_ATTEMPT). Retrying in 5 seconds..."
    INSTALL_ATTEMPT=$((INSTALL_ATTEMPT + 1))
    if [ $INSTALL_ATTEMPT -gt $MAX_INSTALL_ATTEMPTS ]; then
        error "WordPress installation failed after $MAX_INSTALL_ATTEMPTS attempts. Exiting."
        exit 1
    fi
    sleep 5
done

echo "[OK] WordPress is installed and configured."

exec gosu www-data php-fpm8.2 -F