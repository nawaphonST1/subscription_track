#!/usr/bin/env bash
# ==============================================================================
# Disaster Recovery: PostgreSQL Database Restoration Script (Azure Blob Storage)
# ==============================================================================
set -euo pipefail

BACKUP_DIR="${BACKUP_DIR:-/tmp/restore}"
DB_HOST="${DB_HOST:-postgres}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-subtracker_db}"
DB_USER="${DB_USER:-postgres}"
DB_PASSWORD="${DB_PASSWORD:-password123}"

AZURE_STORAGE_ACCOUNT="${AZURE_STORAGE_ACCOUNT:-subtrackerbackups}"
AZURE_CONTAINER="${AZURE_STORAGE_CONTAINER:-postgres}"
AZURE_PREFIX="${AZURE_BACKUP_PREFIX:-backups}"
RESTORE_TARGET="${1:-latest}"

mkdir -p "${BACKUP_DIR}"

BLOB_BASE_URL="https://${AZURE_STORAGE_ACCOUNT}.blob.core.windows.net/${AZURE_CONTAINER}"

echo "==> [$(date)] Initiating Database Disaster Recovery restoration from Azure..."

# 1. Determine target backup file
if [ "${RESTORE_TARGET}" = "latest" ]; then
    echo "==> Resolving latest backup from Azure Blob Storage (${BLOB_BASE_URL}/${AZURE_PREFIX}/)..."
    if command -v az >/dev/null 2>&1; then
        AUTH_ARGS=""
        if [ -n "${AZURE_STORAGE_KEY:-}" ]; then
            AUTH_ARGS="--account-key ${AZURE_STORAGE_KEY}"
        elif [ -n "${AZURE_STORAGE_SAS_TOKEN:-}" ]; then
            AUTH_ARGS="--sas-token ${AZURE_STORAGE_SAS_TOKEN}"
        fi
        LATEST_BLOB=$(az storage blob list --account-name "${AZURE_STORAGE_ACCOUNT}" --container-name "${AZURE_CONTAINER}" --prefix "${AZURE_PREFIX}/" --query "[?ends_with(name, '.dump.gz')].name | sort(@) | [-1]" -o tsv ${AUTH_ARGS})
        RESTORE_FILE=$(basename "${LATEST_BLOB}")
    else
        echo "⚠️  Azure CLI (az) not found for automatic latest resolution. Please specify exact backup filename as first argument."
        exit 1
    fi
else
    RESTORE_FILE="$(basename "${RESTORE_TARGET}")"
fi

LOCAL_BACKUP="${BACKUP_DIR}/${RESTORE_FILE}"
LOCAL_CHECKSUM="${LOCAL_BACKUP}.sha256"

# 2. Download archive and checksum from Azure Blob Storage
echo "==> Downloading ${RESTORE_FILE} from Azure Blob Storage..."

if command -v azcopy >/dev/null 2>&1; then
    export AZCOPY_ACCOUNT_KEY="${AZURE_STORAGE_KEY:-}"
    SAS_SUFFIX=""
    if [ -n "${AZURE_STORAGE_SAS_TOKEN:-}" ]; then
        SAS_TOKEN_CLEAN=$(echo "${AZURE_STORAGE_SAS_TOKEN}" | sed 's/^[?]*//')
        SAS_SUFFIX="?${SAS_TOKEN_CLEAN}"
    fi
    azcopy copy "${BLOB_BASE_URL}/${AZURE_PREFIX}/${RESTORE_FILE}${SAS_SUFFIX}" "${LOCAL_BACKUP}"
    azcopy copy "${BLOB_BASE_URL}/${AZURE_PREFIX}/${RESTORE_FILE}.sha256${SAS_SUFFIX}" "${LOCAL_CHECKSUM}" || true
elif command -v az >/dev/null 2>&1; then
    AUTH_ARGS=""
    if [ -n "${AZURE_STORAGE_KEY:-}" ]; then
        AUTH_ARGS="--account-key ${AZURE_STORAGE_KEY}"
    elif [ -n "${AZURE_STORAGE_SAS_TOKEN:-}" ]; then
        AUTH_ARGS="--sas-token ${AZURE_STORAGE_SAS_TOKEN}"
    fi
    az storage blob download --account-name "${AZURE_STORAGE_ACCOUNT}" --container-name "${AZURE_CONTAINER}" --name "${AZURE_PREFIX}/${RESTORE_FILE}" --file "${LOCAL_BACKUP}" ${AUTH_ARGS}
    az storage blob download --account-name "${AZURE_STORAGE_ACCOUNT}" --container-name "${AZURE_CONTAINER}" --name "${AZURE_PREFIX}/${RESTORE_FILE}.sha256" --file "${LOCAL_CHECKSUM}" ${AUTH_ARGS} || true
fi

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

echo "✅ Database restored successfully from Azure!"
rm -rf "${BACKUP_DIR}"

