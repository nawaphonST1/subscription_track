# 🛡️ Developer Security Baseline: Gitleaks Pre-Commit Hooks Guide

## 1. Overview & Objective
In accordance with the **Shift-Left Security** paradigm, sensitive assets—such as API tokens, database credentials, and cryptographic keys—must be intercepted and prevented from entering the version control system before they are committed locally, well before reaching remote branches or CI pipelines.

---

## 2. Architecture & Components

```
Developer Workspace
  │
  ├─> git add <file>
  │
  ├─> git commit
  │      │
  │      ▼
  │   [.githooks/pre-commit]
  │      │
  │      ├─> `gitleaks protect --staged --verbose --config .gitleaks.toml`
  │      │
  │      ├── Secrets Detected? ───► [BLOCK COMMIT (Exit 1)] ───► Developer notified
  │      │
  │      └── Clean Baseline   ───► [ALLOW COMMIT (Exit 0)] ───► Commit recorded
```

- **Configuration File**: [`.gitleaks.toml`](file:///c:/Users/Devasipason/Desktop/subject/moblie%20app/subscription_track/.gitleaks.toml)
- **Hook Script**: [`.githooks/pre-commit`](file:///c:/Users/Devasipason/Desktop/subject/moblie%20app/subscription_track/.githooks/pre-commit)

---

## 3. Quick Setup Instructions

### On Windows (PowerShell)
```powershell
.\scripts\setup-pre-commit.ps1
```

### On macOS / Linux
```bash
./scripts/setup-pre-commit.sh
```

---

## 4. Manual Verification
```bash
gitleaks protect --staged --verbose --config .gitleaks.toml
```
