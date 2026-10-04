#!/usr/bin/env bash
#
# Produce the two benign traffic patterns the Wazuh demo detects, AGAINST OUR
# OWN AZURE VM AND NOTHING ELSE:
#
#   1. a few failed SSH logins -> /var/log/auth.log -> Wazuh sshd rules
#   2. a few requests for paths that do not exist -> nginx access log ->
#      Wazuh web rules, and the route="other" spike on the Loki dashboard
#
# This is NOT an exploit and NOT a penetration test. It makes a handful of
# login attempts that are DESIGNED TO FAIL (a throwaway username, no real
# password) and requests URLs that return 404 — exactly the noise a commodity
# internet scanner already sends that VM every day. It writes nothing, changes
# nothing, and tries no credential that could ever succeed. Its only purpose is
# to make a detection light up so the SIEM can be shown working.
#
# USAGE — the ownership flag is mandatory and has no default:
#
#   ./scripts/wazuh-demo-attack.sh --target <AZURE_VM_PUBLIC_IP> --i-own-this-target
#
# Refuses, by default, independent of any environment variable:
#   - running at all without --i-own-this-target
#   - --target is RESOLVED first (getent/dig/host), and every resolved
#     address is validated — never the raw string the caller typed. This is
#     what makes a hostname, an IPv6 literal, and a non-canonical IPv4
#     encoding (decimal/octal) all land on the same checks as a plain IP,
#     rather than slipping past string-pattern matching that only recognizes
#     one spelling.
#   - any resolved address that is private / loopback / link-local / CGNAT
#     (so it can never be aimed at the Tailscale network by mistake)
#   - IPv6 outright (not supported; the project's target is IPv4-only)
#   - a hard-coded list of this project's own protected hostnames (the
#     lecturer's monitoring VM and its known aliases) — refused on sight,
#     before resolution, and NOT overridable by any environment variable
#   - any host listed in DENY_HOSTS (an additional, operator-supplied list)
#
# What this does NOT, and architecturally cannot, catch: a hostname that
# resolves to some OTHER public IP this script has no way to know is
# sensitive (e.g. a university address outside every documented private
# range). Resolving the name and checking the result is the best an
# offline script can do; it is not a guarantee about who owns every public
# IP on the internet, so "--target <the real Azure VM>" is still the only
# correct way to run this.
#
# Options:
#   --target <ip|host>   the project's own Azure VM (required)
#   --i-own-this-target  explicit confirmation of ownership (required)
#   --ssh-attempts N     failed SSH logins to make (default 8)
#   --http-probes  N     non-existent paths to request (default 12)
#   --dry-run            print what it would do, contact nothing
#
set -euo pipefail

SSH_ATTEMPTS=8
HTTP_PROBES=12
SSH_PORT="${SSH_PORT:-22}"
HTTP_SCHEME="${HTTP_SCHEME:-http}"
TARGET=""
OWNED="no"
DRY_RUN="no"

# Hostnames this script must never touch, however they are spelled or
# resolved. Hard-coded and checked on the raw input BEFORE resolution — this
# is deliberately not just folded into the private-IP check below, because
# the whole point is that this must still refuse the name even if DNS is
# broken, absent, or returns something unexpected. Extend this list, don't
# rely on DENY_HOSTS, for anything that must never be overridable by an
# operator's environment.
# Known names for the lecturer's monitoring VM
# (doc/architecture/DP5_monitoring_plan.md: "VM อาจารย์ `mob07-mob`").
HARD_DENY_HOSTNAMES="mob07-mob mob07-mob.local mob07-mob.internal"

# Hosts this script must never touch, whatever is passed. Extend via the
# environment: DENY_HOSTS="a.b.c.d e.f.g.h". Unlike HARD_DENY_HOSTNAMES above,
# this list is operator-supplied and checked against the raw input, not a
# resolved address — same as before this fix.
DEFAULT_DENY="${DENY_HOSTS:-}"

die() { echo "REFUSING: $*" >&2; exit 2; }
note() { echo "== $*"; }

usage() {
  sed -n '2,36p' "${BASH_SOURCE[0]}" | sed 's/^#\{0,1\} \{0,1\}//'
  exit "${1:-1}"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --target) TARGET="${2:-}"; shift 2 ;;
    --i-own-this-target) OWNED="yes"; shift ;;
    --ssh-attempts) SSH_ATTEMPTS="${2:-}"; shift 2 ;;
    --http-probes) HTTP_PROBES="${2:-}"; shift 2 ;;
    --dry-run) DRY_RUN="yes"; shift ;;
    -h|--help) usage 0 ;;
    *) echo "unknown argument: $1" >&2; usage 1 ;;
  esac
done

# --- the guard, before anything reaches the network ------------------------
[ "$OWNED" = "yes" ] || die "pass --i-own-this-target. This script is only ever run against the project's own Azure VM."
[ -n "$TARGET" ] || die "--target <ip|host> is required."

case "$SSH_ATTEMPTS" in (*[!0-9]*|'') die "--ssh-attempts must be a number";; esac
case "$HTTP_PROBES" in (*[!0-9]*|'') die "--http-probes must be a number";; esac
[ "$SSH_ATTEMPTS" -le 50 ] || die "--ssh-attempts $SSH_ATTEMPTS is above the safety cap of 50; this is a demo, not a brute-force run."
[ "$HTTP_PROBES" -le 100 ] || die "--http-probes $HTTP_PROBES is above the safety cap of 100."

# --- 0. hard-coded denylist — raw input, before anything else runs --------
lower_target="$(printf '%s' "$TARGET" | tr '[:upper:]' '[:lower:]')"
while [[ "$lower_target" == *. ]]; do
  lower_target="${lower_target%.}"
done
for denied in $HARD_DENY_HOSTNAMES; do
  [ "$lower_target" = "$denied" ] && die "$TARGET is a hard-coded protected host (the lecturer's monitoring VM or a known alias). This cannot be overridden by any flag or environment variable."
done

for denied in $DEFAULT_DENY; do
  [ "$TARGET" = "$denied" ] && die "$TARGET is in DENY_HOSTS."
done

# --- 1. strict IPv4 validator -----------------------------------------------
#
# Exactly four dot-separated groups of 1-3 digits, each 0-255, no leading
# zero on a non-zero octet. Anything that isn't this one canonical shape
# fails — a bare integer (decimal-encoded IPv4, e.g. 2130706433), a
# leading-zero/octal-looking form (e.g. 0177.0.0.1), a hex form, an IPv6
# literal, a hostname — all of them. This is deliberately a allow-list check,
# not a blocklist of known-bad encodings: it does not need to recognize every
# alternate representation by name, only to refuse everything that is not
# exactly dotted-decimal.
is_canonical_ipv4() {
  local ip="$1" octet
  case "$ip" in
    ''|*[!0-9.]*) return 1 ;;  # only digits and dots allowed at all
  esac
  [[ "$ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]] || return 1
  for octet in ${ip//./ }; do
    case "$octet" in
      0) ;;
      0*) return 1 ;; # leading zero (e.g. "077"): refuse rather than guess octal vs decimal
    esac
    [ "$octet" -le 255 ] || return 1
  done
  return 0
}

# --- 2. resolve TARGET; collect every candidate address to validate -------
#
# Tries getent, then dig, then host — whichever this machine has. An
# already-literal IPv4 address is also added to the candidate list directly
# (not only via the resolver), so a missing/broken resolver can never make
# validation silently looser for the common case of a plain IP.
resolve_addresses() {
  local host="$1" out=""
  if command -v getent >/dev/null 2>&1; then
    out="$(getent ahosts "$host" 2>/dev/null | awk '{print $1}' | sort -u || true)"
  fi
  if [ -z "$out" ] && command -v dig >/dev/null 2>&1; then
    out="$( { dig +short A "$host" 2>/dev/null; dig +short AAAA "$host" 2>/dev/null; } | sort -u || true)"
  fi
  if [ -z "$out" ] && command -v host >/dev/null 2>&1; then
    out="$(host "$host" 2>/dev/null \
      | awk '/has address/{print $NF} /has IPv6 address/{print $NF}' || true)"
  fi
  printf '%s\n' "$out"
}

candidates="$(resolve_addresses "$TARGET")"
if is_canonical_ipv4 "$TARGET"; then
  candidates="$(printf '%s\n%s\n' "$TARGET" "$candidates" | sort -u)"
fi
candidates="$(printf '%s\n' "$candidates" | sed '/^$/d')"

[ -n "$candidates" ] || die "could not resolve '$TARGET' to any address. A target must be a plain dotted-decimal IPv4 address, or a hostname this machine's resolver can look up."

# --- 3. every resolved candidate must be a public, non-reserved IPv4 addr --
while IFS= read -r addr; do
  case "$addr" in
    *:*) die "'$TARGET' resolves to an IPv6 address ($addr). IPv6 targets are not supported by this script." ;;
  esac
  is_canonical_ipv4 "$addr" \
    || die "'$TARGET' resolved to '$addr', which is not a canonical dotted-decimal IPv4 address (non-canonical encodings — decimal, octal, leading-zero — are rejected by construction, whatever they decode to)."
  case "$addr" in
    127.*|10.*|169.254.*|0.*|255.*) die "'$TARGET' resolves to $addr, a loopback/private/reserved address." ;;
    192.168.*) die "'$TARGET' resolves to $addr, a private (192.168/16) address." ;;
    172.1[6-9].*|172.2[0-9].*|172.3[0-1].*) die "'$TARGET' resolves to $addr, a private (172.16/12) address." ;;
    100.6[4-9].*|100.[7-9][0-9].*|100.1[0-1][0-9].*|100.12[0-7].*) die "'$TARGET' resolves to $addr, in the Tailscale/CGNAT range (100.64/10). This script is for the PUBLIC Azure VM only." ;;
  esac
done <<< "$candidates"

note "target        : $TARGET"
note "ssh attempts  : $SSH_ATTEMPTS (all designed to fail)"
note "http probes   : $HTTP_PROBES (all expected to 404)"
note "mode          : $([ "$DRY_RUN" = yes ] && echo DRY-RUN || echo live)"
echo

run() {
  if [ "$DRY_RUN" = "yes" ]; then
    echo "DRY-RUN: $*"
  else
    "$@" || true
  fi
}

# --- 1. failed SSH logins --------------------------------------------------
# A username that does not exist on the VM, BatchMode so ssh never prompts and
# never sends a password, and key auth disabled so every attempt is a clean
# failure recorded in auth.log. There is no password here to get right.
note "1/2 failed SSH logins (Wazuh: sshd authentication failure / brute force)"
BOGUS_USER="wazuh-demo-nouser-$$"
if ! command -v ssh >/dev/null 2>&1; then
  echo "   ssh client not found; skipping the SSH pattern"
else
  for i in $(seq 1 "$SSH_ATTEMPTS"); do
    echo "   attempt $i/$SSH_ATTEMPTS as ${BOGUS_USER} (expected: Permission denied)"
    run ssh \
      -o BatchMode=yes \
      -o PreferredAuthentications=password,keyboard-interactive \
      -o PubkeyAuthentication=no \
      -o StrictHostKeyChecking=no \
      -o UserKnownHostsFile=/dev/null \
      -o ConnectTimeout=5 \
      -p "$SSH_PORT" \
      "${BOGUS_USER}@${TARGET}" true
  done
fi
echo

# --- 2. suspicious path probes ---------------------------------------------
# The paths a scanner looks for: leftover admin panels, config files, common
# PHP exploits. Our app serves none of them, so every one is a 404 — which is
# the point. They land on route="other" in the Loki dashboard and trigger
# Wazuh's web rules.
note "2/2 suspicious path probes (Wazuh: web scan / nginx 404 burst)"
if ! command -v curl >/dev/null 2>&1; then
  echo "   curl not found; skipping the HTTP pattern"
else
  PATHS=(
    "/wp-admin/setup-config.php"
    "/wp-login.php"
    "/.env"
    "/.git/config"
    "/phpmyadmin/index.php"
    "/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php"
    "/actuator/env"
    "/config.json"
    "/admin/"
    "/server-status"
    "/.aws/credentials"
    "/cgi-bin/luci"
    "/solr/admin/info/system"
    "/boaform/admin/formLogin"
  )
  n=0
  for path in "${PATHS[@]}"; do
    [ "$n" -ge "$HTTP_PROBES" ] && break
    n=$((n + 1))
    url="${HTTP_SCHEME}://${TARGET}${path}"
    if [ "$DRY_RUN" = "yes" ]; then
      echo "   DRY-RUN: GET $url"
    else
      code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 \
        -A "wazuh-demo-scan (authorized self-test)" "$url" || echo "---")
      echo "   GET $path -> $code"
    fi
  done
fi

echo
note "Done. On the Wazuh dashboard (https://127.0.0.1:8443 on the manager host):"
echo "   Security events -> filter agent.name = the Azure VM"
echo "   expect sshd authentication-failure alerts and web/404 alerts within a minute."
echo "   The same 404 burst also shows on the Grafana Logs Explorer as a route=\"other\" spike."
