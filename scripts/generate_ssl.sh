#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INCEPTION_ROOT="$(dirname "$SCRIPT_DIR")"
SECRETS_DIR="$INCEPTION_ROOT/srcs/secrets"

DOMAIN="emgul.42.fr"

mkdir -p "$SECRETS_DIR"

if [ ! -f "$SECRETS_DIR/nginx_ssl_dhparam.pem" ]; then
    echo "Generating DH parameters..."
    openssl dhparam -out "$SECRETS_DIR/nginx_ssl_dhparam.pem" 2048
fi

if [ ! -f "$SECRETS_DIR/ca-key.pem" ]; then
    echo "Generating CA certificate..."
    openssl genrsa -out "$SECRETS_DIR/ca-key.pem" 4096
    openssl req -new -x509 -sha256 -days 1825 \
        -key "$SECRETS_DIR/ca-key.pem" \
        -out "$SECRETS_DIR/ca-cert.pem" \
        -subj "/CN=Local-CA/O=Inception/C=TR" \
        -addext "basicConstraints=critical,CA:true"
fi

if [ ! -f "$SECRETS_DIR/nginx_ssl_key.pem" ]; then
    echo "Generating server certificate..."
    openssl genrsa -out "$SECRETS_DIR/nginx_ssl_key.pem" 2048

    openssl req -new -sha256 \
        -key "$SECRETS_DIR/nginx_ssl_key.pem" \
        -out "$SECRETS_DIR/$DOMAIN.csr" \
        -subj "/CN=$DOMAIN/O=Inception/C=TR"

    openssl x509 -req -in "$SECRETS_DIR/$DOMAIN.csr" -days 1825 -sha256 \
        -CA "$SECRETS_DIR/ca-cert.pem" -CAkey "$SECRETS_DIR/ca-key.pem" -CAcreateserial \
        -out "$SECRETS_DIR/nginx_ssl_cert.pem" \
        -extfile <(printf "authorityKeyIdentifier=keyid,issuer\nbasicConstraints=CA:FALSE\nkeyUsage=digitalSignature,keyEncipherment\nextendedKeyUsage=serverAuth")
    rm "$SECRETS_DIR/$DOMAIN.csr"
fi

cat "$SECRETS_DIR/nginx_ssl_cert.pem" "$SECRETS_DIR/ca-cert.pem" > "$SECRETS_DIR/nginx_ssl_fullchain.pem"

chmod 644 "$SECRETS_DIR"/nginx_ssl_*.pem
chmod 644 "$SECRETS_DIR"/ca-*.pem

echo "SSL certificates generated successfully."