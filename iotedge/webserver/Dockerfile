FROM arm32v7/ubuntu:18.04

LABEL maintainer="Daniel Neumann <https://www.danielstechblog.io>"
RUN groupadd -r -g 127001 container && \
    useradd -r -u 127001 -g container container

COPY qemu-arm-static /usr/bin/qemu-arm-static

WORKDIR /webapp
ADD --chown=container:container /go-webapp .

USER container

EXPOSE 8080

ENTRYPOINT ./webapp
