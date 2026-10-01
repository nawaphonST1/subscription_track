#!/usr/bin/env bash
# ==============================================================================
# Automated PostgreSQL Backup & S3 Sync Script
# ==============================================================================
set -euo pipefail

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="${BACKUP_DIR:-/tmp/backups}"
DB_HOST="${DB_HOST:-postgres}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-subtracker_db}"
DB_USER="${DB_USER:-postgres}"
DB_PASSWORD="${DB_PASSWORD:-password123}"
S3_BUCKET="${S3_BACKUP_BUCKET:-subtracker-backups}"
S3_PREFIX="${S3_BACKUP_PREFIX:-postgres}"

BACKUP_FILE="${BACKUP_DIR}/${DB_NAME}_backup_${TIMESTAMP}.dump.gz"
CHECKSUM_FILE="${BACKUP_FILE}.sha256"

mkdir -p "${BACKUP_DIR}"

echo "==> [$(date)] Starting automated backup for database: ${DB_NAME} on ${DB_HOST}:${DB_PORT}..."

# Export password for pg_dump non-interactive execution
export PGPASSWORD="${DB_PASSWORD}"

# 1. Execute pg_dump and compress on-the-fly
echo "==> Creating compressed dump file: ${BACKUP_FILE}..."
pg_dump -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -Fc | gzip -c > "${BACKUP_FILE}"

FILE_SIZE=$(du -h "${BACKUP_FILE}" | cut -f1)
echo "✅ Database dump completed successfully. File size: ${FILE_SIZE}"

# 2. Generate SHA256 Checksum
echo "==> Generating SHA256 checksum..."
sha256sum "${BACKUP_FILE}" > "${CHECKSUM_FILE}"
cat "${CHECKSUM_FILE}"

# 3. Upload to S3-compatible object storage
S3_TARGET="s3://${S3_BUCKET}/${S3_PREFIX}/$(basename "${BACKUP_FILE}")"
S3_CHECKSUM_TARGET="s3://${S3_BUCKET}/${S3_PREFIX}/$(basename "${CHECKSUM_FILE}")"

EXTRA_ARGS=""
if [ -n "${AWS_ENDPOINT_URL:-}" ]; then
    EXTRA_ARGS="--endpoint-url ${AWS_ENDPOINT_URL}"
fi

echo "==> Uploading backup archive to S3: ${S3_TARGET}..."
aws s3 cp "${BACKUP_FILE}" "${S3_TARGET}" ${EXTRA_ARGS}
aws s3 cp "${CHECKSUM_FILE}" "${S3_CHECKSUM_TARGET}" ${EXTRA_ARGS}

echo "✅ Backup successfully synced to offsite storage: ${S3_TARGET}"

# 4. Clean up local temporary files
rm -f "${BACKUP_FILE}" "${CHECKSUM_FILE}"
echo "==> [$(date)] Backup process completed successfully!"
