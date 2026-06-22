#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

PYTHON_BIN="${PYTHON_BIN:-python3}"

if [ ! -f .env.production ]; then
  echo "Missing .env.production. Copy .env.production.example and fill in real production values." >&2
  exit 1
fi

"$PYTHON_BIN" scripts/validate_production_env.py
docker compose --env-file .env.production -f docker-compose.production.yml build
docker compose --env-file .env.production -f docker-compose.production.yml up -d
docker compose --env-file .env.production -f docker-compose.production.yml exec api alembic upgrade head
docker compose --env-file .env.production -f docker-compose.production.yml ps
