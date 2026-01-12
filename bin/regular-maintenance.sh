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

report_repo_if_dirty() {
  local repo="$1"
  [[ -d "$repo/.git" ]] || return 0

  local status
  status="$(cd "$repo" && git status --porcelain 2>/dev/null || true)"

  if [[ -n "$status" ]]; then
    log "Dirty repo: $repo"
    log "git status --short:"
    (cd "$repo" && git status --short) | while IFS= read -r line; do log "  $line"; done
    log "git submodule status:"
    (cd "$repo" && git submodule status 2>/dev/null || true) | while IFS= read -r line; do log "  $line"; done
  fi
}

report_dirty_class_repos() {
  local root="$HOME/SoftwareRepositories"
  [[ -d "$root" ]] || return 0

  log "Scanning for dirty class repos under $root ..."
  local repo
  for repo in "$root"/MATH*; do
    [[ -d "$repo" ]] || continue
    report_repo_if_dirty "$repo"
  done
  log "Scan complete."
}

BASE="$HOME/Documents/SharedConfigs/bin"

log "===== Regular maintenance run started. ====="

sudo -v

run_step "sync-brew"          "${BASE}/sync-brew.sh"
run_step "update-texlive"     sudo "${BASE}/update-texlive.sh"
run_step "sharedconfigs-save" "${BASE}/sharedconfigs-save.sh"

if [[ -x "${BASE}/sync-dev.sh" ]]; then
  run_step "sync-dev (pull-only)" "${BASE}/sync-dev.sh"
else
  log "sync-dev.sh not found at ${BASE}/sync-dev.sh; skipping dev sync."
fi

if command -v sync-class.sh >/dev/null 2>&1; then
  log "Starting: sync-class (no-push)"
  set +e
  sync-class.sh
  exit_code=$?
  set -e

  if [[ ${exit_code} -eq 0 ]]; then
    log "Finished: sync-class (no-push) (ok)"
  else
    log "FAILED: sync-class (no-push) (exit ${exit_code})"
    log "sync-class likely detected pointer changes; run sync-class.sh --push when ready."
    report_dirty_class_repos
  fi
else
  log "sync-class.sh not found on PATH; skipping class sync."
fi

log "===== Regular maintenance run finished. ====="
