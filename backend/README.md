# CarConvert Backend

FastAPI backend с SQLite, JWT auth, WebSocket realtime hints и async photo processing.

## Быстрый старт

```powershell
cd backend
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
copy .env.example .env
# заполни OPENROUTER_API_KEY и JWT_SECRET
uvicorn main:app --reload --host 0.0.0.0 --port 3001
```

Полная документация: [../README.md](../README.md)
