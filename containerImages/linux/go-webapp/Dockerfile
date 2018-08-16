FROM ubuntu:bionic

LABEL maintainer="Daniel Neumann <https://www.danielstechblog.io>"
RUN groupadd -r -g 127001 container && \
    useradd -r -u 127001 -g container container

WORKDIR /webapp
ADD --chown=container:container /go-webapp .

USER container

EXPOSE 8080

ENTRYPOINT ./webapp