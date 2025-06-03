FROM debian:bookworm-slim

USER root

RUN apt-get update -y && apt-get install -y \
    mariadb-server \
    mariadb-client \
    gosu \
    curl \
    procps \
    net-tools \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY ./conf/50-server.cnf /etc/mysql/mariadb.conf.d/

COPY ./tools/entrypoint.sh /
RUN chmod +x /entrypoint.sh

EXPOSE 3306

CMD ["/entrypoint.sh"]