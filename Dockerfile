FROM cellofellow/ffmpeg@sha256:1dae0b5235b2385cfcd6ab23350b0ff246769ec0c7d398ff60b68f2af2810ebc

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl

# Setup golang
# from: https://github.com/docker-library/golang/blob/d7e2a8d90a9b8f5dfd5bcd428e0c33b68c40cc19/1.5/Dockerfile
# -----------------------------------------------------------------------------------------------------------

# gcc for cgo
RUN apt-get update && apt-get install -y --no-install-recommends \
		g++ \
		gcc \
		libc6-dev \
		make \
	&& rm -rf /var/lib/apt/lists/*

ENV GOLANG_VERSION 1.7.4
ENV GOLANG_DOWNLOAD_URL https://golang.org/dl/go$GOLANG_VERSION.linux-amd64.tar.gz
ENV GOLANG_DOWNLOAD_SHA256 47fda42e46b4c3ec93fa5d4d4cc6a748aa3f9411a2a2b7e08e3a6d80d753ec8b

RUN curl -fsSL "$GOLANG_DOWNLOAD_URL" -o golang.tar.gz \
	&& echo "$GOLANG_DOWNLOAD_SHA256  golang.tar.gz" | sha256sum -c - \
	&& tar -C /usr/local -xzf golang.tar.gz \
	&& rm golang.tar.gz

ENV GOPATH /go
ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH

RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH"
WORKDIR $GOPATH

COPY go-wrapper /usr/local/bin/

# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

RUN apt-get update && apt-get install -y --no-install-recommends \
		wget \
		libexif-dev \
		imagemagick \
		gifsicle \
		python-setuptools \
  && easy_install qtfaststart

# For some reason go comes with `go vet` and `gofmt` but not with `golint`
RUN go get -u github.com/golang/lint/golint

# Of the dependency management we should use gvt
RUN go get -u github.com/FiloSottile/gvt

# Switch to the src workdir for gvt restore
WORKDIR /go/src

# Copy vendor first to install and cache the dependencies
ONBUILD COPY ./src/vendor $GOPATH/src/vendor

# Get all the dependencies
ONBUILD RUN cd $GOPATH/src/; gvt restore

# We assume that the source code is properly in source
ONBUILD COPY src $GOPATH/src

# Add all bin files to the go bin folder
ONBUILD COPY bin $GOPATH/bin

# Add Makefile for eventual builds - culture effort
ONBUILD ADD Makefile $GOPATH

# Switch to /go folder again because the Makefile is in there and it is in
# relation to the source folder as you would have it in a users image
ONBUILD WORKDIR $GOPATH
