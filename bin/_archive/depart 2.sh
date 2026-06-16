#!/usr/bin/env zsh
set -uo pipefail

sync-dev.sh
rc_dev=$?

sync-class.sh --push
rc_class=$?

if [[ $rc_dev -ne 0 || $rc_class -ne 0 ]]; then
  echo "depart failed (sync-dev=$rc_dev, sync-class=$rc_class)"
  exit 1
fi