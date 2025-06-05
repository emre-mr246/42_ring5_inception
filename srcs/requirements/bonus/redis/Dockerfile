FROM debian:12-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    redis-server \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY ./tools/redis.sh /tmp/redis.sh

EXPOSE 6379

CMD ["sh", "/tmp/redis.sh"]
