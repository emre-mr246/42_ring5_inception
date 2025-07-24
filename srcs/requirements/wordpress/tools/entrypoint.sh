#!/bin/sh

WORDPRESS_DB_PASSWORD=$(cat /run/secrets/wordpress_db_password)
WORDPRESS_ADMIN_PASSWORD=$(cat /run/secrets/wordpress_admin_password)
WORDPRESS_USER_PASSWORD=$(cat /run/secrets/wordpress_user_password)

until mysql -h"$WORDPRESS_DB_HOST" -u"$WORDPRESS_DB_USER" -p"$WORDPRESS_DB_PASSWORD" -e "SELECT 1;" 2>/dev/null; do
  echo "Waiting for MariaDB to be ready..."
  sleep 1
done
echo "[OK] MariaDB is ready"

until nc -z redis 6379; do
  echo "Waiting for Redis to be ready..."
  sleep 1
done
echo "[OK] Redis is ready"

touch /var/log/php8.2-fpm.log
mkdir --parents /run/php
chown --recursive www-data:www-data /var/www/html /run/php /var/log/php8.2-fpm.log

wget --quiet --output-document /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x /usr/local/bin/wp

WORDPRESS_ARCHIVE="wordpress-6.8.1.tar.gz"
WORDPRESS_ARCHIVE_SHA256=3c654d079bc42c4e82ff20a6948c456293e104b6762ff7c9fc948071b3310328

log() { echo "[INFO] $*"; }
cleanup() { rm -rf "$WORDPRESS_ARCHIVE" wordpress /tmp/wp-args.* /tmp/wp-cli-cache; }
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

if  [ -f "/var/www/html/wp-settings.php" ] && [ -f "/var/www/html/wp-config.php" ] ; then
    log "WordPress already exists. Skipping download."
else
    log "WordPress not found. Installing..."

    rm -rf ./wp-*

    wget --quiet "https://wordpress.org/${WORDPRESS_ARCHIVE}" && \
    echo "${WORDPRESS_ARCHIVE_SHA256} ${WORDPRESS_ARCHIVE}" | sha256sum -c -

    tar -xzf "$WORDPRESS_ARCHIVE"
    mv wordpress/* /var/www/html
    
    chown -R www-data:www-data /var/www/html

    log "Creating WordPress configuration..."
    FTP_PASS="$(cat /run/secrets/ftp_password)"
    REDIS_PASS="$(cat /run/secrets/redis_password)"
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
        "/usr/local/share/wp-config.php" > "wp-config.php"
    log "WordPress configuration complete."
fi

mkdir -p /var/www/html/wp-content/uploads /var/www/html/wp-content/plugins /var/www/html/wp-content/themes /var/www/html/wp-content/cache
chown -R www-data:www-data /var/www/html/wp-content

if run_wp core is-installed; then
    log "WordPress core already installed. Skipping installation."
else
    log "WordPress not installed, attempting installation..."
    run_wp core install \
        --url="${DOMAIN_NAME}" \
        --title="Inception - emgul" \
        --admin_user="${WORDPRESS_ADMIN_USER}" \
        --admin_password="${WORDPRESS_ADMIN_PASSWORD}" \
        --admin_email="admin@${DOMAIN_NAME}" \
        --skip-email

    log "Creating initial post..."
    chmod +x /usr/local/bin/create_post.sh
    /usr/local/bin/create_post.sh

    log "Creating additional WordPress user..."
    run_wp user create "${WORDPRESS_USER}" "${WORDPRESS_USER}@${DOMAIN_NAME}" \
        --role=author \
        --user_pass="${WORDPRESS_USER_PASSWORD}" \
        --display_name="${WORDPRESS_USER}" \
        --first_name="${WORDPRESS_USER}"

    log "Configuring Redis cache..."
    mkdir /var/www/.wp-cli
    touch /var/www/.wp-cli/cache
    chown --recursive www-data:www-data /var/www/.wp-cli
    chmod 655 /var/www/.wp-cli
    chmod 644 /var/www/.wp-cli/cache
    run_wp plugin install redis-cache --activate
    run_wp redis enable
fi

echo "[OK] WordPress is installed and configured."

exec gosu www-data php-fpm8.2 --nodaemonize