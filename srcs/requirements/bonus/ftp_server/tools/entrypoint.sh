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

mkdir -p /var/run/vsftpd/empty
chown root:root /var/run/vsftpd/empty
chmod 555 /var/run/vsftpd/empty

if ! id -u ftpuser >/dev/null 2>&1; then
    useradd -m -d /var/www/html -s /bin/bash ftpuser
    echo "ftpuser created"
fi

echo "ftpuser:$FTP_PASSWORD" | chpasswd
if ! groups ftpuser | grep -q www-data; then
    usermod -a -G www-data ftpuser
    echo "ftpuser added to www-data group"
fi

chmod 755 /var

if ! id -u vsftpd >/dev/null 2>&1; then
    useradd -r -s /usr/sbin/nologin vsftpd
    echo "vsftpd user created"
fi

chown -R ftpuser:www-data /var/www/html
find /var/www/html -type d -exec chmod 775 {} \;
find /var/www/html -type f -exec chmod 664 {} \;
mkdir -p /var/www/html/wp-content/uploads /var/www/html/wp-content/plugins /var/www/html/wp-content/themes /var/www/html/wp-content/cache
chown -R ftpuser:www-data /var/www/html/wp-content
find /var/www/html/wp-content -type d -exec chmod 775 {} \;
find /var/www/html/wp-content -type f -exec chmod 664 {} \;

mkdir -p /var/log/vsftpd
touch /var/log/vsftpd/vsftpd.log
chmod 644 /var/log/vsftpd/vsftpd.log

echo "ftpuser" > /etc/vsftpd.userlist
chown root:root /etc/vsftpd.userlist
chmod 644 /etc/vsftpd.userlist

echo "Starting vsftpd..."
/usr/sbin/vsftpd -obackground=NO /etc/vsftpd.conf
