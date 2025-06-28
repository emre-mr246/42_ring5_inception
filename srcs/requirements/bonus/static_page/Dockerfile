FROM debian:12-slim

RUN echo 'Acquire::http::Pipeline-Depth "0";' >> /etc/apt/apt.conf.d/99network && \
    echo 'APT::Install-Recommends "false";' >> /etc/apt/apt.conf.d/99network

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    python3 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    groupadd --system staticpage && \
    useradd --system --gid staticpage --home-dir /var/www/html staticpage

WORKDIR /var/www/html

COPY ./tools/index.html ./tools/style.css ./tools/script.js ./tools/congrats.png ./
COPY ./tools/entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh && \
    chown -R staticpage:staticpage /var/www/html && \
    chmod -R 755 /var/www/html

USER staticpage

EXPOSE 8000

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
