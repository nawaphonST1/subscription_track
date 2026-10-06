#!/usr/bin/env bash
# Start the pinned Grafana against the real provisioning tree and assert that
# it actually loaded everything.
#
# This is the only check that exercises Grafana's own parsers: the alert
# provisioning schema, the dashboard schemaVersion, the datasource refs and the
# $DISCORD_WEBHOOK_URL interpolation. A JSON/YAML linter cannot tell you that a
# field name is wrong — Grafana logs it and moves on with the resource missing,
# which is exactly how a dashboard ends up silently absent on demo day.
#
# The webhook URL here is a throwaway placeholder; nothing is ever sent,
# because no rule can fire against a Prometheus that is not running.
#
# Re-runnable: one container, removed on exit, no volumes, no network exposure
# beyond a loopback port.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
IMAGE="${GRAFANA_IMAGE:-grafana/grafana:12.1.1}"
PORT="${GRAFANA_PORT:-3399}"
NAME="dp5-grafana-check-$$"
PASSWORD="check-only-$(date +%s)"

cleanup() { docker rm -f "$NAME" >/dev/null 2>&1 || true; }
trap cleanup EXIT

docker run -d --rm --name "$NAME" \
  -p "127.0.0.1:$PORT:3000" \
  -e "GF_SECURITY_ADMIN_PASSWORD=$PASSWORD" \
  -e "GF_USERS_ALLOW_SIGN_UP=false" \
  -e "GF_ANALYTICS_REPORTING_ENABLED=false" \
  -e "GF_ANALYTICS_CHECK_FOR_UPDATES=false" \
  -e "DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/000000000000000000/provisioning-check-placeholder" \
  -v "$ROOT/infra/monitoring/grafana/provisioning:/etc/grafana/provisioning:ro" \
  -v "$ROOT/infra/monitoring/grafana/dashboards:/etc/grafana/dashboards:ro" \
  "$IMAGE" >/dev/null

API="http://admin:$PASSWORD@127.0.0.1:$PORT"

echo -n "waiting for grafana"
for _ in $(seq 1 90); do
  if curl -fsS "http://127.0.0.1:$PORT/api/health" >/dev/null 2>&1; then echo " ready"; break; fi
  echo -n "."; sleep 1
done
curl -fsS "http://127.0.0.1:$PORT/api/health" >/dev/null || {
  echo " FAILED to start"; docker logs "$NAME" 2>&1 | tail -30; exit 1; }

# The file provider polls every 30s; give the first pass time to land.
sleep 12

fail=0
note() { if [ "$1" = 0 ]; then printf 'PASS  %s\n' "$2"; else printf 'FAIL  %s\n' "$2"; fail=1; fi; }

# --- provisioning errors in the log ---------------------------------------
# Scoped to the three provisioning subsystems this repo owns. Grafana always
# logs two unrelated errors at startup -- a duplicate `table` plugin
# registration, and a missing provisioning/plugins directory this project has
# no reason to create -- and treating those as failures would make the check
# cry wolf forever.
errs=$(docker logs "$NAME" 2>&1 \
  | grep -E 'logger=provisioning\.(dashboard|datasources|alerting)|logger=ngalert\.provisioning' \
  | grep -iE 'level=(error|warn)' || true)
if [ -n "$errs" ]; then
  note 1 "no dashboard/datasource/alerting provisioning errors in the Grafana log"
  echo "$errs" | head -20 | sed 's/^/      /'
else
  note 0 "no dashboard/datasource/alerting provisioning errors in the Grafana log"
fi

# --- dashboards ------------------------------------------------------------
want_uids="host-overview dp5-system-containers dp5-api-red dp5-business-activity dp5-logs-explorer"
for uid in $want_uids; do
  code=$(curl -s -o /dev/null -w '%{http_code}' "$API/api/dashboards/uid/$uid")
  if [ "$code" = "200" ]; then note 0 "dashboard $uid provisioned"; else note 1 "dashboard $uid provisioned (HTTP $code)"; fi
done

# Every panel's datasource must resolve to one that exists.
for uid in $want_uids; do
  missing=$(curl -fsS "$API/api/dashboards/uid/$uid" \
    | python3 -c '
import json,sys
d=json.load(sys.stdin)["dashboard"]
bad=set()
def walk(p):
    ds=(p.get("datasource") or {}).get("uid")
    if ds and ds not in ("prometheus","loki","__expr__") and not ds.startswith("$"):
        bad.add(ds)
    for t in p.get("targets") or []:
        ds=(t.get("datasource") or {}).get("uid")
        if ds and ds not in ("prometheus","loki","__expr__") and not ds.startswith("$"):
            bad.add(ds)
for p in d.get("panels",[]):
    walk(p)
    for sp in p.get("panels",[]) or []: walk(sp)
print(" ".join(sorted(bad)))')
  if [ -z "$missing" ]; then note 0 "dashboard $uid references only provisioned datasources"
  else note 1 "dashboard $uid references unknown datasource(s): $missing"; fi
done

# --- F6 regression guard: the PostgreSQL/Redis panels on business-activity -
# Checks what Grafana actually SERVES after provisioning (not the static JSON
# file on disk), so a provisioning-time transform or schema migration that
# silently dropped or corrupted a panel would be caught here too.
panel_report=$(curl -fsS "$API/api/dashboards/uid/dp5-business-activity" \
  | python3 -c '
import json, sys

d = json.load(sys.stdin)["dashboard"]
panels = {p["id"]: p for p in d.get("panels", [])}

want = {
    100: "Data Stores (PostgreSQL & Redis)",
    101: "PostgreSQL Status",
    102: "PostgreSQL Active Connections",
    103: "PostgreSQL Transaction Throughput",
    104: "Redis Status",
    105: "Redis Memory Utilization",
    106: "Redis Operations & Connected Clients",
}
problems = []
for pid, title in want.items():
    p = panels.get(pid)
    if p is None:
        problems.append(f"panel {pid} ({title}) missing")
    else:
        actual_title = p.get("title")
        if actual_title != title:
            problems.append(f"panel {pid} title is {actual_title!r}, expected {title!r}")

# Every target on a pg_*/redis_* panel must itself query a pg_*/redis_*
# metric -- catches a panel that exists and is titled right but queries the
# wrong metric namespace (e.g. a copy-paste from the wrong row).
for pid in (101, 102, 103):
    for t in panels.get(pid, {}).get("targets", []):
        expr = t.get("expr", "")
        if "pg_" not in expr:
            problems.append(f"panel {pid} target does not query a pg_* metric: {expr!r}")
for pid in (104, 105, 106):
    for t in panels.get(pid, {}).get("targets", []):
        expr = t.get("expr", "")
        if "redis_" not in expr:
            problems.append(f"panel {pid} target does not query a redis_* metric: {expr!r}")

# gridPos overlap, recomputed against whatever Grafana actually returned.
def overlap(a, b):
    ax, ay, aw, ah = a["x"], a["y"], a["w"], a["h"]
    bx, by, bw, bh = b["x"], b["y"], b["w"], b["h"]
    return not (ax + aw <= bx or bx + bw <= ax or ay + ah <= by or by + bh <= ay)

boxes = [(pid, p["gridPos"]) for pid, p in panels.items()]
for i in range(len(boxes)):
    for j in range(i + 1, len(boxes)):
        if overlap(boxes[i][1], boxes[j][1]):
            problems.append(f"gridPos overlap between panel {boxes[i][0]} and {boxes[j][0]}")

print("\n".join(problems))
')
if [ -z "$panel_report" ]; then
  note 0 "all 6 PostgreSQL/Redis panels (ids 100-106) present, correctly titled, on-topic, non-overlapping"
else
  note 1 "PostgreSQL/Redis panel check found problems:"
  echo "$panel_report" | sed 's/^/      /'
fi

# --- datasources -----------------------------------------------------------
for uid in prometheus loki; do
  code=$(curl -s -o /dev/null -w '%{http_code}' "$API/api/datasources/uid/$uid")
  if [ "$code" = "200" ]; then note 0 "datasource $uid provisioned"; else note 1 "datasource $uid provisioned (HTTP $code)"; fi
done

# --- alert rules -----------------------------------------------------------
rules_json=$(curl -fsS "$API/api/v1/provisioning/alert-rules")
count=$(printf '%s' "$rules_json" | python3 -c 'import json,sys; print(len(json.load(sys.stdin)))')
if [ "$count" = "11" ]; then note 0 "all 11 alert rules provisioned"; else note 1 "expected 11 alert rules, found $count"; fi

printf '%s' "$rules_json" | python3 -c '
import json,sys
rules=json.load(sys.stdin)
bad=[r["uid"] for r in rules if not r.get("noDataState") or not r.get("execErrState")]
print(" ".join(bad))' > /tmp/dp5-missing-states.$$
missing_states=$(cat /tmp/dp5-missing-states.$$); rm -f /tmp/dp5-missing-states.$$
if [ -z "$missing_states" ]; then note 0 "every rule kept an explicit noDataState/execErrState"
else note 1 "rules missing noDataState/execErrState: $missing_states"; fi

# --- contact point, and the secret -----------------------------------------
cp_json=$(curl -fsS "$API/api/v1/provisioning/contact-points")
if printf '%s' "$cp_json" | grep -q '"type": *"discord"'; then
  note 0 "Discord contact point provisioned"
else
  note 1 "Discord contact point provisioned"
fi

# The variable must have been substituted. Grafana may redact the URL on
# read-back, so accept either "the placeholder is there" or "the literal
# variable name is NOT there" -- both prove interpolation happened; only the
# literal '$DISCORD_WEBHOOK_URL' surviving would mean it did not.
if printf '%s' "$cp_json" | grep -q 'provisioning-check-placeholder'; then
  note 0 "\$DISCORD_WEBHOOK_URL was interpolated from the environment"
elif printf '%s' "$cp_json" | grep -q 'DISCORD_WEBHOOK_URL'; then
  note 1 "\$DISCORD_WEBHOOK_URL was NOT interpolated -- the literal name reached Grafana"
else
  note 0 "\$DISCORD_WEBHOOK_URL was interpolated (URL redacted by Grafana on read-back)"
fi

policy=$(curl -fsS "$API/api/v1/provisioning/policies")
if printf '%s' "$policy" | grep -q '"receiver": *"discord"'; then
  note 0 "notification policy routes to the Discord contact point"
else
  note 1 "notification policy routes to the Discord contact point"
fi

if [ "$fail" -eq 0 ]; then
  echo "RESULT: PASS"
else
  echo "RESULT: FAIL"; docker logs "$NAME" 2>&1 | tail -30; exit 1
fi
