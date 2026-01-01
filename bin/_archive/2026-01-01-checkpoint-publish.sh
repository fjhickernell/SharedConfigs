#!/usr/bin/env zsh
set -euo pipefail

log() {
  local ts
  ts=$(/bin/date '+%Y-%m-%d %H:%M:%S')
  echo "[$ts] $*"
}

is_clean() {
  [[ -z "$(/usr/bin/git status --porcelain)" ]]
}

pull_ff_only() {
  /usr/bin/git pull --ff-only
}

STANDALONE_REPOS=(
  "$HOME/SoftwareRepositories/HickernellClassLib:main"
  "$HOME/SoftwareRepositories/QMCSoftware:develop"
)

CLASS_REPOS_ALL=(
  "$HOME/SoftwareRepositories/MATH565Fall2025"
  "$HOME/SoftwareRepositories/MATH476Spring2026"
)

MODE="${1:-}"
START_DIR="$(pwd)"

TARGET_TOP=""
if [[ "${MODE}" != "--all" ]]; then
  if [[ ! -d ".git" ]]; then
    log "ERROR: not in a git repo."
    log "Run from inside a class repo, or use: checkpoint-publish.sh --all"
    exit 1
  fi
  TARGET_TOP="$("/usr/bin/git" rev-parse --show-toplevel)"
fi

publish_class_repo() {
  local repo="$1"

  log "Class repo: ${repo}"
  if [[ ! -d "${repo}/.git" ]]; then
    log "SKIP: not a git repo: ${repo}"
    return 0
  fi

  cd "${repo}"

  if [[ ! -x "./classlib/bin/update-submodules.sh" ]]; then
    log "SKIP: not a class repo (missing ./classlib/bin/update-submodules.sh): ${repo}"
    return 0
  fi

  if ! is_clean; then
    log "SKIP: dirty working tree in ${repo}"
    /usr/bin/git status --short
    return 0
  fi

  pull_ff_only
  ./classlib/bin/update-submodules.sh --push

  if is_clean; then
    /usr/bin/git push
  else
    log "SKIP: repo became dirty in ${repo}"
    /usr/bin/git status --short
  fi
}

log "===== Checkpoint publish started ====="

for spec in "${STANDALONE_REPOS[@]}"; do
  repo="${spec%%:*}"
  branch="${spec##*:}"

  log "Standalone repo: ${repo} (${branch})"
  if [[ ! -d "${repo}/.git" ]]; then
    log "SKIP: not a git repo: ${repo}"
    continue
  fi

  cd "${repo}"

  if ! is_clean; then
    log "SKIP: dirty working tree in ${repo}"
    /usr/bin/git status --short
    continue
  fi

  /usr/bin/git fetch origin || true
  /usr/bin/git checkout "${branch}"
  pull_ff_only
  /usr/bin/git push
done

cd "${START_DIR}"

if [[ "${MODE}" == "--all" ]]; then
  for repo in "${CLASS_REPOS_ALL[@]}"; do
    publish_class_repo "${repo}"
  done
else
  publish_class_repo "${TARGET_TOP}"
fi

cd "${START_DIR}"
log "===== Checkpoint publish finished ====="