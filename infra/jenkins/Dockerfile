FROM jenkins/jenkins:lts-jdk17

USER root

# Disable initial setup wizard for fast, zero-friction local/VM setup
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false"

# Install Docker CLI and Compose plugin inside Jenkins container
RUN apt-get update && apt-get install -y --no-install-recommends \
    docker.io \
    curl \
    ca-certificates \
    openssh-client \
    xz-utils \
    && mkdir -p /usr/local/lib/docker/cli-plugins \
    && (curl -sSL https://github.com/docker/compose/releases/download/v2.29.7/docker-compose-linux-x86_64 -o /usr/local/lib/docker/cli-plugins/docker-compose && chmod +x /usr/local/lib/docker/cli-plugins/docker-compose && ln -sf /usr/local/lib/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose || true) \
    && curl -fsSL https://nodejs.org/dist/v22.14.0/node-v22.14.0-linux-x64.tar.xz | tar -xJ -C /usr/local --strip-components=1 \
    && npm install -g pnpm@10.2.1 \
    && rm -rf /var/lib/apt/lists/*

# Pre-install essential pipeline plugins (Docker pipeline, Git, Pipeline stage view, Pipeline graph view)
RUN jenkins-plugin-cli --plugins \
    docker-workflow \
    git \
    workflow-aggregator \
    pipeline-stage-view \
    pipeline-graph-view \
    credentials-binding

# Auto-configure security and pre-create pipeline job on startup
COPY init.groovy.d/ /usr/share/jenkins/ref/init.groovy.d/
