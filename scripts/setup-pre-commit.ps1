# ==============================================================================
# Setup Gitleaks Pre-commit Hook (Windows PowerShell)
# ==============================================================================
Write-Host "==> [Security Baseline] Setting up Git pre-commit hooks..." -ForegroundColor Cyan

# 1. Configure git core.hooksPath
git config core.hooksPath .githooks
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Configured git hooks path: .githooks" -ForegroundColor Green
} else {
    Write-Host "❌ Failed to configure git core.hooksPath" -ForegroundColor Red
}

# 2. Check for Gitleaks installation
if (Get-Command gitleaks -ErrorAction SilentlyContinue) {
    $version = gitleaks version
    Write-Host "✅ Gitleaks detected in PATH: $version" -ForegroundColor Green
} elseif (Test-Path "scripts/bin/gitleaks.exe") {
    Write-Host "✅ Local Gitleaks binary detected: scripts/bin/gitleaks.exe" -ForegroundColor Green
} else {
    Write-Host "⚠️  Gitleaks is not installed on this machine." -ForegroundColor Yellow
    Write-Host "   Install via:" -ForegroundColor Yellow
    Write-Host "     winget install Gitleaks.Gitleaks" -ForegroundColor White
    Write-Host "   or Scoop:" -ForegroundColor Yellow
    Write-Host "     scoop install gitleaks" -ForegroundColor White
}

Write-Host "==> Pre-commit hook setup complete!" -ForegroundColor Cyan
