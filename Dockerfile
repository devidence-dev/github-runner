FROM debian:13.1-slim

# Avoid interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Runner version argument with default
# https://github.com/actions/runner/releases
ARG RUNNER_VERSION=2.328.0

# Install minimal dependencies for runner + Docker-in-Docker
RUN apt-get update && apt-get install -y \
    curl \
    tar \
    gzip \
    jq \
    git \
    docker.io \
    docker-compose \
    sudo \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create a 'runner' user with sudo and docker permissions
RUN useradd -m -s /bin/bash runner && \
    usermod -aG docker runner && \
    usermod -aG sudo runner && \
    echo "runner ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Download GitHub Actions Runner for ARM64 (Raspberry Pi) - following official instructions
WORKDIR /home/runner
RUN curl -O -L "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-arm64-${RUNNER_VERSION}.tar.gz" && \
    tar xzf ./actions-runner-linux-arm64-${RUNNER_VERSION}.tar.gz && \
    rm actions-runner-linux-arm64-${RUNNER_VERSION}.tar.gz && \
    # Install additional runner dependencies
    sudo ./bin/installdependencies.sh || echo "Some dependencies may not be available"

# Change ownership of files to the 'runner' user
RUN chown -R runner:runner /home/runner

# Copy startup script
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Switch to 'runner' user
USER runner

# Entrypoint
ENTRYPOINT ["/start.sh"]
