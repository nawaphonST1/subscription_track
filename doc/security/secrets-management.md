# Secrets Management

Status: interim. Last reviewed 2026-10-04.

This document covers how credentials reach the two deployment targets in this
repository — the Docker Compose stack on the VMs, and the Kubernetes manifests
under `k8s/` — and what has to change before either is used with real data.

`doc/` is otherwise untracked (see `.gitignore`), but `doc/security/` is
deliberately kept in git: this is team policy, not personal notes.

---

## 1. Current approach: no secrets in git

**No tracked file under `k8s/` defines a `kind: Secret`, and no `.env*` file
with real values is committed.** Credentials are created out-of-band on the
target and are never reconciled from the repository.

`k8s/postgres-secret.yaml` is gitignored. If it exists in your working tree it
is a local leftover from before this change — it is not synced by ArgoCD and
not visible to anyone else, but it still carries the old `password123`, so
delete it rather than applying it.

### Why

`k8s/argocd/application.yaml` syncs the whole `k8s/` directory:

```yaml
  source:
    path: k8s
    directory:
      recurse: false
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

With `selfHeal: true`, ArgoCD continuously reconciles the cluster back to what
is in git. A `Secret` committed under `k8s/` would therefore not merely be
readable by anyone with repository access — it would be *pushed back over* any
value an operator set by hand, every time it drifted. `prune: true` means the
reverse is also true: removing a Secret manifest from git deletes it from the
cluster.

That is exactly what happened before this change. `k8s/postgres-secret.yaml`
shipped `POSTGRES_PASSWORD: "password123"` in plain text, inside the synced
path, with selfHeal enabled.

### How credentials are provided instead

| Target | Mechanism | Source file |
| --- | --- | --- |
| Kubernetes | `scripts/bootstrap-secrets.sh`, run once per cluster/namespace | — (values supplied by the operator) |
| Docker Compose | `apps/server/.env.production`, loaded via `env_file:` | `apps/server/.env.production.example` |

`scripts/bootstrap-secrets.sh` creates the three Secrets with
`kubectl create secret generic ... --dry-run=client -o yaml | kubectl apply -f -`.
It refuses to run on empty values or on known weak defaults (`password123`,
`CHANGE_ME`, `replace-with-...`), never echoes a value, and never passes one in
the argv of an external command, so values cannot be read out of `ps`.

```bash
# interactive, prompts for anything not already in the environment
./scripts/bootstrap-secrets.sh

# render without touching the cluster
DRY_RUN=1 ./scripts/bootstrap-secrets.sh

# skip the Azure backup Secret (see §3.2)
SKIP_AZURE=1 ./scripts/bootstrap-secrets.sh
```

### Schema source of truth

The authoritative list of Secret names and keys is
**`infra/ansible/templates/k8s-secrets.yaml.j2`**. It defines all three:

| Secret | Keys | Consumed by |
| --- | --- | --- |
| `postgres-secret` | `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD` | `k8s/postgres-statefulset.yaml:65`, `k8s/postgres-backup-cronjob.yaml:76-90` |
| `app-secrets` | `JWT_SECRET`, `DB_PASSWORD`, `DATABASE_URL`, `REDIS_PASSWORD` | not referenced by any manifest in `k8s/` yet |
| `backup-azure-secret` | `AZURE_STORAGE_ACCOUNT`, `AZURE_STORAGE_CONTAINER`, `AZURE_STORAGE_KEY`, `AZURE_STORAGE_SAS_TOKEN` | `k8s/postgres-backup-cronjob.yaml:91-111` |

`scripts/bootstrap-secrets.sh` mirrors that list. **When a key is added or
removed in the Jinja2 template, update the script in the same change.** There is
no codegen linking them.

The Ansible template itself is currently inert — see §3.3.

---

## 2. Known gaps

### 2.1 Default credentials are in git history — treat as compromised

`password123` has been committed repeatedly since 2026-09-30 and is still
present in tracked files on this branch:

```
docker-compose.yml:14,15,44,73          ${DB_PASSWORD:-password123}
docker-compose.test.yml:9,46,47         password123
apps/server/docker-compose.yml:11,42,43 password123
scripts/backup-postgres.sh:13           ${DB_PASSWORD:-password123}
scripts/restore-postgres.sh:12          ${DB_PASSWORD:-password123}
```

Commits that introduced or moved it: `925ba3e`, `4194f50`, `f783c59`,
`56082d5`, `ddc401f`.

The dev and test compose files are local-only and the value there is harmless.
The two `scripts/*.sh` defaults are not: those scripts are also the body of the
production backup CronJob's workflow. **Any environment that was ever brought up
with one of these defaults must have its database password rotated before it
holds real data.**

Removing the value from `HEAD` does not remove it from history. **Do not rewrite
history to purge it** (`filter-repo`, `rebase`, force-push) without team
agreement — the branch is shared, and the value is a known-weak default rather
than a live production credential, so rotation is the cheaper and safer fix.

### 2.2 No rotation story

There is no procedure, schedule or automation for rotating any credential.
Rotating today means re-running `bootstrap-secrets.sh` and restarting every
workload that mounts the Secret, by hand. Nothing detects a stale credential.

### 2.3 Secret scanning in CI does not block

`Jenkinsfile:52-63` already runs Gitleaks, but:

```
gitleaks detect ... --report-path gitleaks-report.json || true
```

The `|| true` means a finding never fails the build. `.gitleaks.toml` also
allowlists `doc/.*` wholesale. Making the scan blocking (and narrowing the
allowlist) is a worthwhile follow-up; it is **not** implemented here.

The local pre-commit hook (`.githooks/pre-commit`, installed by
`scripts/setup-pre-commit.sh`) does run Gitleaks on staged files.

### 2.4 `app-secrets` has no consumer

The Jinja2 template defines `app-secrets`, but no manifest under `k8s/`
references it. Either the API Deployment is missing from `k8s/`, or the Secret
is vestigial. Worth resolving before the next deployment attempt.

---

## 3. Specific blockers

### 3.1 `k8s/` has no API/web workload

Only Postgres, Redis, the backup CronJob, Traefik routing and the ArgoCD
Application are present. The Kubernetes path cannot run the application as it
stands; Docker Compose is the only complete deployment path today.

### 3.2 `backup-azure-secret` — the CronJob cannot start without it

`k8s/postgres-backup-cronjob.yaml` reads four keys from `backup-azure-secret`.
Two of them are **not** marked `optional`:

```yaml
                - name: AZURE_STORAGE_ACCOUNT     # line 91
                  valueFrom:
                    secretKeyRef:
                      name: backup-azure-secret
                      key: AZURE_STORAGE_ACCOUNT
                - name: AZURE_STORAGE_CONTAINER   # line 96
```

`AZURE_STORAGE_KEY` and `AZURE_STORAGE_SAS_TOKEN` are `optional: true`.

If `backup-azure-secret` does not exist, the pod never starts — kubelet reports
`CreateContainerConfigError` and the CronJob (`schedule: "0 2 * * *"`) fails
silently every night. Nothing defines this Secret in `k8s/`.

Two acceptable resolutions, **neither applied here** — this needs an owner's
decision:

1. **Create it** via `scripts/bootstrap-secrets.sh` (supported today) once the
   Azure storage account and container actually exist.
2. **Suspend the CronJob** until then, by adding `suspend: true` to its spec, so
   the failure is explicit rather than a nightly crash loop.

Do not invent a placeholder value for this Secret: a backup job that "runs" with
a bogus storage key produces the appearance of backups and no backups.

### 3.3 The Ansible path is a stub

`infra/ansible/` contains only:

```
infra/ansible/ansible.cfg
infra/ansible/templates/k8s-secrets.yaml.j2
infra/ansible/vars/vault.example.yml
```

There is **no playbook and no inventory** — `ansible.cfg` points at
`inventory.ini`, which does not exist. Nothing renders the template. It is a
schema definition, not a working deployment mechanism. Earlier notes in this
repository describing Secrets as "rendered by Ansible from Vault" were wrong.

---

## 4. Target approach (once a real cluster exists)

Both options below put the Secret back under GitOps control, so ArgoCD manages
the full desired state again and `prune`/`selfHeal` stop being hazards. Pick one.

### Option A — Sealed Secrets (Bitnami)

Commit a `SealedSecret` CRD encrypted with the cluster's public key; an
in-cluster controller decrypts it into a real `Secret`.

- **Prerequisites:** install the controller; `kubeseal` on each operator's
  machine; **back up the controller's sealing key** — lose it and every sealed
  value in git becomes undecryptable.
- **Trade-offs:** lowest setup cost and fits the existing "ArgoCD syncs `k8s/`"
  model unchanged. Ciphertext is cluster-specific, so a new cluster means
  re-sealing everything. Rotation still means a commit.

### Option B — External Secrets Operator + Azure Key Vault

Commit only an `ExternalSecret` pointing at a secret in Key Vault; the operator
materialises the `Secret` in-cluster.

- **Prerequisites:** an Azure Key Vault; workload identity or a service
  principal for the operator; the ESO controller.
- **Trade-offs:** no ciphertext in git at all, rotation happens in Key Vault
  without touching the repository, and it aligns with the Azure Blob Storage
  already used for backups. Higher setup cost and an extra runtime dependency —
  if Key Vault or the operator is down, Secrets do not refresh.

**Recommendation:** Option A to get GitOps coverage back quickly; revisit
Option B when the Azure footprint grows beyond backup storage.

Not recommended: SOPS + `ksops`, which requires a custom ArgoCD config
management plugin — more moving parts than this team needs.

---

## 5. Pre-deployment checklist

Before pointing any environment holding real data at this repository:

- [ ] No `kind: Secret` with a literal value tracked under `k8s/` —
      `git grep -n "kind: Secret" -- k8s/` returns nothing. (A plain `grep`
      will also match the gitignored local `k8s/postgres-secret.yaml`.)
- [ ] Database password rotated away from `password123` and from anything else
      that has ever been committed (§2.1).
- [ ] `JWT_SECRET` regenerated from a CSPRNG, ≥ 32 characters
      (`openssl rand -base64 48`).
- [ ] `apps/server/.env.production` exists on the VM, contains no `REPLACE_ME`,
      and is not in git (`git check-ignore apps/server/.env.production`).
- [ ] `scripts/bootstrap-secrets.sh` run against the target namespace; verify
      with `kubectl get secret -n <ns>` — names only, never `-o yaml`.
- [ ] `backup-azure-secret` either created or the CronJob suspended (§3.2).
- [ ] An API workload exists under `k8s/`, or the Kubernetes path is explicitly
      declared out of scope for this release (§3.1).
- [ ] ArgoCD `prune: true` reviewed against what is already live — pruning a
      Secret that ArgoCD previously tracked will delete it from the cluster.
- [ ] A restore from backup has been rehearsed with the rotated credentials.

---

## 6. Follow-ups (not implemented)

| Item | Owner | Notes |
| --- | --- | --- |
| Make Gitleaks blocking in CI; narrow the `doc/.*` allowlist | DevOps | `Jenkinsfile:58` drops `\|\| true` |
| Decide `backup-azure-secret`: create vs suspend CronJob | DevOps | §3.2 |
| Finish or remove the Ansible path (playbook + inventory) | Infra owner | §3.3 — the template is useful as a schema either way |
| Resolve `app-secrets` (missing consumer or vestigial) | Backend | §2.4 |
| Rotate every credential that appeared in git history | DevOps | §2.1 |
| Adopt Sealed Secrets or ESO | DevOps | §4 |
