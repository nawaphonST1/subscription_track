# Lab 07 Assessment Checklist & Deliverables Guide

This document maps all assessment criteria for **Lab 07: Containers, Image Scanning & Deployment** directly to actionable verification steps and deliverable artifacts.

---

## 1. Deliverables Checklist

| # | Deliverable | Location / Command | Status |
|---|---|---|---|
| 1 | `kubectl get svc taskflow -o yaml` before and after successful switch | Output captured in terminal / CI logs | Ready to execute |
| 2 | Trivy SARIF report for one image build | Archived in Jenkins artifacts as `trivy-results.sarif` | Configured |
| 3 | Console log of failed deploy showing automatic rollback | Jenkins build console output showing rollback hook | Documented |

---

## 2. Assessment Criteria Mapping

### Criterion 1: Images are immutably tagged and pushed correctly (never `latest`)
- **Pipeline Implementation**:
  - Image is tagged with `${env.GIT_COMMIT.take(7)}` (e.g. `taskflow-api:a1b2c3d`).
  - Never uses `latest` tag.
  - Pushed to local registry (`${REGISTRY}/taskflow-api:${shortCommit}`).
- **Verification Evidence**:
  - Check Jenkins console output in stage `Build Image`:
    ```text
    ==> [taskflow-api] Building versioned Docker image: taskflow-api:a1b2c3d (never latest)...
    ```

---

### Criterion 2: Trivy gate genuinely blocks a vulnerable image
- **Pipeline Implementation**:
  - Command: `trivy image --exit-code 1 --severity HIGH,CRITICAL --format sarif --output trivy-results.sarif ${IMAGE_TAG}`
  - If any HIGH or CRITICAL vulnerability is detected, Trivy exits with code 1 and halts the pipeline before deployment.
  - SARIF report is saved and archived in `post.always`.
- **Verification Evidence**:
  - Green run: Clean scan passes with 0 blocking CVEs, emits `trivy-results.sarif`.
  - Red run: Vulnerable base image triggers exit code 1, stage fails, `trivy-results.sarif` is archived.

---

### Criterion 3: Blue/green switch works and is verified by smoke test first
- **Pipeline Implementation**:
  - Query current active color: `kubectl get svc taskflow -o jsonpath='{.spec.selector.color}'`.
  - Determine inactive target: `(current == 'blue') ? 'green' : 'blue'`.
  - Deploy new image to inactive deployment: `deployment/taskflow-${next}`.
  - Wait for rollout completion: `kubectl rollout status deployment/taskflow-${next}`.
  - **Smoke test pod**: `kubectl run smoke-${BUILD_NUMBER} --rm -i --restart=Never --image=curlimages/curl -- curl -sf http://taskflow-${next}:8080/health`.
  - Switch traffic only after smoke test succeeds: `kubectl patch svc taskflow -p '{"spec":{"selector":{"color":"${next}"}}}'`.
- **Verification Evidence**:
  - Service YAML shows selector before switch: `color: blue`.
  - Service YAML shows selector after switch: `color: green`.

---

### Criterion 4: Automatic rollback on failure is demonstrated, not just coded
- **Pipeline Implementation**:
  - Handled in `post.failure` hook.
  - If rollout or smoke test fails before traffic switch completes, `post.failure` executes:
    `kubectl patch svc taskflow -p '{"spec":{"selector":{"color":"${env.PREV_COLOR}"}}}'`.
- **Verification Evidence**:
  - Jenkins build console shows failure at `Blue/Green Deploy`.
  - Console shows automated rollback:
    ```text
    ⚠️ Blue/Green deployment or smoke test failed! Executing automated rollback to blue...
    🔄 Service taskflow selector preserved/rolled back to: blue
    ```
  - `kubectl get svc taskflow -o yaml` confirms the service remains on the working color.
