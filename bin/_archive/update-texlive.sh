#!/bin/zsh
set -euo pipefail

LOG_DIR="$HOME/Library/Logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/update-texlive.log"

{
  echo "===== $(date '+%Y-%m-%d %H:%M:%S %Z') TeX Live update started. ====="

  export PATH="/Library/TeX/texbin:$PATH"

  if ! command -v tlmgr >/dev/null 2>&1; then
    echo "ERROR: tlmgr not found in PATH. Is MacTeX/TeX Live installed?"
    exit 1
  fi

  tlmgr update --self --all --reinstall-forcibly-removed

  print -P "%B%F{green}===== $(date '+%Y-%m-%d %H:%M:%S %Z') TeX Live update finished. =====%f%b"
} | tee -a "$LOG_FILE"