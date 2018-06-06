FROM arm32v7/ubuntu:18.04

LABEL Daniel Neumann <https://www.danielstechblog.io>

ENV VERSION=1.10.2
ENV OS=linux
ENV ARCH=armv6l
ENV GO_DL=https://dl.google.com/go/go$VERSION.$OS-$ARCH.tar.gz

RUN apt-get update \
  && apt-get install -y wget \
  #&& apt-get install -y gcc \
  && rm -rf /var/lib/apt/lists/* \
  && wget $GO_DL --no-check-certificate \
  && tar -C /usr/local -xzf go$VERSION.$OS-$ARCH.tar.gz \
  && rm go$VERSION.$OS-$ARCH.tar.gz
ENV PATH=/usr/local/go/bin:$PATH

WORKDIR /webapp
ADD /go-webapp .
RUN go build .

ENTRYPOINT ./webapp

EXPOSE 80
