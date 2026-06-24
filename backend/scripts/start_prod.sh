#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

if [ -n "${REDIS_URL:-}" ]; then
  echo "Starting ARQ worker in background..."
  arq app.worker.WorkerSettings &
  WORKER_PID=$!
  trap "kill $WORKER_PID 2>/dev/null || true" EXIT
fi

exec uvicorn main:app --host 0.0.0.0 --port "${PORT:-3001}"
