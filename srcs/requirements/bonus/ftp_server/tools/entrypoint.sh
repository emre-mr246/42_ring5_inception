#!/bin/bash

while [ ! -f /tmp/vsftpd.conf ]; do
    echo "Waiting for vsftpd.conf..."
    sleep 1
done

if ! id -u ftpuser >/dev/null 2>&1; then
    adduser -D -h /var/www/html ftpuser
    echo "ftpuser:${FTP_PASSWORD}" | chpasswd
    chown -R ftpuser:ftpuser /var/www/html
    chmod 755 /var/www/html
fi

mkdir -p /var/run/vsftpd/empty
chmod 755 /var/run/vsftpd/empty
mkdir -p /var/log/vsftpd
touch /var/log/vsftpd/vsftpd.log
chmod 644 /var/log/vsftpd/vsftpd.log

echo "Starting vsftpd..."
vsftpd /tmp/vsftpd.conf

tail -f /var/log/vsftpd/vsftpd.log
