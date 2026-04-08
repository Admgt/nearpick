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
    $hasIntegrationTests = (Test-Path "integration_test" -PathType Container) -and
        ((Get-ChildItem "integration_test" -Recurse -Filter *.dart -File | Measure-Object).Count -gt 0)

    if ($hasIntegrationTests) {
        $devicesReportPath = Join-Path $reportsDir "flutter-integration-devices.txt"
        $integrationReportPath = Join-Path $reportsDir "flutter-integration-test.txt"

        $devicesOutput = & flutter devices
        $devicesExitCode = $LASTEXITCODE
        $devicesOutput | Out-File -Encoding utf8 $devicesReportPath
        if ($devicesExitCode -ne 0) { throw "flutter devices failed" }

        $androidDeviceId = $null
        $devicesJson = & flutter devices --machine
        if ($LASTEXITCODE -eq 0 -and $devicesJson) {
            try {
                $parsedDevices = $devicesJson | ConvertFrom-Json
                $androidDevice = $parsedDevices | Where-Object {
                    $_.targetPlatform -like "android-*"
                } | Select-Object -First 1
                if ($androidDevice) {
                    $androidDeviceId = $androidDevice.id
                }
            } catch {
                Write-Host "Nem sikerult a flutter devices --machine kimenetet feldolgozni."
            }
        }

        if (-not $androidDeviceId) {
            $skipMessage = "Skipping integration_test locally: no Android emulator/device is configured on this machine."
            Write-Host $skipMessage
            $skipMessage | Out-File -Encoding utf8 $integrationReportPath
        } else {
            Write-Host "==> integration_test futtatasa android device-en: $androidDeviceId"
            $integrationOutput = & flutter test integration_test -d $androidDeviceId 2>&1
            $integrationExitCode = $LASTEXITCODE
            $integrationOutput | Out-File -Encoding utf8 $integrationReportPath
            $integrationOutput | ForEach-Object { Write-Host $_ }
            if ($integrationExitCode -ne 0) { throw "flutter test integration_test failed" }
        }
    } else {
        Write-Host "Nincs integration_test fajl, integration lepes kihagyva."
    }

    Pop-Location

    Write-Host "==> Repo secret scan"
    & powershell -ExecutionPolicy Bypass -File (Join-Path $rootDir "scripts/secret_scan.ps1")
    if ($LASTEXITCODE -ne 0) { throw "secret scan failed" }

    $functionsDir = Join-Path $rootDir "functions"
    $npmCommand = "npm.cmd"
    Write-Host "==> Functions quality gate futtatasa: $functionsDir"
    Push-Location $functionsDir

    Write-Host "==> npm ci"
    & $npmCommand ci
    if ($LASTEXITCODE -ne 0) { throw "npm ci failed" }

    Write-Host "==> npm run lint"
    & $npmCommand run lint
    if ($LASTEXITCODE -ne 0) { throw "npm run lint failed" }

    Write-Host "==> npm test"
    & $npmCommand test
    if ($LASTEXITCODE -ne 0) { throw "npm test failed" }

    Write-Host "==> npm run scan:deps"
    & $npmCommand run scan:deps
    if ($LASTEXITCODE -ne 0) { throw "npm run scan:deps failed" }

    Write-Host "==> Kesz. Flutter JUnit: mobile/nearpick/reports/junit-flutter.xml"
}
finally {
    if ((Get-Location).Path -ne $rootDir) {
        Pop-Location
    }
}
