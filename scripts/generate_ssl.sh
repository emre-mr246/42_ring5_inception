#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INCEPTION_ROOT="$(dirname "$SCRIPT_DIR")"
SSL_DIR="$INCEPTION_ROOT/srcs/certificates/nginx"
FTP_CERT_DIR="$INCEPTION_ROOT/srcs/certificates/ftp"

DOMAIN="emgul.42.fr"

mkdir -p "$SSL_DIR"
mkdir -p "$FTP_CERT_DIR"

if [ ! -f "$SSL_DIR/dhparam.pem" ]; then
    openssl dhparam -out "$SSL_DIR/dhparam.pem" 2048
fi

if [ ! -f "$SSL_DIR/ca-key.pem" ]; then
    openssl genrsa -out "$SSL_DIR/ca-key.pem" 4096
    openssl req -new -x509 -sha256 -days 1825 \
        -key "$SSL_DIR/ca-key.pem" \
        -out "$SSL_DIR/ca-cert.pem" \
        -subj "/CN=Local-CA/O=Inception/C=TR" \
        -addext "basicConstraints=critical,CA:true"
fi

if [ ! -f "$SSL_DIR/$DOMAIN.key" ]; then
    openssl genrsa -out "$SSL_DIR/$DOMAIN.key" 2048

    openssl req -new -sha256 \
        -key "$SSL_DIR/$DOMAIN.key" \
        -out "$SSL_DIR/$DOMAIN.csr" \
        -subj "/CN=$DOMAIN/O=Inception/C=TR"

    openssl x509 -req -in "$SSL_DIR/$DOMAIN.csr" -days 1825 -sha256 \
        -CA "$SSL_DIR/ca-cert.pem" -CAkey "$SSL_DIR/ca-key.pem" -CAcreateserial \
        -out "$SSL_DIR/$DOMAIN.crt" \
        -extfile <(printf "authorityKeyIdentifier=keyid,issuer\nbasicConstraints=CA:FALSE\nkeyUsage=digitalSignature,keyEncipherment\nextendedKeyUsage=serverAuth")
fi

cat $SSL_DIR/emgul.42.fr.crt $SSL_DIR/ca-cert.pem > $SSL_DIR/$DOMAIN.fullchain.pem

chmod 644 "$SSL_DIR/ca-key.pem"
chmod 644 "$SSL_DIR/ca-cert.pem"
chmod 644 "$SSL_DIR/$DOMAIN.key"
chmod 644 "$SSL_DIR/$DOMAIN.crt"
chmod 644 "$SSL_DIR/dhparam.pem"
chmod 644 "$SSL_DIR/$DOMAIN.fullchain.pem"

echo "SSL sertifikaları başarıyla oluşturuldu: $DOMAIN"

if [ ! -f "$FTP_CERT_DIR/vsftpd.key" ]; then
    echo "Generating FTPS certificate..."
    openssl genrsa -out "$FTP_CERT_DIR/vsftpd.key" 2048
    openssl req -new -sha256 \
        -key "$FTP_CERT_DIR/vsftpd.key" \
        -out "$FTP_CERT_DIR/vsftpd.csr" \
        -subj "/CN=$DOMAIN/O=Inception/C=TR"
    openssl x509 -req -in "$FTP_CERT_DIR/vsftpd.csr" -days 1825 -sha256 \
        -CA "$SSL_DIR/ca-cert.pem" -CAkey "$SSL_DIR/ca-key.pem" -CAcreateserial \
        -out "$FTP_CERT_DIR/vsftpd.crt"
    cat "$FTP_CERT_DIR/vsftpd.key" "$FTP_CERT_DIR/vsftpd.crt" > "$FTP_CERT_DIR/vsftpd.pem"
fi

chmod 600 "$FTP_CERT_DIR/vsftpd.key" "$FTP_CERT_DIR/vsftpd.pem"
