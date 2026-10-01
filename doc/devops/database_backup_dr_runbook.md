# 🗄️ Database Backup & Disaster Recovery (DR) Runbook

**Service**: Subscription Track PostgreSQL Database  
**Workload**: Kubernetes CronJob `postgres-backup`  
**Storage Tier**: S3-Compatible Object Storage (AWS S3 / MinIO / LocalStack)  

---

## 1. Overview & Service Level Objectives

- **Recovery Point Objective (RPO)**: 24 hours (Automated daily snapshot at 02:00 UTC).
- **Recovery Time Objective (RTO)**: $< 15$ minutes (Automated restore via `scripts/restore-postgres.sh`).
- **Data Protection**: AES-256 encryption at rest, TLS 1.3 in transit, SHA256 integrity checksums accompanying each backup archive.

---

## 2. Automated Backup Architecture

```
CronJob (0 2 * * *)
  │
  ├─> 1. pg_dump -Fc (Custom compressed format)
  │
  ├─> 2. sha256sum generation (*.dump.gz.sha256)
  │
  └─> 3. aws s3 cp ───► s3://${S3_BACKUP_BUCKET}/postgres/subtracker_db_backup_<timestamp>.dump.gz
```

---

## 3. Manual Backup Trigger (On-Demand)

To trigger an immediate snapshot before a major database migration:

```bash
kubectl create job --from=cronjob/postgres-backup manual-backup-$(date +%s)
kubectl logs -f job/manual-backup-*
```

---

## 4. Disaster Recovery (DR) Restoration Procedure

In the event of database node corruption or catastrophic data loss:

### Step 1: Scale down application pods to prevent conflicting write operations
```bash
kubectl scale deployment taskflow --replicas=0
```

### Step 2: Execute Disaster Recovery Restore Script
```bash
export DB_HOST="postgres"
export DB_NAME="subtracker_db"
export DB_USER="postgres"
export DB_PASSWORD="password123"
export S3_BACKUP_BUCKET="subtracker-backups"

# Restore the latest backup:
./scripts/restore-postgres.sh latest

# Or restore a specific timestamp:
./scripts/restore-postgres.sh subtracker_db_backup_20261001_020000.dump.gz
```

### Step 3: Run Database Health Check & Re-enable Application Traffic
```bash
# Verify database responsiveness:
kubectl exec -it postgres-0 -- pg_isready -U postgres -d subtracker_db

# Restore application replicas:
kubectl scale deployment taskflow --replicas=2
```
