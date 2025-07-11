FROM debian:12-slim

RUN echo 'Acquire::http::Pipeline-Depth "0";' >> /etc/apt/apt.conf.d/99network && \
    echo 'APT::Install-Recommends "false";' >> /etc/apt/apt.conf.d/99network

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    bash \
    tar \
    procps \
    curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY ./tools/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY ./tools/install_splunk.sh /usr/local/bin/install_splunk.sh
RUN chmod +x /usr/local/bin/install_splunk.sh /usr/local/bin/entrypoint.sh

COPY ./tools/splunkforwarder.tgz /tmp/splunkforwarder.tgz

CMD ["/usr/local/bin/entrypoint.sh"]