#!/bin/sh

echo "Starting Static Page HTTP Server..."

if [ ! -f "index.html" ]; then
    echo "Warning: index.html not found in current directory"
    echo "Current directory: $(pwd)"
    echo "Contents:"
    ls -la
fi

echo "Serving static files from: $(pwd)"
echo "Contents of web directory:"
ls -la

echo "Static Page HTTP Server starting on port 8000..."

if [ -d "/var/www/html" ] && [ "$(pwd)" != "/var/www/html" ]; then
    echo "Copying files to volume mount..."
    cp -R ./* /var/www/html/ 2>/dev/null || true
    cd /var/www/html
fi

exec python3 -m http.server 8000 --bind 0.0.0.0
