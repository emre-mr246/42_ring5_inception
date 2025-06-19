#!/bin/bash

echo "Setting up SSL certificates from Docker secrets..."
mkdir -p /etc/nginx/ssl

if [ -f "/run/secrets/nginx_ssl_cert" ]; then
    cp /run/secrets/nginx_ssl_cert /etc/nginx/ssl/emgul.42.fr.crt
    echo "SSL certificate copied from secret"
else
    echo "ERROR: nginx_ssl_cert secret not found!"
    exit 1
fi

if [ -f "/run/secrets/nginx_ssl_key" ]; then
    cp /run/secrets/nginx_ssl_key /etc/nginx/ssl/emgul.42.fr.key
    chmod 600 /etc/nginx/ssl/emgul.42.fr.key
    echo "SSL private key copied from secret"
else
    echo "ERROR: nginx_ssl_key secret not found!"
    exit 1
fi

if [ -f "/run/secrets/nginx_ssl_fullchain" ]; then
    cp /run/secrets/nginx_ssl_fullchain /etc/nginx/ssl/emgul.42.fr.fullchain.pem
    echo "SSL fullchain copied from secret"
else
    echo "ERROR: nginx_ssl_fullchain secret not found!"
    exit 1
fi

if [ -f "/run/secrets/nginx_ssl_dhparam" ]; then
    cp /run/secrets/nginx_ssl_dhparam /etc/nginx/ssl/dhparam.pem
    echo "DH parameters copied from secret"
else
    echo "ERROR: nginx_ssl_dhparam secret not found!"
    exit 1
fi

chown -R nginx:nginx /etc/nginx/ssl
chmod -R 644 /etc/nginx/ssl
chmod 600 /etc/nginx/ssl/emgul.42.fr.key

echo "Testing DNS resolution..."
if command -v nslookup >/dev/null 2>&1; then
    nslookup wordpress || echo "DNS resolution failed for wordpress"
else
    echo "nslookup not available, skipping DNS test"
fi

echo "Testing ping to wordpress..."
ping -c 1 wordpress >/dev/null 2>&1 && echo "WordPress pingable" || echo "WordPress not pingable"

echo "Waiting for WordPress PHP-FPM to be ready..."
until nc -z wordpress 9000; do
  echo "Still waiting for WordPress PHP-FPM..."
  sleep 5
done

echo "WordPress PHP-FPM is ready!"

echo "Checking SSL certificates..."
if [ ! -f "/etc/nginx/ssl/emgul.42.fr.crt" ]; then
    echo "ERROR: SSL certificate not found!"
    ls -la /etc/nginx/ssl/ || echo "SSL directory not found"
    exit 1
fi

echo "Testing Nginx configuration as root..."
if ! nginx -t; then
    echo "ERROR: Nginx configuration test failed!"
    exit 1
fi

echo "Starting Nginx daemon (master as root, workers as nginx)..."
exec nginx -g 'daemon off;'