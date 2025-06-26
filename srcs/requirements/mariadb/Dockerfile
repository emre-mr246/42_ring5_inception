FROM debian:12-slim

RUN echo 'Acquire::http::Pipeline-Depth "0";' >> /etc/apt/apt.conf.d/99network && \
    echo 'APT::Install-Recommends "false";' >> /etc/apt/apt.conf.d/99network

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y && apt-get install -y \
    mariadb-server \
    mariadb-client \
    gosu \
    curl \
    procps \
    net-tools \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN groupmod -g 999 mysql && \
    usermod -u 999 -g 999 mysql

RUN mkdir -p /run/mysqld /var/log/mysql \
    && chown -R mysql:mysql /run/mysqld /var/lib/mysql /var/log/mysql

COPY ./conf/50-server.cnf /etc/mysql/mariadb.conf.d/
COPY ./tools/entrypoint.sh /
RUN chmod +x /entrypoint.sh

EXPOSE 3306

USER mysql

CMD ["/entrypoint.sh"]