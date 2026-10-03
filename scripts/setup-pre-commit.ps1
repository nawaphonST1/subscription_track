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
    Write-Host "⚠️  Gitleaks is not installed on this machine. Attempting automatic download to scripts/bin/..." -ForegroundColor Yellow
    try {
        $ProgressPreference = 'SilentlyContinue'
        New-Item -ItemType Directory -Force -Path "scripts\bin" | Out-Null
        Invoke-WebRequest -Uri "https://github.com/gitleaks/gitleaks/releases/download/v8.24.0/gitleaks_8.24.0_windows_x64.zip" -OutFile "$env:TEMP\gitleaks.zip"
        Expand-Archive -Path "$env:TEMP\gitleaks.zip" -DestinationPath "$env:TEMP\gitleaks_extracted" -Force
        Copy-Item "$env:TEMP\gitleaks_extracted\gitleaks.exe" "scripts\bin\gitleaks.exe" -Force
        Remove-Item "$env:TEMP\gitleaks.zip" -Force
        Remove-Item "$env:TEMP\gitleaks_extracted" -Recurse -Force
        Write-Host "✅ Successfully downloaded local Gitleaks binary to scripts/bin/gitleaks.exe" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to auto-download Gitleaks: $_" -ForegroundColor Red
        Write-Host "   Please install manually via: winget install Gitleaks.Gitleaks" -ForegroundColor White
    }
}

Write-Host "==> Pre-commit hook setup complete!" -ForegroundColor Cyan
