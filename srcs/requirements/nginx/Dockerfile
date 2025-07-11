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

COPY ./conf/nginx.conf /etc/nginx/nginx.conf
COPY ./tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 443

CMD ["/usr/local/bin/entrypoint.sh"]