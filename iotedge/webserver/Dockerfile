FROM arm32v7/ubuntu:18.04

LABEL Daniel Neumann <https://www.danielstechblog.io>

COPY qemu-arm-static /usr/bin/qemu-arm-static

WORKDIR /webapp
ADD /go-webapp .
RUN chmod +x ./webapp

ENTRYPOINT ./webapp

EXPOSE 80
