FROM armhf/alpine

LABEL maintainer="Daniel Neumann <https://www.danielstechblog.io>"

RUN addgroup -S -g 127001 container && \
    adduser -SD -u 127001 -G container container

WORKDIR /webapp
ADD --chown=container:container /go-webapp .
RUN chmod +x ./webapp

USER container

EXPOSE 8080

ENTRYPOINT ./webapp
