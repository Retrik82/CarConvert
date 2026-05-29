# CarConvert Mobile

Flutter-приложение для Android (и iOS).

## Быстрый старт (локально)

```powershell
cd mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3001
```

Для физического телефона: скопируй `dart_defines.local.json.example` → `dart_defines.local.json` и укажи IP ПК.

## APK для Render (телефон без Wi-Fi к ПК)

```powershell
.\scripts\build_apk_prod.ps1
```

Полная инструкция: [../README.md](../README.md) — **Часть 7**.
