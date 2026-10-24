#!/bin/bash
set -e # stop on error

echo "Starting FastAPI application..."

# Default configure
ENV=${ENV:-prod}
HOST=${HOST:-0.0.0.0}
PORT=${PORT:-8000}
WORKERS=${WORKERS:-2}
LOG_LEVEL=${LOG_LEVEL:-info}

echo "ENV=$ENV"
echo "HOST=$HOST PORT=$PORT WORKERS=$WORKERS"

if [ "$ENV" = "dev" ]; then
  echo "Running in DEV mode (auto-reload enable)"

  exec uv run uvicorn app.main:app \
    --host $HOST \
    --port $PORT \
    --reload \
    --log-level $LOG_LEVEL

else
  echo "Running in PROD mode (gunicorn + uvicorn workers)"
  exec gunicorn app.main:app \
    -k uv run uvicorn.workers.UvicornWorker \
    --bind $HOST:$PORT \
    --workers $WORKERS \
    --log-level $LOG_LEVEL \
    --access-logfile - \
    --error-logfile -
fi