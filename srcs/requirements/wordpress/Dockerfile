FROM debian:12-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get -y install --no-install-recommends \
    wget \
    curl \
    ca-certificates \
    php8.2-fpm \
    php8.2-cgi \
    php8.2-mysql \
    php8.2-gd \
    php8.2-cli \
    php8.2-mbstring \
    php8.2-xml \
    php8.2-zip \
    php-redis \
    mariadb-client && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY ./conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf
COPY  ./tools/healthcheck.sh /usr/local/bin/healthcheck.sh

RUN curl -sS -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x /usr/local/bin/wp

RUN mkdir -p /var/www/html /run/php \
 && chown -R www-data:www-data /var/www/html /run/php \
 && chmod -R 775 /var/www/html /run/php

COPY ./tools/create_wordpress.sh /usr/local/bin/create_wordpress.sh
RUN chmod +x /usr/local/bin/create_wordpress.sh

WORKDIR /var/www/html

EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/create_wordpress.sh"]
