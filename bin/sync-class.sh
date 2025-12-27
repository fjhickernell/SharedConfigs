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
  /usr/bin/git pull --ff-only
}

sync_standalone_repo() {
  local repo="$1"
  local branch="$2"

  log "Standalone repo: ${repo} (${branch})"
  if [[ ! -d "${repo}/.git" ]]; then
    log "SKIP: not a git repo: ${repo}"
    return 0
  fi

  (
    cd "${repo}"

    if ! is_clean; then
      log "SKIP: dirty working tree in ${repo}"
      /usr/bin/git status --short
      return 0
    fi

    /usr/bin/git fetch origin || true
    /usr/bin/git checkout "${branch}"
    pull_ff_only
  )
}

sync_class_repo_latest_submodules() {
  local repo="$1"
  local do_commit="$2"
  local do_push="$3"

  log "Class repo: ${repo}"
  if [[ ! -d "${repo}/.git" ]]; then
    log "SKIP: not a git repo: ${repo}"
    return 0
  fi

  (
    cd "${repo}"

    if ! only_submodule_pointers_dirty; then
      log "SKIP: dirty working tree (non-submodule changes) in ${repo}"
      /usr/bin/git status --short
      return 0
    fi

    pull_ff_only

    if [[ -x "./classlib/bin/update-submodules.sh" ]]; then
      ./classlib/bin/update-submodules.sh || true
    else
      log "SKIP: missing ./classlib/bin/update-submodules.sh in ${repo}"
      return 0
    fi

    /usr/bin/git submodule status
    /usr/bin/git status --short

    if ! is_clean; then
      if [[ "${do_commit}" -eq 1 || "${do_push}" -eq 1 ]]; then
        if only_submodule_pointers_dirty; then
          /usr/bin/git add classlib qmcsoftware
          /usr/bin/git commit -m "Update submodule pointers"
        else
          log "SKIP: changes present but not only submodule pointers; not committing"
          /usr/bin/git status --short
          return 0
        fi
      else
        log "Uncommitted submodule pointer changes detected."
        log ""
        log "git status --short:"
        /usr/bin/git status --short
        log ""
        log "Run: sync-class.sh --commit   (then optionally --push)"
        return 0
      fi
    fi

    if [[ "${do_push}" -eq 1 ]]; then
      /usr/bin/git push
    fi
  )
}

do_commit=0
do_push=0

for arg in "$@"; do
  case "${arg}" in
    --commit) do_commit=1 ;;
    --push) do_push=1 ;;
    *)
      log "ERROR: unknown argument: ${arg}"
      exit 2
      ;;
  esac
done

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
  sync_class_repo_latest_submodules "${repo}" "${do_commit}" "${do_push}"
done

log "===== Sync class finished ====="
