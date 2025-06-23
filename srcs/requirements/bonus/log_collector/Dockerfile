FROM debian:12-slim

RUN apt-get update && \
	apt-get install -y --no-install-recommends \
	wget \
	curl \
	ca-certificates \
	bash \
	tar \
	gzip \
	libc6 \
	libgcc-s1 \
	libstdc++6 \
	libseccomp2 \
	libpam0g \
	libcap2 \
	liblzma5 \
	libssl3 \
	libssl-dev \
	python3 \
	python3-pip \
	python3-setuptools \
	procps \
	docker.io && \
	rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY ./tools/entrypoint.sh .
COPY ./tools/install_splunk.sh .
COPY ./tools/splunkforwarder.tgz /tmp/splunkforwarder.tgz
RUN chmod +x entrypoint.sh install_splunk.sh

CMD ["/app/entrypoint.sh"]