#!/usr/bin/env bash
#
# Phase 1.5 — does remote_write backfill survive a gap, and does it need
# `storage.tsdb.out_of_order_time_window` on the Prometheus side?
#
# Run ONE round at a time on the monitoring VM:
#   ./run.sh A            # phase-1 Prometheus config (out_of_order_time_window: 1h)
#   ./run.sh B            # control config, no out-of-order window
#   ./run.sh A S1         # a single scenario
#
# WHAT IT TOUCHES: it stops/starts and pauses/unpauses the `prometheus`
# container of the `subscription-monitoring` project, and starts/restarts the
# test-only `alloy-test` container. It NEVER runs `down`, never passes `-v`,
# never prunes, and never touches another compose project. All data volumes
# are left alone; the only thing recreated is the prometheus container itself
# (to swap which config file is mounted), which keeps the prom-data volume.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MON_DIR="$(cd "$HERE/../.." && pwd)"

ROUND="${1:-}"
SCENARIOS="${2:-S1 S2 S3}"

PROM_URL="${PROM_URL:-http://127.0.0.1:9090}"   # override if you used the fallback ports
ALLOY_URL="${ALLOY_URL:-http://127.0.0.1:12345}"
BASELINE="${BASELINE:-120}"   # seconds of normal operation before the first gap
OUTAGE="${OUTAGE:-180}"       # length of each induced gap
SETTLE="${SETTLE:-240}"       # time given to Alloy to replay after the gap
STEP=15                       # scrape_interval of the test agent
PASS_PCT="${PASS_PCT:-90}"

PROM_METRIC_RE='^prometheus_tsdb_(head_)?(out_of_order|too_old|out_of_bound|head_samples_appended|samples_appended)'
ALLOY_METRIC_RE='^prometheus_remote_(storage|write)_[a-z_]*(samples|failed|dropped|retried|pending|highest|exemplars)[a-z_]*'

TMP="$(mktemp -d)"
trap 'cleanup' EXIT INT TERM

log()  { printf '%s  %s\n' "$(date +%H:%M:%S)" "$*"; }
fail() { printf '\nERROR: %s\n' "$*" >&2; exit 1; }

compose() {
  local files=(-f "$MON_DIR/docker-compose.yml" -f "$HERE/docker-compose.backfill.yml")
  if [ "$ROUND" = "B" ]; then
    files+=(-f "$HERE/docker-compose.round-b.yml")
  fi
  docker compose "${files[@]}" "$@"
}

cleanup() {
  # Whatever happened, never leave Prometheus paused or stopped.
  local cid
  cid="$(compose ps -q prometheus 2>/dev/null || true)"
  if [ -n "$cid" ]; then
    docker unpause "$cid" >/dev/null 2>&1 || true
  fi
  compose start prometheus >/dev/null 2>&1 || true
  rm -rf "$TMP"
}

prom_query() {
  # $1 = PromQL. Prints the scalar value, or 0 when the query returns nothing.
  curl -sG --max-time 15 --data-urlencode "query=$1" "$PROM_URL/api/v1/query" \
    | jq -r '.data.result[0].value[1] // "0"'
}

wait_prom_ready() {
  local i
  for i in $(seq 1 60); do
    if curl -sf --max-time 3 "$PROM_URL/-/ready" >/dev/null 2>&1; then return 0; fi
    sleep 2
  done
  fail "Prometheus ไม่กลับมา ready ที่ $PROM_URL"
}

# Metric names are never assumed: whatever the running binaries expose and
# matches the regexes above is what gets reported.
snapshot() {
  # $1 = base url, $2 = regex, $3 = output file
  curl -s --max-time 10 "$1/metrics" 2>/dev/null \
    | grep -Ev '^#' \
    | grep -E "$2" \
    | awk '{print $1, $NF}' | sort > "$3" || true
}

delta_table() {
  # $1 = before file, $2 = after file
  if [ ! -s "$2" ]; then
    echo "      (ไม่พบ metric ที่ตรงกับ pattern — ดูหัวข้อ UNVERIFIED ใน README)"
    return
  fi
  awk 'NR==FNR { b[$1]=$2; next }
       { d = $2 - (($1 in b) ? b[$1] : 0);
         printf "      %-62s %+12.0f   (now %.0f)\n", $1, d, $2 }' "$1" "$2"
}

ensure_round_config() {
  log "ปรับ Prometheus ให้ตรงกับรอบ $ROUND (recreate container, ไม่แตะ volume)"
  compose up -d prometheus >/dev/null
  wait_prom_ready
  local cfg has
  cfg="$(curl -sf --max-time 10 "$PROM_URL/api/v1/status/config" | jq -r '.data.yaml')"
  has="$(printf '%s' "$cfg" | grep -c 'out_of_order_time_window' || true)"
  case "$ROUND" in
    A) [ "$has" -ge 1 ] || fail "รอบ A ต้องมี out_of_order_time_window ใน config ที่โหลดอยู่ แต่ไม่พบ" ;;
    B) [ "$has" -eq 0 ] || fail "รอบ B ต้องไม่มี out_of_order_time_window แต่พบในconfig ที่โหลดอยู่" ;;
  esac
  if [ "$has" -ge 1 ]; then
    log "ยืนยันแล้ว: config ที่โหลดอยู่ 'มี' out_of_order_time_window"
  else
    log "ยืนยันแล้ว: config ที่โหลดอยู่ 'ไม่มี' out_of_order_time_window"
  fi
}

measure() {
  # $1 = scenario, $2 = gap start epoch, $3 = gap end epoch
  local name="$1" t0="$2" t1="$3"
  local dur expected actual actual_node control pct verdict gap
  dur=$(( t1 - t0 ))
  expected=$(( dur / STEP ))

  actual="$(prom_query "count_over_time(up{job=\"backfill_test\",test=\"backfill\"}[${dur}s] @ ${t1})")"
  actual_node="$(prom_query "count_over_time(node_time_seconds{job=\"backfill_test\",test=\"backfill\"}[${dur}s] @ ${t1})")"
  control="$(prom_query "count_over_time(up{job=\"monitoring-host\"}[${dur}s] @ ${t1})")"

  pct="$(awk -v a="$actual" -v e="$expected" 'BEGIN{ if (e==0) print 0; else printf "%.1f", (a/e)*100 }')"
  verdict="$(awk -v p="$pct" -v t="$PASS_PCT" 'BEGIN{ print (p+0 >= t+0) ? "PASS" : "FAIL" }')"
  gap="$(awk -v c="$control" -v e="$expected" 'BEGIN{ print (c+0 <= e*0.1) ? "ยืนยันว่าขาดจริง" : "ไม่ขาด (ผลเป็นโมฆะ)" }')"

  printf '\n  ── ผลรอบ %s / %s ──────────────────────────────────────\n' "$ROUND" "$name"
  printf '    ช่วงขาด                : %ss (%s → %s)\n' "$dur" "$(date -d "@$t0" +%H:%M:%S)" "$(date -d "@$t1" +%H:%M:%S)"
  printf '    sample ที่ควรมี        : %s   (ช่วง / %ss)\n' "$expected" "$STEP"
  printf '    backfill_test up series: %s  → %s%%  [%s]\n' "$actual" "$pct" "$verdict"
  printf '    backfill_test node_time : %s  (ตัวเทียบชุดที่สอง)\n' "$actual_node"
  printf '    ตัวควบคุม monitoring-host: %s  → %s\n' "$control" "$gap"
  printf '    Prometheus counters (delta ตลอดกรณีนี้):\n'
  delta_table "$TMP/prom.before.$name" "$TMP/prom.after.$name"
  printf '    Alloy counters (delta ตลอดกรณีนี้):\n'
  delta_table "$TMP/alloy.before.$name" "$TMP/alloy.after.$name"

  RESULTS+=("$(printf '%-6s %-4s %6ss %9s %9s %8s%%  %-5s  %s' \
    "$ROUND" "$name" "$dur" "$expected" "$actual" "$pct" "$verdict" "$gap")")
}

run_scenario() {
  local name="$1" cid t0 t1
  log "เริ่มกรณี $name (ขาด ${OUTAGE}s แล้วรอส่งต่อ ${SETTLE}s)"
  snapshot "$PROM_URL"  "$PROM_METRIC_RE"  "$TMP/prom.before.$name"
  snapshot "$ALLOY_URL" "$ALLOY_METRIC_RE" "$TMP/alloy.before.$name"

  t0="$(date +%s)"
  case "$name" in
    S1)
      log "  S1: docker compose stop prometheus"
      compose stop prometheus >/dev/null
      sleep "$OUTAGE"
      log "  S1: start prometheus"
      compose start prometheus >/dev/null
      ;;
    S2)
      cid="$(compose ps -q prometheus)"
      [ -n "$cid" ] || fail "หา container prometheus ไม่เจอ"
      log "  S2: docker pause prometheus"
      docker pause "$cid" >/dev/null
      sleep "$OUTAGE"
      log "  S2: unpause prometheus"
      docker unpause "$cid" >/dev/null
      ;;
    S3)
      log "  S3: stop prometheus แล้ว restart alloy-test ระหว่างช่วงขาด"
      compose stop prometheus >/dev/null
      sleep $(( OUTAGE / 3 ))
      compose --profile backfilltest restart alloy-test >/dev/null
      sleep $(( OUTAGE - OUTAGE / 3 ))
      log "  S3: start prometheus"
      compose start prometheus >/dev/null
      ;;
    *) fail "ไม่รู้จักกรณี '$name' (ใช้ได้: S1 S2 S3)" ;;
  esac
  t1="$(date +%s)"

  wait_prom_ready
  log "  รอ ${SETTLE}s ให้ Alloy ส่งย้อนหลัง"
  sleep "$SETTLE"

  snapshot "$PROM_URL"  "$PROM_METRIC_RE"  "$TMP/prom.after.$name"
  snapshot "$ALLOY_URL" "$ALLOY_METRIC_RE" "$TMP/alloy.after.$name"
  measure "$name" "$t0" "$t1"
}

### main ######################################################################

case "$ROUND" in
  A|B) ;;
  *) fail "ใช้: $0 A|B [\"S1 S2 S3\"]" ;;
esac

for tool in docker curl jq awk; do
  command -v "$tool" >/dev/null 2>&1 || fail "ต้องมีคำสั่ง '$tool' บนเครื่องนี้"
done

read -r -a SCENARIO_LIST <<< "$SCENARIOS"
est=$(( BASELINE + ${#SCENARIO_LIST[@]} * (OUTAGE + SETTLE + 40) ))
cat <<EOF

Phase 1.5 backfill test — รอบ $ROUND
  กรณีที่จะรัน      : ${SCENARIO_LIST[*]}
  เวลาโดยประมาณ     : ~$(( est / 60 )) นาที
  Prometheus        : $PROM_URL
  Alloy (ทดสอบ)     : $ALLOY_URL
  เกณฑ์ผ่าน         : ความครบ >= ${PASS_PCT}%

สคริปต์นี้จะ stop/pause container prometheus ชั่วคราว — ข้อมูลใน volume ไม่ถูกแตะ
และไม่มีการรัน down / prune / -v ที่ใดเลย

EOF

log "ตรวจว่า stack เฟส 1 ขึ้นอยู่"
compose ps --status running --format '{{.Service}}' | grep -qx prometheus    || fail "prometheus ไม่ได้รันอยู่ — เปิด stack เฟส 1 ก่อน"
compose ps --status running --format '{{.Service}}' | grep -qx node-exporter || fail "node-exporter ไม่ได้รันอยู่"

ensure_round_config

log "เปิด alloy-test (profile backfilltest)"
compose --profile backfilltest up -d alloy-test >/dev/null
for i in $(seq 1 30); do
  curl -sf --max-time 3 "$ALLOY_URL/metrics" >/dev/null 2>&1 && break
  [ "$i" -eq 30 ] && fail "alloy-test ไม่ ready ที่ $ALLOY_URL"
  sleep 2
done

log "รอ ${BASELINE}s ให้มีข้อมูลตั้งต้น"
sleep "$BASELINE"

base_up="$(prom_query 'count_over_time(up{job="backfill_test",test="backfill"}[2m])')"
log "ข้อมูลตั้งต้น: มี ${base_up} sample ของ backfill_test ใน 2 นาทีล่าสุด"
awk -v v="$base_up" 'BEGIN{ if (v+0 < 1) { print "ERROR: ยังไม่มีข้อมูลจาก alloy-test เข้ามาเลย — ตรวจ docker compose logs alloy-test"; exit 1 } }'

RESULTS=()
for s in "${SCENARIO_LIST[@]}"; do
  run_scenario "$s"
done

cat <<EOF

══════════════════════════════════════════════════════════════════════════════
สรุปรอบ $ROUND
รอบ    กรณี   ช่วง    ควรมี      ได้จริง    ความครบ  ผล     ตัวควบคุม
EOF
printf '%s\n' "${RESULTS[@]}"
cat <<EOF

ตีความ (ต้องมีผลทั้งรอบ A และ B ก่อนสรุป):
  A ผ่าน / B ล้ม   → out_of_order_time_window จำเป็นจริง เก็บค่าไว้
  ผ่านทั้ง A และ B → ไม่จำเป็น เอาออกได้ (แล้วรันซ้ำเพื่อยืนยัน)
  A ล้ม            → หยุด อย่าเพิ่งสรุป รายงานผลดิบทั้งหมด
ถ้าคอลัมน์ "ตัวควบคุม" ไม่ได้บอกว่า "ยืนยันว่าขาดจริง" แปลว่ากรณีนั้นเป็นโมฆะ
══════════════════════════════════════════════════════════════════════════════
EOF
