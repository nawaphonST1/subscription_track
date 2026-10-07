FROM jenkins/jenkins:lts-jdk17

USER root

# Disable initial setup wizard for fast, zero-friction local/VM setup
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false"

# Install Docker CLI and Docker Compose v2 inside Jenkins container
RUN apt-get update && apt-get install -y --no-install-recommends \
    docker.io \
    docker-compose-v2 \
    && rm -rf /var/lib/apt/lists/*

# Pre-install essential pipeline plugins (Docker pipeline, Git, Pipeline stage view)
RUN jenkins-plugin-cli --plugins \
    docker-workflow \
    git \
    workflow-aggregator \
    pipeline-stage-view \
    credentials-binding

# Auto-configure security and pre-create pipeline job on startup
COPY init.groovy.d/ /usr/share/jenkins/ref/init.groovy.d/
