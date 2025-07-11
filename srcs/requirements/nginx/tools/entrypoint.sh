#!/bin/bash

echo "Setting up SSL certificates from Docker secrets..."
mkdir -p /etc/nginx/ssl

if [ -f "/run/secrets/nginx_ssl_fullchain" ] && [ -f "/run/secrets/nginx_ssl_key" ] && \
 [ -f "/run/secrets/nginx_ssl_cert" ] && [ -f "/run/secrets/nginx_ssl_dhparam" ]; then
    cp /run/secrets/nginx_ssl_fullchain /etc/nginx/ssl/emgul.42.fr.fullchain.pem
    cp /run/secrets/nginx_ssl_key /etc/nginx/ssl/emgul.42.fr.key
    cp /run/secrets/nginx_ssl_cert /etc/nginx/ssl/emgul.42.fr.crt
    cp /run/secrets/nginx_ssl_dhparam /etc/nginx/ssl/dhparam.pem
else
    echo "ERROR: secrets not found!"
    exit 1
fi

useradd --system --shell /bin/false nginx
chmod 600 /etc/nginx/ssl/emgul.42.fr.key

echo "Waiting for WordPress PHP-FPM to be ready..."
until nc -z wordpress 9000; do
  echo "Still waiting for WordPress PHP-FPM..."
  sleep 5
done

echo "Testing static page..."
until nc -z static-page 8000; do
    echo "Still waiting for static page..."
    sleep 5
done

echo "Testing Nginx configuration as root..."
if ! nginx -t; then
    echo "ERROR: Nginx configuration test failed!"
    exit 1
fi

echo "Starting Nginx daemon..."
exec nginx -g 'daemon off;'