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

umask 027

WORDPRESS_ARCHIVE="wordpress-6.8.1.tar.gz"
WORDPRESS_DIR="wordpress"
CONFIG_FILE="wp-config.php"
SAMPLE_CONFIG="wp-config-sample.php"

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

    cp "$SAMPLE_CONFIG" "$CONFIG_FILE"

    sed -i "s/database_name_here/${WORDPRESS_DB_NAME}/" "$CONFIG_FILE"
    sed -i "s/username_here/${WORDPRESS_DB_USER}/" "$CONFIG_FILE"
    sed -i "s/password_here/${WORDPRESS_DB_PASSWORD}/" "$CONFIG_FILE"
    sed -i "s/localhost/${WORDPRESS_DB_HOST}/" "$CONFIG_FILE"

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

        if [ "${ENABLE_REDIS:-0}" = "1" ]; then
            log "Configuring Redis cache..."
            run_wp config set WP_REDIS_HOST redis --allow-root
            run_wp config set WP_REDIS_PORT 6379 --raw --allow-root
            run_wp config set WP_CACHE_KEY_SALT "${DOMAIN_NAME}" --allow-root
            run_wp config set WP_REDIS_CLIENT phpredis --allow-root
            run_wp plugin install redis-cache --activate --allow-root
            run_wp plugin update --all --allow-root
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