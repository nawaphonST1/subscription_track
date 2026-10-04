[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet('combined', 'realistic', 'ceiling', 'spike')]
    [string]$Profile = 'combined',

    [Parameter(Mandatory = $false)]
    [string]$TargetUrl = ''
)

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  Subscription Track - k6 Load & Performance Testing" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# Auto-detect target port if not explicitly passed
if ([string]::IsNullOrWhiteSpace($TargetUrl)) {
    try {
        $tcpCheck = Test-NetConnection -ComputerName "localhost" -Port 8080 -InformationLevel Quiet -WarningAction SilentlyContinue
        if ($tcpCheck) {
            $TargetUrl = "http://localhost:8080"
        } else {
            $TargetUrl = "http://localhost:3000"
        }
    } catch {
        $TargetUrl = "http://localhost:8080"
    }
}

Write-Host "Target URL : $TargetUrl" -ForegroundColor Yellow
Write-Host "Profile    : $Profile" -ForegroundColor Yellow

switch ($Profile) {
    'realistic' {
        Write-Host "Mode: Realistic Traffic (15 -> 50 VUs, normal user think time)" -ForegroundColor Green
    }
    'ceiling' {
        Write-Host "Mode: Aggressive Ceiling Stress (50 -> 150 -> 300 -> 500 VUs, rapid fire 0.05s)" -ForegroundColor Red
    }
    'spike' {
        Write-Host "Mode: Instant Surge Spike (0 -> 300 VUs in 10s)" -ForegroundColor Magenta
    }
    'combined' {
        Write-Host "Mode: Realistic -> Peak -> Ceiling Ramp-up -> Recovery" -ForegroundColor White
    }
}

Write-Host "Checking k6 binary..." -ForegroundColor Gray
if (-not (Get-Command k6 -ErrorAction SilentlyContinue)) {
    Write-Error "k6 binary not found in PATH. Please install or add k6 to PATH."
    exit 1
}

$ScriptPath = Join-Path $PSScriptRoot "load-test.js"

Write-Host "Executing k6 test suite..." -ForegroundColor Cyan
& k6 run -e "TARGET_URL=$TargetUrl" -e "TEST_PROFILE=$Profile" "$ScriptPath"
