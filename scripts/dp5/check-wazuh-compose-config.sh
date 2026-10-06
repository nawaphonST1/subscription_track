#!/usr/bin/env bash
# Regression test for F5: infra/security/wazuh/.env.example must always be a
# valid, complete placeholder for infra/security/wazuh/docker-compose.yml --
# in particular, WAZUH_BIND_ADDR must stay a syntactically valid address, so
# `docker compose config` doesn't fail before anyone gets to deployment.
#
# This does not start any container; `config -q` only parses and interpolates
# the compose file and exits non-zero on the first problem (unset required
# variable, invalid port binding, YAML error).
#
#   ./check-wazuh-compose-config.sh
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
ENV_FILE="$ROOT/infra/security/wazuh/.env.example"
COMPOSE_FILE="$ROOT/infra/security/wazuh/docker-compose.yml"

test -r "$ENV_FILE" || { echo "missing $ENV_FILE" >&2; exit 1; }
test -r "$COMPOSE_FILE" || { echo "missing $COMPOSE_FILE" >&2; exit 1; }

fail=0
note() { if [ "$1" = 0 ]; then printf 'PASS  %s\n' "$2"; else printf 'FAIL  %s\n' "$2"; fail=1; fi; }

if docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" config -q 2>/tmp/dp5-wazuh-config-err.$$; then
  note 0 "docker compose config -q accepts .env.example as-is"
else
  note 1 "docker compose config -q accepts .env.example as-is"
  sed 's/^/      /' /tmp/dp5-wazuh-config-err.$$
fi
rm -f /tmp/dp5-wazuh-config-err.$$

# Regression guard for the original F5 bug specifically: the placeholder must
# still be a syntactically valid IPv4 literal, not a human-readable stand-in
# string (the original bug was WAZUH_BIND_ADDR set to a non-address
# placeholder, which docker rejects as a bind address at the port-mapping
# stage regardless of `config -q`'s own parse succeeding).
placeholder="$(grep -E '^WAZUH_BIND_ADDR=' "$ENV_FILE" | head -1 | cut -d= -f2-)"
if [[ "$placeholder" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
  note 0 "WAZUH_BIND_ADDR placeholder ($placeholder) is a syntactically valid IPv4 address"
else
  note 1 "WAZUH_BIND_ADDR placeholder ($placeholder) is a syntactically valid IPv4 address"
fi

# Port bindings must never widen to 0.0.0.0 -- this is a property of
# docker-compose.yml itself, not of the .env file, but it is cheap to assert
# here too since both this and the bind address are part of the same F5
# "don't expose the agent port to the world" guarantee.
exposed="$(grep -E '^\s*- "0\.0\.0\.0:' "$COMPOSE_FILE" || true)"
if [ -z "$exposed" ]; then
  note 0 "no port in docker-compose.yml is explicitly bound to 0.0.0.0"
else
  note 1 "a port is bound to 0.0.0.0: $exposed"
fi

if [ "$fail" -ne 0 ]; then
  echo "RESULT: FAIL"; exit 1
fi
echo "RESULT: PASS"
