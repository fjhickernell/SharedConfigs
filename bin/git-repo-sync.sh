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

pull_rebase() {
  local name="$1"

  if git pull --rebase; then
    return 0
  fi

  # Do not leave a repository in an interrupted rebase. This is harmless when
  # the pull failed before starting one.
  git rebase --abort >/dev/null 2>&1 || true
  log "FAILED: could not rebase $name; any interrupted rebase was aborted."
  return 1
}

sync_repo() {
  local entry="$1"
  local repo="${entry%%|*}"
  local name="${entry#*|}"
  local exit_code=0
  local lock_dir="${TMPDIR:-/tmp}/git-repo-sync-${name}.lock"

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

  # This lock is machine-local, so it prevents overlapping maintenance jobs
  # without adding synchronization files to iCloud.
  if ! mkdir "$lock_dir" 2>/dev/null; then
    log "FAILED: another local sync appears to be running for $name."
    return 1
  fi

  (
    trap 'rmdir "$lock_dir" 2>/dev/null || true' EXIT

    cd "$repo" || exit 1

    git add -A

    if git diff --cached --quiet --exit-code; then
      log "No local changes to commit in $name."
    else
      git commit -m "$name snapshot on $(hostname -s) at $(date '+%Y-%m-%d %H:%M:%S')" ||
        exit 1
    fi

    pull_rebase "$name" || exit 1

    if ! git push; then
      # Another Mac may have pushed after our pull. Integrate once and retry;
      # persistent failures still stop safely and are reported to the caller.
      log "Push did not succeed for $name; rebasing and retrying once."
      pull_rebase "$name" || exit 1
      git push || exit 1
    fi
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
