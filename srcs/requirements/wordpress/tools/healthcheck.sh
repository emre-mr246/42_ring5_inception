#!/bin/sh

set -e

echo "[INFO] Starting basic health check for WordPress..."

# PHP-FPM
if ! pgrep php-fpm8.2 > /dev/null 2>&1; then
    echo "[ERROR] PHP-FPM process is not running"
    exit 1
fi
echo "[OK] PHP-FPM process is running"

# WordPress
if [ ! -f /var/www/html/wp-load.php ]; then
    echo "[ERROR] WordPress core file wp-load.php not found"
    exit 1
fi
echo "[OK] WordPress core files exist"

# PHP
if ! php -r 'echo "OK\n";' > /dev/null 2>&1; then
    echo "[ERROR] PHP is not functioning correctly"
    exit 1
fi

echo "[OK] All basic health checks passed - WordPress is healthy"
exit 0
