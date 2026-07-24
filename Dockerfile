FROM oven/bun:1

ARG GBRAIN_REPO=garrytan/gbrain
ARG GBRAIN_REF=master

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       bash \
       curl \
       ca-certificates \
       git \
       postgresql-client \
    && rm -rf /var/lib/apt/lists/*

RUN bun install -g "github:${GBRAIN_REPO}#${GBRAIN_REF}"

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

RUN chmod 0755 /usr/local/bin/docker-entrypoint.sh \
    && command -v gbrain \
    && gbrain --help >/dev/null

EXPOSE 3001

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
