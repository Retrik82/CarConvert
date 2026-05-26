# CarConvert - AI замена фона авто

Локальный проект без Docker: загружаешь фото машины, задаешь prompt нового фона, получаешь отредактированное фото с сохранением автомобиля.

## Что нужно заранее

- Python 3.10+
- Node.js 18+
- npm 9+
- Ключ OpenRouter

## Структура

```txt
CarConvert/
  client/
  server/
  render.yaml
```

## Deploy на Render

Проект подготовлен под `Blueprint` (файл `render.yaml` в корне).

Что будет создано:

- `carconvert-api` (Web Service, FastAPI)
- `carconvert-web` (Static Site, React/Vite)

Шаги:

1. Запушь репозиторий на GitHub/GitLab.
2. В Render нажми **New +** -> **Blueprint**.
3. Выбери репозиторий с этим проектом.
4. Render автоматически прочитает `render.yaml` и создаст 2 сервиса.
5. В `carconvert-api` добавь переменные окружения:
   - `OPENROUTER_API_KEY` = твой реальный ключ
   - `CORS_ORIGINS` = URL фронтенда на Render (например `https://carconvert-web.onrender.com`)
6. В `carconvert-web` проверь `VITE_API_URL`:
   - должен указывать на backend URL (например `https://carconvert-api.onrender.com`)
7. Перезапусти деплой `carconvert-web`, если менял `VITE_API_URL`.

Проверка после деплоя:

- `https://<api-service>.onrender.com/health` -> `{"status":"ok"}`
- Открой `https://<web-service>.onrender.com` и проверь генерацию изображения

## 1) Запуск Backend (FastAPI)

Открой терминал в папке `server`:

```bash
cd server
```

Создай виртуальное окружение:

```bash
python -m venv venv
```

Активируй окружение:

Windows (PowerShell):

```bash
venv\Scripts\activate
```

Mac/Linux:

```bash
source venv/bin/activate
```

Установи зависимости:

```bash
pip install -r requirements.txt
```

Создай файл `server/.env` (или скопируй из `server/.env.example`) и заполни:

```env
OPENROUTER_API_KEY=your_real_openrouter_key
PORT=3001
```

Запусти сервер:

```bash
uvicorn main:app --reload --port 3001
```

Важно: эту команду нужно запускать именно из папки `server`.

Если запускаешь из корня проекта `CarConvert`, используй:

```bash
uvicorn main:app --reload --port 3001
```

(в корне есть прокси-файл `main.py`, который подключает `server.main`).

Проверка backend:

- Health: `http://localhost:3001/health`
- Должен вернуть: `{"status":"ok"}`

## 2) Запуск Frontend (React + Vite)

Открой второй терминал в папке `client`:

```bash
cd client
```

Установи зависимости:

```bash
npm install
```

Создай `client/.env` (или скопируй из `client/.env.example`):

```env
VITE_API_URL=http://localhost:3001
```

Запусти фронт:

```bash
npm run dev
```

Открой в браузере:

- `http://localhost:5173`

## 3) Проверка работы приложения

1. Загрузи изображение (`jpg/jpeg/png/webp`, до 10MB).
2. Введи prompt для нового фона.
3. Нажми `Generate`.
4. Дождись результата и сравни `Before/After`.
5. Скачай результат кнопкой `Download result`.

## API (backend)

### `POST /api/edit`

Формат: `multipart/form-data`

- `image`: файл (`jpg`, `jpeg`, `png`, `webp`, максимум 10MB)
- `prompt`: текст промпта

Успешный ответ:

```json
{
  "success": true,
  "image_base64": "...",
  "mime_type": "image/png",
  "message": "Image generated successfully.",
  "error": null
}
```

## Частые проблемы

### Порт `3001` занят

Проверь процесс:

```bash
netstat -ano | findstr :3001
```

Останови процесс:

```bash
taskkill /PID <PID> /F
```

Или запусти backend на другом порту и обнови `client/.env`:

```env
VITE_API_URL=http://localhost:3002
```

### Ошибка `OPENROUTER_API_KEY is not configured`

Проверь, что в `server/.env` стоит реальный ключ, не `your_key_here`.

### Frontend не видит backend

- Убедись, что backend запущен
- Проверь `VITE_API_URL` в `client/.env`
- Перезапусти `npm run dev` после изменения `.env`

## Стек

- Frontend: React, Vite, TailwindCSS, Axios
- Backend: FastAPI, Uvicorn, python-dotenv, Pillow, requests
- AI: OpenRouter `google/gemini-3.1-flash-image-preview`
