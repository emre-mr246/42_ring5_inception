#!/bin/sh

TARGET_DIR="/var/www/html"
mkdir -p ${TARGET_DIR}

echo "Copying static files from /app to ${TARGET_DIR}"
cp -R /app/* ${TARGET_DIR}/

echo "Contents of ${TARGET_DIR}:"
ls -l ${TARGET_DIR}

echo "Static files copied. Nginx will serve them from the volume."
echo "This container will now sleep. Press Ctrl+C to exit."

tail -f /dev/null
