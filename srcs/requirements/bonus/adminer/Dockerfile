FROM debian:12-slim

RUN echo 'Acquire::http::Pipeline-Depth "0";' >> /etc/apt/apt.conf.d/99network && \
    echo 'APT::Install-Recommends "false";' >> /etc/apt/apt.conf.d/99network

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    php8.2-cli \
    php8.2-mysql \
    wget \
    ca-certificates \
    netcat-openbsd && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN groupadd --system adminer \
 && useradd --system --gid adminer --home-dir /var/www/html adminer \
 && mkdir -p /var/www/html \
 && chown adminer:adminer /var/www/html

WORKDIR /var/www/html

ARG ADMINER_SHA256=ff627c90795371e2c81c1815902fdce80833f5630f3c9a2dc864244da6784f2d
RUN wget -qO index.php \
    https://github.com/vrana/adminer/releases/download/v5.3.0/adminer-5.3.0-mysql-en.php \
    && echo "${ADMINER_SHA256} index.php" | sha256sum -c -

COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

RUN chown -R adminer:adminer /var/www/html

USER adminer

EXPOSE 8080

CMD ["/usr/local/bin/entrypoint.sh"]