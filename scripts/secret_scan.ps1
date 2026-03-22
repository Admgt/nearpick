$ErrorActionPreference = "Stop"

$rootDir = Split-Path -Parent $PSScriptRoot
$reportDir = Join-Path $rootDir "reports/security"
$reportFile = Join-Path $reportDir "secret-scan.txt"

New-Item -ItemType Directory -Force -Path $reportDir | Out-Null

$pattern = "(-----BEGIN [A-Z ]+PRIVATE KEY-----|AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{36,}|AIza[0-9A-Za-z_-]{20,})"

$gitArgs = @(
    "-C", $rootDir,
    "grep",
    "-nI",
    "-E",
    $pattern,
    "--",
    ".",
    ":(exclude)docs/**",
    ":(exclude)**/*.example.*",
    ":(exclude)mobile/nearpick/lib/firebase_options.example.dart",
    ":(exclude)mobile/nearpick/android/app/google-services.example.json",
    ":(exclude)mobile/nearpick/web/firebase-messaging-sw.example.js",
    ":(exclude)scripts/secret_scan.sh",
    ":(exclude)scripts/secret_scan.ps1"
)

$matches = & git @gitArgs 2>$null

if ($LASTEXITCODE -eq 0 -and $matches) {
    Set-Content -Path $reportFile -Value ($matches -join [Environment]::NewLine)
    Write-Host "Secret scan talalatok:"
    Get-Content $reportFile
    exit 1
}

if ($LASTEXITCODE -gt 1) {
    throw "git grep vegrehajtasa sikertelen (exit code: $LASTEXITCODE)."
}

Set-Content -Path $reportFile -Value "Nem talalhato magas kockazatu secret-minta."
Write-Host "Nem talalhato magas kockazatu secret-minta."
