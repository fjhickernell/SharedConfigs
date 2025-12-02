#!/bin/zsh

set -euo pipefail

log() {
  local message="$1"
  local ts
  ts=$(date '+%Y-%m-%d %H:%M:%S')
  echo "[$ts] $message"
}

run_step() {
  local name="$1"
  local cmd="$2"

  log "Starting: ${name}"
  eval "${cmd}"
  local exit_code=$?

  if [[ ${exit_code} -eq 0 ]]; then
    log "Finished: ${name} (ok)"
  else
    log "FAILED: ${name} (exit ${exit_code})"
  fi

  return ${exit_code}
}

BASE="$HOME/Documents/SharedConfigs/bin"

log "===== Regular maintenance run started. ====="

sudo -v
# keep sudo alive during the whole script
while true; do sudo -n true; sleep 60; done 2>/dev/null &
SUDO_KEEPALIVE_PID=$!

run_step "sync-brew"         "${BASE}/sync-brew.sh"
run_step "sync-qmcpy-env"    "${BASE}/sync-qmcpy-env.sh"
run_step "update-texlive"    "${BASE}/update-texlive.sh"
run_step "sharedconfigs-save" "${BASE}/sharedconfigs-save.sh"

kill "$SUDO_KEEPALIVE_PID"

log "===== Regular maintenance run finished. ====="