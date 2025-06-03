FROM debian:bookworm-slim

USER root

RUN apt-get update -y && apt-get install mariadb-server -y

COPY ./conf/50-server.cnf /etc/mysql/mariadb.conf.d/

COPY ./tools/entrypoint.sh /
RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]