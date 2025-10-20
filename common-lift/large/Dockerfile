
FROM ghcr.io/actions/actions-runner:latest

USER root

# install docker engine tools and common utils
#RUN apt-get update \
# && apt-get install -y --no-install-recommends \
#      docker.io \
#      curl \
#      ca-certificates \
#      git \
#      jq \
# && rm -rf /var/lib/apt/lists/*

# install the standalone docker-compose (v2 CLI binary)
#   you can pin a version if you want stability
#ARG COMPOSE_VERSION=2.27.0
#RUN curl -fsSL "https://github.com/docker/compose/releases/download/v${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" \
#      -o /usr/local/bin/docker-compose \
# && chmod +x /usr/local/bin/docker-compose \
# && docker-compose version

# switch back to runner user for runtime
USER runner

COPY entrypoint.sh /entrypoint.sh
USER root
RUN chmod +x /entrypoint.sh && chown runner:runner /entrypoint.sh
USER runner

RUN mkdir -p /home/runner/_work && mkdir -p /home/runner/_tool

ENTRYPOINT ["/entrypoint.sh"]
