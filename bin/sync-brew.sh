#!/bin/zsh
set -euo pipefail

LOGDIR="$HOME/Library/Logs"
LOGFILE="$LOGDIR/sync-brew.log"

mkdir -p "$LOGDIR"

if [ -t 1 ]; then
  MODE="manual"
else
  MODE="launchd"
fi

run_syncbrew() {
  echo "===== $(date '+%Y-%m-%d %H:%M:%S %Z') syncbrew ${MODE} run started. ====="

  if command -v brew >/dev/null 2>&1; then
    brew update
    brew bundle --global
    brew upgrade
    brew cleanup
  else
    echo "brew not found on PATH; skipping Homebrew tasks."
  fi

  if command -v mas >/dev/null 2>&1; then
    if [ "$MODE" = "manual" ]; then
      echo "Running mas upgrade in manual (interactive) mode."
      mas upgrade || echo "mas upgrade encountered errors; see above."
    else
      echo "Skipping mas upgrade in launchd (non-interactive) mode."
    fi
  else
    echo "mas not found on PATH; skipping Mac App Store tasks."
  fi

  echo "===== $(date '+%Y-%m-%d %H:%M:%S %Z') syncbrew ${MODE} run finished. ====="
}

if [ "$MODE" = "manual" ]; then
  run_syncbrew | tee -a "$LOGFILE"
else
  run_syncbrew >> "$LOGFILE" 2>&1
fi