#!/bin/sh

if [ ! -f "/etc/redis/redis.conf.bak" ]; then

    cp /etc//redis/redis.conf /etc/redis/redis.conf.bak

    sed -i "s|bind 127.0.0.1|bind 0.0.0.0|g" /etc/redis/redis.conf
    sed -i "s|# maxmemory <bytes>|maxmemory 2mb|g" /etc/redis/redis.conf
    sed -i "s|# maxmemory-policy noeviction|maxmemory-policy allkeys-lru|g" /etc/redis/redis.conf
    
    # Redis kalıcı veri için yapılandırma
    sed -i "s|# save 900 1|save 900 1|g" /etc/redis/redis.conf
    sed -i "s|# save 300 10|save 300 10|g" /etc/redis/redis.conf
    sed -i "s|# save 60 10000|save 60 10000|g" /etc/redis/redis.conf
    echo "dir /data" >> /etc/redis/redis.conf

fi

redis-server --protected-mode no
