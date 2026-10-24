#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DASHBOARD_FILE="$ROOT_DIR/grafana/dashboards/fastapi-overview.json"
ENV_FILE="$ROOT_DIR/.env"

if [[ ! -f "$DASHBOARD_FILE" ]]; then
  echo "Dashboard JSON not found: $DASHBOARD_FILE"
  exit 1
fi

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Grafana .env file not found: $ENV_FILE"
  exit 1
fi

set -a
source "$ENV_FILE"
set +a

: "${GRAFANA_ADMIN_USER:?Missing GRAFANA_ADMIN_USER in .env}"
: "${GRAFANA_ADMIN_PASSWORD:?Missing GRAFANA_ADMIN_PASSWORD in .env}"

echo "Waiting for Grafana..."

until curl -fsS http://localhost:3000/api/health >/dev/null; do
  sleep 2
done

echo "Importing dashboard JSON..."

jq -n \
  --argjson dashboard "$(cat "$DASHBOARD_FILE")" \
  '{
    dashboard: $dashboard,
    folderUid: "",
    overwrite: true
  }' |
curl --fail-with-body -sS \
  -u "${GRAFANA_ADMIN_USER}:${GRAFANA_ADMIN_PASSWORD}" \
  -H "Content-Type: application/json" \
  -X POST \
  http://localhost:3000/api/dashboards/db \
  -d @-

echo
echo "Dashboard import completed."
