FROM debian:12-slim

RUN echo 'Acquire::http::Pipeline-Depth "0";' >> /etc/apt/apt.conf.d/99network && \
    echo 'APT::Install-Recommends "false";' >> /etc/apt/apt.conf.d/99network

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    bash \
    tar \
    gzip \
    curl \
    procps && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /splunk

COPY ./tools/entrypoint.sh .
COPY ./tools/install_splunk.sh .
COPY ./tools/splunkforwarder.tgz /tmp/splunkforwarder.tgz
RUN chmod +x entrypoint.sh install_splunk.sh

CMD ["/splunk/entrypoint.sh"]