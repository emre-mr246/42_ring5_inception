FROM debian:bookworm-slim

USER root

RUN apt-get update -y && apt-get install -y \
    mariadb-server \
    mariadb-client \
    gosu \
    curl \
    procps \
    net-tools \
    && apt-get clean && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /run/mysqld \
    && chown -R mysql:mysql /run/mysqld /var/lib/mysql

COPY ./conf/50-server.cnf /etc/mysql/mariadb.conf.d/
COPY ./tools/entrypoint.sh /
RUN chmod +x /entrypoint.sh

EXPOSE 3306

USER mysql

CMD ["/entrypoint.sh"]