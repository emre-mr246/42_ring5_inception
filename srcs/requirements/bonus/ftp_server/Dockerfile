FROM alpine:3.21.3

RUN apk update && apk upgrade && apk add --no-cache \
        vsftpd \
        openssl && \
    rm -rf /var/cache/apk/* \
           /tmp/* \
           /var/tmp/* \
           /usr/share/man/* \
           /usr/share/doc/*

COPY conf/vsftpd.conf /tmp/vsftpd.conf

COPY tools/entrypoint.sh /tmp/entrypoint.sh

RUN chmod +x /tmp/entrypoint.sh && \
    chmod 600 /tmp/vsftpd.conf

HEALTHCHECK --interval=10s --timeout=10s --start-period=15s --retries=3 \
    CMD pgrep vsftpd > /dev/null || exit 1

ENTRYPOINT ["sh", "/tmp/entrypoint.sh"]
