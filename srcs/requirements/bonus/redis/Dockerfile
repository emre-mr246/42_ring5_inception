FROM debian:12-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    redis-server curl procps \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && echo "vm.overcommit_memory=1" >> /etc/sysctl.conf \
    && mkdir -p /data \
    && chown redis:redis /data \
    && chmod 755 /data

COPY ./tools/redis.sh /tmp/redis.sh
RUN chmod +x /tmp/redis.sh

EXPOSE 6379

USER redis

CMD ["sh", "/tmp/redis.sh"]
