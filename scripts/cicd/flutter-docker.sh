#!/usr/bin/env bash
# ==============================================================================
# flutter-docker.sh — Dockerized Flutter Mobile Runner with Persistent Caches
# ==============================================================================
set -euo pipefail

FLUTTER_IMAGE="${FLUTTER_IMAGE:-ghcr.io/cirruslabs/flutter:stable}"

# Determine whether running inside Jenkins container or on host VM
if [ -n "${WORKSPACE:-}" ] && [ -d "/var/jenkins_home" ]; then
  # Inside Jenkins container (subtracker_jenkins)
  JENKINS_VOL="jenkins_home"
  if command -v docker >/dev/null 2>&1; then
    DETECTED_VOL=$(docker inspect subtracker_jenkins --format '{{range .Mounts}}{{if eq .Destination "/var/jenkins_home"}}{{.Name}}{{end}}{{end}}' 2>/dev/null || true)
    if [ -n "${DETECTED_VOL}" ]; then
      JENKINS_VOL="${DETECTED_VOL}"
    fi
  fi
  TARGET_DIR="${WORKSPACE}/apps/mobile"
  MOUNT_FLAG="-v ${JENKINS_VOL}:/var/jenkins_home"
else
  # Direct host execution on VM
  HOST_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
  TARGET_DIR="${HOST_ROOT}/apps/mobile"
  MOUNT_FLAG="-v ${HOST_ROOT}:${HOST_ROOT}"
fi

echo "==> [Flutter Runner] Running command inside ${FLUTTER_IMAGE}..."
docker run --rm \
  -u root:root \
  ${MOUNT_FLAG} \
  -v subscription-mobile-pub-cache:/root/.pub-cache \
  -v subscription-mobile-gradle:/root/.gradle \
  -w "${TARGET_DIR}" \
  -e CI=true \
  "${FLUTTER_IMAGE}" \
  sh -c "$*"
