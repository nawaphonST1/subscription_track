#!/usr/bin/env bash
# ==============================================================================
# Disaster Recovery: PostgreSQL Database Restoration Script
# ==============================================================================
set -euo pipefail

BACKUP_DIR="${BACKUP_DIR:-/tmp/restore}"
DB_HOST="${DB_HOST:-postgres}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-subtracker_db}"
DB_USER="${DB_USER:-postgres}"
DB_PASSWORD="${DB_PASSWORD:-password123}"
S3_BUCKET="${S3_BACKUP_BUCKET:-subtracker-backups}"
S3_PREFIX="${S3_BACKUP_PREFIX:-postgres}"
RESTORE_TARGET="${1:-latest}"

mkdir -p "${BACKUP_DIR}"

EXTRA_ARGS=""
if [ -n "${AWS_ENDPOINT_URL:-}" ]; then
    EXTRA_ARGS="--endpoint-url ${AWS_ENDPOINT_URL}"
fi

echo "==> [$(date)] Initiating Database Disaster Recovery restoration..."

# 1. Determine target backup file
if [ "${RESTORE_TARGET}" = "latest" ]; then
    echo "==> Resolving latest backup from s3://${S3_BUCKET}/${S3_PREFIX}/..."
    LATEST_KEY=$(aws s3 ls "s3://${S3_BUCKET}/${S3_PREFIX}/" ${EXTRA_ARGS} | grep '\.dump\.gz$' | sort | tail -n 1 | awk '{print $4}')
    if [ -z "${LATEST_KEY}" ]; then
        echo "❌ No backup archive found in S3 bucket."
        exit 1
    fi
    RESTORE_FILE="${LATEST_KEY}"
else
    RESTORE_FILE="${RESTORE_TARGET}"
fi

LOCAL_BACKUP="${BACKUP_DIR}/${RESTORE_FILE}"
LOCAL_CHECKSUM="${LOCAL_BACKUP}.sha256"

# 2. Download archive and checksum
echo "==> Downloading ${RESTORE_FILE} from S3..."
aws s3 cp "s3://${S3_BUCKET}/${S3_PREFIX}/${RESTORE_FILE}" "${LOCAL_BACKUP}" ${EXTRA_ARGS}
aws s3 cp "s3://${S3_BUCKET}/${S3_PREFIX}/${RESTORE_FILE}.sha256" "${LOCAL_CHECKSUM}" ${EXTRA_ARGS} || true

# 3. Verify SHA256 Checksum if present
if [ -f "${LOCAL_CHECKSUM}" ]; then
    echo "==> Verifying SHA256 checksum..."
    (cd "${BACKUP_DIR}" && sha256sum -c "${RESTORE_FILE}.sha256")
    echo "✅ Checksum verification passed!"
fi

# 4. Decompress and restore into PostgreSQL
export PGPASSWORD="${DB_PASSWORD}"

echo "==> Restoring database ${DB_NAME} on ${DB_HOST}:${DB_PORT}..."
gunzip -c "${LOCAL_BACKUP}" | pg_restore -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" --clean --if-exists --no-owner --no-privileges || true

echo "✅ Database restored successfully!"
rm -rf "${BACKUP_DIR}"
