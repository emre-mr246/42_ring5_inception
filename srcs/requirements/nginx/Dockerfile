FROM debian:12-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    nginx \
    openssl \
    curl \
    netcat-openbsd \
    dnsutils \
    iputils-ping \
    ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY ./conf/nginx.conf /etc/nginx/sites-enabled/default
COPY ./tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

RUN mkdir -p /run/nginx

EXPOSE 443

CMD ["/usr/local/bin/entrypoint.sh"]