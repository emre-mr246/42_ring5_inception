#!/bin/sh

if [ ! -f "/etc/vsftpd/vsftpd.conf.bak" ]; then

    mkdir -p /var/www/html

    cp /etc/vsftpd/vsftpd.conf /etc/vsftpd/vsftpd.conf.bak
    mv /tmp/vsftpd.conf /etc/vsftpd/vsftpd.conf

    # Güvenli kullanıcı oluşturma
    echo "Creating FTP user: $FTP_USR"
    adduser $FTP_USR --disabled-password --gecos ""
    echo "$FTP_USR:$FTP_PWD" | chpasswd
    
    # Güvenli dizin izinleri
    chown -R $FTP_USR:$FTP_USR /var/www/html
    chmod 755 /var/www/html

    echo $FTP_USR | tee -a /etc/vsftpd.userlist > /dev/null

fi

echo "FTP configuration completed"
echo "Starting vsftpd without SSL..."
exec /usr/sbin/vsftpd /etc/vsftpd/vsftpd.conf
