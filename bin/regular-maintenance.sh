#!/bin/zsh

set -euo pipefail

# Starting this maintenance workflow authorizes its Homebrew installations
# and upgrades, including the separate TeXstudio step.
export HOMEBREW_NO_ASK=1

log() {
  local message="$1"
  local ts
  ts=$(date '+%Y-%m-%d %H:%M:%S')
  echo "[$ts] $message"
}

banner() {
  printf '\033[1;32m%s\033[0m\n' "$(log "$1")"
}

report_elapsed() {
  local exit_code="$1"
  local elapsed=$(( $(/bin/date +%s) - maintenance_started_at ))
  local duration
  duration="$(printf '%02d:%02d:%02d' $(( elapsed / 3600 )) $(( (elapsed % 3600) / 60 )) $(( elapsed % 60 )))"

  if (( exit_code == 0 )); then
    log "Total elapsed wall time: ${duration}."
  else
    log "Total elapsed wall time: ${duration} (exit ${exit_code})."
  fi
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
    failed_steps+=("${name} (exit ${exit_code})")
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
    exit ${exit_code}
  fi
}

report_repo_if_dirty() {
  local repo="$1"
  [[ -d "$repo/.git" ]] || return 0

  local repo_status
  repo_status="$(cd "$repo" && git status --porcelain 2>/dev/null || true)"

  if [[ -n "$repo_status" ]]; then
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
  for repo in "$root"/MATH*(N/); do
    [[ -d "$repo" ]] || continue
    report_repo_if_dirty "$repo"
  done
  log "Scan complete."
}

BASE="$HOME/Documents/SharedConfigs/bin"
typeset -a failed_steps=()
maintenance_started_at=$(/bin/date +%s)
trap 'report_elapsed $?' EXIT

banner "===== Regular maintenance run started. ====="

sudo -v

# Refresh metadata once before any install/upgrade command in this run.
run_step_fatal "brew-update" brew update
export HOMEBREW_NO_AUTO_UPDATE=1

run_step_fatal "prepare-texstudio" "${BASE}/update-texstudio.sh" --prepare
run_step "sync-brew"          env SYNC_BREW_SKIP_UPDATE=1 "${BASE}/sync-brew.sh"
run_step "update-texlive"     sudo "${BASE}/update-texlive.sh"
run_step "git-repo-sync"      "${BASE}/git-repo-sync.sh"

if [[ -x "${BASE}/sync-dev.sh" ]]; then
  run_step "sync-dev (pull-only)" "${BASE}/sync-dev.sh"
else
  log "sync-dev.sh not found at ${BASE}/sync-dev.sh; skipping dev sync."
fi

if command -v sync-active.sh >/dev/null 2>&1; then
  log "Starting: sync-active (no-push)"
  set +e
  sync-active.sh
  exit_code=$?
  set -e

  if [[ ${exit_code} -eq 0 ]]; then
    log "Finished: sync-active (no-push) (ok)"
  else
    log "FAILED: sync-active (no-push) (exit ${exit_code})"
    failed_steps+=("sync-active (no-push) (exit ${exit_code})")
    log "Review the sync-active output before retrying; a dirty working tree can cause a skip without changing any pointers."
    report_dirty_class_repos || log "Diagnostic folder scan failed; see output above."
  fi
else
  log "sync-active.sh not found on PATH; skipping class sync."
fi

if (( ${#failed_steps} )); then
  banner "===== Regular maintenance finished with ${#failed_steps} failed step(s). ====="
  for failed_step in "${failed_steps[@]}"; do
    log "Needs attention: ${failed_step}"
  done
  exit 1
fi

banner "===== Regular maintenance run finished successfully. ====="
