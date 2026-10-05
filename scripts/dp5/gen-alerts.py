#!/usr/bin/env python3
"""Generate the DP-504 Grafana alert rules.

Hand-written, a Grafana provisioned alert rule is ~40 lines of query/expression
boilerplate for one threshold. Generating them keeps the part that matters —
expression, threshold, for, severity, and the two states — on one line each,
and makes it structurally impossible to forget noDataState/execErrState on a
rule, which is the failure this project is most exposed to: the monitoring VM
sits behind a university captive portal whose session expires daily.

    python3 scripts/dp5/gen-alerts.py
"""

from __future__ import annotations

import pathlib

OUT = pathlib.Path(__file__).resolve().parents[2] / "infra/monitoring/grafana/provisioning/alerting"

FOLDER = "DP-5 Alerts"
DS = "prometheus"


def rule(uid, title, expr, threshold, for_, severity, summary, description,
         no_data="OK", exec_err="Error", op="gt"):
    """One alert rule: an instant PromQL query (A) and a threshold on it (B).

    `op` is the comparison the threshold expression applies to A: "gt" for the
    usual "above this is bad", "lt" for the health signals that are 1 when
    healthy and 0 when not (probe_success, up, worker_queue_scrape_ok), where
    the alert has to be "below 1".
    """
    assert op in ("gt", "lt"), op
    cond = {
        "refId": "B",
        "datasourceUid": "__expr__",
        "model": {
            "refId": "B",
            "type": "threshold",
            "datasource": {"type": "__expr__", "uid": "__expr__"},
            "expression": "A",
            "conditions": [{
                "type": "query",
                "evaluator": {"type": op, "params": [threshold]},
                "operator": {"type": "and"},
                "query": {"params": ["B"]},
                "reducer": {"type": "last"},
            }],
            "intervalMs": 1000,
            "maxDataPoints": 43200,
        },
    }
    return {
        "uid": uid,
        "title": title,
        "condition": "B",
        "for": for_,
        "noDataState": no_data,
        "execErrState": exec_err,
        "labels": {"severity": severity},
        "annotations": {"summary": summary, "description": description},
        "data": [
            {
                "refId": "A",
                "relativeTimeRange": {"from": 600, "to": 0},
                "datasourceUid": DS,
                "model": {
                    "refId": "A",
                    "datasource": {"type": "prometheus", "uid": DS},
                    "expr": expr,
                    "instant": True,
                    "range": False,
                    "editorMode": "code",
                    "intervalMs": 1000,
                    "maxDataPoints": 43200,
                },
            },
            cond,
        ],
    }


CAPTIVE = ("If prod-ingestion-halt is firing at the same time, suspect the monitoring VM's "
           "captive-portal session before suspecting production.")

GROUPS = [
    ("api", "1m", [
        rule("dp5-api-down", "API down",
             'min(probe_success{job="blackbox-http"})', 1, "2m", "critical",
             "The blackbox probe of production has been failing for 2 minutes",
             "probe_success is 0. The probe runs from the monitoring VM, so a lost "
             "captive-portal session makes production look down when it is not. " + CAPTIVE,
             no_data="OK", op="lt"),

        rule("dp5-api-5xx", "5xx ratio above 5%",
             'sum(rate(http_requests_total{status=~"5.."}[5m])) / '
             'clamp_min(sum(rate(http_requests_total[5m])), 0.0001) * 100',
             5, "5m", "critical",
             "More than 5% of requests are failing with a 5xx",
             "Measured over a 5-minute window. status=\"aborted\" is a string and never "
             "matches 5.., so client disconnects do not inflate this; watch the Aborted "
             "requests panel for those. No traffic means no data, which is deliberately not "
             "an alert."),

        rule("dp5-api-latency", "p95 latency above 1s",
             'histogram_quantile(0.95, sum by (le) (rate(http_request_duration_seconds_bucket[5m])))',
             1, "5m", "warning",
             "p95 request latency has been above 1s for 5 minutes",
             "Interpolated from the histogram; the top finite bucket is 10s. On a burstable "
             "B2als v2 this is also what exhausted CPU credits look like — check the CPU "
             "panel before blaming the code."),
    ]),

    ("host", "1m", [
        rule("dp5-host-disk", "Disk above 85%",
             '100 - (min(node_filesystem_avail_bytes{mountpoint="/", fstype!~"tmpfs|overlay|squashfs|ramfs"} '
             '/ node_filesystem_size_bytes{mountpoint="/", fstype!~"tmpfs|overlay|squashfs|ramfs"}) * 100)',
             85, "10m", "warning",
             "Root filesystem above 85% on at least one monitored host",
             "Covers both VMs. On the monitoring VM, Prometheus is capped by "
             "--storage.tsdb.retention.size=3GB and Loki by a 7-day retention, so a rise "
             "here is usually container logs or images, not the TSDB."),

        rule("dp5-host-ram", "Available RAM below 10%",
             '100 - (min(node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100)',
             90, "10m", "warning",
             "Less than 10% of RAM is available on at least one monitored host",
             "Expressed as used% > 90 so the threshold reads the same way as the others. "
             "Production is a 4 GiB VM running the app, the database, Redis and five agent "
             "containers."),

        rule("dp5-host-cpu", "CPU above 90%",
             '100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)',
             90, "10m", "warning",
             "CPU above 90% for 10 minutes on at least one monitored host",
             "On the production B2als v2 this burns CPU credits; sustained load will be "
             "throttled to the 2 vCPU baseline rather than failing outright."),

        rule("dp5-container-restarts", "Container restarting repeatedly",
             'max(changes(container_start_time_seconds{name!=""}[10m]))',
             3, "0s", "warning",
             "A container restarted more than 3 times in 10 minutes",
             "cAdvisor has no restart counter, so this counts changes of the container start "
             "timestamp. `for` is 0s on purpose: the 10-minute range already is the window.",
             ),
    ]),

    ("datastores", "1m", [
        rule("dp5-store-exporter-down", "Postgres or Redis unreachable",
             'min(up{job=~"postgres|redis"})', 1, "2m", "critical",
             "The Postgres or Redis exporter has been down for 2 minutes",
             "`up` is synthesised by Alloy's own scrape on the production VM and pushed in, "
             "so this reports the exporter's view of the datastore, not the tunnel. " + CAPTIVE,
             no_data="OK", op="lt"),

        rule("dp5-queue-scrape-failing", "Queue scrape failing",
             'min(worker_queue_scrape_ok)', 1, "5m", "warning",
             "The worker cannot read the BullMQ queue (usually Redis)",
             "worker_queue_scrape_ok is 0. The worker_queue_jobs series are dropped rather "
             "than frozen at their last values, so the queue panels go blank instead of "
             "showing a reassuring empty queue.",
             no_data="OK", op="lt"),

        rule("dp5-bullmq-failures", "BullMQ job failures rising",
             'sum(increase(worker_jobs_processed_total{result="failure"}[10m]))',
             5, "0s", "warning",
             "More than 5 renewal-reminder jobs failed in the last 10 minutes",
             "Uses the counter, not worker_queue_jobs{state=\"failed\"} — that gauge plateaus "
             "at the 500 retained records BullMQ keeps and stops moving."),
    ]),

    ("pipeline", "1m", [
        rule("dp5-prod-ingestion-halt", "No data arriving from production",
             'count(up{site="prod"} == 1)', 1, "2m", "warning",
             "Production has not pushed any samples for about 5 minutes",
             "DISTINCT from 'API down'. Production pushes through a reverse SSH tunnel that "
             "only exists while the monitoring VM's captive-portal session is alive, so this "
             "fires on a dead session, a dead tunnel, a dead Alloy or a dead VM — and on none "
             "of those is the public site necessarily affected. Detection takes roughly 5 "
             "minutes of staleness (Prometheus' lookback) plus the 2-minute pending period. "
             "noDataState is Alerting here and only here: an empty result IS the signal.",
             no_data="Alerting", exec_err="Error", op="lt"),
    ]),
]


def y(value, indent=0):
    """Minimal YAML emitter — deterministic output, no dependency on PyYAML."""
    pad = "  " * indent
    if isinstance(value, dict):
        out = []
        for k, v in value.items():
            if isinstance(v, (dict, list)) and v:
                out.append(f"{pad}{k}:")
                out.append(y(v, indent + 1))
            elif isinstance(v, (dict, list)):
                out.append(f"{pad}{k}: {'{}' if isinstance(v, dict) else '[]'}")
            else:
                out.append(f"{pad}{k}: {scalar(v)}")
        return "\n".join(out)
    if isinstance(value, list):
        out = []
        for item in value:
            if isinstance(item, (dict, list)):
                body = y(item, indent + 1)
                out.append(f"{pad}- " + body[len(pad) + 2:])
            else:
                out.append(f"{pad}- {scalar(item)}")
        return "\n".join(out)
    return f"{pad}{scalar(value)}"


def scalar(v):
    if isinstance(v, bool):
        return "true" if v else "false"
    if v is None:
        return "null"
    if isinstance(v, (int, float)):
        return str(v)
    s = str(v)
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


HEADER_RULES = """# DP-504 — Grafana alert rules, provisioned from this file.
#
# Generated by scripts/dp5/gen-alerts.py — edit that, not this.
#
# Grafana 12.1.x file provisioning. Rules provisioned this way are read-only in
# the UI, which is the point: the file in git is the only source of truth.
#
# EVERY rule sets noDataState and execErrState explicitly. The reason is this
# project's network: the monitoring VM lives behind a university captive portal
# whose session expires about once a day, and production pushes to it through a
# reverse SSH tunnel that dies with that session. Under Grafana's default
# noDataState (NoData -> alerting), every single rule would fire every morning.
#
#   noDataState: OK        - absence of data is not evidence of a problem. No
#                            traffic produces no rate(); a dead tunnel produces
#                            no prod series. The one rule below whose job is to
#                            notice that absence covers both cases.
#   noDataState: Alerting  - only dp5-prod-ingestion-halt, where an empty query
#                            result IS the condition being detected.
#   execErrState: Error    - a query error means a broken rule, not a network
#                            blip: Grafana and Prometheus are the same host and
#                            the datasource is reachable over the Compose
#                            network. Surfacing it as an error is correct.
#
# See docs/dp5-loop-verification.md for the tunnel-drop vs real-outage table.
"""

HEADER_CP = """# DP-504 — contact point and notification policy.
#
# Generated by scripts/dp5/gen-alerts.py — edit that, not this.
#
# NO SECRET IN THIS FILE. $DISCORD_WEBHOOK_URL is interpolated by Grafana at
# startup from the container's environment, which comes from
# infra/monitoring/.env (git-ignored). Grafana's provisioning uses plain
# $VAR / ${VAR} interpolation -- NOT the $__env{VAR} form used by dashboard
# JSON -- verified against the Grafana 12.1.x provisioning documentation.
#
# If DISCORD_WEBHOOK_URL is unset, docker compose refuses to start with a
# message naming the variable, rather than Grafana starting up with a contact
# point that silently delivers nowhere.
"""


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)

    groups = [{
        "orgId": 1,
        "name": name,
        "folder": FOLDER,
        "interval": interval,
        "rules": rules,
    } for name, interval, rules in GROUPS]

    rules_doc = {"apiVersion": 1, "groups": groups}
    (OUT / "alert-rules.yaml").write_text(
        HEADER_RULES + y(rules_doc) + "\n", encoding="utf-8")

    cp_doc = {
        "apiVersion": 1,
        "contactPoints": [{
            "orgId": 1,
            "name": "discord",
            "receivers": [{
                "uid": "dp5-discord",
                "type": "discord",
                "disableResolveMessage": False,
                "settings": {
                    "url": "$DISCORD_WEBHOOK_URL",
                    "title": "{{ .CommonLabels.severity | toUpper }} — {{ .CommonLabels.alertname }}",
                    "message": "{{ range .Alerts }}{{ .Annotations.summary }}\n{{ .Annotations.description }}\n{{ end }}",
                },
            }],
        }],
        "policies": [{
            "orgId": 1,
            "receiver": "discord",
            "group_by": ["alertname", "severity"],
            "group_wait": "30s",
            "group_interval": "5m",
            "repeat_interval": "4h",
        }],
    }
    (OUT / "contact-points.yaml").write_text(
        HEADER_CP + y(cp_doc) + "\n", encoding="utf-8")

    total = sum(len(g["rules"]) for g in groups)
    print(f"wrote alert-rules.yaml ({len(groups)} groups, {total} rules)")
    print("wrote contact-points.yaml (1 contact point, 1 policy)")


if __name__ == "__main__":
    main()
