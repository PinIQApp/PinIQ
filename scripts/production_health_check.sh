#!/usr/bin/env bash
set -euo pipefail

API_URL="${1:-http://127.0.0.1:8000}"
WEB_URL="${2:-http://127.0.0.1:8080}"

curl --fail --show-error --silent "$API_URL/health/live" >/dev/null
curl --fail --show-error --silent "$API_URL/health/ready" >/dev/null
curl --fail --show-error --silent "$WEB_URL/" >/dev/null
curl --fail --show-error --silent "$WEB_URL/manifest.json" >/dev/null
curl --fail --show-error --silent "$WEB_URL/offline.html" >/dev/null

echo "Production health checks passed."
