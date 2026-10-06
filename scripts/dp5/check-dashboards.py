#!/usr/bin/env python3
"""Static review of the DP-5 Grafana dashboards, as a test rather than a habit.

Three things are checked, in rising order of how much they would hurt to miss:

1. Shape — every dashboard parses as JSON and carries a stable `uid`, a title,
   the schemaVersion Grafana 12.1.x reads, and a datasource uid on the
   dashboard, every panel and every target. A missing uid is how a provisioned
   dashboard silently becomes a *second* dashboard on the next restart.
2. Metric names — every Prometheus series referenced must exist in the
   allowlist below, which is transcribed from apps/server/docs/metrics.md (the
   app's own contract) and from the exporters pinned in
   infra/monitoring/prod-agent/docker-compose.yml. A typo in a PromQL metric
   name does not error anywhere: the panel just draws nothing, forever.
3. Cardinality — no panel may group by a label the metrics contract forbids.

PromQL *syntax* is not checked here; scripts/dp5/verify.sh feeds the same
expressions to promtool, which is the real parser.

    python3 scripts/dp5/check-dashboards.py [--emit-promql FILE] [--emit-logql FILE]
"""

from __future__ import annotations

import argparse
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
DASH_DIR = ROOT / "infra/monitoring/grafana/dashboards"

# --- allowlist ------------------------------------------------------------
# App contract — apps/server/docs/metrics.md, "API series" / "Worker series".
APP_METRICS = {
    "http_requests_total",
    "http_request_duration_seconds_bucket",
    "http_request_duration_seconds_sum",
    "http_request_duration_seconds_count",
    "auth_login_total",
    "subscriptions_created_total",
    "subscriptions_updated_total",
    "subscriptions_deleted_total",
    "active_users",
    "active_users_tracker_dropped_total",
    "worker_jobs_processed_total",
    "worker_job_duration_seconds_bucket",
    "worker_job_duration_seconds_sum",
    "worker_job_duration_seconds_count",
    "worker_scheduler_runs_total",
    "worker_queue_jobs",
    "worker_queue_scrape_ok",
}
# node_exporter v1.12.1
NODE_METRICS = {
    "node_cpu_seconds_total",
    "node_memory_MemTotal_bytes",
    "node_memory_MemAvailable_bytes",
    "node_filesystem_avail_bytes",
    "node_filesystem_size_bytes",
    "node_network_receive_bytes_total",
    "node_network_transmit_bytes_total",
    "node_load1",
    "node_load5",
    "node_boot_time_seconds",
    "node_time_seconds",
}
# cAdvisor v0.55.1, with --docker_only and --store_container_labels=false
CADVISOR_METRICS = {
    "container_cpu_usage_seconds_total",
    "container_memory_working_set_bytes",
    "container_spec_memory_limit_bytes",
    "container_start_time_seconds",
    "container_last_seen",
}
# postgres_exporter v0.20.1 / redis_exporter v1.93.0
STORE_METRICS = {
    "pg_up",
    "pg_stat_database_numbackends",
    "pg_stat_database_xact_commit",
    "pg_stat_database_xact_rollback",
    "pg_settings_max_connections",
    "redis_up",
    "redis_memory_used_bytes",
    "redis_connected_clients",
    "redis_commands_processed_total",
    "redis_commands_total",
}
# Prometheus / blackbox_exporter v0.28.0
INFRA_METRICS = {"up", "probe_success", "probe_duration_seconds", "scrape_samples_scraped"}

ALLOWED = APP_METRICS | NODE_METRICS | CADVISOR_METRICS | STORE_METRICS | INFRA_METRICS

# Labels no panel may group by, per the metrics contract's cardinality rules
# and operator §5.3 — if one of these ever appears in a `by (...)`, something
# upstream started emitting a per-user or per-request series.
FORBIDDEN_GROUP_LABELS = {"user", "user_id", "userId", "email", "path", "url", "request_id",
                          "requestId", "remote_addr", "ip", "token", "job_id", "subscription"}

PROMQL_KEYWORDS = {
    "by", "without", "on", "ignoring", "group_left", "group_right", "offset", "bool",
    "and", "or", "unless", "start", "end", "le", "Inf", "NaN", "atan2",
}
PROMQL_FUNCS = {
    "abs", "absent", "absent_over_time", "avg", "avg_over_time", "ceil", "changes",
    "clamp", "clamp_max", "clamp_min", "count", "count_over_time", "count_values",
    "day_of_month", "day_of_week", "day_of_year", "days_in_month", "delta", "deriv",
    "exp", "floor", "group", "histogram_quantile", "histogram_count", "histogram_sum",
    "holt_winters", "hour", "idelta", "increase", "irate", "label_join", "label_replace",
    "last_over_time", "ln", "log10", "log2", "max", "max_over_time", "min", "min_over_time",
    "minute", "month", "predict_linear", "present_over_time", "quantile",
    "quantile_over_time", "rate", "resets", "round", "scalar", "sgn", "sort", "sort_desc",
    "sqrt", "stddev", "stddev_over_time", "stdvar", "sum", "sum_over_time", "time",
    "timestamp", "topk", "bottomk", "vector", "year",
}

# Grafana interpolations, replaced so the expression becomes parseable PromQL.
SUBSTITUTIONS = [
    (r'=~"\$site"', '=~"prod"'),
    (r'=~"\$route"', '=~".*"'),
    (r'=~"\$service"', '=~".*"'),
    (r'=~"\$level"', '=~".*"'),
    (r'\|= "\$search"', '|= ""'),
    (r'\$__auto', '5m'),
    (r'\$__rate_interval', '5m'),
    (r'\$__interval', '5m'),
]


def strip_for_metric_scan(expr: str) -> str:
    expr = re.sub(r'"[^"]*"', '""', expr)
    expr = re.sub(r'\{[^}]*\}', "", expr)
    expr = re.sub(r'\[[^\]]*\]', "", expr)
    expr = re.sub(r'\b(by|without|on|ignoring|group_left|group_right)\s*\([^)]*\)', " ", expr)
    return expr


def metric_names(expr: str) -> set[str]:
    cleaned = strip_for_metric_scan(expr)
    found = set()
    for m in re.finditer(r"[a-zA-Z_][a-zA-Z0-9_]*", cleaned):
        name = m.group(0)
        rest = cleaned[m.end():].lstrip()
        if rest.startswith("("):
            continue  # function call
        if name in PROMQL_KEYWORDS or name in PROMQL_FUNCS:
            continue
        found.add(name)
    return found


def group_labels(expr: str) -> set[str]:
    out = set()
    for m in re.finditer(r"\b(?:by|without)\s*\(([^)]*)\)", expr):
        out.update(p.strip() for p in m.group(1).split(",") if p.strip())
    return out


def substitute(expr: str) -> str:
    for pat, rep in SUBSTITUTIONS:
        expr = re.sub(pat, rep, expr)
    return expr


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--emit-promql")
    ap.add_argument("--emit-logql")
    args = ap.parse_args()

    failures: list[str] = []
    promql: list[tuple[str, str, str]] = []
    logql: list[tuple[str, str, str]] = []
    seen_uids: dict[str, str] = {}

    files = sorted(DASH_DIR.glob("*.json"))
    if not files:
        print(f"FAIL  no dashboards in {DASH_DIR}")
        return 1

    for path in files:
        rel = path.relative_to(ROOT)
        try:
            doc = json.loads(path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as exc:
            failures.append(f"{rel}: not valid JSON — {exc}")
            continue

        uid = doc.get("uid")
        if not uid:
            failures.append(f"{rel}: no top-level uid")
        elif uid in seen_uids:
            failures.append(f"{rel}: uid {uid!r} already used by {seen_uids[uid]}")
        else:
            seen_uids[uid] = str(rel)

        if not doc.get("title"):
            failures.append(f"{rel}: no title")
        sv = doc.get("schemaVersion")
        if not isinstance(sv, int) or not 36 <= sv <= 41:
            failures.append(f"{rel}: schemaVersion {sv!r} outside the range Grafana 12.1.x reads (36-41)")
        if doc.get("editable") is not False:
            failures.append(f"{rel}: editable should be false — the file is the source of truth")

        panels = doc.get("panels") or []
        if not panels:
            failures.append(f"{rel}: no panels")

        for p in panels:
            where = f"{rel} panel {p.get('id')} {p.get('title')!r}"
            ds = p.get("datasource") or {}
            if ds.get("uid") not in {"prometheus", "loki"}:
                failures.append(f"{where}: datasource uid {ds.get('uid')!r} is not provisioned")
            for t in p.get("targets") or []:
                tds = (t.get("datasource") or {}).get("uid")
                if tds != ds.get("uid"):
                    failures.append(f"{where}: target {t.get('refId')} datasource {tds!r} != panel datasource")
                expr = t.get("expr", "")
                if not expr:
                    failures.append(f"{where}: target {t.get('refId')} has no expr")
                    continue
                if tds == "prometheus":
                    unknown = metric_names(expr) - ALLOWED
                    unknown = {u for u in unknown if not u.startswith("$")}
                    if unknown:
                        failures.append(f"{where}: metric(s) not in the contract: {sorted(unknown)}")
                    bad = group_labels(expr) & FORBIDDEN_GROUP_LABELS
                    if bad:
                        failures.append(f"{where}: groups by high-cardinality label(s) {sorted(bad)}")
                    promql.append((str(rel), str(p.get("id")), substitute(expr)))
                else:
                    logql.append((str(rel), str(p.get("id")), substitute(expr)))

    if args.emit_promql:
        rules = ["# Generated by check-dashboards.py — every dashboard PromQL expression as a",
                 "# recording rule, purely so promtool parses it for real.",
                 "groups:", "  - name: dashboard-expressions", "    rules:"]
        for i, (f, pid, expr) in enumerate(promql):
            rules.append(f"      # {f} panel {pid}")
            rules.append(f"      - record: dashboard:expr{i}")
            rules.append("        expr: " + json.dumps(expr))
        pathlib.Path(args.emit_promql).write_text("\n".join(rules) + "\n", encoding="utf-8")

    if args.emit_logql:
        pathlib.Path(args.emit_logql).write_text(
            "\n".join(f"{f}\t{pid}\t{expr}" for f, pid, expr in logql) + "\n", encoding="utf-8")

    print(f"dashboards: {len(files)}   prometheus targets: {len(promql)}   loki targets: {len(logql)}")
    for f in failures:
        print(f"FAIL  {f}")
    if failures:
        return 1
    print("PASS  shape, uids, datasources, metric names and group-by labels")
    return 0


if __name__ == "__main__":
    sys.exit(main())
