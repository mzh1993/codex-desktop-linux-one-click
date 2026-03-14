ARG BASE_IMAGE=ubuntu:20.04
FROM ${BASE_IMAGE}

ARG http_proxy=
ARG https_proxy=
ARG HTTP_PROXY=
ARG HTTPS_PROXY=
ARG ALL_PROXY=
ARG all_proxy=
ARG no_proxy=
ARG NO_PROXY=
ARG NODE_DIST=latest-v22.x

ENV DEBIAN_FRONTEND=noninteractive \
    http_proxy= \
    https_proxy= \
    HTTP_PROXY= \
    HTTPS_PROXY= \
    ALL_PROXY= \
    all_proxy= \
    no_proxy= \
    NO_PROXY= \
    CC=clang-18 \
    CXX=clang++-18 \
    CXXFLAGS="-stdlib=libc++" \
    LDFLAGS="-stdlib=libc++" \
    CODEX_TARGET_GLIBC_MAX=2.31 \
    CODEX_EXPECT_STATIC_LIBSTDCXX=0 \
    CODEX_BUNDLE_LIBCXX=1

RUN cat > /etc/apt/apt.conf.d/99no-proxy <<'APTCONF'
Acquire::http::Proxy "false";
Acquire::https::Proxy "false";
APTCONF

RUN apt-get update \
    && apt-get install -y \
        ca-certificates \
        clang-18 \
        curl \
        git \
        libc++-18-dev \
        libc++abi-18-dev \
        make \
        p7zip-full \
        python3 \
        unzip \
        xz-utils \
    && ln -sf /usr/bin/clang++-18 /usr/local/bin/g++ \
    && ln -sf /usr/bin/clang-18 /usr/local/bin/gcc \
    && rm -rf /var/lib/apt/lists/*

RUN arch="$(dpkg --print-architecture)" \
    && case "$arch" in \
        amd64) node_arch="x64" ;; \
        arm64) node_arch="arm64" ;; \
        *) echo "Unsupported architecture: $arch" >&2; exit 1 ;; \
       esac \
    && curl -fsSL "https://nodejs.org/dist/${NODE_DIST}/SHASUMS256.txt" -o /tmp/SHASUMS256.txt \
    && node_tarball="$(grep "linux-${node_arch}.tar.xz$" /tmp/SHASUMS256.txt | head -n 1 | awk '{print $2}')" \
    && test -n "$node_tarball" \
    && curl -fsSL "https://nodejs.org/dist/${NODE_DIST}/${node_tarball}" -o /tmp/node.tar.xz \
    && tar -xJf /tmp/node.tar.xz -C /usr/local --strip-components=1 \
    && rm -f /tmp/node.tar.xz /tmp/SHASUMS256.txt \
    && node --version \
    && npm --version \
    && "$CC" --version \
    && "$CXX" --version \
    && g++ --version

WORKDIR /workspace

CMD ["bash"]
