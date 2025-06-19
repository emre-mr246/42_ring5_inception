FROM debian:12-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    nginx \
    openssl \
    ca-certificates \
    curl \
    netcat-openbsd \
    iputils-ping \
    gosu && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN useradd -r -s /bin/false nginx || true

COPY ./conf/nginx.conf /etc/nginx/sites-enabled/default
COPY ./tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

RUN mkdir -p /run/nginx /var/cache/nginx /var/log/nginx /var/lib/nginx/body && \
    touch /run/nginx.pid && \
    chown -R nginx:nginx /var/log/nginx /var/cache/nginx /run/nginx /run/nginx.pid /var/lib/nginx && \
    chmod -R 755 /var/log/nginx /var/cache/nginx /run/nginx /var/lib/nginx && \
    chmod 644 /run/nginx.pid

RUN sed -i '/^user/d' /etc/nginx/nginx.conf && \
    echo "user nginx;" >> /etc/nginx/nginx.conf

EXPOSE 443

CMD ["/usr/local/bin/entrypoint.sh"]