#!/bin/bash
set -e # stop on error

echo "Starting FastAPI application..."

if [ "$ENV" = "dev" ]; then
  echo "Running in DEV mode (auto-reload enable)"

  HOST=${HOST:-0.0.0.0}
  PORT=${PORT:-8000}
  LOG_LEVEL=${LOG_LEVEL:-debug}

  echo "ENV=$ENV HOST=$HOST PORT=$PORT LOG_LEVEL=$LOG_LEVEL"

  exec uv run uvicorn main:app \
    --host $HOST \
    --port $PORT \
    --reload \
    --log-level $LOG_LEVEL

else
  echo "Running in PROD mode (gunicorn + uvicorn workers)"

  HOST=${HOST:-0.0.0.0}
  PORT=${PORT:-8000}
  WORKERS=${WORKERS:2}
  LOG_LEVEL=${LOG_LEVEL:-info}

  echo "ENV=$ENV HOST=$HOST PORT=$PORT WORKERS=$WORKERS LOG_LEVEL=$LOG_LEVEL"

  exec uv run gunicorn main:app \
    -k uvicorn.workers.UvicornWorker \
    --bind $HOST:$PORT \
    --workers $WORKERS \
    --log-level $LOG_LEVEL \
    --access-logfile - \
    --error-logfile -
fi
