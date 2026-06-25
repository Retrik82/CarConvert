#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

if [ "${USE_ARQ_WORKER:-}" = "1" ] && [ -n "${REDIS_URL:-}" ]; then
  echo "Starting ARQ worker in background (USE_ARQ_WORKER=1)..."
  arq app.worker.WorkerSettings &
  WORKER_PID=$!
  trap "kill $WORKER_PID 2>/dev/null || true" EXIT
else
  echo "Photo jobs will run in-process (default). Set USE_ARQ_WORKER=1 for a separate ARQ worker."
fi

exec uvicorn main:app --host 0.0.0.0 --port "${PORT:-3001}"
