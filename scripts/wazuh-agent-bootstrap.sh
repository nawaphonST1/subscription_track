#!/usr/bin/env bash
#
# Install and enroll the Wazuh agent on the Azure PRODUCTION VM (Ubuntu 24.04).
#
# Run ON that VM, as root. Idempotent: re-running on an already-enrolled host
# re-applies the configuration and restarts the agent, and does not re-import
# the repository key or create a second registration.
#
#   sudo WAZUH_MANAGER=100.x.y.z \
#        WAZUH_REGISTRATION_PASSWORD='<from infra/security/wazuh/.env>' \
#        ./scripts/wazuh-agent-bootstrap.sh
#
# WAZUH_MANAGER must be a TAILSCALE address. The manager runs on the developer
# workstation and 1514/1515 are bound to its Tailscale interface only; a public
# address here would mean the enrollment password crosses the open internet.
#
set -euo pipefail

WAZUH_VERSION="${WAZUH_VERSION:-4.14.8-1}"
AGENT_NAME="${WAZUH_AGENT_NAME:-$(hostname)}"
AGENT_GROUP="${WAZUH_AGENT_GROUP:-default}"
CONF_TEMPLATE="${WAZUH_CONF_TEMPLATE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/infra/security/wazuh/ossec-agent.conf.example}"

KEYRING=/usr/share/keyrings/wazuh.gpg
SOURCES=/etc/apt/sources.list.d/wazuh.list
OSSEC_CONF=/var/ossec/etc/ossec.conf

die() { echo "ERROR: $*" >&2; exit 1; }
step() { echo; echo "== $*"; }

# --- preconditions ---------------------------------------------------------
[ "$(id -u)" -eq 0 ] || die "run as root (sudo)"
[ -n "${WAZUH_MANAGER:-}" ] || die "WAZUH_MANAGER is required (the manager's Tailscale IP)"
[ -n "${WAZUH_REGISTRATION_PASSWORD:-}" ] || die "WAZUH_REGISTRATION_PASSWORD is required"
[ -r "$CONF_TEMPLATE" ] || die "agent config template not found at $CONF_TEMPLATE"

case "$WAZUH_MANAGER" in
  100.*) ;;  # Tailscale CGNAT range, 100.64.0.0/10
  *)
    if [ "${I_KNOW_THIS_IS_NOT_TAILSCALE:-}" != "yes" ]; then
      die "WAZUH_MANAGER=$WAZUH_MANAGER is not a Tailscale address (100.64.0.0/10).
     The enrollment password is sent to this host. If you really mean it,
     re-run with I_KNOW_THIS_IS_NOT_TAILSCALE=yes."
    fi
    echo "WARNING: enrolling against a non-Tailscale address at your own request."
    ;;
esac

if ! command -v tailscale >/dev/null 2>&1; then
  echo "WARNING: tailscale is not installed on this host; the agent will not reach $WAZUH_MANAGER."
fi

# --- repository ------------------------------------------------------------
step "Wazuh APT repository"
if [ -f "$KEYRING" ] && [ -f "$SOURCES" ]; then
  echo "already configured, leaving as is"
else
  apt-get update -qq
  apt-get install -y -qq curl gnupg apt-transport-https >/dev/null
  curl -fsSL https://packages.wazuh.com/key/GPG-KEY-WAZUH \
    | gpg --no-default-keyring --keyring "$KEYRING" --import
  chmod 644 "$KEYRING"
  echo "deb [signed-by=$KEYRING] https://packages.wazuh.com/4.x/apt/ stable main" > "$SOURCES"
  apt-get update -qq
fi

# --- package ---------------------------------------------------------------
step "wazuh-agent $WAZUH_VERSION"
installed="$(dpkg-query -W -f='${Version}' wazuh-agent 2>/dev/null || true)"
if [ "$installed" = "$WAZUH_VERSION" ]; then
  echo "already installed at $installed"
else
  # These two are read by the package's postinst to pre-seed the agent.
  WAZUH_MANAGER="$WAZUH_MANAGER" \
  WAZUH_AGENT_NAME="$AGENT_NAME" \
  WAZUH_AGENT_GROUP="$AGENT_GROUP" \
    DEBIAN_FRONTEND=noninteractive apt-get install -y "wazuh-agent=$WAZUH_VERSION"
  # Pin it: an unattended upgrade that moves the agent past the manager's
  # version is a supported-but-unhappy combination, and this host is a demo.
  apt-mark hold wazuh-agent >/dev/null
fi

# --- configuration ---------------------------------------------------------
step "agent configuration"
systemctl stop wazuh-agent 2>/dev/null || true

if [ -f "$OSSEC_CONF" ] && [ ! -f "$OSSEC_CONF.orig" ]; then
  cp -a "$OSSEC_CONF" "$OSSEC_CONF.orig"
  echo "kept the packaged config at $OSSEC_CONF.orig"
fi

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
sed "s|WAZUH_MANAGER_ADDRESS|${WAZUH_MANAGER}|g" "$CONF_TEMPLATE" > "$tmp"
# Written as an `if`, not `grep ... && die`: under `set -e` the latter exits
# the script when grep finds nothing, which is the SUCCESS case here.
if grep -q "WAZUH_MANAGER_ADDRESS" "$tmp"; then
  die "manager address substitution failed"
fi
install -o root -g wazuh -m 0660 "$tmp" "$OSSEC_CONF"
echo "wrote $OSSEC_CONF"

# --- enrollment ------------------------------------------------------------
step "enrollment"
if [ -s /var/ossec/etc/client.keys ]; then
  echo "already enrolled (client.keys present); not registering again"
else
  umask 077
  printf '%s' "$WAZUH_REGISTRATION_PASSWORD" > /var/ossec/etc/authd.pass
  chown root:wazuh /var/ossec/etc/authd.pass
  chmod 640 /var/ossec/etc/authd.pass

  /var/ossec/bin/agent-auth -m "$WAZUH_MANAGER" -p 1515 -A "$AGENT_NAME" -G "$AGENT_GROUP"

  # The password is only needed for this one call. Leaving it on a
  # public-facing VM would hand the next agent enrollment to whoever gets in.
  shred -u /var/ossec/etc/authd.pass 2>/dev/null || rm -f /var/ossec/etc/authd.pass
  echo "registered as '$AGENT_NAME' and removed the enrollment password"
fi

# --- service ---------------------------------------------------------------
step "service"
systemctl daemon-reload
systemctl enable wazuh-agent >/dev/null
systemctl restart wazuh-agent
sleep 3
systemctl --no-pager --lines=0 status wazuh-agent || true

echo
echo "Done. Verify from the manager side:"
echo "  docker compose -f infra/security/wazuh/docker-compose.yml exec wazuh.manager /var/ossec/bin/agent_control -l"
echo "The agent should appear as '$AGENT_NAME' with status Active."
