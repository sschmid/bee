ARG BASH_VERSION=5.1
FROM bash:${BASH_VERSION} AS base
WORKDIR /usr/local/opt/bee
COPY DEPENDENCIES.md .
RUN apk add --no-cache $(cat DEPENDENCIES.md)

FROM base AS bee
WORKDIR /usr/local/opt/bee
COPY src src
COPY version.txt .
RUN echo "complete -C bee bee" > /root/.bashrc
RUN ln -s /usr/local/opt/bee/src/bee /usr/local/bin/bee
WORKDIR /root/project
CMD ["bee"]

FROM bee AS test
WORKDIR /usr/local/opt/bee
COPY test test
RUN test/bats/bin/bats --tap test
