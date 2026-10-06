#!/usr/bin/env bash
# ==============================================================================
# Bootstrap Kubernetes Secrets (created out-of-band, never committed to git)
# ==============================================================================
# The Secrets referenced by k8s/*.yaml are deliberately absent from this
# repository. The ArgoCD Application (k8s/argocd/application.yaml) syncs the
# whole `k8s/` directory with prune + selfHeal, so any Secret committed there
# would be reconciled onto the cluster together with its value — and would be
# pushed back over anything an operator set by hand.
#
# Schema source of truth: infra/ansible/templates/k8s-secrets.yaml.j2
#   postgres-secret      POSTGRES_DB, POSTGRES_USER, POSTGRES_PASSWORD
#   app-secrets          JWT_SECRET, DB_PASSWORD, DATABASE_URL, REDIS_PASSWORD
#   backup-azure-secret  AZURE_STORAGE_ACCOUNT, AZURE_STORAGE_CONTAINER,
#                        AZURE_STORAGE_KEY, AZURE_STORAGE_SAS_TOKEN
# When a key is added or removed there, update this script to match.
#
# Usage:
#   ./scripts/bootstrap-secrets.sh              # prompts for anything unset
#   POSTGRES_PASSWORD=... JWT_SECRET=... ./scripts/bootstrap-secrets.sh
#   NAMESPACE=staging ./scripts/bootstrap-secrets.sh
#   DRY_RUN=1 ./scripts/bootstrap-secrets.sh    # render only, apply nothing
#   SKIP_AZURE=1 ./scripts/bootstrap-secrets.sh # skip backup-azure-secret
#
# Safety properties:
#   - values are never echoed, and never appear in the argv of an external
#     command, so they cannot be read out of `ps`;
#   - they are written only to 0600 files under a temp dir removed on exit;
#   - known weak defaults (password123, replace-with-..., CHANGE_ME, ...) are
#     rejected, as are empty values.
# ==============================================================================
set -euo pipefail

NAMESPACE="${NAMESPACE:-default}"
DRY_RUN="${DRY_RUN:-0}"
SKIP_AZURE="${SKIP_AZURE:-0}"

# Values that mean "nobody has chosen a real one yet". Sourced from the
# placeholders in .env.example, infra/ansible/vars/vault.example.yml and the
# defaults that used to be hardcoded in the compose files.
WEAK_VALUES=(
    "password123"
    "Password123"
    "password"
    "postgres"
    "admin"
    "secret"
    "test"
    "changeme"
    "change-me"
    "CHANGE_ME"
    "CHANGEME"
    "REPLACE_ME"
    "replace_me"
    "replace-with-a-secure-production-db-password"
    "replace-with-a-cryptographically-random-secret"
    "replace-with-a-cryptographically-random-secret-at-least-32-chars"
    "replace-with-azure-storage-account-key"
)

MIN_JWT_LENGTH=32

die() {
    printf 'ERROR: %s\n' "$1" >&2
    exit 1
}

info() {
    printf '%s\n' "$1"
}

# ------------------------------------------------------------------------------
# Input collection. Values arrive from the environment, or are prompted for on
# an interactive terminal. Nothing is ever printed back.
# ------------------------------------------------------------------------------

ask_plain() {
    local name="$1" desc="$2" value="${!1:-}"
    if [ -z "${value}" ] && [ -t 0 ]; then
        printf '%s (%s): ' "${name}" "${desc}" >&2
        IFS= read -r value
    fi
    printf -v "${name}" '%s' "${value}"
}

ask_secret() {
    local name="$1" desc="$2" value="${!1:-}"
    if [ -z "${value}" ] && [ -t 0 ]; then
        printf '%s (%s, input hidden): ' "${name}" "${desc}" >&2
        IFS= read -rs value
        printf '\n' >&2
    fi
    printf -v "${name}" '%s' "${value}"
}

require_strong() {
    local name="$1" value="${!1:-}" weak
    [ -n "${value}" ] || die "${name} is empty. Set it in the environment or run this script interactively."
    for weak in "${WEAK_VALUES[@]}"; do
        if [ "${value}" = "${weak}" ]; then
            die "${name} is set to a known weak default. Choose a real value — this script will not deploy placeholder credentials."
        fi
    done
}

# A password that is interpolated into DATABASE_URL must be percent-encoded if
# it contains anything outside the URL "unreserved" set. Rather than encode it
# silently (and risk a mismatch with what Postgres was initialised with), refuse
# and ask for an explicit DATABASE_URL.
require_url_safe() {
    local name="$1" value="${!1:-}"
    case "${value}" in
        *[!A-Za-z0-9._~-]*)
            die "${name} contains characters that must be percent-encoded inside DATABASE_URL. Set DATABASE_URL explicitly and re-run."
            ;;
    esac
}

# ------------------------------------------------------------------------------
# Rendering and applying
# ------------------------------------------------------------------------------

umask 077
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

# write_env_file <path> <KEY=VALUE>...
# Arguments to a shell function are not visible in `ps`; only external commands
# expose their argv.
write_env_file() {
    local path="$1"
    shift
    : >"${path}"
    local pair
    for pair in "$@"; do
        printf '%s\n' "${pair}" >>"${path}"
    done
}

apply_secret() {
    local name="$1" env_file="$2"
    local manifest="${TMP_DIR}/${name}.yaml"

    kubectl create secret generic "${name}" \
        --namespace "${NAMESPACE}" \
        --from-env-file="${env_file}" \
        --dry-run=client -o yaml >"${manifest}"

    if [ "${DRY_RUN}" = "1" ]; then
        info "   dry run: rendered ${name} (${NAMESPACE}), nothing applied"
        return 0
    fi

    kubectl apply -f "${manifest}"
}

# ------------------------------------------------------------------------------
main() {
    command -v kubectl >/dev/null 2>&1 || die "kubectl not found in PATH."

    info "==> Bootstrapping Secrets into namespace '${NAMESPACE}'"
    [ "${DRY_RUN}" = "1" ] && info "    DRY_RUN=1 — manifests are rendered but not applied"

    # --- postgres-secret -------------------------------------------------------
    ask_plain  POSTGRES_DB       "database name"
    ask_plain  POSTGRES_USER     "database user"
    ask_secret POSTGRES_PASSWORD "database password"

    require_strong POSTGRES_DB
    require_strong POSTGRES_USER
    require_strong POSTGRES_PASSWORD

    write_env_file "${TMP_DIR}/postgres.env" \
        "POSTGRES_DB=${POSTGRES_DB}" \
        "POSTGRES_USER=${POSTGRES_USER}" \
        "POSTGRES_PASSWORD=${POSTGRES_PASSWORD}"
    apply_secret "postgres-secret" "${TMP_DIR}/postgres.env"

    # --- app-secrets -----------------------------------------------------------
    ask_secret JWT_SECRET "API signing secret, >= ${MIN_JWT_LENGTH} chars"
    require_strong JWT_SECRET
    [ "${#JWT_SECRET}" -ge "${MIN_JWT_LENGTH}" ] ||
        die "JWT_SECRET is shorter than ${MIN_JWT_LENGTH} characters. Generate one with: openssl rand -base64 48"

    if [ -z "${DATABASE_URL:-}" ]; then
        require_url_safe POSTGRES_USER
        require_url_safe POSTGRES_PASSWORD
        require_url_safe POSTGRES_DB
        DATABASE_URL="postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/${POSTGRES_DB}?schema=public"
    fi

    app_pairs=(
        "JWT_SECRET=${JWT_SECRET}"
        "DB_PASSWORD=${POSTGRES_PASSWORD}"
        "DATABASE_URL=${DATABASE_URL}"
    )
    # Optional: only set when Redis is configured with authentication.
    if [ -n "${REDIS_PASSWORD:-}" ]; then
        require_strong REDIS_PASSWORD
        app_pairs+=("REDIS_PASSWORD=${REDIS_PASSWORD}")
    fi

    write_env_file "${TMP_DIR}/app.env" "${app_pairs[@]}"
    apply_secret "app-secrets" "${TMP_DIR}/app.env"

    # --- backup-azure-secret ---------------------------------------------------
    # k8s/postgres-backup-cronjob.yaml reads ACCOUNT and CONTAINER without
    # `optional: true`, so the backup pod cannot start until this Secret exists.
    # KEY and SAS_TOKEN are optional there; exactly one of them is needed for
    # the upload to authenticate.
    if [ "${SKIP_AZURE}" = "1" ]; then
        info "==> SKIP_AZURE=1 — not creating backup-azure-secret."
        info "    k8s/postgres-backup-cronjob.yaml will fail to start without it."
        info "    Suspend the CronJob until Azure storage exists, or re-run without SKIP_AZURE."
    else
        ask_plain  AZURE_STORAGE_ACCOUNT   "Azure storage account name"
        ask_plain  AZURE_STORAGE_CONTAINER "Azure blob container"
        ask_secret AZURE_STORAGE_KEY       "storage account key, blank to use a SAS token"

        require_strong AZURE_STORAGE_ACCOUNT
        require_strong AZURE_STORAGE_CONTAINER

        azure_pairs=(
            "AZURE_STORAGE_ACCOUNT=${AZURE_STORAGE_ACCOUNT}"
            "AZURE_STORAGE_CONTAINER=${AZURE_STORAGE_CONTAINER}"
        )
        if [ -n "${AZURE_STORAGE_KEY:-}" ]; then
            require_strong AZURE_STORAGE_KEY
            azure_pairs+=("AZURE_STORAGE_KEY=${AZURE_STORAGE_KEY}")
        fi
        if [ -n "${AZURE_STORAGE_SAS_TOKEN:-}" ]; then
            require_strong AZURE_STORAGE_SAS_TOKEN
            azure_pairs+=("AZURE_STORAGE_SAS_TOKEN=${AZURE_STORAGE_SAS_TOKEN}")
        fi
        if [ -z "${AZURE_STORAGE_KEY:-}" ] && [ -z "${AZURE_STORAGE_SAS_TOKEN:-}" ]; then
            die "Provide either AZURE_STORAGE_KEY or AZURE_STORAGE_SAS_TOKEN, or re-run with SKIP_AZURE=1."
        fi

        write_env_file "${TMP_DIR}/azure.env" "${azure_pairs[@]}"
        apply_secret "backup-azure-secret" "${TMP_DIR}/azure.env"
    fi

    info "==> Done. Restart the workloads that mount these Secrets so they pick up new values:"
    info "    kubectl -n ${NAMESPACE} rollout restart statefulset/postgres"
}

main "$@"
