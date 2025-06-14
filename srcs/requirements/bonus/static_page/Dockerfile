FROM debian:12-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
	curl \
	ca-certificates \
	openssl \
	netcat-openbsd \
	dnsutils \
	iputils-ping \
	nodejs \
	npm && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /app

COPY ./tools /app

COPY ./tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
