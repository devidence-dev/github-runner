FROM debian:13.4-slim AS builder

ARG RUNNER_VERSION=2.333.1
ARG TARGETPLATFORM

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl=8.14.1-2+deb13u2 \
    tar=1.35+dfsg-3.1 \
    gzip=1.13-1 \
    ca-certificates=20250419 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /home/runner
RUN set -e && \
    if [ "$TARGETPLATFORM" = "linux/arm64" ]; then \
      RUNNER_ARCH="arm64"; \
    elif [ "$TARGETPLATFORM" = "linux/amd64" ]; then \
      RUNNER_ARCH="x64"; \
    else \
      echo "Arquitectura no soportada: $TARGETPLATFORM"; exit 1; \
    fi && \
    curl -fsSL -O "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz" && \
    tar xzf "./actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz" && \
    rm "./actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz"


FROM debian:13.4-slim

ENV DEBIAN_FRONTEND=noninteractive

ARG TARGETPLATFORM

# Install runtime dependencies with pinned versions for reproducibility
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl=8.14.1-2+deb13u2 \
    jq=1.7.1-6+deb13u1 \
    file=1:5.46-5 \
    git=1:2.47.3-0+deb13u1 \
    docker.io=26.1.5+dfsg1-9+b12 \
    docker-compose=2.26.1-4 \
    sudo=1.9.16p2-3+deb13u1 \
    ca-certificates=20250419 \
    libicu76=76.1-4 \
    libc6=2.41-12+deb13u2 \
    libssl3t64=3.5.5-1~deb13u2 \
    unzip=6.0-29 \
    python3=3.13.5-1 \
    python3-pip=25.1.1+dfsg-1 \
    python3-venv=3.13.5-1 \
    && rm -rf /var/lib/apt/lists/*

# Create runner user with matching host UID/GID
RUN groupadd -g 1000 runner && \
    useradd -m -u 1000 -g 1000 -s /bin/bash runner && \
    groupmod -g 989 docker && \
    usermod -aG docker runner && \
    usermod -aG sudo runner && \
    echo "runner ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

WORKDIR /home/runner

COPY --from=builder --chown=runner:runner /home/runner ./

# Create work directories with proper permissions
RUN mkdir -p _work/_tool _work/_actions && \
    chown -R runner:runner _work && \
    chmod -R 755 _work

USER runner

COPY --chown=runner:runner --chmod=755 start.sh /home/runner/start.sh

ENTRYPOINT ["/home/runner/start.sh"]
