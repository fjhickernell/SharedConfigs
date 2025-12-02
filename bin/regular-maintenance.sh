#!/bin/zsh

set -u

notify() {
  local message="$1"
  local title="${2:-Regular Maintenance}"
  osascript -e "display notification \"${message}\" with title \"${title}\"" >/dev/null 2>&1
}

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
  notify "Starting ${name}…" "Regular Maintenance"

  eval "${cmd}"
  local status=$?

  if [[ ${status} -eq 0 ]]; then
    log "Finished: ${name} (ok)"
    notify "${name} finished successfully." "Regular Maintenance"
  else
    log "FAILED: ${name} (exit ${status})"
    notify "${name} failed (exit ${status}). Check Terminal." "Regular Maintenance"
  fi

  return ${status}
}

BASE="$HOME/Documents/SharedConfigs/bin"

notify "Maintenance run started." "Regular Maintenance"
log "===== Regular maintenance run started. ====="

run_step "sync-brew" "${BASE}/sync-brew.sh"
run_step "sync-qmcpy-env" "${BASE}/sync-qmcpy-env.sh"
run_step "sharedconfigs-save" "${BASE}/sharedconfigs-save.sh"

log "===== Regular maintenance run finished. ====="
notify "Maintenance run finished. Check Terminal for details." "Regular Maintenance"
