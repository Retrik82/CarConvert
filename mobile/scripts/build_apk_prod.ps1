# Сборка release APK для телефона с API на Render.
# Перед запуском: flutter pub get
# После сборки: mobile\build\app\outputs\flutter-apk\app-release.apk

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..

$definesFile = Join-Path $PWD "dart_defines.prod.json"
if (-not (Test-Path $definesFile)) {
    Write-Error "Не найден $definesFile"
}

Write-Host "API URL из dart_defines.prod.json"
flutter build apk --release --dart-define-from-file=dart_defines.prod.json

$apk = "build\app\outputs\flutter-apk\app-release.apk"
if (Test-Path $apk) {
    Write-Host ""
    Write-Host "Готово: $((Resolve-Path $apk).Path)"
    Write-Host "Скопируйте APK на телефон и установите."
}
