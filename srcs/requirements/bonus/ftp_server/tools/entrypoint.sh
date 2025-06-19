#!/bin/bash

while [ ! -f /etc/vsftpd.conf ]; do
    echo "Waiting for vsftpd.conf..."
    sleep 1
done

if [ -f /run/secrets/ftp_password ]; then
    FTP_PASSWORD=$(cat /run/secrets/ftp_password)
    echo "FTP password loaded from secret"
else
    echo "Error: FTP password secret not found at /run/secrets/ftp_password"
    exit 1
fi

if ! id -u ftpuser >/dev/null 2>&1; then
    echo "Creating ftpuser..."
    useradd -M -d /var/www/html ftpuser
    echo "ftpuser:$FTP_PASSWORD" | chpasswd
    if [ $? -eq 0 ]; then
        echo "Password set successfully for ftpuser"
    else
        echo "Error: Failed to set password for ftpuser"
        exit 1
    fi
    chown -R ftpuser:ftpuser /var/www/html
    chmod 755 /var/www/html
    echo "ftpuser" > /etc/vsftpd.userlist
    echo "ftpuser added to userlist"
else
    echo "ftpuser already exists"
fi

mkdir -p /var/run/vsftpd/empty
chown root:root /var/run/vsftpd/empty
chmod 555 /var/run/vsftpd/empty
mkdir -p /var/log/vsftpd
touch /var/log/vsftpd/vsftpd.log
chmod 644 /var/log/vsftpd/vsftpd.log

echo "Starting vsftpd in foreground mode..."
exec vsftpd /etc/vsftpd.conf
