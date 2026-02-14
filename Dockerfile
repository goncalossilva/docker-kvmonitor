# Compile capnproto (v2) + kvmonitor and prepare dependencies for running.
FROM ubuntu:24.04 AS builder

ARG CAPNPROTO_REF=v2
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    autoconf \
    automake \
    libtool \
    make \
    build-essential \
    clang \
    libavcodec-dev \
    libavformat-dev \
    libswresample-dev \
    libswscale-dev \
    libavutil-dev \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

WORKDIR /tmp/capnproto
RUN git clone --depth 1 --single-branch --branch "$CAPNPROTO_REF" \
      https://github.com/capnproto/capnproto.git . && \
    cd c++ && \
    autoreconf -i && \
    CC=clang CXX=clang++ CPPFLAGS="-include stdint.h" ./configure --prefix=/usr && \
    make -j"$(nproc)" && \
    make install && \
    cd / && \
    rm -rf /tmp/capnproto

# Used for cache-busting so `RUN git clone …kvmonitor…` doesn't get stuck on an old commit when
# buildx caching is enabled (Docker cache keys don't include remote git repo state).
ARG KVMONITOR_SHA=unknown
WORKDIR /app
RUN echo "kvmonitor: ${KVMONITOR_SHA}" && \
    git clone --depth 1 --single-branch https://github.com/goncalossilva/kvmonitor.git && \
    cd kvmonitor && \
    make && \
    cp server .. && \
    cd .. && \
    rm -rf kvmonitor
RUN mkdir -p /deps && \
    ldd /app/server | grep "=> /" | awk '{print $3}' | xargs -I '{}' cp -v '{}' /deps && \
    cp -v $(ldconfig -p | grep "ld-linux.*\.so" | head -n1 | tr ' ' '\n' | grep /) /deps/

# Run kvmonitor
FROM ubuntu:24.04
COPY --from=builder /deps/* /lib/
COPY --from=builder /app/server /app/server
WORKDIR /app
EXPOSE 58666
ENV CAMERA_URLS=""
SHELL ["/bin/bash", "-c"]
CMD /app/server "0.0.0.0:58666" $CAMERA_URLS
