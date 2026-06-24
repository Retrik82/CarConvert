# Таблица 1. Какие модели OpenRouter на какую задачу (AutoCut)

Обновлено после внедрения раздельного пайплайна моделей.

| Задача | Primary | Fallback | Env-переменная |
|--------|---------|----------|----------------|
| Realtime hints (камера) | `rekaai/reka-edge` | `google/gemini-2.5-flash-lite` | `HINT_MODEL_PRIMARY` / `HINT_MODEL_FALLBACK` |
| Ракурс (pose → catalog angle) | `google/gemini-2.5-flash-lite` | `rekaai/reka-edge` | `POSE_MODEL` / `POSE_MODEL_FALLBACK` |
| Обрезка машины (cutout) | `google/gemini-2.5-flash-image` | `google/gemini-3.1-flash-image-preview` | `CUTOUT_MODEL` / `CUTOUT_MODEL_FALLBACK` |
| Композит на фон | `google/gemini-3.1-flash-image-preview` | `google/gemini-2.5-flash-image` | `COMPOSITE_MODEL` / `COMPOSITE_MODEL_FALLBACK` |
| Premium композит | — | — | `COMPOSITE_MODEL_PREMIUM` |

## Legacy aliases

- `HINT_MODEL` → alias для `HINT_MODEL_PRIMARY`
- `PROCESS_MODEL` → alias для `COMPOSITE_MODEL`

## Маршрутизация

Все вызовы идут через `app/services/ai/model_router.py`:
**primary → retry (429/5xx/timeout) → fallback → ошибка**

## Лимиты нагрузки

| Параметр | Default | Назначение |
|----------|---------|------------|
| `HINT_MAX_CONCURRENT` | 8 | Параллельные hint-запросы |
| `PROCESS_MAX_CONCURRENT` | 3 | Параллельные photo jobs |
| `MAX_QUEUE_SIZE` | 50 | Backpressure (503) |
| `MAX_ACTIVE_JOBS_PER_USER` | 2 | Анти-спам |
| `PHOTO_RATE_LIMIT_MAX` | 10/мин | Per user |

## Очередь

- Production: **ARQ + Redis** (`REDIS_URL`)
- Local dev: in-process queue (без Redis)
