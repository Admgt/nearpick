$ErrorActionPreference = "Stop"

$rootDir = Split-Path -Parent $PSScriptRoot
$appDir = Join-Path $rootDir "mobile/nearpick"
$reportsDir = Join-Path $appDir "reports"

Write-Host "==> Flutter quality gate futtatasa: $appDir"
Push-Location $appDir

try {
    Write-Host "==> flutter pub get"
    & flutter pub get
    if ($LASTEXITCODE -ne 0) { throw "flutter pub get failed" }

    Write-Host "==> Flutter dependency audit"
    & dart run tool/audit_pub_dependencies.dart --report-dir=reports
    if ($LASTEXITCODE -ne 0) { throw "Flutter dependency audit failed" }

    Write-Host "==> dart format gate"
    & dart format --output=none --set-exit-if-changed .
    if ($LASTEXITCODE -ne 0) { throw "dart format failed" }

    Write-Host "==> flutter analyze"
    & flutter analyze
    if ($LASTEXITCODE -ne 0) { throw "flutter analyze failed" }

    $pubCacheBin = Join-Path $HOME ".pub-cache/bin"
    if (Test-Path $pubCacheBin) {
        $env:PATH += ";$pubCacheBin"
    }

    if ($env:LOCALAPPDATA) {
        $localPubBin = Join-Path $env:LOCALAPPDATA "Pub/Cache/bin"
        if (Test-Path $localPubBin) {
            $env:PATH += ";$localPubBin"
        }
    }

    if (-not (Get-Command tojunit -ErrorAction SilentlyContinue)) {
        Write-Host "==> junitreport telepites (tojunit)"
        & dart pub global activate junitreport
        if ($LASTEXITCODE -ne 0) { throw "dart pub global activate junitreport failed" }
    } else {
        Write-Host "==> tojunit mar telepitve"
    }

    New-Item -ItemType Directory -Force -Path $reportsDir | Out-Null
    $junitPath = Join-Path $reportsDir "junit-flutter.xml"

    Write-Host "==> unit/widget tesztek + junit"
    & flutter test --machine | & tojunit | Out-File -Encoding utf8 $junitPath
    if ($LASTEXITCODE -ne 0) { throw "flutter test --machine | tojunit failed" }

    Write-Host "==> integration_test ellenorzes"
    $hasIntegrationTests = Test-Path "integration_test" -PathType Container -and
        (Get-ChildItem "integration_test" -Recurse -Filter *.dart -File | Measure-Object).Count -gt 0

    if ($hasIntegrationTests) {
        & flutter test integration_test
        if ($LASTEXITCODE -ne 0) { throw "flutter test integration_test failed" }
    } else {
        Write-Host "Nincs integration_test fajl, integration lepes kihagyva."
    }

    Write-Host "==> Kesz. JUnit: mobile/nearpick/reports/junit-flutter.xml"
}
finally {
    Pop-Location
}
