#!/usr/bin/env bash
# ==============================================================================
# Setup Gitleaks Pre-commit Hook (Unix / macOS / Git Bash)
# ==============================================================================
set -e

echo "==> [Security Baseline] Setting up Git pre-commit hooks..."

git config core.hooksPath .githooks
chmod +x .githooks/pre-commit 2>/dev/null || true
echo "✅ Configured git hooks path: .githooks"

if command -v gitleaks >/dev/null 2>&1; then
    VERSION=$(gitleaks version)
    echo "✅ Gitleaks detected in PATH: ${VERSION}"
elif [ -x "scripts/bin/gitleaks" ]; then
    echo "✅ Local Gitleaks binary detected: scripts/bin/gitleaks"
else
    echo "⚠️  Gitleaks is not installed on this machine."
    echo "   Install via:"
    echo "     macOS: brew install gitleaks"
    echo "     Linux: https://github.com/gitleaks/gitleaks/releases"
fi

echo "==> Pre-commit hook setup complete!"
