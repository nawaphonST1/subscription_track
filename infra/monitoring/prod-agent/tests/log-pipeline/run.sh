#!/usr/bin/env bash
# Functional test for the nginx stage of ../../config.alloy.
#
# `alloy validate` proves the config parses. It does NOT run the regex, the
# Go templates or the label/structured-metadata split — and those are where
# the cardinality guarantee in §5.3 actually lives. This test feeds sample
# access logs through the REAL pipeline block (extracted from config.alloy at
# run time, so it cannot drift) and asserts on what comes out of loki.echo.
#
# Two fixtures, two different jobs:
#   nginx-access.log  — the original adversarial fixture (scanner paths,
#                        query strings, mid-path ids, structured metadata).
#   real-routes.log    — every route in every real NestJS controller under
#                        apps/server/src (grepped by hand — see F3 round-3
#                        review), so a future edit to config.alloy's route
#                        whitelist can't silently start dropping real traffic
#                        to "other", and can't silently resurrect a dead
#                        whitelist entry (F3 cleanup: /users/me/pin was
#                        removed because no controller ever served it).
#
# Re-runnable: writes only to a temp dir, starts no long-lived container.
#
#   ./run.sh
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$HERE/../../config.alloy"
ALLOY_IMAGE="${ALLOY_IMAGE:-grafana/alloy:v1.20.1}"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

test -r "$SRC" || { echo "missing $SRC" >&2; exit 1; }

# Extract `loki.process "pipeline" { ... }` verbatim, then redirect its output
# from the tunnel to loki.echo so the result lands on stdout.
python3 - "$SRC" "$WORK/pipeline.alloy" <<'PY'
import sys
src, dst = sys.argv[1], sys.argv[2]
text = open(src, encoding="utf-8").read()
start = text.index('loki.process "pipeline" {')
depth, i = 0, start
while True:
    if text[i] == "{":
        depth += 1
    elif text[i] == "}":
        depth -= 1
        if depth == 0:
            break
    i += 1
block = text[start : i + 1]
assert "loki.write.tunnel.receiver" in block, "pipeline no longer forwards to the tunnel"
open(dst, "w", encoding="utf-8").write(
    block.replace("loki.write.tunnel.receiver", "loki.echo.out.receiver")
)
PY

fail=0
expect() {  # expect <outfile> <description> <grep -E pattern>
  if grep -Eq "$3" "$1"; then
    echo "PASS  $2"
  else
    echo "FAIL  $2  (no line matching: $3)"
    fail=1
  fi
}
refute() {  # refute <outfile> <description> <grep -E pattern>
  if grep -Eq "$3" "$1"; then
    echo "FAIL  $2  (unexpected match: $3)"
    fail=1
  else
    echo "PASS  $2"
  fi
}

# Runs the real pipeline over one fixture log and leaves the decoded
# labels/structured-metadata in $2. Each fixture gets its own subdirectory so
# the two docker runs (and their position files) never interfere.
run_pipeline() {
  local fixture="$1" out="$2"
  local rundir="$WORK/$(basename "$fixture" .log)"
  mkdir -p "$rundir"

  cat > "$rundir/config.alloy" <<EOF
local.file_match "nginx" {
  path_targets = [{
    __path__ = "/data/nginx-access.log",
    service  = "nginx",
    site     = "prod",
  }]
}

loki.source.file "nginx" {
  targets       = local.file_match.nginx.targets
  forward_to    = [loki.process.pipeline.receiver]
  tail_from_end = false
}

loki.echo "out" {}

EOF
  cat "$WORK/pipeline.alloy" >> "$rundir/config.alloy"
  cp "$fixture" "$rundir/nginx-access.log"

  echo "== running the pipeline over $(wc -l < "$fixture") lines of $(basename "$fixture")"
  timeout 40s docker run --rm \
    -v "$rundir/config.alloy:/etc/alloy/config.alloy:ro" \
    -v "$rundir:/data" \
    "$ALLOY_IMAGE" run \
      --server.http.listen-addr=127.0.0.1:12345 \
      --storage.path=/tmp/alloy \
      /etc/alloy/config.alloy \
    > "$rundir/raw.txt" 2>&1 || true

  # loki.echo writes through Alloy's logger (stderr), with the label set
  # escaped inside a logfmt value. Keep only those lines and unescape them,
  # so the assertions below can be written the way the labels actually read.
  grep -F 'component_id=loki.echo.out' "$rundir/raw.txt" | sed 's/\\"/"/g' > "$out" || true

  if [ ! -s "$out" ]; then
    echo "FAIL  $(basename "$fixture") produced no entries at all"
    tail -20 "$rundir/raw.txt"
    fail=1
    return
  fi

  echo "== pipeline output ($(wc -l < "$out") entries): labels | structured metadata"
  sed -E 's/^.*labels="\{([^}]*)\}".*structured_metadata="(.*)"$/\1 | \2/' "$out"
}

# --- fixture 1: the original adversarial log --------------------------------
OUT1="$WORK/out-adversarial.txt"
run_pipeline "$HERE/nginx-access.log" "$OUT1"

expect "$OUT1" "numeric id collapses to /subscriptions/:id"      'route="/subscriptions/:id"'
expect "$OUT1" "uuid collapses to the same route template"       'DELETE.*route="/subscriptions/:id"'
expect "$OUT1" "known route kept verbatim"                       'route="/auth/login"'
expect "$OUT1" "root path kept"                                  'route="/"'
expect "$OUT1" "query string stripped from the route"            'route="/subscriptions"'
expect "$OUT1" "method promoted to a label"                      'method="DELETE"'
expect "$OUT1" "status promoted to a label"                      'status="401"'
expect "$OUT1" "scanner path collapses to other"                 'route="other"'
expect "$OUT1" "remote_addr is structured metadata, not a label" '"remote_addr":"203\.0\.113\.10"'
expect "$OUT1" "optional request_time captured when present"     '"request_time":"0\.042"'
expect "$OUT1" "id collapsed mid-path too"                       'route="/packages/:id/offers"'
refute "$OUT1" "no raw scanner path anywhere in the labels"      'route="/(wp-admin|\.env|vendor)'
refute "$OUT1" "no per-request numeric path label"               'route="/packages/7/offers"'
refute "$OUT1" "no raw non-uuid/numeric suffix leaked as route (F3)" 'route="/subscriptions/(abc|%2e)'
expect "$OUT1" "adversarial uncollapsed suffix collapses to other (F3)" 'route="other"'

# --- fixture 2: every real controller route, plus adversarial edge cases ---
OUT2="$WORK/out-real-routes.txt"
run_pipeline "$HERE/real-routes.log" "$OUT2"

# One assertion per controller group, so a route-table drift in config.alloy
# (a renamed route, a prefix typo) fails here instead of silently degrading
# to "other" in production dashboards.
expect "$OUT2" "GET / kept as root"                               'route="/"'
expect "$OUT2" "GET /health kept (real route)"                    'route="/health"'
expect "$OUT2" "GET /metrics kept (own job's /metrics server)"    'route="/metrics"'
expect "$OUT2" "POST /auth/login kept"                            'route="/auth/login"'
expect "$OUT2" "POST /auth/register kept"                         'route="/auth/register"'
expect "$OUT2" "GET /users/me kept"                                'route="/users/me"'
expect "$OUT2" "PATCH /users/income kept"                         'route="/users/income"'
expect "$OUT2" "POST /users/verify-pin kept"                      'route="/users/verify-pin"'
expect "$OUT2" "PATCH /users/pin kept (the real PIN route)"       'route="/users/pin"'
expect "$OUT2" "GET /creep-score kept"                            'route="/creep-score"'
expect "$OUT2" "POST /device-registrations kept"                  'route="/device-registrations"'
expect "$OUT2" "GET /subscriptions/upcoming kept"                 'route="/subscriptions/upcoming"'
expect "$OUT2" "GET /subscriptions/presets kept"                  'route="/subscriptions/presets"'
expect "$OUT2" "GET /subscriptions/:id kept (numeric id)"         'GET.*route="/subscriptions/:id"'
expect "$OUT2" "GET /admin/packages kept"                         'route="/admin/packages"'
expect "$OUT2" "PATCH /admin/packages/:id/disable kept"           'route="/admin/packages/:id/disable"'
expect "$OUT2" "PATCH /admin/packages/:id/enable kept"            'route="/admin/packages/:id/enable"'
expect "$OUT2" "PATCH /admin/packages/:id/status kept"            'route="/admin/packages/:id/status"'
expect "$OUT2" "GET /savings/optimizer kept"                      'route="/savings/optimizer"'
expect "$OUT2" "POST /savings/batch-cancel kept"                  'route="/savings/batch-cancel"'
expect "$OUT2" "GET /savings/logs kept"                           'route="/savings/logs"'
expect "$OUT2" "GET /cards/total-balance kept"                    'route="/cards/total-balance"'
expect "$OUT2" "GET /cards/mock kept"                             'route="/cards/mock"'
expect "$OUT2" "POST /cards/link kept"                            'route="/cards/link"'
expect "$OUT2" "GET /cards/:id kept"                              'route="/cards/:id"'
expect "$OUT2" "GET /notifications kept"                          'route="/notifications"'
expect "$OUT2" "PATCH /notifications/read-all kept"               'route="/notifications/read-all"'
expect "$OUT2" "PATCH /notifications/:id/read kept"                'route="/notifications/:id/read"'
expect "$OUT2" "GET /packages/:id kept"                            'route="/packages/:id"'
expect "$OUT2" "PATCH /packages/:id/disable kept"                  'route="/packages/:id/disable"'

# Regression guards for the F3 round-3 cleanup: these must NEVER come back as
# their own kept route — they have no controller behind them, so letting them
# through again would silently reopen the exact whitelist-drift gap the
# review found.
refute "$OUT2" "removed dead whitelist entry /users/me/pin never kept verbatim" 'route="/users/me/pin"'
refute "$OUT2" "case-mismatched path never kept verbatim"                       'route="/SUBSCRIPTIONS'
refute "$OUT2" "path traversal never kept verbatim"                            'route="/subscriptions/\.\.'
refute "$OUT2" "path traversal out of /users/pin never kept verbatim"          'route="/users/pin/\.\.'
refute "$OUT2" "an unregistered trailing segment never kept verbatim"          'route="/subscriptions/:id/extra'

if [ "$fail" -ne 0 ]; then
  echo "RESULT: FAIL"; exit 1
fi
echo "RESULT: PASS"
