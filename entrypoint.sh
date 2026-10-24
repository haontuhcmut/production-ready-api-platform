
#!/bin/bash
set -e

echo "Starting FastAPI application..."

ENV=${ENV:-prod}
HOST=${HOST:-0.0.0.0}
PORT=${PORT:-8000}
WORKERS=${WORKERS:-2}
LOG_LEVEL=${LOG_LEVEL:-info}

echo "ENV=$ENV"
echo "HOST=$HOST PORT=$PORT WORKERS=$WORKERS"

if [ "$ENV" = "dev" ]; then
    echo "Running in DEV mode"

    exec uv run uvicorn backend.app.main:app \
        --host "$HOST" \
        --port "$PORT" \
        --reload \
        --reload-dir backend \
        --log-level "$LOG_LEVEL"
else
    echo "Running in PROD mode"

    exec uv run gunicorn backend.app.main:app \
        -k uvicorn.workers.UvicornWorker \
        --bind "$HOST:$PORT" \
        --workers "$WORKERS" \
        --log-level "$LOG_LEVEL" \
        --access-logfile - \
        --error-logfile -
fi
