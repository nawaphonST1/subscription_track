#!/bin/bash
set -euo pipefail

# ==============================================================================
# Wazuh Agent Installation Script for Host / K8s Node VM (DP-203)
# ==============================================================================

WAZUH_MANAGER_IP="${1:-wazuh-manager.default.svc.cluster.local}"
WAZUH_AGENT_NAME="${2:-$(hostname)}"
WAZUH_AGENT_GROUP="${3:-k8s-nodes}"

echo "==> [1/4] Installing Wazuh repository and GPG key..."
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import && chmod 644 /usr/share/keyrings/wazuh.gpg
echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | tee -a /etc/apt/sources.list.d/wazuh.list
apt-get update

echo "==> [2/4] Installing Wazuh Agent..."
WAZUH_MANAGER="${WAZUH_MANAGER_IP}" WAZUH_AGENT_GROUP="${WAZUH_AGENT_GROUP}" WAZUH_AGENT_NAME="${WAZUH_AGENT_NAME}" apt-get install -y wazuh-agent

echo "==> [3/4] Enabling Wazuh Agent service on boot..."
systemctl daemon-reload
systemctl enable wazuh-agent
systemctl restart wazuh-agent

echo "==> [4/4] Verifying Wazuh Agent status..."
systemctl status wazuh-agent --no-pager

echo "==> Wazuh Agent installation and host-level security configuration completed successfully!"
