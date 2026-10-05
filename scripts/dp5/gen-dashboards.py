#!/usr/bin/env python3
"""Generate the DP-502 Grafana dashboards.

Why a generator and not four hand-written JSON files: a Grafana dashboard is
~90% boilerplate per panel. Writing it once here keeps the PromQL/LogQL — the
only part a reviewer actually has to read — on one line per panel, and makes a
sweeping change (datasource uid, refresh, schemaVersion) a one-line edit
instead of four files of find-and-replace.

Every metric name used below comes from apps/server/docs/metrics.md (the app
contract) or from the exporters pinned in
infra/monitoring/prod-agent/docker-compose.yml. Nothing is referenced from
memory; scripts/dp5/check-dashboards.py re-checks the names against an
allowlist built from those two sources.

Re-runnable: overwrites its outputs, creates nothing else.

    python3 scripts/dp5/gen-dashboards.py
"""

from __future__ import annotations

import json
import pathlib

OUT = pathlib.Path(__file__).resolve().parents[2] / "infra/monitoring/grafana/dashboards"

PROM = {"type": "prometheus", "uid": "prometheus"}
LOKI = {"type": "loki", "uid": "loki"}

# Grafana 12.1.1 reads this happily; it is also the version the already-deployed
# host-overview.json uses, so all five dashboards stay on one schema.
SCHEMA_VERSION = 39


def target(expr: str, legend: str = "", ds=PROM, ref: str = "A", **extra) -> dict:
    t = {"refId": ref, "datasource": ds, "expr": expr}
    if legend:
        t["legendFormat"] = legend
    t.update(extra)
    return t


def panel(pid, ptype, title, gridPos, targets, desc="", unit=None, ds=PROM, **opts):
    p = {
        "id": pid,
        "type": ptype,
        "title": title,
        "description": desc,
        "gridPos": gridPos,
        "datasource": ds,
        "targets": targets,
    }
    defaults = {"custom": {"fillOpacity": 10, "lineWidth": 1}}
    if unit:
        defaults["unit"] = unit
    for key in ("min", "max", "decimals", "thresholds", "noValue"):
        if key in opts:
            defaults[key] = opts.pop(key)
    p["fieldConfig"] = {"defaults": defaults, "overrides": opts.pop("overrides", [])}
    if opts:
        p["options"] = opts
    return p


def grid(x, y, w=12, h=8):
    return {"h": h, "w": w, "x": x, "y": y}


def dashboard(uid, title, desc, tags, panels, templating=None, refresh="30s", time_from="now-6h"):
    return {
        "uid": uid,
        "title": title,
        "description": desc,
        "tags": tags,
        "timezone": "browser",
        "editable": False,
        "schemaVersion": SCHEMA_VERSION,
        "version": 1,
        "refresh": refresh,
        "time": {"from": time_from, "to": "now"},
        "templating": {"list": templating or []},
        "panels": panels,
    }


def prom_var(name, label, metric, multi=True, all_value=True, ds=PROM):
    return {
        "name": name,
        "label": label,
        "type": "query",
        "datasource": ds,
        "query": {"qryType": 1, "query": f"label_values({metric}, {name})", "refId": name},
        "definition": f"label_values({metric}, {name})",
        "refresh": 1,
        "includeAll": all_value,
        "multi": multi,
        "allValue": ".*",
        "current": {"text": "All", "value": "$__all"},
        "sort": 1,
    }


def textbox_var(name, label, default=""):
    return {
        "name": name,
        "label": label,
        "type": "textbox",
        "query": default,
        "current": {"text": default, "value": default},
        "options": [],
    }


# ---------------------------------------------------------------------------
# 1. System & containers
# ---------------------------------------------------------------------------
# `site` separates the two hosts: Alloy stamps site="prod" on everything it
# pushes (external_labels in config.alloy); the monitoring VM's own scrapes
# carry site="monitoring-vm" (prometheus.yml global.external_labels).
system = dashboard(
    "dp5-system-containers",
    "System & Containers",
    "Host and per-container health for whichever site is selected. Node metrics come from node_exporter, container metrics from cAdvisor (--docker_only, container labels off).",
    ["dp-5", "dp-502", "system"],
    [
        panel(1, "timeseries", "CPU used", grid(0, 0), [
            target('100 - (avg by (site, instance) (rate(node_cpu_seconds_total{mode="idle", site=~"$site"}[5m])) * 100)', "{{site}} {{instance}}"),
        ], "100% minus idle, averaged over all cores.", unit="percent", min=0, max=100),

        panel(2, "timeseries", "Memory used", grid(12, 0), [
            target('node_memory_MemTotal_bytes{site=~"$site"} - node_memory_MemAvailable_bytes{site=~"$site"}', "{{site}} used"),
            target('node_memory_MemTotal_bytes{site=~"$site"}', "{{site}} total", ref="B"),
        ], "Used = total - available, which is what the RAM alert also watches.", unit="bytes", min=0),

        panel(3, "timeseries", "Root filesystem used", grid(0, 8), [
            target('100 - (node_filesystem_avail_bytes{site=~"$site", mountpoint="/", fstype!~"tmpfs|overlay|squashfs|ramfs"} / node_filesystem_size_bytes{site=~"$site", mountpoint="/", fstype!~"tmpfs|overlay|squashfs|ramfs"} * 100)', "{{site}} {{instance}} /"),
        ], "The disk alert fires at 85% of this.", unit="percent", min=0, max=100),

        panel(4, "timeseries", "Network throughput", grid(12, 8), [
            target('rate(node_network_receive_bytes_total{site=~"$site", device!~"lo|veth.*|docker.*|br-.*"}[5m])', "{{site}} {{device}} in"),
            target('rate(node_network_transmit_bytes_total{site=~"$site", device!~"lo|veth.*|docker.*|br-.*"}[5m])', "{{site}} {{device}} out", ref="B"),
        ], "On the monitoring VM node-exporter runs without host networking, so its node_network_* figures describe the container namespace, not the host (see ../docker-compose.yml).", unit="Bps"),

        panel(5, "timeseries", "Container memory vs its limit", grid(0, 16), [
            target('container_memory_working_set_bytes{site=~"$site", name!=""} / (container_spec_memory_limit_bytes{site=~"$site", name!=""} > 0) * 100', "{{name}}"),
        ], "Working set as a percentage of mem_limit. Containers started without a limit report a limit of 0 and are filtered out by `> 0` rather than dividing by zero.", unit="percent", min=0),

        panel(6, "timeseries", "Container CPU", grid(12, 16), [
            target('rate(container_cpu_usage_seconds_total{site=~"$site", name!=""}[5m]) * 100', "{{name}}"),
        ], "Percent of one core.", unit="percent", min=0),

        panel(7, "timeseries", "Container restarts (1h)", grid(0, 24), [
            target('changes(container_start_time_seconds{site=~"$site", name!=""}[1h])', "{{name}}"),
        ], "cAdvisor exports no restart counter, so restarts are counted as changes of the container start timestamp. A container that restarts more than 3 times in 10 minutes is what the restart alert looks for.", min=0),

        panel(8, "stat", "Scrape targets up", grid(12, 24), [
            target('sum by (job) (up{site=~"$site"})', "{{job}}"),
        ], "0 for a job means Prometheus/Alloy cannot reach that exporter at all.", min=0,
           reduceOptions={"calcs": ["lastNotNull"], "fields": "", "values": False}),
    ],
    templating=[prom_var("site", "Site", "node_cpu_seconds_total", multi=True)],
)

# ---------------------------------------------------------------------------
# 2. API RED
# ---------------------------------------------------------------------------
red = dashboard(
    "dp5-api-red",
    "API — Rate, Errors, Duration",
    "RED method over http_requests_total / http_request_duration_seconds. `route` is always a route template (/subscriptions/:id); unmatched requests collapse onto route=\"unmatched\" and client-aborted ones onto status=\"aborted\" — see apps/server/docs/metrics.md.",
    ["dp-5", "dp-502", "api", "red"],
    [
        panel(1, "stat", "Requests / s", grid(0, 0, 6, 4), [
            target('sum(rate(http_requests_total{site=~"$site", route=~"$route"}[5m]))', "rps"),
        ], unit="reqps", decimals=2,
           reduceOptions={"calcs": ["lastNotNull"], "fields": "", "values": False}),

        panel(2, "stat", "5xx ratio", grid(6, 0, 6, 4), [
            target('sum(rate(http_requests_total{site=~"$site", route=~"$route", status=~"5.."}[5m])) / clamp_min(sum(rate(http_requests_total{site=~"$site", route=~"$route"}[5m])), 0.0001) * 100', "5xx %"),
        ], "The critical alert fires above 5% for 5 minutes. clamp_min keeps the panel at 0 instead of NaN when there is no traffic.", unit="percent", decimals=2,
           reduceOptions={"calcs": ["lastNotNull"], "fields": "", "values": False}),

        panel(3, "stat", "4xx ratio", grid(12, 0, 6, 4), [
            target('sum(rate(http_requests_total{site=~"$site", route=~"$route", status=~"4.."}[5m])) / clamp_min(sum(rate(http_requests_total{site=~"$site", route=~"$route"}[5m])), 0.0001) * 100', "4xx %"),
        ], "Expected to be non-zero: 401 on an expired token is normal traffic.", unit="percent", decimals=2,
           reduceOptions={"calcs": ["lastNotNull"], "fields": "", "values": False}),

        panel(4, "stat", "p95 latency", grid(18, 0, 6, 4), [
            target('histogram_quantile(0.95, sum by (le) (rate(http_request_duration_seconds_bucket{site=~"$site", route=~"$route"}[5m])))', "p95"),
        ], "The warning alert fires above 1s for 5 minutes.", unit="s", decimals=3,
           reduceOptions={"calcs": ["lastNotNull"], "fields": "", "values": False}),

        panel(5, "timeseries", "Requests / s by route", grid(0, 4), [
            target('sum by (route) (rate(http_requests_total{site=~"$site", route=~"$route"}[5m]))', "{{route}}"),
        ], unit="reqps"),

        panel(6, "timeseries", "Responses by status class", grid(12, 4), [
            target('sum by (status) (rate(http_requests_total{site=~"$site", route=~"$route"}[5m]))', "{{status}}"),
        ], "status=\"aborted\" is the client hanging up mid-response: the work was done, the response was not delivered. It is a string, so it never matches 5.. .", unit="reqps"),

        panel(7, "timeseries", "Latency percentiles", grid(0, 12), [
            target('histogram_quantile(0.50, sum by (le) (rate(http_request_duration_seconds_bucket{site=~"$site", route=~"$route"}[5m])))', "p50"),
            target('histogram_quantile(0.95, sum by (le) (rate(http_request_duration_seconds_bucket{site=~"$site", route=~"$route"}[5m])))', "p95", ref="B"),
            target('histogram_quantile(0.99, sum by (le) (rate(http_request_duration_seconds_bucket{site=~"$site", route=~"$route"}[5m])))', "p99", ref="C"),
        ], "Interpolated from the histogram buckets, whose top finite bucket is 10s — anything slower is only visible as +Inf.", unit="s", min=0),

        panel(8, "timeseries", "p95 by route", grid(12, 12), [
            target('histogram_quantile(0.95, sum by (le, route) (rate(http_request_duration_seconds_bucket{site=~"$site", route=~"$route"}[5m])))', "{{route}}"),
        ], unit="s", min=0),

        panel(9, "table", "Top routes (5m)", grid(0, 20), [
            target('topk(10, sum by (route, method) (rate(http_requests_total{site=~"$site", route=~"$route"}[5m])))', "", instant=True, format="table"),
        ], "Instant query: the ten busiest route+method pairs right now.", unit="reqps"),

        panel(10, "timeseries", "Aborted requests", grid(12, 20), [
            target('sum by (route) (rate(http_requests_total{site=~"$site", route=~"$route", status="aborted"}[5m]))', "{{route}}"),
        ], "A rise here with flat 5xx means clients are timing out before the server answers — invisible on the status-class panel.", unit="reqps", min=0),
    ],
    templating=[
        prom_var("site", "Site", "http_requests_total"),
        prom_var("route", "Route", "http_requests_total"),
    ],
)

# ---------------------------------------------------------------------------
# 3. Business activity
# ---------------------------------------------------------------------------
business = dashboard(
    "dp5-business-activity",
    "Business Activity",
    "What users and the queue are actually doing: logins, subscription CRUD, active users, BullMQ renewal-reminder queue.",
    ["dp-5", "dp-502", "business"],
    [
        panel(1, "timeseries", "Logins / min by outcome", grid(0, 0), [
            target('sum by (result, method) (rate(auth_login_total{site=~"$site"}[5m])) * 60', "{{method}} {{result}}"),
        ], "method=password is POST /auth/login, method=pin is POST /users/me/pin/verify. Their failure counts are not directly comparable — the PIN path throws before the counter for an unknown user (apps/server/docs/metrics.md).", min=0),

        panel(2, "stat", "Login failure ratio (5m)", grid(12, 0, 6, 4), [
            target('sum(rate(auth_login_total{site=~"$site", result="failure"}[5m])) / clamp_min(sum(rate(auth_login_total{site=~"$site"}[5m])), 0.0001) * 100', "failure %"),
        ], "A sustained jump with steady volume is the credential-stuffing signal; Wazuh covers the SSH side of the same question.", unit="percent", decimals=1,
           reduceOptions={"calcs": ["lastNotNull"], "fields": "", "values": False}),

        panel(3, "stat", "Active users", grid(18, 0, 6, 4), [
            target('max by (site) (active_users{site=~"$site"})', "{{site}}"),
        ], "Distinct users on an authenticated request inside a 900s window. The gauge is per API process, so replicas overlap: max is a lower bound, summing would double-count (apps/server/docs/metrics.md).", min=0,
           reduceOptions={"calcs": ["lastNotNull"], "fields": "", "values": False}),

        panel(4, "timeseries", "Subscription changes / h", grid(12, 4, 12, 4), [
            target('sum(increase(subscriptions_created_total{site=~"$site"}[1h]))', "created"),
            target('sum(increase(subscriptions_updated_total{site=~"$site"}[1h]))', "updated", ref="B"),
            target('sum(increase(subscriptions_deleted_total{site=~"$site"}[1h]))', "deleted", ref="C"),
        ], min=0),

        panel(5, "timeseries", "BullMQ renewal-reminder queue", grid(0, 8), [
            target('sum by (state) (worker_queue_jobs{site=~"$site", state=~"waiting|active|delayed|failed"})', "{{state}}"),
        ], "Read from getJobCounts() at scrape time. completed/failed are capped at 500 retained records by removeOnComplete/removeOnFail, so they plateau — use the counter panel beside this one for rates.", min=0),

        panel(6, "timeseries", "Worker jobs / min by outcome", grid(12, 8), [
            target('sum by (result) (rate(worker_jobs_processed_total{site=~"$site"}[5m])) * 60', "{{result}}"),
        ], "This, not worker_queue_jobs{state=\"failed\"}, is the real failure rate.", min=0),

        panel(7, "timeseries", "Worker job duration", grid(0, 16), [
            target('histogram_quantile(0.95, sum by (le, queue) (rate(worker_job_duration_seconds_bucket{site=~"$site"}[5m])))', "p95 {{queue}}"),
            target('histogram_quantile(0.50, sum by (le, queue) (rate(worker_job_duration_seconds_bucket{site=~"$site"}[5m])))', "p50 {{queue}}", ref="B"),
        ], unit="s", min=0),

        panel(8, "stat", "Queue scrape OK", grid(12, 16, 6, 4), [
            target('min by (site) (worker_queue_scrape_ok{site=~"$site"})', "{{site}}"),
        ], "0 means the last read of the queue failed or timed out — usually Redis. The worker_queue_jobs series are dropped rather than held at their last value, so a flat 0-waiting queue cannot be mistaken for a healthy idle one.", min=0, max=1,
           reduceOptions={"calcs": ["lastNotNull"], "fields": "", "values": False}),

        panel(9, "stat", "Active-user tracker evictions (1h)", grid(18, 16, 6, 4), [
            target('sum(increase(active_users_tracker_dropped_total{site=~"$site"}[1h]))', "dropped"),
        ], "Non-zero means the 10 000-entry cap was hit and `active_users` is under-reporting.", min=0,
           reduceOptions={"calcs": ["lastNotNull"], "fields": "", "values": False}),
    ],
    templating=[prom_var("site", "Site", "http_requests_total")],
)

# ---------------------------------------------------------------------------
# 4. Logs explorer
# ---------------------------------------------------------------------------
logs = dashboard(
    "dp5-logs-explorer",
    "Logs Explorer",
    "Container logs shipped by Alloy. Labels: service, container, compose_project, site (everything) plus method/route/status on nginx. remote_addr and request_time are structured metadata, not labels.",
    ["dp-5", "dp-502", "logs"],
    [
        panel(1, "timeseries", "Log volume by service", grid(0, 0, 16, 6), [
            target('sum by (service) (count_over_time({site=~"$site", service=~"$service"}[$__auto]))', "{{service}}", ds=LOKI),
        ], ds=LOKI, min=0),

        panel(2, "stat", "Lines matching the filter", grid(16, 0, 8, 6), [
            target('sum(count_over_time({site=~"$site", service=~"$service"} |= "$search" [$__auto]))', "lines", ds=LOKI),
        ], "Leave $search empty to count everything. Put a requestId in it to follow one request across services.", ds=LOKI, min=0,
           reduceOptions={"calcs": ["sum"], "fields": "", "values": False}),

        panel(3, "logs", "Logs", grid(0, 6, 24, 12), [
            target('{site=~"$site", service=~"$service", level=~"$level"} |= "$search"', "", ds=LOKI),
        ], "`level` only exists on api/worker lines, where Alloy pulls Nest's level token out of the line. Until the app emits JSON logs (DP-5 phase 2d, deferred) there is no structured requestId field — $search is a substring match over the raw line, which works the same way for a requestId.",
           ds=LOKI, showTime=True, wrapLogMessage=True, sortOrder="Descending", enableLogDetails=True),

        panel(4, "timeseries", "nginx responses by status", grid(0, 18), [
            target('sum by (status) (count_over_time({site=~"$site", service="nginx"}[$__auto]))', "{{status}}", ds=LOKI),
        ], ds=LOKI, min=0),

        panel(5, "timeseries", "nginx top routes", grid(12, 18), [
            target('topk(10, sum by (route) (count_over_time({site=~"$site", service="nginx"}[$__auto])))', "{{route}}", ds=LOKI),
        ], "route=\"other\" is every path outside the app's route table lumped together — a scanner shows up as a spike on that one series instead of thousands of new streams.", ds=LOKI, min=0),

        panel(6, "logs", "nginx 4xx / 5xx", grid(0, 26, 24, 10), [
            target('{site=~"$site", service="nginx", status=~"4..|5.."}', "", ds=LOKI),
        ], "Expand a line to see remote_addr and request_time in structured metadata. Filter by caller with: | remote_addr = \"203.0.113.10\"",
           ds=LOKI, showTime=True, wrapLogMessage=True, sortOrder="Descending", enableLogDetails=True),
    ],
    templating=[
        {**prom_var("site", "Site", "", ds=LOKI), "query": {"label": "site", "refId": "LokiVariableQueryEditor-VariableQuery", "stream": "", "type": 1}, "definition": "label_values(site)"},
        {**prom_var("service", "Service", "", ds=LOKI), "query": {"label": "service", "refId": "LokiVariableQueryEditor-VariableQuery", "stream": "", "type": 1}, "definition": "label_values(service)"},
        {**prom_var("level", "Level", "", ds=LOKI), "query": {"label": "level", "refId": "LokiVariableQueryEditor-VariableQuery", "stream": "", "type": 1}, "definition": "label_values(level)"},
        textbox_var("search", "Search / requestId"),
    ],
    time_from="now-1h",
)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for name, doc in [
        ("system-containers.json", system),
        ("api-red.json", red),
        ("business-activity.json", business),
        ("logs-explorer.json", logs),
    ]:
        path = OUT / name
        path.write_text(json.dumps(doc, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        print(f"wrote {path.relative_to(OUT.parents[4])} ({len(doc['panels'])} panels)")


if __name__ == "__main__":
    main()
