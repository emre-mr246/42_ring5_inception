FROM debian:12-slim

RUN groupadd --system staticpage && \
    useradd --system --gid staticpage --home-dir /app staticpage

WORKDIR /app

COPY ./tools /app

RUN mkdir -p /var/www/html && \
    chown -R staticpage:staticpage /app /var/www/html && \
    chmod -R 755 /app /var/www/html

COPY ./tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh && \
    chown staticpage:staticpage /usr/local/bin/entrypoint.sh

USER staticpage

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
