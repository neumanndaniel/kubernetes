FROM arm32v7/ubuntu:16.04

ENV VERSION=1.10.2
ENV OS=linux
ENV ARCH=armv6l
ENV GO_DL=https://dl.google.com/go/go$VERSION.$OS-$ARCH.tar.gz

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
        apt-utils

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
        software-properties-common \
        apt-utils \
 && apt-add-repository ppa:git-core/ppa \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
        curl \
        git \
        jq \
        libcurl3 \
        libicu55 \
        libunwind8 \
        netcat

RUN apt-get install -y --no-install-recommends \
  wget \
  &&wget $GO_DL \
  && tar -C /usr/local -xzf go$VERSION.$OS-$ARCH.tar.gz \
  && rm go$VERSION.$OS-$ARCH.tar.gz
ENV PATH=/usr/local/go/bin:$PATH

RUN apt install -y --no-install-recommends \
 gcc

COPY ./install_git_lfs.sh .
RUN chmod +x install_git_lfs.sh
RUN ./install_git_lfs.sh

# Accept the TEE EULA
RUN mkdir -p "/root/.microsoft/Team Foundation/4.0/Configuration/TEE-Mementos" \
 && cd "/root/.microsoft/Team Foundation/4.0/Configuration/TEE-Mementos" \
 && echo '<ProductIdData><eula-14.0 value="true"/></ProductIdData>' > "com.microsoft.tfs.client.productid.xml"

WORKDIR /vsts

COPY ./start.sh .
RUN chmod +x start.sh

CMD ["./start.sh"]
