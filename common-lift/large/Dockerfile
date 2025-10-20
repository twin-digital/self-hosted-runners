FROM ghcr.io/actions/actions-runner:latest

# Minimal tools for token fetch + docker client
RUN apt-get update \
 && apt-get install -y --no-install-recommends docker.io docker-compose-plugin curl ca-certificates git \
 && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]