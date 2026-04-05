#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/.venv/bin/activate"

exec python -c "import importlib.util; import uvicorn; spec = importlib.util.spec_from_file_location('manim_test_app', '$SCRIPT_DIR/manim-test.py'); module = importlib.util.module_from_spec(spec); spec.loader.exec_module(module); uvicorn.run(module.app, host='127.0.0.1', port=8000)"
