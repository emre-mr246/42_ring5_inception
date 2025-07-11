FROM debian:12-slim

RUN echo 'Acquire::http::Pipeline-Depth "0";' >> /etc/apt/apt.conf.d/99network && \
    echo 'APT::Install-Recommends "false";' >> /etc/apt/apt.conf.d/99network

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    vsftpd \
    bash \
    passwd \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

COPY conf/vsftpd.conf /etc/vsftpd.conf

COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/bin/bash", "/usr/local/bin/entrypoint.sh"]
