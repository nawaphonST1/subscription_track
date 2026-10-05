#!/usr/bin/env bash
# Regression test for F4: the monitoring-VM Prometheus must attach site=
# "monitoring-vm" to its OWN locally-scraped series, not only to whatever it
# remote-writes or federates out.
#
# Why this needs a real Prometheus and not just `promtool check config`:
# `external_labels` (set once, under `global:`) is a well-known Prometheus
# footgun -- it is applied to data LEAVING this Prometheus (remote_write,
# federation), never to data it scrapes and stores locally. A config that
# relies on external_labels alone validates perfectly and still leaves every
# local query (and the Grafana $site template variable) without the label.
# The only way to prove the label is actually on a locally-scraped series is
# to start the real binary, let it scrape, and query it -- so that's what
# this does, automating the before/after proof from the F4 round-3 review.
#
# Re-runnable: one container, removed on exit, no state kept, no network
# exposure beyond a loopback port.
#
#   ./check-prometheus-site-label.sh
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
CONFIG="$ROOT/infra/monitoring/prometheus/prometheus.yml"
IMAGE="${PROMETHEUS_IMAGE:-prom/prometheus:v3.5.5}"
# Fixed at 9090, NOT overridable: the config's own `prometheus` scrape job is
# hardcoded to target localhost:9090 (it scrapes Prometheus' own /metrics to
# prove it is alive). Listening anywhere else would make that job's scrapes
# fail silently, and the resulting absence of prometheus_build_info would
# look exactly like this test catching a real regression when it is really
# just a port mismatch -- so this is deliberately not parameterized.
PORT=9090
NAME="dp5-prom-site-label-check-$$"

test -r "$CONFIG" || { echo "missing $CONFIG" >&2; exit 1; }

cleanup() { docker rm -f "$NAME" >/dev/null 2>&1 || true; }
trap cleanup EXIT

docker run -d --rm --name "$NAME" \
  --network host \
  -v "$CONFIG:/etc/prometheus/prometheus.yml:ro" \
  "$IMAGE" \
    --config.file=/etc/prometheus/prometheus.yml \
    --storage.tsdb.path=/tmp/prom-data >/dev/null

echo -n "waiting for prometheus"
for _ in $(seq 1 30); do
  if curl -fsS "http://127.0.0.1:$PORT/-/ready" >/dev/null 2>&1; then echo " ready"; break; fi
  echo -n "."; sleep 1
done
curl -fsS "http://127.0.0.1:$PORT/-/ready" >/dev/null || {
  echo " FAILED to start"; docker logs "$NAME" 2>&1 | tail -30; exit 1; }

# One scrape_interval (15s in this config) plus a little slack, so the
# `prometheus` self-scrape job has actually produced a sample.
sleep 18

fail=0
note() { if [ "$1" = 0 ]; then printf 'PASS  %s\n' "$2"; else printf 'FAIL  %s\n' "$2"; fail=1; fi; }

query() {  # query <promql> -> prints the JSON "result" array
  curl -fsS --data-urlencode "query=$1" "http://127.0.0.1:$PORT/api/v1/query" \
    | python3 -c 'import json,sys; print(json.dumps(json.load(sys.stdin)["data"]["result"]))'
}

# --- the actual regression check -------------------------------------------
# prometheus_build_info is emitted only by a successful, genuinely local
# scrape of Prometheus' own /metrics -- not by remote_write or federation --
# so this is exactly the series external_labels alone would NOT have labeled.
result="$(query 'prometheus_build_info')"
if printf '%s' "$result" | python3 -c '
import json, sys
rows = json.load(sys.stdin)
sys.exit(0 if any(r["metric"].get("site") == "monitoring-vm" for r in rows) else 1)
'; then
  note 0 "a locally-scraped series (prometheus_build_info) carries site=\"monitoring-vm\""
else
  note 1 "a locally-scraped series (prometheus_build_info) carries site=\"monitoring-vm\" (got: $result)"
fi

# --- the Grafana $site template variable would see it -----------------------
result="$(query 'up')"
if printf '%s' "$result" | python3 -c '
import json, sys
rows = json.load(sys.stdin)
sys.exit(0 if rows and all(r["metric"].get("site") == "monitoring-vm" for r in rows) else 1)
'; then
  note 0 "every up{} series (every scrape job) carries site=\"monitoring-vm\""
else
  note 1 "every up{} series carries site=\"monitoring-vm\" (got: $result)"
fi

if [ "$fail" -ne 0 ]; then
  echo "RESULT: FAIL"; docker logs "$NAME" 2>&1 | tail -30; exit 1
fi
echo "RESULT: PASS"
