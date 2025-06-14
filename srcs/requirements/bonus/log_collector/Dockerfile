FROM debian:12-slim

RUN apt-get update && \
	apt-get install -y --no-install-recommends \
		docker.io \
		bash \
		coreutils \
		tar \
		gzip && \
	rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY ./tools/entrypoint.sh .
RUN chmod +x entrypoint.sh

CMD ["/app/entrypoint.sh"]