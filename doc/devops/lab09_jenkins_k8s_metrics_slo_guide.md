# Lab 09 — Jenkins on Kubernetes: Dynamic Agents & Pipeline Metrics Guide

## 1. Objectives & Overview
- **Dynamic Kubernetes Agents**: Replace long-lived static build agents with ephemeral Kubernetes Pods scheduled on-demand and terminated immediately upon pipeline completion.
- **Prometheus Metrics Plugin**: Expose native Jenkins CI/CD queue, executor, build latency, and success/failure counters at `/prometheus`.
- **Grafana Health Dashboard**: Visualize pipeline reliability via 3 dedicated panels (Build Success Rate, p95 Build Duration, Current Queue Length).
- **SRE SLO Definition & Alerting**: Define a pipeline-level Service Level Objective (95% builds < 6 mins) and an alerting rule for build queue backlog (`JenkinsQueueBacklog`).
- **Capacity Saturation & Recovery**: Saturate the Jenkins cloud with 10 concurrent jobs against a 2-pod limit to trigger the alert, then increase concurrency to observe recovery.

---

## 2. Dynamic Kubernetes Agent Configuration

### 2.1 Pod Template in `Jenkinsfile`
The static `agent { docker { ... } }` is replaced with the Declarative Kubernetes pod definition:

```groovy
agent {
    kubernetes {
        yaml '''
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: node
    image: node:20-alpine
    command: ['cat']
    tty: true
'''
    }
}
```

### 2.2 Verifying Pod Lifecycle in Kubernetes
Watch dynamic build pods spin up and terminate in real time:
```bash
kubectl get pods -w
```
Expected output:
```text
NAME                                READY   STATUS              RESTARTS   AGE
taskflow-api-12-x8k9l-p941q-2mfd0   0/2     ContainerCreating   0          2s
taskflow-api-12-x8k9l-p941q-2mfd0   2/2     Running             0          5s
taskflow-api-12-x8k9l-p941q-2mfd0   2/2     Terminating         0          48s
```

---

## 3. Prometheus Metrics & Configuration

### 3.1 Enabling the Prometheus Plugin in Jenkins
1. Navigate to **Manage Jenkins** > **Plugins** > **Available plugins**.
2. Search and install **Prometheus metrics**.
3. Verify the metrics endpoint by visiting:
   ```http
   http://<jenkins-url>/prometheus
   ```

### 3.2 Prometheus Configuration (`infra/monitoring/prometheus.yml`)
```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "/etc/prometheus/jenkins-slo-alerts.yml"

scrape_configs:
  - job_name: "jenkins"
    metrics_path: "/prometheus"
    scrape_interval: 10s
    static_configs:
      - targets: ["jenkins:8080", "host.docker.internal:8080"]
        labels:
          service: "jenkins-ci"
          environment: "lab09"
```

---

## 4. Pipeline SLO & Prometheus Alerting Rules

### 4.1 SLO Definition
- **SLO Target**: 95% of pipeline runs finish in under 6 minutes (360 seconds) over a rolling 7-day window.
- **Alert Indicator**: Build queue wait time exceeds 2 minutes for 5 continuous minutes (`JenkinsQueueBacklog`).

### 4.2 Alert Rule (`infra/monitoring/jenkins-slo-alerts.yml`)
```yaml
groups:
  - name: jenkins-slo
    rules:
      - alert: JenkinsQueueBacklog
        expr: jenkins_queue_size_value > 0 and avg_over_time(jenkins_queue_size_value[5m]) > 0
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Jenkins build queue backlog exceeds 2 minutes"
          description: "Jenkins build queue has had queued jobs waiting with a 5m rolling average > 0 for more than 5 minutes."
```

---

## 5. Grafana Dashboard Panels
Import `infra/monitoring/grafana-jenkins-dashboard.json` into Grafana:

| Panel # | Panel Name | Metric / PromQL Query | Purpose |
| :--- | :--- | :--- | :--- |
| **Panel 1** | **Build Success Rate** | `(sum(jenkins_runs_success_build_count) / sum(jenkins_runs_total_build_count)) * 100` | Tracks % of successful CI builds vs total runs |
| **Panel 2** | **p95 Build Duration** | `jenkins_builds_duration_milliseconds_summary{quantile="0.95"} / 1000` | Latency gauge against 6m (360s) SLO threshold |
| **Panel 3** | **Current Queue Length**| `jenkins_queue_size_value` | Real-time pending builds waiting for pod capacity |

---

## 6. Saturation Load Test & Recovery Procedure

1. **Set Cloud Concurrency Limit**:
   - Go to **Manage Jenkins** > **Clouds** > **Kubernetes**.
   - Set **Concurrency limit** / **Container Cap** to `2`.
2. **Trigger 10 Concurrent Builds**:
   - Run 10 pipeline builds in rapid succession.
   - Observe in Jenkins UI that only 2 pods run concurrently while 8 builds sit in the build queue.
3. **Confirm Alert Firing**:
   - Open Prometheus Alerts tab (`http://localhost:9090/alerts`).
   - Observe `JenkinsQueueBacklog` entering `Pending` state and transitioning to `Firing` after 5 minutes.
4. **Scale Cloud Concurrency & Clear Backlog**:
   - Increase Kubernetes cloud **Container Cap** to `10` (or higher).
   - Dynamic pods spawn concurrently, the queue drops to `0`, and the alert status clears back to `Green / Inactive`.
