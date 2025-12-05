FROM debian:13.1-slim

ENV DEBIAN_FRONTEND=noninteractive

ARG RUNNER_VERSION=2.330.0
ARG SONAR_SCANNER_VERSION=8.0.0.6341
ARG BUILDPLATFORM
ARG TARGETPLATFORM

# Apply security updates and install dependencies (including unzip)
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    curl \
    tar \
    gzip \
    jq \
    git \
    docker.io \
    docker-compose \
    sudo \
    ca-certificates \
    libicu-dev \
    binutils \
    file \
    libc6 \
    libssl3 \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Create runner user with matching host UID/GID
RUN groupadd -g 1000 runner && \
    useradd -m -u 1000 -g 1000 -s /bin/bash runner && \
    groupmod -g 989 docker && \
    usermod -aG docker runner && \
    usermod -aG sudo runner && \
    echo "runner ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Download GitHub Actions Runner
WORKDIR /home/runner
RUN set -e && \
    if [ "$TARGETPLATFORM" = "linux/arm64" ]; then \
      RUNNER_ARCH="arm64"; \
    elif [ "$TARGETPLATFORM" = "linux/amd64" ]; then \
      RUNNER_ARCH="x64"; \
    else \
      echo "❌ Arquitectura no soportada: $TARGETPLATFORM"; exit 1; \
    fi && \
    curl -O -L "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz" && \
    tar xzf "./actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz" && \
    rm "./actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz" && \
    chown -R runner:runner /home/runner

# Download and install SonarScanner CLI
RUN set -e && \
    if [ "$TARGETPLATFORM" = "linux/arm64" ]; then \
      SONAR_ARCH="aarch64"; \
    elif [ "$TARGETPLATFORM" = "linux/amd64" ]; then \
      SONAR_ARCH="x64"; \
    else \
      echo "❌ Arquitectura no soportada: $TARGETPLATFORM"; exit 1; \
    fi && \
    curl -o /tmp/sonar-scanner.zip "https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONAR_SCANNER_VERSION}-linux-${SONAR_ARCH}.zip" && \
    unzip /tmp/sonar-scanner.zip -d /opt && \
    mv /opt/sonar-scanner-${SONAR_SCANNER_VERSION}-linux-${SONAR_ARCH} /opt/sonar-scanner && \
    ln -s /opt/sonar-scanner/bin/sonar-scanner /usr/local/bin/sonar-scanner && \
    rm /tmp/sonar-scanner.zip && \
    chown -R runner:runner /opt/sonar-scanner

# Create work directories with proper permissions
RUN mkdir -p /home/runner/_work/_tool /home/runner/_work/_actions && \
    chown -R runner:runner /home/runner/_work && \
    chmod -R 755 /home/runner/_work

USER runner

COPY --chown=runner:runner start.sh /home/runner/start.sh
RUN chmod +x /home/runner/start.sh

ENTRYPOINT ["/home/runner/start.sh"]
