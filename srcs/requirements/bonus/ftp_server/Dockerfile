FROM alpine:3.21.3

RUN apk update && apk upgrade && apk add --no-cache \
        vsftpd \
        openssl \
        shadow \
        bash \
        netcat-openbsd \
        && rm -rf /var/cache/apk/* \
           /tmp/* \
           /var/tmp/* \
           /usr/share/man/* \
           /usr/share/doc/*

COPY conf/vsftpd.conf /tmp/vsftpd.conf

COPY tools/entrypoint.sh /tmp/entrypoint.sh

RUN chmod +x /tmp/entrypoint.sh && \
    chmod 600 /tmp/vsftpd.conf && \
    mkdir -p /var/www/html && \
    chmod 755 /var/www/html && \
    mkdir -p /var/log/vsftpd && \
    touch /var/log/vsftpd/vsftpd.log && \
    chmod 644 /var/log/vsftpd/vsftpd.log && \
    mkdir -p /var/run/vsftpd/empty && \
    chmod 755 /var/run/vsftpd/empty && \
    mkdir -p /var/run/vsftpd && \
    chmod 755 /var/run/vsftpd

HEALTHCHECK --interval=10s --timeout=10s --start-period=15s --retries=3 \
    CMD nc -z localhost 21 || exit 1

ENTRYPOINT ["sh", "/tmp/entrypoint.sh"]
