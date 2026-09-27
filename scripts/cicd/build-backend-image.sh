#!/usr/bin/env bash
set -euo pipefail

# Builds the backend API's Docker `runtime` target via Buildx and loads it
# into the local image store, tagged with both an immutable commit SHA and a
# convenient branch name. Requires only Git + Docker; never pushes anywhere.
#
# Usage:
#   ./scripts/cicd/build-backend-image.sh
#   IMAGE_REPOSITORY=ghcr.io/<owner>/subscription-track-api ./scripts/cicd/build-backend-image.sh

ROOT_DIR="$(git rev-parse --show-toplevel)"
SHORT_SHA="$(git -C "${ROOT_DIR}" rev-parse --short=12 HEAD)"
BRANCH_RAW="$(git -C "${ROOT_DIR}" branch --show-current)"

# Sanitize the branch name into a valid Docker tag component:
#   - lowercase
#   - '/' -> '-'
#   - anything outside [a-z0-9_.-] -> '-'
#   - collapse repeated '-'
#   - strip a leading character that isn't alphanumeric (tags must start with one)
#   - fall back to the commit SHA if the result is empty (e.g. detached HEAD)
BRANCH_TAG="$(
  printf '%s' "${BRANCH_RAW}" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -e 's#/#-#g' \
          -e 's#[^a-z0-9_.-]#-#g' \
          -e 's#-\{2,\}#-#g' \
          -e 's#^[^a-z0-9]*##'
)"
if [ -z "${BRANCH_TAG}" ]; then
  BRANCH_TAG="${SHORT_SHA}"
fi

IMAGE_REPOSITORY="${IMAGE_REPOSITORY:-subscription-track-api}"

echo "Building ${IMAGE_REPOSITORY} (target: runtime) from ${ROOT_DIR}/apps/server"
echo "  commit tag: ${SHORT_SHA}"
echo "  branch tag: ${BRANCH_TAG}"

docker buildx build \
  --target runtime \
  --tag "${IMAGE_REPOSITORY}:${SHORT_SHA}" \
  --tag "${IMAGE_REPOSITORY}:${BRANCH_TAG}" \
  --load \
  "${ROOT_DIR}/apps/server"

echo ""
echo "Built and loaded:"
echo "  ${IMAGE_REPOSITORY}:${SHORT_SHA}"
echo "  ${IMAGE_REPOSITORY}:${BRANCH_TAG}"
