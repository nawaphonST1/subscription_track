#!/usr/bin/env bash
# Parse every LogQL expression in the dashboards with a real Loki.
#
# There is no offline LogQL linter, and a query that does not parse shows up in
# Grafana only as an empty panel with a red corner. So: start the pinned Loki,
# send each expression to /loki/api/v1/query_range, and treat an HTTP 400
# ("parse error") as a failure. An empty result is a PASS — there is no data in
# this throwaway instance, and that is not what is being tested.
#
# Re-runnable, leaves nothing behind: one container, removed on exit.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
LOKI_IMAGE="${LOKI_IMAGE:-grafana/loki:3.5.10}"
PORT="${LOKI_PORT:-3199}"
NAME="dp5-logql-check-$$"
TMP="$(mktemp -d)"

cleanup() { docker rm -f "$NAME" >/dev/null 2>&1 || true; rm -rf "$TMP"; }
trap cleanup EXIT

python3 "$HERE/check-dashboards.py" --emit-logql "$TMP/logql.txt" >/dev/null

docker run -d --rm --name "$NAME" \
  -p "127.0.0.1:$PORT:3100" \
  -v "$ROOT/infra/monitoring/loki/loki-config.yml:/etc/loki/loki-config.yml:ro" \
  "$LOKI_IMAGE" -config.file=/etc/loki/loki-config.yml >/dev/null

echo -n "waiting for loki"
for _ in $(seq 1 60); do
  if curl -fsS "http://127.0.0.1:$PORT/ready" >/dev/null 2>&1; then echo " ready"; break; fi
  echo -n "."; sleep 1
done
curl -fsS "http://127.0.0.1:$PORT/ready" >/dev/null || { echo " FAILED to start"; docker logs "$NAME" | tail -20; exit 1; }

fail=0
now=$(date +%s)
while IFS=$'\t' read -r file pid expr; do
  [ -n "${expr:-}" ] || continue
  body=$(curl -sS -G "http://127.0.0.1:$PORT/loki/api/v1/query_range" \
    --data-urlencode "query=$expr" \
    --data-urlencode "start=$(( now - 3600 ))000000000" \
    --data-urlencode "end=${now}000000000" \
    --data-urlencode "limit=1" \
    -w '\n%{http_code}')
  code=$(printf '%s' "$body" | tail -1)
  msg=$(printf '%s' "$body" | head -n -1)
  if [ "$code" = "200" ]; then
    printf 'PASS  %-55s panel %-3s %s\n' "$(basename "$file")" "$pid" "${expr:0:60}"
  else
    printf 'FAIL  %-55s panel %-3s HTTP %s\n      %s\n      %s\n' \
      "$(basename "$file")" "$pid" "$code" "$expr" "$msg"
    fail=1
  fi
done < "$TMP/logql.txt"

if [ "$fail" -eq 0 ]; then
  echo "RESULT: PASS"
else
  echo "RESULT: FAIL"; exit 1
fi
