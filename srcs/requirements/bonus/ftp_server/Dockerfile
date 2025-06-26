FROM debian:12-slim

RUN echo 'Acquire::http::Pipeline-Depth "0";' >> /etc/apt/apt.conf.d/99network && \
    echo 'APT::Install-Recommends "false";' >> /etc/apt/apt.conf.d/99network

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    vsftpd \
    bash \
    passwd \
    netcat-openbsd \
    ca-certificates \
    openssl \
    && rm -rf /var/lib/apt/lists/*

COPY conf/vsftpd.conf /etc/vsftpd.conf
COPY tools/entrypoint.sh /tmp/entrypoint.sh

RUN chmod +x /tmp/entrypoint.sh && \
    chmod 644 /etc/vsftpd.conf && \
    mkdir -p /var/www/html && \
    chmod 755 /var/www/html && \
    mkdir -p /var/log/vsftpd && \
    touch /var/log/vsftpd/vsftpd.log && \
    chmod 644 /var/log/vsftpd/vsftpd.log && \
    mkdir -p /var/run/vsftpd/empty && \
    chmod 755 /var/run/vsftpd/empty && \
    mkdir -p /var/run/vsftpd && \
    chmod 755 /var/run/vsftpd

ENTRYPOINT ["/bin/bash", "/tmp/entrypoint.sh"]
