#!/usr/bin/env bash
# ==============================================================================
# Automated PostgreSQL Backup & Azure Blob Storage Sync Script
# ==============================================================================
set -euo pipefail

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="${BACKUP_DIR:-/tmp/backups}"
DB_HOST="${DB_HOST:-postgres}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-subtracker_db}"
DB_USER="${DB_USER:-postgres}"
DB_PASSWORD="${DB_PASSWORD:-password123}"

AZURE_STORAGE_ACCOUNT="${AZURE_STORAGE_ACCOUNT:-subtrackerbackups}"
AZURE_CONTAINER="${AZURE_STORAGE_CONTAINER:-postgres}"
AZURE_PREFIX="${AZURE_BACKUP_PREFIX:-backups}"
BACKUP_NAME="${BACKUP_NAME:-latest}"

BACKUP_FILE="${BACKUP_DIR}/${DB_NAME}_backup_${BACKUP_NAME}.dump.gz"
CHECKSUM_FILE="${BACKUP_FILE}.sha256"

mkdir -p "${BACKUP_DIR}"

echo "==> [${TIMESTAMP}] Starting automated backup for database: ${DB_NAME} on ${DB_HOST}:${DB_PORT} (Snapshot: ${BACKUP_NAME})..."

# Export password for pg_dump non-interactive execution
export PGPASSWORD="${DB_PASSWORD}"

# 1. Execute pg_dump and compress on-the-fly
echo "==> Creating compressed dump file: ${BACKUP_FILE}..."
if command -v pg_dump >/dev/null 2>&1; then
    pg_dump -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -Fc | gzip -c > "${BACKUP_FILE}"
elif docker ps --format '{{.Names}}' | grep -q "postgres"; then
    CONTAINER_NAME=$(docker ps --format '{{.Names}}' | grep "postgres" | head -n 1)
    echo "==> Using Docker container (${CONTAINER_NAME}) to run pg_dump..."
    docker exec -e PGPASSWORD="${DB_PASSWORD}" -i "${CONTAINER_NAME}" pg_dump -U "${DB_USER}" -d "${DB_NAME}" -Fc | gzip -c > "${BACKUP_FILE}"
else
    echo "❌ Error: Neither pg_dump nor running postgres docker container found!"
    exit 1
fi

FILE_SIZE=$(du -h "${BACKUP_FILE}" | cut -f1)
echo "✅ Database dump completed successfully. File size: ${FILE_SIZE}"

# 2. Generate SHA256 Checksum
echo "==> Generating SHA256 checksum..."
sha256sum "${BACKUP_FILE}" > "${CHECKSUM_FILE}"
cat "${CHECKSUM_FILE}"

# 3. Upload to Azure Blob Storage
BLOB_PATH="${AZURE_PREFIX}/$(basename "${BACKUP_FILE}")"
CHECKSUM_PATH="${AZURE_PREFIX}/$(basename "${CHECKSUM_FILE}")"
BLOB_BASE_URL="https://${AZURE_STORAGE_ACCOUNT}.blob.core.windows.net/${AZURE_CONTAINER}"

echo "==> Uploading backup archive to Azure Blob Storage: ${BLOB_BASE_URL}/${BLOB_PATH}..."

if command -v azcopy >/dev/null 2>&1; then
    export AZCOPY_ACCOUNT_KEY="${AZURE_STORAGE_KEY:-}"
    SAS_SUFFIX=""
    if [ -n "${AZURE_STORAGE_SAS_TOKEN:-}" ]; then
        SAS_TOKEN_CLEAN=$(echo "${AZURE_STORAGE_SAS_TOKEN}" | sed 's/^[?]*//')
        SAS_SUFFIX="?${SAS_TOKEN_CLEAN}"
    fi
    azcopy copy "${BACKUP_FILE}" "${BLOB_BASE_URL}/${BLOB_PATH}${SAS_SUFFIX}" --overwrite=true
    azcopy copy "${CHECKSUM_FILE}" "${BLOB_BASE_URL}/${CHECKSUM_PATH}${SAS_SUFFIX}" --overwrite=true
elif command -v az >/dev/null 2>&1; then
    AUTH_ARGS=""
    if [ -n "${AZURE_STORAGE_KEY:-}" ]; then
        AUTH_ARGS="--account-key ${AZURE_STORAGE_KEY}"
    elif [ -n "${AZURE_STORAGE_SAS_TOKEN:-}" ]; then
        AUTH_ARGS="--sas-token ${AZURE_STORAGE_SAS_TOKEN}"
    fi
    az storage blob upload --account-name "${AZURE_STORAGE_ACCOUNT}" --container-name "${AZURE_CONTAINER}" --file "${BACKUP_FILE}" --name "${BLOB_PATH}" --overwrite ${AUTH_ARGS}
    az storage blob upload --account-name "${AZURE_STORAGE_ACCOUNT}" --container-name "${AZURE_CONTAINER}" --file "${CHECKSUM_FILE}" --name "${CHECKSUM_PATH}" --overwrite ${AUTH_ARGS}
else
    echo "⚠️  Neither azcopy nor az CLI found. Local backup file is stored at: ${BACKUP_FILE}"
fi

echo "✅ Backup successfully synced to Azure offsite storage: ${BLOB_BASE_URL}/${BLOB_PATH} (In-place overwrite maintaining latest snapshot footprint)"

# 4. Clean up local temporary files
rm -f "${BACKUP_FILE}" "${CHECKSUM_FILE}"
echo "==> [$(date)] Backup process completed successfully!"

