#!/usr/bin/env bash
# Functional test for the nginx stage of ../../config.alloy.
#
# `alloy validate` proves the config parses. It does NOT run the regex, the
# Go templates or the label/structured-metadata split — and those are where
# the cardinality guarantee in §5.3 actually lives. This test feeds a sample
# access log through the REAL pipeline block (extracted from config.alloy at
# run time, so it cannot drift) and asserts on what comes out of loki.echo.
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

cat > "$WORK/config.alloy" <<'EOF'
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
cat "$WORK/pipeline.alloy" >> "$WORK/config.alloy"

cp "$HERE/nginx-access.log" "$WORK/nginx-access.log"

echo "== running the pipeline over $(wc -l < "$WORK/nginx-access.log") sample lines"
timeout 40s docker run --rm \
  -v "$WORK/config.alloy:/etc/alloy/config.alloy:ro" \
  -v "$WORK:/data" \
  "$ALLOY_IMAGE" run \
    --server.http.listen-addr=127.0.0.1:12345 \
    --storage.path=/tmp/alloy \
    /etc/alloy/config.alloy \
  > "$WORK/raw.txt" 2>&1 || true

# loki.echo writes through Alloy's logger (stderr), with the label set escaped
# inside a logfmt value. Keep only those lines and unescape them, so the
# assertions below can be written the way the labels actually read.
OUT="$WORK/out.txt"
grep -F 'component_id=loki.echo.out' "$WORK/raw.txt" | sed 's/\\"/"/g' > "$OUT" || true

if [ ! -s "$OUT" ]; then
  echo "FAIL  the pipeline produced no entries at all"
  tail -20 "$WORK/raw.txt"
  exit 1
fi

echo "== pipeline output ($(wc -l < "$OUT") entries): labels | structured metadata"
sed -E 's/^.*labels="\{([^}]*)\}".*structured_metadata="(.*)"$/\1 | \2/' "$OUT"

fail=0
expect() {  # expect <description> <grep -E pattern>
  if grep -Eq "$2" "$OUT"; then
    echo "PASS  $1"
  else
    echo "FAIL  $1  (no line matching: $2)"
    fail=1
  fi
}
refute() {
  if grep -Eq "$2" "$OUT"; then
    echo "FAIL  $1  (unexpected match: $2)"
    fail=1
  else
    echo "PASS  $1"
  fi
}

expect "numeric id collapses to /subscriptions/:id"      'route="/subscriptions/:id"'
expect "uuid collapses to the same route template"       'DELETE.*route="/subscriptions/:id"'
expect "known route kept verbatim"                       'route="/auth/login"'
expect "root path kept"                                  'route="/"'
expect "query string stripped from the route"            'route="/subscriptions"'
expect "method promoted to a label"                      'method="DELETE"'
expect "status promoted to a label"                      'status="401"'
expect "scanner path collapses to other"                 'route="other"'
expect "remote_addr is structured metadata, not a label" '"remote_addr":"203\.0\.113\.10"'
expect "optional request_time captured when present"     '"request_time":"0\.042"'
expect "id collapsed mid-path too"                       'route="/packages/:id/offers"'
refute "no raw scanner path anywhere in the labels"      'route="/(wp-admin|\.env|vendor)'
refute "no per-request numeric path label"               'route="/packages/7/offers"'
refute "no raw non-uuid/numeric suffix leaked as route (F3)" 'route="/subscriptions/(abc|%2e)'
expect "adversarial uncollapsed suffix collapses to other (F3)" 'route="other"'

if [ "$fail" -ne 0 ]; then
  echo "== alloy log (last 20 lines)"; tail -20 "$WORK/raw.txt"
  echo "RESULT: FAIL"; exit 1
fi
echo "RESULT: PASS"
