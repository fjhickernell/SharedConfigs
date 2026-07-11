#!/bin/zsh

set -uo pipefail

typeset -a REPOS=(
  "$HOME/Documents/SharedConfigs|SharedConfigs"
  "$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/ObsidianVault/GitTracked|GitTrackedObsidian"
)

log() {
  local message="$1"
  local ts
  ts=$(date '+%Y-%m-%d %H:%M:%S')
  echo "[$ts] $message"
}

sync_repo() {
  local entry="$1"
  local repo="${entry%%|*}"
  local name="${entry#*|}"
  local commit_message
  local exit_code=0

  echo
  log "Starting Git synchronization: $name"

  if [[ ! -d "$repo" ]]; then
    log "FAILED: folder does not exist: $repo"
    return 1
  fi

  if [[ ! -d "$repo/.git" ]]; then
    log "FAILED: not a Git repository: $repo"
    return 1
  fi

  (
    cd "$repo" || exit 1

    git add -A

    if ! git diff --cached --quiet --exit-code; then
      commit_message="$name snapshot on $(hostname -s) at $(date '+%Y-%m-%d %H:%M:%S')"
      git commit -m "$commit_message" || exit 1
    else
      log "No local changes to commit in $name."
    fi

    git pull --rebase || exit 1
    git push || exit 1
  ) || exit_code=$?

  if [[ $exit_code -eq 0 ]]; then
    log "Finished Git synchronization: $name (ok)"
  else
    log "FAILED Git synchronization: $name (exit $exit_code)"
  fi

  return $exit_code
}

log "===== Git repository synchronization started. ====="

overall_exit_code=0

for entry in "${REPOS[@]}"; do
  if ! sync_repo "$entry"; then
    overall_exit_code=1
  fi
done

if [[ $overall_exit_code -eq 0 ]]; then
  print -P "%B%F{green}All configured Git repositories synchronized.%f%b"
else
  print -P "%B%F{red}One or more Git repositories failed to synchronize.%f%b"
fi

log "===== Git repository synchronization finished. ====="

exit $overall_exit_code