# Build release APK for phone (API URL from dart_defines.prod.json).
# Output: mobile\build\app\outputs\flutter-apk\app-release.apk

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..

$definesFile = Join-Path $PWD "dart_defines.prod.json"
if (-not (Test-Path $definesFile)) {
    Write-Error "Missing $definesFile"
}

Write-Host "Building APK (API_BASE_URL from dart_defines.prod.json)..."
flutter build apk --release --dart-define-from-file=dart_defines.prod.json

$apk = "build\app\outputs\flutter-apk\app-release.apk"
if (Test-Path $apk) {
    Write-Host ""
    Write-Host "Done: $((Resolve-Path $apk).Path)"
    Write-Host "Copy app-release.apk to your phone and install it."
}
