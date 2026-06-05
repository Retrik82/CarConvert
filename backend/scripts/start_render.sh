#!/usr/bin/env bash
set -euo pipefail
python -c "from main import app; print('Import OK:', app.title)"
exec uvicorn main:app --host 0.0.0.0 --port "${PORT:-3001}"
