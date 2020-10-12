ARG ALPINE_VERSION=3.12
FROM erlang:23.1.1-alpine

# elixir expects utf8.
ENV ELIXIR_VERSION="v1.11.0" \
  LANG=C.UTF-8

RUN set -xe \
  && ELIXIR_DOWNLOAD_URL="https://github.com/elixir-lang/elixir/archive/${ELIXIR_VERSION}.tar.gz" \
  && buildDeps=' \
  ca-certificates \
  curl \
  make \
  ' \
  && apk add --no-cache --virtual .build-deps $buildDeps \
  && curl -fSL -o elixir-src.tar.gz $ELIXIR_DOWNLOAD_URL \
  && mkdir -p /usr/local/src/elixir \
  && tar -xzC /usr/local/src/elixir --strip-components=1 -f elixir-src.tar.gz \
  && rm elixir-src.tar.gz \
  && cd /usr/local/src/elixir \
  && make install clean \
  && apk del .build-deps

ENV LANG=en_US.UTF-8 \
    TERM=xterm

RUN apk update && \
  apk upgrade --no-cache && \
  apk add --no-cache \
  bash \
  make gcc g++ python2 python3 \
  npm
RUN apk add --no-cache \
  git \
  openssh

WORKDIR /opt/build

CMD ["/bin/bash"]
