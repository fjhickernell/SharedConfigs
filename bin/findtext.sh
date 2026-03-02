#!/usr/bin/env bash
# findtext — recursively search for literal text in a directory tree
# Usage: findtext "search string"
# Example: findtext "??"

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: findtext \"search string\""
  exit 1
fi

find . \
  -type d \( \
    -name .git -o \
    -name _site -o \
    -name site_libs -o \
    -name _freeze -o \
    -name .quarto -o \
    -name .quarto-watch-logs -o \
    -name node_modules -o \
    -name dist -o \
    -name build -o \
    -name coverage -o \
    -name __pycache__ -o \
    -name .ipynb_checkpoints -o \
    -name .venv -o \
    -name .mypy_cache -o \
    -name "*_files" \
  \) -prune -o \
  -type f \( \
    -name .DS_Store -o \
    -name "*.min.js" -o \
    -name "*.min.css" -o \
    -name "*.map" -o \
    -name "package-lock.json" -o \
    -name "yarn.lock" -o \
    -name "pnpm-lock.yaml" \
  \) -prune -o \
  -type f -print0 | xargs -0 grep -nIF "$1"