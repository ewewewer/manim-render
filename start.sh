#!/usr/bin/env bash

set -euo pipefail

PORT="${PORT:-8000}"
HOST="${HOST:-0.0.0.0}"

exec uvicorn render_app:app --host "$HOST" --port "$PORT"
