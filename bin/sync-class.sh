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
  /usr/bin/git fetch origin
  /usr/bin/git merge --ff-only '@{u}'
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

    /usr/bin/git checkout "${branch}"
    pull_ff_only
  )
}

push_if_ahead() {
  if /usr/bin/git rev-parse --quiet --verify '@{u}' >/dev/null 2>&1; then
    local ahead_count
    ahead_count=$(/usr/bin/git rev-list --count '@{u}..HEAD')
    if [[ "${ahead_count}" -gt 0 ]]; then
      /usr/bin/git push
    else
      log "No commits to push; skipping git push."
    fi
  else
    /usr/bin/git push
  fi
}

sync_class_repo() {
  local repo="$1"
  local do_promote="$2"
  local do_commit="$3"
  local do_push="$4"

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

    if [[ "${do_promote}" -eq 1 ]]; then
      if command -v update-submodules.sh >/dev/null 2>&1; then
        update-submodules.sh || true
      else
        log "SKIP: missing update-submodules.sh on PATH in ${repo}"
        return 0
      fi
    else
      /usr/bin/git submodule update --init --recursive
    fi

    /usr/bin/git submodule status
    /usr/bin/git status --short

    if ! is_clean; then
      if [[ "${do_commit}" -eq 1 ]]; then
        if only_submodule_pointers_dirty; then
          local msg cls_sha qmc_sha
          cls_sha=""
          qmc_sha=""

          if [[ -d "classlib/.git" || -f "classlib/.git" ]]; then
            cls_sha=$(/usr/bin/git -C classlib rev-parse --short=12 HEAD 2>/dev/null || true)
          fi
          if [[ -d "qmcsoftware/.git" || -f "qmcsoftware/.git" ]]; then
            qmc_sha=$(/usr/bin/git -C qmcsoftware rev-parse --short=12 HEAD 2>/dev/null || true)
          fi

          msg="Update submodule pointers"
          if [[ -n "${cls_sha}" || -n "${qmc_sha}" ]]; then
            msg="${msg} (classlib ${cls_sha:-na}, qmcsoftware ${qmc_sha:-na})"
          fi

          /usr/bin/git add classlib qmcsoftware
          /usr/bin/git commit -m "${msg}"
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
        log "Run: sync-class.sh --commit   (or --push)"
        return 0
      fi
    fi

    if [[ "${do_push}" -eq 1 ]]; then
      push_if_ahead
    fi
  )
}

usage() {
  cat <<'EOF'
sync-class.sh

Default (no flags):
  - Pull standalone repos
  - Pull class repos
  - Update submodules to pinned SHAs (git submodule update --init --recursive)
  - No commits, no pushes

Flags:
  --promote   Advance submodules to tip (runs update-submodules.sh from PATH)
  --commit    If submodule pointers changed, commit them in each class repo
  --push      Implies --commit and --promote; push the pointer commits
EOF
}

do_promote=0
do_commit=0
do_push=0

for arg in "$@"; do
  case "${arg}" in
    --promote) do_promote=1 ;;
    --commit) do_commit=1 ;;
    --push) do_push=1 ;;
    --help|-h) usage; exit 0 ;;
    *)
      log "ERROR: unknown argument: ${arg}"
      usage
      exit 2
      ;;
  esac
done

if [[ "${do_push}" -eq 1 ]]; then
  do_commit=1
  do_promote=1
fi

STANDALONE_REPOS=(
  "$HOME/SoftwareRepositories/HickernellClassLib:main"
  "$HOME/SoftwareRepositories/QMCSoftware:develop"
)

CLASS_REPOS=(
  "$HOME/SoftwareRepositories/MATH565Fall2025"
  "$HOME/SoftwareRepositories/MATH476Spring2026"
  "$HOME/SoftwareRepositories/MATH563Spring2026"
  "$HOME/SoftwareRepositories/SIAMUQ26"
)

if [[ "${do_promote}" -eq 1 ]]; then
  log "===== Sync class started (PROMOTE: advance submodules to tip) ====="
else
  log "===== Sync class started (PINNED: match class repo submodule SHAs) ====="
fi

for spec in "${STANDALONE_REPOS[@]}"; do
  repo="${spec%%:*}"
  branch="${spec##*:}"
  sync_standalone_repo "${repo}" "${branch}"
done

for repo in "${CLASS_REPOS[@]}"; do
  sync_class_repo "${repo}" "${do_promote}" "${do_commit}" "${do_push}"
done

log "===== Sync class finished ====="