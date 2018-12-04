FROM golang:1.10.5-alpine3.8 AS build
WORKDIR /webapp
ADD /go-webapp .
RUN apk update && \
    apk add git && \
    go get github.com/sirupsen/logrus && \
    go build -o webapp .

FROM alpine:3.8
LABEL maintainer="Daniel Neumann <https://www.danielstechblog.io>"
RUN addgroup -S -g 127001 container && \
    adduser -SD -u 127001 -G container container
USER container
WORKDIR /webapp
COPY --from=build /webapp .
EXPOSE 8080
ENTRYPOINT ./webapp
