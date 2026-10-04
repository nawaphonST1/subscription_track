#!/usr/bin/env bash
# Regression test for the guard in ../wazuh-demo-attack.sh.
#
# A non-zero exit alone is not enough: the script has two separate refusal
# layers (the hard-coded HARD_DENY_HOSTNAMES list, checked on the raw input
# before anything else runs, and the private/loopback/CGNAT address check,
# which only fires after DNS resolution). F1-NEW-1 was specifically about the
# hard-deny layer failing to strip a trailing dot before comparing, so a
# refusal from the private-IP fallback alone does NOT prove the bug is fixed
# -- that fallback is not guaranteed to fire for every real-world IP a
# hostname might resolve to. Every assertion below checks the ACTUAL message
# text, not just the exit code, so a regression that moves the refusal to the
# wrong layer still fails this test even though the script still exits 2.
#
# Pure string/argument-parsing checks: makes no network connection, contacts
# no host, requires only bash + coreutils.
#
#   ./check-wazuh-demo-attack-guard.sh
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$HERE/../wazuh-demo-attack.sh"
test -r "$SCRIPT" || { echo "missing $SCRIPT" >&2; exit 1; }

fail=0

# run <target> [env=val ...] -- always --i-own-this-target --dry-run, so this
# never contacts a real host even on a target that passes the guard.
run() {
  local target="$1"; shift
  OUT="$("$SCRIPT" --target "$target" --i-own-this-target --dry-run "$@" 2>&1)"
  EC=$?
}

expect_hard_deny() {  # expect_hard_deny <description> <target>
  run "$2" || true
  if [ "$EC" -eq 2 ] && printf '%s' "$OUT" | grep -q 'hard-coded protected host'; then
    echo "PASS  $1"
  else
    echo "FAIL  $1  (exit=$EC, output: $OUT)"
    fail=1
  fi
}

expect_not_hard_deny_but_refused() {  # a different refusal layer must catch it
  run "$2" || true
  if [ "$EC" -eq 2 ] && ! printf '%s' "$OUT" | grep -q 'hard-coded protected host'; then
    echo "PASS  $1"
  else
    echo "FAIL  $1  (exit=$EC, output: $OUT)"
    fail=1
  fi
}

expect_proceeds() {  # a legitimate target must not be refused at all
  run "$2" || true
  if [ "$EC" -eq 0 ]; then
    echo "PASS  $1"
  else
    echo "FAIL  $1  (exit=$EC, output: $OUT)"
    fail=1
  fi
}

# --- F1-NEW-1: trailing dot(s), stripped before the hard-deny comparison ---
expect_hard_deny "single trailing dot refused by hard-deny"        "mob07-mob."
expect_hard_deny "double trailing dot refused by hard-deny"        "mob07-mob.."
expect_hard_deny "trailing dot on a known alias refused by hard-deny" "mob07-mob.internal."
expect_hard_deny "case-mixed + trailing dot refused by hard-deny"  "MOB07-MOB."
expect_hard_deny "case-mixed + double trailing dot refused by hard-deny" "MOB07-MOB.."

# --- unchanged baseline: exact match (no dot) still refused the same way ---
expect_hard_deny "bare hostname (no dot) still refused by hard-deny" "mob07-mob"
expect_hard_deny "known alias (no dot) still refused by hard-deny"   "mob07-mob.local"

# --- a different name must NOT be caught by hard-deny (no over-blocking) ---
# It is still refused -- it fails to resolve -- but via a DIFFERENT message,
# proving hard-deny does exact, not prefix/fuzzy, matching.
expect_not_hard_deny_but_refused "unrelated similarly-spelled host is not hard-denied" "mob07.mob"

# --- regression guard: a real target must still proceed ------------------
expect_proceeds "a legitimate public IPv4 target still proceeds" "93.184.216.34"

if [ "$fail" -ne 0 ]; then
  echo "RESULT: FAIL"
  exit 1
fi
echo "RESULT: PASS"
