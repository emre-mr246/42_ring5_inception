#!/bin/sh

echo "Checking if index.html exists in the current directory..."
if [ ! -f "index.html" ]; then
    echo "Warning: index.html not found!"
    echo "Current directory: $(pwd)"
    echo "Contents:"
    ls -la
fi

echo "Static Page HTTP Server starting on port 8000..."
exec python3 -m http.server 8000 --bind 0.0.0.0
