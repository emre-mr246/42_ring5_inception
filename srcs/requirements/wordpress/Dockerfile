FROM debian:12-slim

RUN echo 'Acquire::http::Pipeline-Depth "0";' >> /etc/apt/apt.conf.d/99network && \
    echo 'APT::Install-Recommends "false";' >> /etc/apt/apt.conf.d/99network

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get -y install \
    wget \
    ca-certificates \
    openssl \
    php8.2-fpm \
    php8.2-mysql \
    php8.2-cli \
    php-redis \
    netcat-openbsd \
    mariadb-client \
    gosu && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY ./conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf
COPY ./tools/create_post.sh /usr/local/bin/create_post.sh
COPY ./conf/wp-config.php /usr/local/share/wp-config.php
COPY ./tools/healthcheck.sh /usr/local/bin/healthcheck.sh

COPY ./tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /var/www/html

EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
