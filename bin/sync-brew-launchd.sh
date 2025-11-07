#!/usr/bin/env bash
# Launchd-friendly wrapper to run sync-brew.sh daily and log output.

set -euo pipefail

LOG="${HOME}/Library/Logs/syncbrew.log"

{
  echo "===== $(date '+%Y-%m-%d %H:%M:%S %z') syncbrew started on $(hostname) ====="

  # Make sure PATH is good for both Intel and Apple Silicon
  export PATH="$HOME/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

  # Prefer sync-brew.sh from PATH (usually ~/bin), then fall back to SharedConfigs
  if command -v sync-brew.sh >/dev/null 2>&1; then
    echo "Using sync-brew.sh from PATH: $(command -v sync-brew.sh)"
    sync-brew.sh
  elif [[ -x "${HOME}/Documents/SharedConfigs/bin/sync-brew.sh" ]]; then
    echo "Using SharedConfigs script as fallback: ${HOME}/Documents/SharedConfigs/bin/sync-brew.sh"
    "${HOME}/Documents/SharedConfigs/bin/sync-brew.sh"
  else
    echo "ERROR: sync-brew.sh not found in PATH or SharedConfigs" >&2
    exit 78
  fi

  echo "===== $(date '+%Y-%m-%d %H:%M:%S %z') syncbrew job done. ====="
} >> "${LOG}" 2>&1