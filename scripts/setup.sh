#!/bin/bash
set -euo pipefail
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
case "${1:-}" in
  ""|--build-only) ;;
  *) echo 'Usage: bash scripts/setup.sh [--build-only]'; exit 2 ;;
esac
if ! xcode-select -p >/dev/null 2>&1; then
  echo '请先运行 xcode-select --install，完成 Apple Command Line Tools 安装后重试。'; exit 1
fi
if ! command -v python3 >/dev/null 2>&1; then echo '需要 Python 3.9+（Apple Command Line Tools 通常提供）。'; exit 1; fi
python3 "$PROJECT_ROOT/scripts/doctor.py"
python3 "$PROJECT_ROOT/scripts/fetch_dependencies.py"
python3 "$PROJECT_ROOT/scripts/build.py"
if [[ "${1:-}" != --build-only ]]; then python3 "$PROJECT_ROOT/scripts/manage.py" install; fi
