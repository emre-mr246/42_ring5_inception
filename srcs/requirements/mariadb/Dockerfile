FROM debian:12-slim

RUN echo 'Acquire::http::Pipeline-Depth "0";' >> /etc/apt/apt.conf.d/99network && \
    echo 'APT::Install-Recommends "false";' >> /etc/apt/apt.conf.d/99network

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y && apt-get install -y \
    mariadb-server \
    netcat-openbsd \
    ftp \
    mariadb-client && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir -p /run/mysqld /var/log/mysql \
    && chown -R mysql:mysql /run/mysqld /var/lib/mysql /var/log/mysql

COPY ./conf/50-server.cnf /etc/mysql/mariadb.conf.d/
COPY ./tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 3306

USER mysql

CMD ["/usr/local/bin/entrypoint.sh"]