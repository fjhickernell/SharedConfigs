#!/usr/bin/env zsh
set -uo pipefail

sync-dev.sh
rc_dev=$?

sync-class.sh
rc_class=$?

if [[ $rc_dev -ne 0 || $rc_class -ne 0 ]]; then
  echo "arrive failed (sync-dev=$rc_dev, sync-class=$rc_class)"
  exit 1
fi

if command -v pr-status >/dev/null 2>&1; then
  pr-status || true
fi