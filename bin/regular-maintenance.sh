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
  shift

  log "Starting: ${name}"
  set +e
  "$@"
  local exit_code=$?
  set -e

  if [[ ${exit_code} -eq 0 ]]; then
    log "Finished: ${name} (ok)"
  else
    log "FAILED: ${name} (exit ${exit_code})"
  fi

  return 0
}

run_step_fatal() {
  local name="$1"
  shift

  log "Starting: ${name}"
  set +e
  "$@"
  local exit_code=$?
  set -e

  if [[ ${exit_code} -eq 0 ]]; then
    log "Finished: ${name} (ok)"
    return 0
  else
    log "FAILED: ${name} (exit ${exit_code})"
    return ${exit_code}
  fi
}

BASE="$HOME/Documents/SharedConfigs/bin"

log "===== Regular maintenance run started. ====="

sudo -v

run_step "sync-brew"          "${BASE}/sync-brew.sh"
run_step "update-texlive"     sudo "${BASE}/update-texlive.sh"
run_step "sharedconfigs-save" "${BASE}/sharedconfigs-save.sh"

if [ -x "${BASE}/update-class-submodules.sh" ]; then
  run_step "update-class-submodules" "${BASE}/update-class-submodules.sh" || \
    log "update-class-submodules failed (non-fatal; continuing)."
fi

log "===== Regular maintenance run finished. ====="
