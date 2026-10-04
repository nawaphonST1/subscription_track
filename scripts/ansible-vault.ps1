# ==============================================================================
# Ansible Vault Cross-Platform CLI Wrapper for Windows (Docker Powered)
# ==============================================================================
# Enables running ansible-vault on Windows without WSL or Python environment setup.
# ==============================================================================

param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ArgsList
)

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Docker is not running or not installed. Please start Docker." -ForegroundColor Red
    exit 1
}

$passFileArg = ""
$newArgs = @()
$skipNext = $false

for ($i = 0; $i -lt $ArgsList.Count; $i++) {
    if ($skipNext) {
        $skipNext = $false
        continue
    }
    if ($ArgsList[$i] -eq "--vault-password-file" -or $ArgsList[$i] -eq "--vault-pass-file") {
        $passFileArg = $ArgsList[$i + 1]
        $skipNext = $true
    } elseif ($ArgsList[$i] -like "--vault-password-file=*") {
        $passFileArg = $ArgsList[$i].Split("=")[1]
    } else {
        $newArgs += $ArgsList[$i]
    }
}

$workDir = (Get-Location).Path.Replace('\', '/')
$remainingCommand = $newArgs -join " "

if ($passFileArg -and (Test-Path $passFileArg)) {
    $relPass = $passFileArg.Replace('\', '/')
    $shCmd = "cp '$relPass' /tmp/.vpass && chmod 600 /tmp/.vpass && ansible-vault $remainingCommand --vault-password-file /tmp/.vpass"
    docker run --rm -v "${PWD}:/workspace" -w /workspace alpine/ansible sh -c "$shCmd"
} else {
    docker run --rm -v "${PWD}:/workspace" -w /workspace alpine/ansible ansible-vault $ArgsList
}
