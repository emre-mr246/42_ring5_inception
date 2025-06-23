FROM debian:12-slim

RUN apt-get update && \
	apt-get install -y --no-install-recommends \
	curl \
	ca-certificates \
	bash \
	tar \
	gzip \
	procps && \
	apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /splunk

COPY ./tools/entrypoint.sh .
COPY ./tools/install_splunk.sh .
COPY ./tools/splunkforwarder.tgz /tmp/splunkforwarder.tgz
RUN chmod +x entrypoint.sh install_splunk.sh

CMD ["/splunk/entrypoint.sh"]