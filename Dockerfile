FROM rust:latest AS builder
RUN apt-get update && apt-get install -y \
    build-essential \
    libssl-dev \
    pkg-config \
    libasound2-dev \
    git \
    curl \
    && apt-get clean
WORKDIR /librespot
RUN git clone https://github.com/librespot-org/librespot.git /librespot
RUN git checkout v0.4.2
RUN cargo build --release



FROM debian:latest
ARG MAINTAINER="ISZ"
LABEL maintainer="${MAINTAINER}"
ARG SNAPCAST_VERSION="0.29.0"
ARG SNAPCAST_BUILD="-1"
ARG TARGETARCH
RUN apt-get update \
    && apt-get install -y wget ca-certificates \
    && rm -rf /var/lib/apt/lists/*
RUN wget https://github.com/badaix/snapcast/releases/download/v${SNAPCAST_VERSION}/snapserver_${SNAPCAST_VERSION}${SNAPCAST_BUILD}_${TARGETARCH}_bookworm.deb
RUN dpkg -i snapserver_${SNAPCAST_VERSION}${SNAPCAST_BUILD}_${TARGETARCH}_bookworm.deb; \
    apt-get update \
    && apt-get -f install -y \
    && rm -rf /var/lib/apt/lists/*
COPY --from=builder /librespot/target/release/librespot /usr/local/bin/
RUN snapserver -v
EXPOSE 1704 1705 1780
ENTRYPOINT ["snapserver"]