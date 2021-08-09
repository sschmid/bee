ARG ALPINE_VERSION=3.14
FROM alpine:${ALPINE_VERSION} AS base
RUN apk add --no-cache bash curl git jq util-linux
RUN git config --global user.email "bee" && git config --global user.name "bee"

FROM base AS bee
WORKDIR /usr/local/opt/bee
COPY src src
COPY etc etc
COPY version.txt .
RUN echo "source /usr/local/opt/bee/etc/bash_completion.d/bee-completion.bash" > /root/.bashrc
RUN ln -s /usr/local/opt/bee/src/bee /usr/local/bin/bee
VOLUME /root/project
WORKDIR /root/project
CMD ["bee"]

FROM bee AS test
WORKDIR /usr/local/opt/bee
COPY test test
RUN test/bats/bin/bats --tap test test/fixtures
