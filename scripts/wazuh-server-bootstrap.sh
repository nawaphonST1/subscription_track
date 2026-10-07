#!/usr/bin/env bash
# =============================================================================
# wazuh-server-bootstrap.sh — เตรียมฝั่ง SERVER ของ Wazuh single-node ให้พร้อม up
# =============================================================================
#
# ทำไมต้องมีสคริปต์นี้:
#   ไฟล์ที่ compose mount เข้าไป (infra/security/wazuh/config/) ไม่ได้อยู่ใน git
#   เพราะมี bcrypt hash และรหัส API จริงอยู่ข้างใน ตอนย้ายไปเครื่องใหม่จึงไม่มีอะไร
#   ตามไปด้วย และเคยต้องไล่แก้ทีละขั้นด้วยมือ ซึ่งพลาดง่ายมาก — 3 ใน 4 ขั้นข้างล่าง
#   เคยทำให้ stack พังมาแล้วจริง ๆ:
#
#     1. cert ถูก generate ลงผิดโฟลเดอร์ (ลืม --project-directory .) แล้ว docker
#        สร้าง *.pem เป็น "โฟลเดอร์เปล่า" ให้แทน -> indexer/manager ขึ้นไม่ได้
#     2. internal_users.yml ยังเป็น bcrypt hash default ของ upstream -> 401 ทุกทาง
#     3. wazuh_dashboard/wazuh.yml ยังเป็นรหัส API default ของ upstream -> 401
#
#   สคริปต์นี้ทำขั้น 3-9 ของ portability checklist ให้จบในคำสั่งเดียว และ idempotent
#   รันซ้ำกับ stack ที่กำลังรันอยู่ได้ โดยไม่แตะอะไรที่ถูกต้องอยู่แล้ว
#
# ใช้งาน:
#   ./scripts/wazuh-server-bootstrap.sh                 # ตั้งค่าตามค่า default
#   ./scripts/wazuh-server-bootstrap.sh --dry-run       # บอกว่าจะทำอะไร โดยไม่แตะไฟล์
#   ./scripts/wazuh-server-bootstrap.sh --rotate        # บังคับสร้าง hash/รหัสใหม่จาก .env
#   ./scripts/wazuh-server-bootstrap.sh --vd on         # เปิด Vulnerability Detection
#   ./scripts/wazuh-server-bootstrap.sh --apply-security  # push internalusers เข้า indexer ที่รันอยู่
#
# ต้องมีก่อน: docker + compose plugin, python3, infra/security/wazuh/.env (คัดจาก .env.example)
# และ upstream/ ที่ clone มาแล้ว:
#   git clone --depth 1 -b v4.14.8 https://github.com/wazuh/wazuh-docker.git \
#     infra/security/wazuh/upstream
#
# สคริปต์นี้ไม่ฝังรหัสผ่านใด ๆ ทุกค่าอ่านจาก .env และไม่ echo ค่าออกมาที่ stdout
# =============================================================================
set -euo pipefail

# ---------------------------------------------------------------------------
# ค่าคงที่
# ---------------------------------------------------------------------------
INDEXER_IMAGE="wazuh/wazuh-indexer:4.14.8"   # ใช้ hash.sh/securityadmin.sh จาก image นี้
CERT_COUNT_EXPECTED=12                       # จำนวนไฟล์ที่ generator ต้องผลิตออกมา

DRY_RUN=0
FORCE_ROTATE=0
VD_MODE="off"            # off = ปิด Vulnerability Detection (ค่า default ดูเหตุผลใน apply_vd)
APPLY_SECURITY=0

RED=$'\033[31m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; BOLD=$'\033[1m'; RESET=$'\033[0m'
[ -t 1 ] || { RED=""; GREEN=""; YELLOW=""; BOLD=""; RESET=""; }

step()  { printf '\n%s==> %s%s\n' "$BOLD" "$*" "$RESET"; }
ok()    { printf '    %sOK%s    %s\n'   "$GREEN"  "$RESET" "$*"; }
skip()  { printf '    %sSKIP%s  %s\n'   "$YELLOW" "$RESET" "$*"; }
fail()  { printf '    %sFAIL%s  %s\n'   "$RED"    "$RESET" "$*" >&2; }
die()   { fail "$*"; exit 1; }
would() { printf '    %sDRY%s   จะ: %s\n' "$YELLOW" "$RESET" "$*"; }

usage() { sed -n '2,36p' "$0" | sed 's/^# \{0,1\}//'; exit 0; }

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run)        DRY_RUN=1 ;;
    --rotate)         FORCE_ROTATE=1 ;;
    --apply-security) APPLY_SECURITY=1 ;;
    --vd)             shift; VD_MODE="${1:-}" ;;
    -h|--help)        usage ;;
    *) die "ไม่รู้จัก option: $1 (ดู --help)" ;;
  esac
  shift
done
case "$VD_MODE" in on|off) ;; *) die "--vd ต้องเป็น on หรือ off เท่านั้น" ;; esac

# ---------------------------------------------------------------------------
# 0. preflight
# ---------------------------------------------------------------------------
step "0. preflight"

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[ -n "$REPO_ROOT" ] || die "ต้องรันในรีโป git"
WAZUH_DIR="$REPO_ROOT/infra/security/wazuh"
[ -d "$WAZUH_DIR" ] || die "ไม่พบ $WAZUH_DIR"
cd "$WAZUH_DIR"

for c in docker python3; do
  command -v "$c" >/dev/null 2>&1 || die "ต้องมี $c ก่อน"
done
docker compose version >/dev/null 2>&1 || die "ต้องมี docker compose plugin (v2)"
ok "docker, docker compose, python3 พร้อม"

[ -f .env ] || die ".env ยังไม่มี — cp .env.example .env แล้วใส่ค่าจริงก่อน (ดู README §3)"
[ -d upstream/single-node/config ] || die \
  "upstream/ ยังไม่มี — git clone --depth 1 -b v4.14.8 https://github.com/wazuh/wazuh-docker.git upstream"
ok ".env และ upstream/ อยู่ครบ"

# อ่าน .env เข้ามาแบบไม่ echo ค่าใด ๆ ออกไป
set -a; . ./.env; set +a
missing=""
for v in WAZUH_INDEXER_PASSWORD WAZUH_API_PASSWORD WAZUH_DASHBOARD_PASSWORD; do
  [ -n "${!v:-}" ] || missing="$missing $v"
done
[ -z "$missing" ] || die "ตัวแปรใน .env ยังว่าง:$missing"
ok "ตัวแปรรหัสผ่านใน .env ครบ (ไม่แสดงค่า)"

# เลือก image เล็ก ๆ ที่มีอยู่แล้วสำหรับอ่านโฟลเดอร์ cert ที่ generator ตั้งเป็น root:500
pick_helper_image() {
  local img
  for img in alpine:3 busybox:latest "$INDEXER_IMAGE"; do
    docker image inspect "$img" >/dev/null 2>&1 && { echo "$img"; return; }
  done
  echo alpine:3   # ไม่มีเลย -> ให้ docker ไป pull (ขนาด ~4 MB)
}

# ---------------------------------------------------------------------------
# 1. คัด config ของ upstream มาไว้ที่ ./config
# ---------------------------------------------------------------------------
step "1. config/ (คัดจาก upstream/single-node/config)"

if [ -d config/wazuh_cluster ] && [ -d config/wazuh_indexer ] && [ -d config/wazuh_dashboard ]; then
  skip "config/ มีอยู่แล้ว ไม่เขียนทับ (ของจริงอยู่ในนี้)"
elif [ "$DRY_RUN" = 1 ]; then
  would "cp -r upstream/single-node/config ./config"
else
  cp -r upstream/single-node/config ./config
  ok "คัด config/ มาแล้ว"
fi

# ---------------------------------------------------------------------------
# 2. generate cert — ต้องมี --project-directory . เสมอ
# ---------------------------------------------------------------------------
step "2. cert ของ indexer"

CERTS_DIR="config/wazuh_indexer_ssl_certs"

# generator ตั้งโฟลเดอร์เป็น root dr-x------ ผู้ใช้ปกติจึงอ่านไม่ได้ ต้องนับผ่าน container
count_certs() {
  local img; img="$(pick_helper_image)"
  docker run --rm -v "$PWD/$CERTS_DIR":/c:ro --entrypoint sh "$img" -c '
    n=0; bad=0
    for f in /c/*; do
      [ -e "$f" ] || continue
      if [ -f "$f" ]; then n=$((n+1)); else bad=$((bad+1)); fi
    done
    echo "$n $bad"' 2>/dev/null || echo "0 0"
}

certs_ok() {
  [ -d "$CERTS_DIR" ] || return 1
  local out n bad
  out="$(count_certs)"; n="${out% *}"; bad="${out#* }"
  [ "$n" = "$CERT_COUNT_EXPECTED" ] && [ "$bad" = "0" ]
}

if certs_ok; then
  skip "cert ครบ $CERT_COUNT_EXPECTED ไฟล์ และเป็น regular file ทั้งหมด"
elif [ "$DRY_RUN" = 1 ]; then
  would "ลบ $CERTS_DIR แล้ว generate ใหม่ด้วย --project-directory ."
else
  # ถ้าเคย up ไปก่อนที่ cert จะมี docker จะสร้าง *.pem เป็นโฟลเดอร์เปล่าทิ้งไว้ ต้องล้างก่อน
  if [ -d "$CERTS_DIR" ]; then
    docker run --rm -v "$PWD:/w" --entrypoint sh "$(pick_helper_image)" \
      -c "rm -rf /w/$CERTS_DIR" >/dev/null
  fi
  # --project-directory . คือหัวใจ: ถ้าไม่ใส่ compose จะคิด ./config/ เทียบกับโฟลเดอร์ของไฟล์ -f
  # (upstream/single-node/) แล้ว cert จะไปตกผิดที่ โดยไม่มี error ใด ๆ ให้เห็น
  docker compose -f upstream/single-node/generate-indexer-certs.yml \
    --project-directory . run --rm generator
  certs_ok || die "generate cert แล้วยังไม่ครบ $CERT_COUNT_EXPECTED ไฟล์ — ดู log ข้างบน และเช็ก df -h /"
  ok "generate cert สำเร็จ ครบ $CERT_COUNT_EXPECTED ไฟล์"
fi

# ---------------------------------------------------------------------------
# 3. หมุน bcrypt hash ของ admin + kibanaserver ใน internal_users.yml
# ---------------------------------------------------------------------------
step "3. รหัสผ่าน internal_users.yml (admin, kibanaserver)"

IU="config/wazuh_indexer/internal_users.yml"
IU_UPSTREAM="upstream/single-node/config/wazuh_indexer/internal_users.yml"

# bcrypt หา hash ย้อนกลับไม่ได้ จึงใช้วิธีเทียบกับ hash default ของ upstream:
# ถ้ายังเหมือน upstream = ยังไม่เคยหมุน -> หมุนให้ ถ้าต่างแล้ว = หมุนไปแล้ว -> ข้าม
# อยากหมุนซ้ำ (เช่นเปลี่ยนรหัสใน .env) ให้ใส่ --rotate
needs_rotate() {
  local user="$1"
  [ "$FORCE_ROTATE" = 1 ] && return 0
  python3 - "$IU" "$IU_UPSTREAM" "$user" <<'PY'
import io, re, sys
cur, up, user = sys.argv[1], sys.argv[2], sys.argv[3]
def h(path):
    s = io.open(path, encoding='utf-8').read()
    m = re.search(r'(?m)^%s:\n(?:[ \t]+.*\n)*?[ \t]+hash:[ \t]*(.*)$' % re.escape(user), s)
    return m.group(1).strip() if m else None
sys.exit(0 if h(cur) is not None and h(cur) == h(up) else 1)
PY
}

gen_hash() {   # $1 = ชื่อตัวแปรใน .env ที่เก็บรหัสผ่าน; พิมพ์เฉพาะ bcrypt hash ออกมา
  docker run --rm -e PW="${!1}" -e OPENSEARCH_JAVA_HOME=/usr/share/wazuh-indexer/jdk \
    --entrypoint bash "$INDEXER_IMAGE" \
    /usr/share/wazuh-indexer/plugins/opensearch-security/tools/hash.sh -env PW 2>/dev/null \
    | grep -oE '^\$2[aby]\$[0-9]{2}\$[./A-Za-z0-9]{53}$' | tail -1
}

set_hash() {   # $1 = ชื่อ user, $2 = hash
  python3 - "$IU" "$1" "$2" <<'PY'
import io, os, re, sys, tempfile
p, user, h = sys.argv[1], sys.argv[2], sys.argv[3]
s = io.open(p, encoding='utf-8').read()
assert len(s) > 500, 'internal_users.yml สั้นผิดปกติ — หยุด'
pat = re.compile(r'(?m)^(%s:\n(?:[ \t]+.*\n)*?[ \t]+hash:[ \t]*).*$' % re.escape(user))
new, n = pat.subn(lambda m: m.group(1) + '"%s"' % h, s, count=1)
assert n == 1, 'ไม่พบบรรทัด hash ของ %s' % user
# เขียนลง temp แล้ว rename ทับ: ถ้าดิสก์เต็มกลางคัน ไฟล์เดิมจะไม่โดน truncate
fd, tmp = tempfile.mkstemp(dir=os.path.dirname(p))
with io.open(fd, 'w', encoding='utf-8') as f:
    f.write(new); f.flush(); os.fsync(f.fileno())
assert os.path.getsize(tmp) == len(new.encode()), 'เขียนไม่ครบ (ดิสก์เต็ม?) — ยกเลิก'
os.chmod(tmp, 0o664); os.replace(tmp, p)
PY
}

ROTATED=0
for pair in "admin:WAZUH_INDEXER_PASSWORD" "kibanaserver:WAZUH_DASHBOARD_PASSWORD"; do
  user="${pair%%:*}"; var="${pair##*:}"
  if ! needs_rotate "$user"; then
    skip "$user — หมุนไปแล้ว (ใส่ --rotate ถ้าต้องการหมุนซ้ำ)"
    continue
  fi
  if [ "$DRY_RUN" = 1 ]; then
    would "สร้าง bcrypt hash ใหม่ของ $user จาก \$$var แล้วเขียนลง $IU"
    continue
  fi
  h="$(gen_hash "$var")"
  [ -n "$h" ] || die "สร้าง bcrypt hash ของ $user ไม่สำเร็จ"
  set_hash "$user" "$h"
  ok "$user — เขียน hash ใหม่จาก \$$var แล้ว (${#h} ตัวอักษร)"
  ROTATED=1
done

# ---------------------------------------------------------------------------
# 4. รหัส API ของ wazuh-wui ใน wazuh_dashboard/wazuh.yml
# ---------------------------------------------------------------------------
step "4. รหัส API ใน wazuh_dashboard/wazuh.yml"

WY="config/wazuh_dashboard/wazuh.yml"

# อันนี้เก็บเป็น plaintext เทียบตรง ๆ ได้ จึง idempotent จริงและแก้ตัวเองได้
if [ "$DRY_RUN" = 1 ]; then
  if python3 - "$WY" <<'PY'
import io, os, re, sys
s = io.open(sys.argv[1], encoding='utf-8').read()
m = re.search(r'(?m)^\s*password:\s*"?(.*?)"?\s*$', s)
sys.exit(0 if m and m.group(1) == os.environ['WAZUH_API_PASSWORD'] else 1)
PY
  then skip "ตรงกับ \$WAZUH_API_PASSWORD อยู่แล้ว"
  else would "เขียน \$WAZUH_API_PASSWORD ลง $WY แทนค่าเดิม"
  fi
else
  wy_result="$(python3 - "$WY" <<'PY'
import io, os, re, sys, tempfile
p = sys.argv[1]
s = io.open(p, encoding='utf-8').read()
pw = os.environ['WAZUH_API_PASSWORD']
m = re.search(r'(?m)^\s*password:\s*"?(.*?)"?\s*$', s)
assert m, 'ไม่พบบรรทัด password ใน wazuh.yml'
if m.group(1) == pw:
    print('__SKIP__'); raise SystemExit(0)
new = re.sub(r'(?m)^(\s*password:\s*).*$', lambda mm: mm.group(1) + '"%s"' % pw, s, count=1)
# อ่านกลับมาตรวจว่าแทนที่โดนบรรทัดที่ถูกต้องจริง (กันกรณี regex ไปโดนบรรทัดอื่น
# แล้วรหัส default ของ upstream ยังค้างอยู่ ซึ่งจะทำให้ dashboard ได้ 401 เงียบ ๆ)
check = re.search(r'(?m)^\s*password:\s*"?(.*?)"?\s*$', new)
assert check and check.group(1) == pw, 'แทนรหัส API ไม่สำเร็จ — ยกเลิก'
fd, tmp = tempfile.mkstemp(dir=os.path.dirname(p))
with io.open(fd, 'w', encoding='utf-8') as f:
    f.write(new); f.flush(); os.fsync(f.fileno())
assert os.path.getsize(tmp) == len(new.encode()), 'เขียนไม่ครบ (ดิสก์เต็ม?) — ยกเลิก'
os.chmod(tmp, 0o664); os.replace(tmp, p)
print('__WROTE__')
PY
)"
  case "$wy_result" in
    __SKIP__) skip "ตรงกับ \$WAZUH_API_PASSWORD อยู่แล้ว" ;;
    *)        ok "เขียน \$WAZUH_API_PASSWORD ลง $WY แล้ว" ;;
  esac
fi

# ---------------------------------------------------------------------------
# 5. Vulnerability Detection
# ---------------------------------------------------------------------------
step "5. Vulnerability Detection (--vd $VD_MODE)"

MC="config/wazuh_cluster/wazuh_manager.conf"
VD_NOTE='ปิดไว้ตั้งใจ: image แถมไฟล์ CVE มาเป็น .tar.xz ~410 MB และทุกครั้งที่สร้าง container
       ใหม่ manager จะแตกมันเป็น .tar ขนาด ~4 GB ลง /var/ossec/tmp ซึ่งไม่ใช่ volume จึงกิน
       writable layer ~4.4 GB ต่อการสร้าง container หนึ่งครั้ง และเคยทำดิสก์เครื่อง dev เต็มจริง
       demo ใช้ FIM + SSH auth.log + nginx 404 ไม่ได้ใช้ CVE feed
       ถ้าเครื่องใหม่ดิสก์ >= 64 GB เปิดกลับได้ด้วย --vd on'

apply_vd() {
  VD_MODE="$VD_MODE" VD_NOTE="$VD_NOTE" python3 - "$MC" <<'PY'
import io, os, re, sys, tempfile
p = sys.argv[1]
want = 'yes' if os.environ['VD_MODE'] == 'on' else 'no'
note = os.environ['VD_NOTE']
s = io.open(p, encoding='utf-8').read()
m = re.search(r'(?s)(<vulnerability-detection>\s*<enabled>)(yes|no)(</enabled>)', s)
assert m, 'ไม่พบบล็อก <vulnerability-detection> ใน wazuh_manager.conf'
new = s
if want == 'no':
    if '/var/ossec/tmp' not in new:                      # ใส่คอมเมนต์อธิบายครั้งเดียว
        new = new.replace('  <vulnerability-detection>',
                          '  <!-- %s -->\n  <vulnerability-detection>' % note, 1)
else:
    new = re.sub(r'(?s)[ \t]*<!--[^>]*?/var/ossec/tmp.*?-->\n', '', new, count=1)
new = re.sub(r'(?s)(<vulnerability-detection>\s*<enabled>)(yes|no)(</enabled>)',
             lambda mm: mm.group(1) + want + mm.group(3), new, count=1)
if new == s:
    print('__SKIP__'); raise SystemExit(0)
fd, tmp = tempfile.mkstemp(dir=os.path.dirname(p))
with io.open(fd, 'w', encoding='utf-8') as f:
    f.write(new); f.flush(); os.fsync(f.fileno())
assert os.path.getsize(tmp) == len(new.encode()), 'เขียนไม่ครบ (ดิสก์เต็ม?) — ยกเลิก'
os.chmod(tmp, 0o664); os.replace(tmp, p)
print('__WROTE__')
PY
}

if [ "$DRY_RUN" = 1 ]; then
  cur="$(grep -A1 '<vulnerability-detection>' "$MC" | grep -oE '<enabled>(yes|no)' | head -1 | sed 's/<enabled>//')"
  want=$([ "$VD_MODE" = on ] && echo yes || echo no)
  [ "$cur" = "$want" ] && skip "<enabled>$cur</enabled> ตรงกับที่ต้องการแล้ว" \
                       || would "เปลี่ยน <enabled>$cur</enabled> เป็น <enabled>$want</enabled>"
else
  case "$(apply_vd)" in
    __SKIP__) skip "ตั้งเป็น $VD_MODE อยู่แล้ว" ;;
    *)        ok "ตั้ง Vulnerability Detection = $VD_MODE แล้ว" ;;
  esac
fi

# ---------------------------------------------------------------------------
# 6. (ไม่บังคับ) push internalusers เข้า indexer ที่รันอยู่
# ---------------------------------------------------------------------------
step "6. ดันรหัสใหม่เข้า security index"

# indexer อ่าน internal_users.yml แค่ตอนสร้าง .opendistro_security ครั้งแรกเท่านั้น
# เครื่องใหม่ที่ยังไม่เคย up -> ไม่ต้องทำอะไร boot แรกมันอ่านเอง
# แต่ถ้า index มีอยู่แล้ว (เช่นเคย up ด้วยรหัสเก่า) ต้อง push ด้วย securityadmin.sh
if [ "$APPLY_SECURITY" != 1 ]; then
  if [ "$ROTATED" = 1 ] && docker compose ps --status running --services 2>/dev/null | grep -q '^wazuh.indexer$'; then
    skip "indexer กำลังรันและเพิ่งหมุนรหัส — ต้องรันซ้ำด้วย --apply-security ไม่งั้นรหัสใหม่ยังไม่มีผล"
  else
    skip "ข้าม (boot แรกของ indexer จะอ่าน internal_users.yml เอง)"
  fi
elif [ "$DRY_RUN" = 1 ]; then
  would "รัน securityadmin.sh -t internalusers บน wazuh.indexer"
else
  docker compose ps --status running --services 2>/dev/null | grep -q '^wazuh.indexer$' \
    || die "--apply-security ต้องให้ wazuh.indexer รันอยู่ก่อน (docker compose up -d wazuh.indexer)"
  docker compose exec -T wazuh.indexer env OPENSEARCH_JAVA_HOME=/usr/share/wazuh-indexer/jdk bash \
    /usr/share/wazuh-indexer/plugins/opensearch-security/tools/securityadmin.sh \
    -f /usr/share/wazuh-indexer/config/opensearch-security/internal_users.yml \
    -t internalusers -icl -nhnv \
    -cacert /usr/share/wazuh-indexer/config/certs/root-ca.pem \
    -cert   /usr/share/wazuh-indexer/config/certs/admin.pem \
    -key    /usr/share/wazuh-indexer/config/certs/admin-key.pem \
    -h localhost -p 9200 | tail -3
  ok "push internalusers เข้า security index แล้ว"
fi

# ---------------------------------------------------------------------------
step "เสร็จแล้ว"
cat <<'NEXT'
    ขั้นต่อไป:
      docker compose up -d
      docker compose ps
      แล้วทำ README §4 (authd.pass) และ §5 (ติดตั้ง agent)

    ก่อน up ครั้งแรก ตรวจด้วยว่า:
      df -h /                      # ต้องเหลืออย่างน้อย ~8 GB
      cat /proc/sys/vm/max_map_count   # ต้องเป็น 262144
NEXT
