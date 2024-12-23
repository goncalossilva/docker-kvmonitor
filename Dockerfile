# Compile capnproto and kvmonitor and prepare dependencies for running
FROM debian:12-slim AS builder
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    autoconf \
    automake \
    libtool \
    make \
    clang-16 \
    clang++-16 \
    libavcodec-dev \
    libavformat-dev \
    libswscale-dev \
    zlib1g-dev \
    && update-alternatives --install /usr/bin/clang clang /usr/bin/clang-16 100 \
    && update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-16 100 \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean
WORKDIR /tmp/capnproto
RUN git clone -b v2 --depth 1 --single-branch https://github.com/capnproto/capnproto.git && \
    cd capnproto/c++ && \
    autoreconf -i && \
    ./configure && \
    make -j$(nproc) && \
    make install && \
    cd ../.. && \
    rm -rf capnproto
WORKDIR /app
RUN git clone --depth 1 --single-branch https://github.com/goncalossilva/kvmonitor.git && \
    cd kvmonitor && \
    make && \
    cp server .. && \
    cd .. && \
    rm -rf kvmonitor
RUN mkdir -p /deps && \
    ldd /app/server | grep "=> /" | awk '{print $3}' | xargs -I '{}' cp -v '{}' /deps && \
    cp -v $(ldconfig -p | grep "ld-linux.*\.so" | head -n1 | tr ' ' '\n' | grep /) /deps/

# Run kvmonitor
FROM debian:12-slim
COPY --from=builder /deps/* /lib/
COPY --from=builder /app/server /app/server
WORKDIR /app
EXPOSE 58666
ENV CAMERA_URLS=""
SHELL ["/bin/bash", "-c"]
CMD /app/server "0.0.0.0:58666" $CAMERA_URLS
