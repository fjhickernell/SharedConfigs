#!/usr/bin/env zsh
set -euo pipefail

log() {
  local ts
  ts=$(/bin/date '+%Y-%m-%d %H:%M:%S')
  echo "[$ts] $*"
}

is_clean() {
  [[ -z "$(git status --porcelain)" ]]
}

only_submodule_pointers_dirty() {
  local ws line path
  ws="$(/usr/bin/git status --porcelain)"
  [[ -z "${ws}" ]] && return 0

  while IFS= read -r line; do
    path="${line##* }"
    if [[ "${path}" != "classlib" && "${path}" != "qmcsoftware" ]]; then
      return 1
    fi
  done <<< "${ws}"

  return 0
}

pull_ff_only() {
  git pull --ff-only
}

sync_standalone_repo() {
  local repo="$1"
  local branch="$2"

  log "Standalone repo: ${repo} (${branch})"
  if [[ ! -d "${repo}/.git" ]]; then
    log "SKIP: not a git repo: ${repo}"
    return 0
  fi

  cd "${repo}"

  if ! is_clean; then
    log "SKIP: dirty working tree in ${repo}"
    git status --short
    return 0
  fi

  git fetch origin || true
  git checkout "${branch}"
  pull_ff_only
}

sync_class_repo_latest_submodules() {
  local repo="$1"

  log "Class repo: ${repo}"
  if [[ ! -d "${repo}/.git" ]]; then
    log "SKIP: not a git repo: ${repo}"
    return 0
  fi

  cd "${repo}"

  if ! only_submodule_pointers_dirty; then
    log "SKIP: dirty working tree (non-submodule changes) in ${repo}"
    git status --short
    return 0
  fi

  pull_ff_only

  if [[ -x "./classlib/bin/update-submodules.sh" ]]; then
    ./classlib/bin/update-submodules.sh
  else
    log "SKIP: missing ./classlib/bin/update-submodules.sh in ${repo}"
    return 0
  fi

  git submodule status
  git status --short
}

STANDALONE_REPOS=(
  "$HOME/SoftwareRepositories/HickernellClassLib:main"
  "$HOME/SoftwareRepositories/QMCSoftware:develop"
)

CLASS_REPOS=(
  "$HOME/SoftwareRepositories/MATH565Fall2025"
  "$HOME/SoftwareRepositories/MATH476Spring2026"
)

log "===== Sync class started (absolute latest submodules) ====="

for spec in "${STANDALONE_REPOS[@]}"; do
  repo="${spec%%:*}"
  branch="${spec##*:}"
  sync_standalone_repo "${repo}" "${branch}"
done

for repo in "${CLASS_REPOS[@]}"; do
  sync_class_repo_latest_submodules "${repo}"
done

log "===== Sync class finished ====="