#!/bin/bash

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
    exit 0
fi

echo "Testing Nginx configuration..."
if ! nginx -t; then
    echo "ERROR: Nginx configuration test failed!"
    exit 1
fi

echo "Starting Nginx daemon..."
exec nginx -g 'daemon off;'