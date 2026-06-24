# AutoCut — AI-ассистент автомобильной съёмки

Мобильное приложение (Flutter) + общий backend (FastAPI) для:

- **Realtime AI-подсказок ДО съёмки** (rekaai/reka-edge через OpenRouter)
- **Автоматической замены фона на пустыню ПОСЛЕ съёмки** (google/gemini-3.1-flash-image-preview)
- **Авторизации пользователей** (PostgreSQL на production, SQLite локально + JWT)

React web-клиент (`client/`) продолжает работать через legacy endpoint `POST /api/edit` без изменений.

---

## Структура проекта

```txt
AutoCut/
  backend/          # FastAPI — общий API для web и mobile
  mobile/           # Flutter app (Android / iOS)
  client/           # React web (без изменений)
  server/           # Старый backend (deprecated, используй backend/)
  render.yaml       # Deploy на Render
```

---

## Что нужно заранее

| Компонент | Версия |
|-----------|--------|
| Python | 3.10+ |
| Node.js | 18+ (только для web client) |
| Flutter SDK | 3.7+ |
| Android Studio | для SDK и эмулятора |
| OpenRouter API key | [openrouter.ai/keys](https://openrouter.ai/settings/keys) |

---

# Часть 1 — Запуск Backend

### 1. Перейди в папку backend

```powershell
cd D:\projects\CarConvert\backend
```

### 2. Создай виртуальное окружение

```powershell
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
```

### 3. Создай файл `.env`

Скопируй `backend/.env.example` → `backend/.env` и заполни:

```env
OPENROUTER_API_KEY=sk-or-v1-ВАШ_КЛЮЧ
PORT=3001
CORS_ORIGINS=*
DATABASE_URL=sqlite+aiosqlite:///./data/carconvert.db
JWT_SECRET=случайная_строка_минимум_32_символа
JWT_ACCESS_EXPIRE_MIN=15
JWT_REFRESH_EXPIRE_DAYS=30
AUTH_RATE_LIMIT_LOGIN_MAX=10
AUTH_RATE_LIMIT_REFRESH_MAX=30
HINT_MODEL=rekaai/reka-edge
PROCESS_MODEL=google/gemini-3.1-flash-image-preview
HINT_TIMEOUT_SEC=15
PROCESS_TIMEOUT_SEC=120
MAX_PREVIEW_BYTES=512000
UPLOAD_DIR=./data/uploads
```

### 4. Запусти сервер

```powershell
uvicorn main:app --reload --host 0.0.0.0 --port 3001
```

> `--host 0.0.0.0` обязателен, если телефон подключается по Wi-Fi (не localhost).

### 5. Проверь

Открой в браузере: `http://localhost:3001/health`  
Ожидаемый ответ: `{"status":"ok"}`

---

# Часть 2 — Установка на Android-телефон

## Вариант A: Физический телефон + Wi-Fi (рекомендуется)

### Шаг 1 — Подготовь телефон

1. **Настройки → О телефоне →** нажми 7 раз на «Номер сборки» (включится режим разработчика)
2. **Настройки → Для разработчиков →** включи **Отладку по USB**
3. Подключи телефон USB-кабелем к компьютеру
4. На телефоне подтверди «Разрешить отладку по USB»

### Шаг 2 — Узнай IP компьютера в локальной сети

```powershell
ipconfig
```

Найди строку **IPv4 Address** для Wi-Fi адаптера, например: `192.168.1.105`

> Компьютер и телефон должны быть в **одной Wi-Fi сети**.

### Шаг 3 — Проверь, что backend доступен с телефона

Backend должен быть запущен с `--host 0.0.0.0`.

На телефоне открой браузер и перейди:
```
http://192.168.1.105:3001/health
```
(замени IP на свой)

Если видишь `{"status":"ok"}` — всё работает.

### Шаг 4 — Разреши HTTP в Windows Firewall (если не открывается)

```powershell
netsh advfirewall firewall add rule name="AutoCut API" dir=in action=allow protocol=TCP localport=3001
```

### Шаг 5 — Установи Flutter-приложение на телефон

```powershell
cd D:\projects\CarConvert\mobile
flutter pub get
flutter devices
```

Убедись, что телефон виден в списке устройств, затем:

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.1.105:3001
```

(замени IP на свой)

Flutter соберёт APK и установит его на телефон. Первый запуск может занять 3–5 минут.

---

## Вариант B: USB + adb reverse (без Wi-Fi)

Если не хочешь возиться с IP и firewall:

```powershell
adb reverse tcp:3001 tcp:3001
cd D:\projects\CarConvert\mobile
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:3001
```

`adb reverse` пробрасывает порт телефона на localhost компьютера. Backend можно запускать с `--host 127.0.0.1`.

> Команда `adb reverse` сбрасывается после перезагрузки телефона — запускай её снова.

---

## Вариант C: Android Emulator

```powershell
cd D:\projects\CarConvert\mobile
flutter emulators
flutter emulators --launch <emulator_id>
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3001
```

`10.0.2.2` — специальный адрес эмулятора для доступа к localhost хост-машины.

---

## Вариант D: Сборка APK для ручной установки

```powershell
cd D:\projects\CarConvert\mobile
flutter build apk --dart-define=API_BASE_URL=http://192.168.1.105:3001
```

APK будет здесь:
```
mobile\build\app\outputs\flutter-apk\app-release.apk
```

Скопируй файл на телефон и установи. Разреши установку из неизвестных источников, если система попросит.

> **Важно:** IP backend зашивается при сборке через `--dart-define`. Если сменишь IP — пересобери APK.

---

# Часть 3 — Проверка работы приложения

### 1. Регистрация / вход

1. Открой приложение AutoCut
2. Нажми **«Создать аккаунт»**
3. Введи имя, email, пароль (мин. 6 символов)
4. Пройди onboarding (3 экрана)

### 2. Realtime AI-подсказки (главная функция)

1. Вкладка **«Камера»**
2. Разреши доступ к камере
3. Наведи камеру на машину (или фото машины на экране)
4. Через 1–2 секунды появятся подсказки:
   - текст внизу («Сместись левее», «Идеально» и т.д.)
   - анимированные стрелки
   - рамка кадра (зелёная = идеальный кадр)
5. Статус «AI активен» вверху подтверждает WebSocket-соединение

### 3. Съёмка и обработка

1. Когда кадр хороший — нажми **белую кнопку съёмки**
2. Экран «Создаём пустынный фон» — жди 10–20 секунд
3. Результат: свайп влево для сравнения до/после
4. Кнопка **скачивания** сохраняет фото на телефон

### 4. История

Вкладка **«История»** — список всех обработок вашего аккаунта.

### 5. Профиль

Вкладка **«Профиль»** — данные аккаунта и кнопка **«Выйти»**.

---

# Часть 4 — API Reference

## Auth

| Method | Path | Notes |
|--------|------|-------|
| POST | `/auth/register` | `{email, password, display_name, device_id?, device_name?}` → tokens + `session_id` |
| POST | `/auth/login` | same device fields |
| POST | `/auth/refresh` | `{refresh_token}` — rotates refresh token (old token invalidated) |
| POST | `/auth/logout` | `{refresh_token}` only (no Bearer required) |
| POST | `/auth/logout-all` | Bearer — revoke all devices; optional `keep_current_session` + header `X-Session-Id` |
| GET | `/auth/me` | Bearer access token |
| GET | `/auth/sessions` | Bearer — list active devices/sessions |
| DELETE | `/auth/sessions/{id}` | Bearer — revoke one device |
| POST | `/auth/forgot-password` | `{email}` |
| POST | `/auth/reset-password` | `{token, new_password}` |
| POST | `/auth/verify-email` | Bearer |

Roles: `user`, `admin`, `moderator` (JWT claim `role`). Admin routes require `admin`.

Mobile: access token in RAM only; refresh token in Keychain / EncryptedSharedPreferences (`flutter_secure_storage`). Header: `Authorization: Bearer <access>`.

## Camera session (Bearer)

| Method | Path | Response |
|--------|------|----------|
| POST | `/session/start` | `{session_id, expires_at}` |

## WebSocket (realtime hints)

```
WS /camera/stream?session_id={uuid}&token={access_token}
```

Client → Server:
```json
{"type":"frame","image_base64":"...","mime_type":"image/jpeg","timestamp":1710000000}
```

Server → Client:
```json
{
  "type":"hint",
  "hint":"move_left",
  "message":"Сместись левее",
  "confidence":0.92,
  "scores":{"centering":0.81,"distance":0.74,"angle":0.88},
  "overlay":{"arrow":"left","color":"yellow"}
}
```

## Photo processing (Bearer)

| Method | Path | Description |
|--------|------|-------------|
| POST | `/photo/process` | multipart: `image` + optional `session_id` |
| GET | `/photo/result/{job_id}` | polling статуса |
| GET | `/photos/history` | история пользователя |

## Legacy web (public, без auth)

| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/edit` | multipart: `image` + `prompt` |
| GET | `/health` | health check |

---

# Часть 5 — Запуск Web-клиента (React)

Web-клиент не менялся и работает через старый endpoint:

```powershell
# Терминал 1 — backend (уже запущен)
cd D:\projects\CarConvert\backend
venv\Scripts\uvicorn main:app --reload --port 3001

# Терминал 2 — frontend
cd D:\projects\CarConvert\client
npm install
# client/.env: VITE_API_URL=http://localhost:3001
npm run dev
```

Открой `http://localhost:5173`

---

# Часть 6 — Частые проблемы

### «Не удаётся подключиться к серверу» на телефоне

- Backend запущен с `--host 0.0.0.0`?
- IP в `--dart-define=API_BASE_URL` правильный?
- Телефон и ПК в одной Wi-Fi сети?
- Firewall пропускает порт 3001?
- Попробуй `adb reverse tcp:3001 tcp:3001` + `API_BASE_URL=http://127.0.0.1:3001`

### «OPENROUTER_API_KEY is not configured»

Проверь `backend/.env` — ключ должен быть реальным, не `your_key_here`. Перезапусти backend.

### Подсказки не появляются

- Проверь WebSocket: статус должен быть «AI активен»
- Убедись, что OpenRouter ключ имеет доступ к `rekaai/reka-edge`
- Наведи камеру на объект, похожий на машину

### Обработка фото зависла

- Gemini-обработка занимает 10–20 секунд — это нормально
- Проверь баланс OpenRouter
- Смотри логи backend в терминале

### `flutter devices` не видит телефон

- Включена отладка по USB?
- Установлены драйверы (для Samsung/Xiaomi — их USB-драйвер)?
- Попробуй: `adb kill-server` → `adb start-server` → `adb devices`

### Developer Mode для symlinks (Windows)

Если `flutter pub get` просит Developer Mode:
```
start ms-settings:developers
```
Включи **Режим разработчика**.

### bcrypt / auth ошибки

```powershell
cd backend
venv\Scripts\pip install bcrypt==4.0.1
```

---

# Часть 7 — Deploy на Render + установка на телефон

Схема: **API на Render** → **APK на телефоне** с тем же URL. Wi-Fi и домашний ПК для работы приложения не нужны.

## Шаг 1 — Задеплой backend на Render

1. Запушь репозиторий на GitHub.
2. [Render Dashboard](https://dashboard.render.com) → **New** → **Blueprint** → выбери репозиторий проекта.
3. Render подхватит `render.yaml` и создаст:
   - `carconvert-db` — PostgreSQL (постоянные аккаунты и история)
   - `carconvert-api` — FastAPI (Starter + persistent disk для фото)
   - `carconvert-web` — React (статика, опционально)
4. В сервисе **carconvert-api** → **Environment**:
   - добавь `OPENROUTER_API_KEY` — ключ с [openrouter.ai](https://openrouter.ai/settings/keys)
   - `DATABASE_URL` и `UPLOAD_DIR` подставляются из `render.yaml` автоматически
   - если сервис уже существовал со старым SQLite — **Manual Deploy → Clear build cache & deploy**
   - **Settings → Start Command** должен совпадать с `render.yaml` (если в логах всё ещё старый `uvicorn main:app` без `Import OK` — обнови вручную в Dashboard)
5. Дождись зелёного статуса **Live**. Проверь в браузере:
   ```
   https://carconvert-api.onrender.com/health
   https://carconvert-api.onrender.com/health/db
   https://carconvert-api.onrender.com/health/storage
   ```
   Ожидаемо: `{"status":"ok"}`, `{"status":"ok","database":"connected"}`, `{"status":"ok","storage":"writable"}`

> **Стоимость (~$13/мес):** Starter API (~$7) + Basic Postgres (~$6). API на Starter не засыпает.  
> **Данные:** аккаунты и история в Postgres, фото на persistent disk `/var/data/uploads` — **сохраняются после redeploy**. `JWT_SECRET` Render сгенерирует сам.

Если имя сервиса API на Render не `carconvert-api`, измени URL в:
- `render.yaml` → `VITE_API_URL` (для web)
- `mobile/dart_defines.prod.json` → `API_BASE_URL`

## Шаг 2 — Собери APK для телефона

На компьютере с Flutter:

```powershell
cd D:\projects\CarConvert\mobile
flutter pub get
.\scripts\build_apk_prod.ps1
```

Или вручную:

```powershell
flutter build apk --release --dart-define-from-file=dart_defines.prod.json
```

APK:

```
mobile\build\app\outputs\flutter-apk\app-release.apk
```

## Шаг 3 — Установи на Android

1. Скопируй `app-release.apk` на телефон (USB, Telegram, Google Drive и т.д.).
2. Открой файл на телефоне → **Установить**.
3. Разреши установку из неизвестных источников, если Android попросит.
4. Открой **AutoCut** → регистрация → камера и съёмка.

Приложение ходит на `https://carconvert-api.onrender.com` (зашито в `dart_defines.prod.json` при сборке).

## Шаг 4 — Локальная разработка (по желанию)

Скопируй `mobile/dart_defines.local.json.example` → `dart_defines.local.json`, укажи IP ПК в Wi-Fi:

```powershell
flutter run --dart-define-from-file=dart_defines.local.json
```

## Частые проблемы (Render + телефон)

| Симптом | Решение |
|---------|---------|
| Deploy падает на старте (`Exited with status 1`) | Проверь логи: должна быть строка `Import OK: AutoCut API`. Чаще всего — пустой или битый `DATABASE_URL`; убедись, что Blueprint привязал Postgres `carconvert-db`. |
| `/health/db` → failed | Проверь, что `DATABASE_URL` из `carconvert-db` (Internal URL), не SQLite. Redeploy с clear cache. |
| `/health/storage` → not_writable | Убедись, что у API подключён persistent disk (`/var/data/uploads`) и план Starter. |
| «Не удаётся подключиться» | Проверь `/health` в браузере телефона. |
| 500 / OPENROUTER | Задай `OPENROUTER_API_KEY` в Render → Environment → **Save** → redeploy. |
| WebSocket «Отключено» | Убедись, что API Live; перелогинься в приложении. |
| Сменил URL API на Render | Обнови `dart_defines.prod.json` и **пересобери** APK. |

---

# Стек

| Слой | Технологии |
|------|-----------|
| Mobile | Flutter, camera, web_socket_channel, flutter_secure_storage |
| Backend | FastAPI, SQLAlchemy, aiosqlite, httpx, python-jose, bcrypt |
| AI | OpenRouter → rekaai/reka-edge (hints), google/gemini-3.1-flash-image-preview (desert bg) |
| Web | React, Vite, Tailwind (legacy client/) |
| DB | PostgreSQL (Render production), SQLite (локально и тесты) |
| Фото | Persistent Disk `/var/data/uploads` (Render), `data/uploads/` (локально) |

---

# AI-модели (не менять)

| Задача | Модель |
|--------|--------|
| Realtime подсказки | `rekaai/reka-edge` |
| Замена фона на пустыню | `google/gemini-3.1-flash-image-preview` |

Ключ OpenRouter хранится **только на backend**. В Flutter-коде ключей нет.
