FROM debian:12-slim

RUN echo 'Acquire::http::Pipeline-Depth "0";' >> /etc/apt/apt.conf.d/99network && \
    echo 'APT::Install-Recommends "false";' >> /etc/apt/apt.conf.d/99network

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    nginx \
    openssl \
    netcat-openbsd && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN useradd --system --shell /bin/false nginx

COPY ./conf/nginx.conf /etc/nginx/nginx.conf
COPY ./tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

RUN mkdir -p /run/nginx /var/cache/nginx /var/log/nginx /var/lib/nginx/body && \
    touch /run/nginx.pid && \
    chown -R nginx:nginx /var/log/nginx /var/cache/nginx /run/nginx /run/nginx.pid /var/lib/nginx && \
    chmod -R 755 /var/log/nginx /var/cache/nginx /run/nginx /var/lib/nginx && \
    chmod 644 /run/nginx.pid

EXPOSE 443

CMD ["/usr/local/bin/entrypoint.sh"]