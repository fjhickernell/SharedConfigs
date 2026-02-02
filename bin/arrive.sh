#!/usr/bin/env bash
set -euo pipefail

sync-dev.sh
sync-class.sh

if [[ -f .uses-qmcpy ]]; then
  if command -v conda >/dev/null 2>&1; then
    eval "$(conda shell.bash hook)"
    conda activate qmcpy
  fi
fi