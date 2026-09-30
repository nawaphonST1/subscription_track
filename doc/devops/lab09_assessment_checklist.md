# Lab 09 Assessment Checklist: Dynamic Agents, Pipeline Metrics & SLO Alerting

| # | Requirement | Status | Deliverable / Implementation Reference |
|---|-------------|:------:|-----------------------------------------|
| 1 | **Dynamic Kubernetes Pod Agent** |  | [Jenkinsfile](file:///c:/Users/Devasipason/Desktop/subject/moblie%20app/subscription_track/Jenkinsfile#L2-L17) (`agent { kubernetes { yaml ... } }`) |
| 2 | **Ephemeral Pod Lifecycle** |  | Pod creates on build start and terminates on completion (`kubectl get pods -w`) |
| 3 | **Jenkins Prometheus Metrics Plugin** |  | `<jenkins-url>/prometheus` exposing queue, executor, and latency metrics |
| 4 | **Prometheus Scrape Target & Config** |  | [infra/monitoring/prometheus.yml](file:///c:/Users/Devasipason/Desktop/subject/moblie%20app/subscription_track/infra/monitoring/prometheus.yml) |
| 5 | **Grafana Health Dashboard (3 Panels)** |  | [infra/monitoring/grafana-jenkins-dashboard.json](file:///c:/Users/Devasipason/Desktop/subject/moblie%20app/subscription_track/infra/monitoring/grafana-jenkins-dashboard.json) |
| 6 | **Pipeline SLO Definition** |  | 95% builds complete under 6 minutes over rolling 7 days |
| 7 | **Prometheus Queue Backlog Alert Rule** |  | [infra/monitoring/jenkins-slo-alerts.yml](file:///c:/Users/Devasipason/Desktop/subject/moblie%20app/subscription_track/infra/monitoring/jenkins-slo-alerts.yml) (`JenkinsQueueBacklog`) |
| 8 | **Capacity Saturation & Alert Trigger** |  | 10 concurrent builds vs 2-pod cap triggering backlog alert |
| 9 | **Capacity Recovery & Alert Clear** |  | Increased pod cap draining backlog and clearing alert |

---

## Deliverables Summary
1. **Jenkinsfile Diff**: Replaced static Docker agent with Kubernetes pod template.
2. **Grafana Dashboard JSON**: Exported 3-panel dashboard ([grafana-jenkins-dashboard.json](file:///c:/Users/Devasipason/Desktop/subject/moblie%20app/subscription_track/infra/monitoring/grafana-jenkins-dashboard.json)).
3. **Alerting Rules**: Defined `JenkinsQueueBacklog` alert rule ([jenkins-slo-alerts.yml](file:///c:/Users/Devasipason/Desktop/subject/moblie%20app/subscription_track/infra/monitoring/jenkins-slo-alerts.yml)).
