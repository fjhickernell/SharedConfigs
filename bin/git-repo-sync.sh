#!/bin/zsh

set -uo pipefail

# Codex may run this script from a non-login shell that has not loaded the
# Homebrew PATH. Include both Intel and Apple Silicon locations so Git hooks
# can find git-lfs even when it is installed but absent from the caller's PATH.
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

typeset -a REPOS=(
  "$HOME/Documents/SharedConfigs|SharedConfigs"
  "$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/ObsidianVault/GitTracked|GitTrackedObsidian"
)

log() {
  local message="$1"
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  echo "[$timestamp] $message"
}

sync_repo() {
  local entry="$1"
  local repo="${entry%%|*}"
  local name="${entry#*|}"
  local exit_code=0

  echo
  log "Starting: $name"

  if [[ ! -d "$repo" ]]; then
    log "FAILED: folder not found: $repo"
    return 1
  fi

  if [[ ! -d "$repo/.git" ]]; then
    log "FAILED: not a Git repository: $repo"
    return 1
  fi

  (
    cd "$repo" || exit 1

    git add -A

    if git diff --cached --quiet --exit-code; then
      log "No local changes to commit in $name."
    else
      git commit -m "$name snapshot on $(hostname -s) at $(date '+%Y-%m-%d %H:%M:%S')" ||
        exit 1
    fi

    git pull --rebase || exit 1
    git push || exit 1
  ) || exit_code=$?

  if [[ $exit_code -eq 0 ]]; then
    log "Finished: $name (ok)"
  else
    log "FAILED: $name (exit $exit_code)"
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
