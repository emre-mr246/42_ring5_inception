FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
      mariadb-server \
      gosu \
      tzdata \
      ca-certificates \
      openssl \
      libssl-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    mkdir -p /var/log/mysql /run/mysqld /var/lib/mysql && \
    chown -R mysql:mysql /var/log/mysql /run/mysqld /var/lib/mysql && \
    chmod -R 750 /var/log/mysql && \
    rm -f /etc/mysql/mariadb.conf.d/50-mysqld_safe.cnf

COPY --chown=mysql:mysql ./conf/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf
COPY --chown=mysql:mysql ./tools/initial_db.sql /tmp/initial_db.sql
COPY ./tools/entrypoint.sh /entrypoint.sh

RUN chmod 755 /entrypoint.sh

EXPOSE 3306

ENTRYPOINT ["/entrypoint.sh"]