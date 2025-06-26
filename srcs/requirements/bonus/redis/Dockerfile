FROM debian:12-slim

RUN echo 'Acquire::http::Pipeline-Depth "0";' >> /etc/apt/apt.conf.d/99network && \
    echo 'APT::Install-Recommends "false";' >> /etc/apt/apt.conf.d/99network

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    redis-server \
    gosu \
    && rm -rf /var/lib/apt/lists/* && \
    mkdir -p /etc/redis /data && \
    chown -R redis:redis /etc/redis /data && \
    chmod 755 /etc/redis

COPY --chown=redis:redis conf/redis.conf /etc/redis/redis.conf
RUN chmod 644 /etc/redis/redis.conf

COPY tools/entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

VOLUME ["/data"]

EXPOSE 6379

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]