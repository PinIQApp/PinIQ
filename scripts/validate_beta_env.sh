#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
PRODUCTION_ENV_FILE="${PRODUCTION_ENV_FILE:-.env.beta}" python3 scripts/validate_production_env.py
