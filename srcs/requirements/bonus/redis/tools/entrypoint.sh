#!/bin/bash

set -e

mkdir -p /data
chown -R redis:redis /data
chmod 750 /data

REDIS_CONF=/etc/redis/redis.conf

if [ -f /run/secrets/redis_password ]; then
    REDIS_PASS="$(cat /run/secrets/redis_password)"
    TMP_CONF=$(mktemp)
    cat "$REDIS_CONF" > "$TMP_CONF"
    printf "\n# Authentication\nrequirepass %s\n" "${REDIS_PASS}" >> "$TMP_CONF"
    chown redis:redis "$TMP_CONF"
    chmod 644 "$TMP_CONF"
    mv "$TMP_CONF" "$REDIS_CONF"
fi

exec gosu redis redis-server "$REDIS_CONF"