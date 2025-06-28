#!/bin/bash
set -e

if [ ! -f /etc/vsftpd.conf ]; then
    echo "ERROR: vsftpd.conf not found!"
    exit 1
fi

if [ -f /run/secrets/ftp_password ]; then
    FTP_PASSWORD=$(cat /run/secrets/ftp_password)
else
    echo "ERROR: FTP password secret not found!"
    exit 1
fi

if ! id -u vsftpd >/dev/null 2>&1; then
    useradd -M -d /var/run/vsftpd -s /usr/sbin/nologin vsftpd
    echo "vsftpd user created"
fi

mkdir -p /var/run/vsftpd/empty
chown root:root /var/run/vsftpd/empty
chmod 555 /var/run/vsftpd/empty

mkdir -p /etc/vsftpd/ssl
if [ -f "/run/secrets/ftp_ssl_cert" ]; then
    cp /run/secrets/ftp_ssl_cert /etc/vsftpd/ssl/vsftpd.pem
    chown vsftpd:vsftpd /etc/vsftpd/ssl/vsftpd.pem
    chmod 600 /etc/vsftpd/ssl/vsftpd.pem
    echo "SSL certificate configured"
else
    echo "ERROR: SSL certificate not found!"
    exit 1
fi
if [ -f "/run/secrets/ftp_ssl_key" ]; then
    cp /run/secrets/ftp_ssl_key /etc/vsftpd/ssl/vsftpd.key
    chown vsftpd:vsftpd /etc/vsftpd/ssl/vsftpd.key
    chmod 600 /etc/vsftpd/ssl/vsftpd.key
    echo "SSL private key configured"
else
    echo "ERROR: SSL private key not found!"
    exit 1
fi

echo "Validating SSL certificates..."
if ! openssl x509 -in /etc/vsftpd/ssl/vsftpd.pem -text -noout >/dev/null 2>&1; then
    echo "ERROR: Invalid SSL certificate!"
    exit 1
fi

if ! openssl rsa -in /etc/vsftpd/ssl/vsftpd.key -check -noout >/dev/null 2>&1; then
    echo "ERROR: Invalid SSL private key!"
    exit 1
fi

if ! id -u ftpuser >/dev/null 2>&1; then
    useradd -M -d /var/www/html -s /usr/sbin/nologin ftpuser
    echo "ftpuser created"
fi
echo "ftpuser:$FTP_PASSWORD" | chpasswd

mkdir -p /var/www/html
chown ftpuser:ftpuser /var/www/html
chmod 755 /var/www/html

mkdir -p /var/log/vsftpd
touch /var/log/vsftpd/vsftpd.log
chmod 644 /var/log/vsftpd/vsftpd.log

echo "ftpuser" > /etc/vsftpd.userlist
chown root:root /etc/vsftpd.userlist
chmod 600 /etc/vsftpd.userlist

echo "Starting vsftpd..."
/usr/sbin/vsftpd -obackground=NO /etc/vsftpd.conf &
