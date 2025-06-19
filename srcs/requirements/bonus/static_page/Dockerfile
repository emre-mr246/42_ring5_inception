FROM debian:12-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3 \
        && rm -rf /var/lib/apt/lists/* && \
    groupadd --system staticpage && \
    useradd --system --gid staticpage --home-dir /var/www/html staticpage

WORKDIR /var/www/html

COPY ./tools/*.html ./tools/*.css ./tools/*.js ./tools/*.png ./

COPY ./tools/entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh && \
    chown -R staticpage:staticpage /var/www/html && \
    chmod -R 755 /var/www/html

USER staticpage

EXPOSE 8000

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
