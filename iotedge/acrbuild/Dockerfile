FROM arm32v7/ubuntu:18.04

LABEL maintainer="Daniel Neumann <https://www.danielstechblog.io>"

WORKDIR /webapp
ADD /go-webapp .
RUN chmod +x ./webapp

EXPOSE 8080

ENTRYPOINT ./webapp
