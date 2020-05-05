ARG ALPINE_VERSION=3.11
FROM elixir:1.10-alpine

ENV LANG=en_US.UTF-8 \
    TERM=xterm

RUN apk update && \
  apk upgrade --no-cache && \
  apk add --no-cache \
  bash \
  make gcc g++ python \
  npm
RUN apk add --no-cache \
  git \
  openssh

WORKDIR /opt/build

CMD ["/bin/bash"]
