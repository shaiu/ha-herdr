ARG BUILD_FROM
FROM ${BUILD_FROM}

SHELL ["/bin/ash", "-o", "pipefail", "-c"]

RUN apk add --no-cache \
    bash \
    curl \
    git \
    jq \
    nano \
    nginx \
    openssh-server \
    python3 \
    py3-pip \
    ttyd \
    vim

# uv runs ha-mcp. Alpine's packaged uv is too old to install the managed
# CPython 3.13 that ha-mcp needs, so take a pinned release from PyPI.
RUN pip3 install --no-cache-dir --break-system-packages uv==0.11.28

# Herdr: a pinned, checksum-verified static binary. Remote Herdr clients find
# it on the default PATH, so `herdr machine add` never installs anything here.
ARG HERDR_VERSION=0.9.5
ARG HERDR_SHA256_AARCH64=17d7536f2da50859523680ef279dffcac8e4a235f4e46fe8da6c2ec44141897c
ARG HERDR_SHA256_X86_64=14d9e8bc8b4a9e0118d77c32266f76d461f09b40342eb23752960bd89f59929d
RUN case "$(apk --print-arch)" in \
        aarch64) arch=aarch64; sum="${HERDR_SHA256_AARCH64}" ;; \
        x86_64)  arch=x86_64;  sum="${HERDR_SHA256_X86_64}" ;; \
        *) echo "Unsupported architecture: $(apk --print-arch)" >&2; exit 1 ;; \
    esac \
    && curl -fsSL -o /usr/local/bin/herdr \
        "https://github.com/herdrdev/herdr/releases/download/v${HERDR_VERSION}/herdr-linux-${arch}" \
    && echo "${sum}  /usr/local/bin/herdr" | sha256sum -c - \
    && chmod 0755 /usr/local/bin/herdr

# Claude Code, bundled as the native musl binary. On first start the app
# also installs Claude's self-updating native copy into /data, which then
# takes precedence on PATH; this bundled copy is the fallback.
RUN case "$(apk --print-arch)" in \
        aarch64) pkg=linux-arm64-musl ;; \
        x86_64)  pkg=linux-x64-musl ;; \
    esac \
    && version="$(curl -fsSL https://registry.npmjs.org/@anthropic-ai/claude-code/latest | jq -r .version)" \
    && curl -fsSL "https://registry.npmjs.org/@anthropic-ai/claude-code-${pkg}/-/claude-code-${pkg}-${version}.tgz" \
        | tar -xz -C /tmp package/claude \
    && install -m 0755 /tmp/package/claude /usr/local/bin/claude \
    && rm -rf /tmp/package

# Everything that must survive restarts and updates lives under /data. Root's
# home points there too, so SSH logins and the Herdr server share one HOME and
# therefore one Herdr socket.
ENV HOME=/data/home \
    PATH=/data/home/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    IS_SANDBOX=1 \
    MCP_TIMEOUT=60000 \
    npm_config_cache=/tmp/npm-cache
RUN sed -i 's|^root:\([^:]*\):0:0:\([^:]*\):[^:]*:|root:\1:0:0:\2:/data/home:|' /etc/passwd \
    && sed -i 's|^root:!:|root:*:|' /etc/shadow

COPY rootfs /

WORKDIR /homeassistant
