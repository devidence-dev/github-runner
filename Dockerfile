FROM debian:13.1-slim

ENV DEBIAN_FRONTEND=noninteractive

ARG RUNNER_VERSION=2.328.0
ARG SONAR_SCANNER_VERSION=7.3.0.5189

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

# Create runner user
RUN useradd -m -s /bin/bash runner && \
    usermod -aG docker runner && \
    usermod -aG sudo runner && \
    echo "runner ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Download GitHub Actions Runner
WORKDIR /home/runner
RUN curl -O -L "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-arm64-${RUNNER_VERSION}.tar.gz" && \
    tar xzf "./actions-runner-linux-arm64-${RUNNER_VERSION}.tar.gz" && \
    rm "./actions-runner-linux-arm64-${RUNNER_VERSION}.tar.gz" && \
    chown -R runner:runner /home/runner

# Download and install SonarScanner CLI
RUN curl -o /tmp/sonar-scanner.zip https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONAR_SCANNER_VERSION}-linux-aarch64.zip && \
    unzip /tmp/sonar-scanner.zip -d /opt && \
    mv /opt/sonar-scanner-${SONAR_SCANNER_VERSION}-linux-aarch64 /opt/sonar-scanner && \
    ln -s /opt/sonar-scanner/bin/sonar-scanner /usr/local/bin/sonar-scanner && \
    rm /tmp/sonar-scanner.zip && \
    chown -R runner:runner /opt/sonar-scanner

USER runner

COPY --chown=runner:runner start.sh /home/runner/start.sh
RUN chmod +x /home/runner/start.sh

ENTRYPOINT ["/home/runner/start.sh"]
