FROM debian:12-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    nginx \
    openssl \
    curl \
    ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY ./conf/nginx.conf /etc/nginx/sites-enabled/default

RUN mkdir -p /run/nginx

EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]
