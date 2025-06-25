#!/bin/sh

set -eu

WORDPRESS_DB_PASSWORD=$(cat /run/secrets/wordpress_db_password)

until mysql -h"$WORDPRESS_DB_HOST" -u"$WORDPRESS_DB_USER" -p"$WORDPRESS_DB_PASSWORD" -e "SELECT 1;" 2>/dev/null; do
  echo "Waiting for MariaDB to be ready..."
  sleep 2
done
echo "[OK] MariaDB is ready"

until nc -z redis 6379; do
  echo "Waiting for Redis to be ready..."
  sleep 2
done
echo "[OK] Redis is ready"

until nc -z ftp-server 21; do
  echo "Waiting for FTP server to be ready..."
  sleep 2
done
echo "[OK] FTP server is ready"

umask 027

WORDPRESS_ARCHIVE="wordpress-6.8.1.tar.gz"
WORDPRESS_DIR="wordpress"
CONFIG_FILE="wp-config.php"

log() { echo "[INFO] $*"; }
cleanup() { rm -rf "$WORDPRESS_ARCHIVE" "$WORDPRESS_DIR" /tmp/wp-args.* /tmp/wp-cli-cache; }
trap cleanup EXIT INT TERM

run_wp() {
    TMP_ARGS="$(mktemp /tmp/wp_args.XXXXXX)"
    printf '%s\0' "$@" > "$TMP_ARGS"
    chown www-data:www-data "$TMP_ARGS"
    
    if gosu www-data sh -c "cd /var/www/html && HTTP_HOST='${DOMAIN_NAME}' SERVER_NAME='${DOMAIN_NAME}' xargs --null -a '$TMP_ARGS' -- wp"; then
        rm -f "$TMP_ARGS"
        return 0
    else
        local status=$?
        rm -f "$TMP_ARGS"
        log "WordPress command failed with exit code: $status"
        return $status
    fi
}

WP_CLI_CACHE_DIR="/tmp/wp-cli-cache"
mkdir -p "$WP_CLI_CACHE_DIR"
chown www-data:www-data "$WP_CLI_CACHE_DIR"

chown -R www-data:www-data /var/www/html /run/php

if [ -f "./$CONFIG_FILE" ] && [ -f "./wp-settings.php" ] && grep -q "wp-settings.php" "./$CONFIG_FILE"; then
    log "WordPress already exists and is properly configured. Skipping download."
else
    log "WordPress not found or improperly configured. Installing..."

    rm -f "./$CONFIG_FILE"
    rm -rf ./wp-*

    wget --quiet "https://wordpress.org/${WORDPRESS_ARCHIVE}"
    tar -xzf "$WORDPRESS_ARCHIVE"
    
    mv "$WORDPRESS_DIR"/* ./
    chown -R www-data:www-data .

    FTP_PASS="$(cat /run/secrets/ftp_password)"
    REDIS_PASS="$(cat /run/secrets/redis_password)"

    log "Creating WordPress configuration..."
    
    AUTH_KEY="$(openssl rand -base64 48)"
    SECURE_AUTH_KEY="$(openssl rand -base64 48)"
    LOGGED_IN_KEY="$(openssl rand -base64 48)"
    NONCE_KEY="$(openssl rand -base64 48)"
    AUTH_SALT="$(openssl rand -base64 48)"
    SECURE_AUTH_SALT="$(openssl rand -base64 48)"
    LOGGED_IN_SALT="$(openssl rand -base64 48)"
    NONCE_SALT="$(openssl rand -base64 48)"

    sed -e "s|\${WORDPRESS_DB_NAME}|${WORDPRESS_DB_NAME}|g" \
        -e "s|\${WORDPRESS_DB_USER}|${WORDPRESS_DB_USER}|g" \
        -e "s|\${WORDPRESS_DB_PASSWORD}|${WORDPRESS_DB_PASSWORD}|g" \
        -e "s|\${WORDPRESS_DB_HOST}|${WORDPRESS_DB_HOST}|g" \
        -e "s|\${DOMAIN_NAME}|${DOMAIN_NAME}|g" \
        -e "s|\${AUTH_KEY}|${AUTH_KEY}|g" \
        -e "s|\${SECURE_AUTH_KEY}|${SECURE_AUTH_KEY}|g" \
        -e "s|\${LOGGED_IN_KEY}|${LOGGED_IN_KEY}|g" \
        -e "s|\${NONCE_KEY}|${NONCE_KEY}|g" \
        -e "s|\${AUTH_SALT}|${AUTH_SALT}|g" \
        -e "s|\${SECURE_AUTH_SALT}|${SECURE_AUTH_SALT}|g" \
        -e "s|\${LOGGED_IN_SALT}|${LOGGED_IN_SALT}|g" \
        -e "s|\${NONCE_SALT}|${NONCE_SALT}|g" \
        -e "s|\${FTP_PASS}|${FTP_PASS}|g" \
        -e "s|\${REDIS_PASS}|${REDIS_PASS}|g" \
        "/usr/local/share/wp-config.php" > "$CONFIG_FILE"
    log "WordPress configuration complete."
fi

chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html
chmod 644 "$CONFIG_FILE"
mkdir -p wp-content
chown -R www-data:www-data wp-content
chmod -R 775 wp-content

until mysql -h "$WORDPRESS_DB_HOST" -u "$WORDPRESS_DB_USER" -p"$WORDPRESS_DB_PASSWORD" -e ";" 2>/dev/null; do
    log "Waiting for database connection..."
    sleep 3
done
log "Database connection established."

if run_wp core is-installed; then
    log "WordPress core already installed. Skipping installation."
else
    log "WordPress not installed, attempting installation..."
    run_wp core install \
        --url="${DOMAIN_NAME}" \
        --title="Inception - emgul" \
        --admin_user="${WORDPRESS_DB_USER}" \
        --admin_password="${WORDPRESS_DB_PASSWORD}" \
        --admin_email="admin@${DOMAIN_NAME}" \
        --skip-email

    log "WordPress installation successful."

    log "Creating initial post..."
    chmod +x /usr/local/bin/create_post.sh
    /usr/local/bin/create_post.sh

    log "Configuring Redis cache..."
    run_wp plugin install redis-cache --activate
    run_wp redis enable
    log "Redis cache enabled."
fi

echo "[OK] WordPress is installed and configured."

exec gosu www-data php-fpm8.2 --nodaemonize