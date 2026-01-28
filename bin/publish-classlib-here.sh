#!/usr/bin/env bash
set -euo pipefail

# ---- color (TTY only) -------------------------------------------------
if [[ -t 1 ]]; then
  BOLD=$'\e[1m'
  DIM=$'\e[2m'
  RED=$'\e[31m'
  YELLOW=$'\e[33m'
  GREEN=$'\e[32m'
  CYAN=$'\e[36m'
  RESET=$'\e[0m'
else
  BOLD=''
  DIM=''
  RED=''
  YELLOW=''
  GREEN=''
  CYAN=''
  RESET=''
fi

log() {
  /bin/date '+[%Y-%m-%d %H:%M:%S]'" $*"
}

ok()   { log "${BOLD}${GREEN}OK:${RESET} $*"; }
warn() { log "${BOLD}${YELLOW}WARN:${RESET} $*"; }

die() {
  log "${BOLD}${RED}ERROR:${RESET} $*"
  exit 1
}

is_git_repo() {
  /usr/bin/git rev-parse --is-inside-work-tree >/dev/null 2>&1
}

require_attached_head_superproject() {
  local b
  b="$(/usr/bin/git symbolic-ref -q --short HEAD 2>/dev/null || true)"
  [[ -n "${b}" ]] || die "Superproject is in DETACHED HEAD. Run: git switch main (or the correct branch) first."
}

require_superproject_main() {
  local b
  b="$(/usr/bin/git symbolic-ref -q --short HEAD 2>/dev/null || true)"
  [[ "${b}" == "main" ]] || die "Superproject is on '${b:-DETACHED}'. Expected 'main' for bump commit/push."
}

require_superproject_not_ahead() {
  local ahead
  ahead="$(/usr/bin/git rev-list --count @{u}..HEAD 2>/dev/null || echo 0)"
  [[ "${ahead}" == "0" ]] || die "Superproject has ${ahead} unpushed commit(s). Push/stash before publishing classlib."
}

require_clean_superproject_except_classlib() {
  local ws line path
  ws="$(/usr/bin/git status --porcelain)"
  [[ -z "${ws}" ]] && return 0
  while IFS= read -r line; do
    path="${line##* }"
    if [[ "${path}" != "classlib" ]]; then
      die "Superproject dirty outside 'classlib'. Commit/stash those changes first."
    fi
  done <<< "${ws}"
}

classlib_head_ref() {
  /usr/bin/git -C classlib symbolic-ref -q --short HEAD 2>/dev/null || true
}

verify_classlib_tracking() {
  local head remote
  head="$(/usr/bin/git -C classlib rev-parse HEAD)"
  remote="$(/usr/bin/git -C classlib rev-parse origin/main)"
  [[ "${head}" == "${remote}" ]] || die "classlib HEAD != origin/main after push/pull. Something is off."
  ok "classlib main matches origin/main (${head:0:12})"
}

ALLOW_MERGE=0

ensure_classlib_main_ready() {
  local cur head_short tmp

  /usr/bin/git -C classlib fetch origin main

  cur="$(classlib_head_ref)"

  if [[ -z "${cur}" ]]; then
    head_short="$(/usr/bin/git -C classlib rev-parse --short=12 HEAD)"
    tmp="wip-classlib-${head_short}"

    log "classlib is detached at ${head_short}; creating temporary branch ${tmp}..."
    /usr/bin/git -C classlib switch -c "${tmp}"

    if [[ -n "$(/usr/bin/git -C classlib status --porcelain)" ]]; then
      log "Committing classlib working-tree changes on ${tmp}..."
      /usr/bin/git -C classlib add -A
      /usr/bin/git -C classlib commit -m "${MSG}"
    else
      log "No classlib working-tree changes to commit on ${tmp}."
    fi

    log "Switching classlib to main and integrating ${tmp}..."
    /usr/bin/git -C classlib switch main
    /usr/bin/git -C classlib pull --ff-only origin main

    if /usr/bin/git -C classlib merge --ff-only "${tmp}"; then
      ok "Integrated ${tmp} into classlib/main via fast-forward."
    else
      if [[ "${ALLOW_MERGE}" -eq 0 ]]; then
        die "Non-fast-forward integration needed for ${tmp} -> main. Re-run with --allow-merge if you really want a merge commit."
      fi
      warn "${RED}Non-fast-forward merge needed to integrate ${tmp} into classlib/main.${RESET}"
      warn "${RED}Proceeding because --allow-merge was provided.${RESET}"
      /usr/bin/git -C classlib merge "${tmp}"
    fi

    /usr/bin/git -C classlib branch -d "${tmp}" || true
    return 0
  fi

  if [[ "${cur}" == "main" ]]; then
    /usr/bin/git -C classlib pull --ff-only origin main
    return 0
  fi

  if [[ "${cur}" == wip-classlib-* ]]; then
    tmp="${cur}"
    log "classlib is on ${tmp}; integrating into main..."
    /usr/bin/git -C classlib switch main
    /usr/bin/git -C classlib pull --ff-only origin main

    if /usr/bin/git -C classlib merge --ff-only "${tmp}"; then
      ok "Integrated ${tmp} into classlib/main via fast-forward."
    else
      if [[ "${ALLOW_MERGE}" -eq 0 ]]; then
        die "Non-fast-forward integration needed for ${tmp} -> main. Re-run with --allow-merge if you really want a merge commit."
      fi
      warn "${RED}Non-fast-forward merge needed to integrate ${tmp} into classlib/main.${RESET}"
      warn "${RED}Proceeding because --allow-merge was provided.${RESET}"
      /usr/bin/git -C classlib merge "${tmp}"
    fi

    /usr/bin/git -C classlib branch -d "${tmp}" || true
    return 0
  fi

  die "classlib is on branch '${cur}' (expected 'main' or 'wip-classlib-*')."
}

MSG=""
if [[ "${1:-}" == "--allow-merge" ]]; then
  ALLOW_MERGE=1
  shift
fi

MSG="${1:-}"
[[ -n "${MSG}" ]] || die "Usage: publish-classlib-here.sh [--allow-merge] \"commit message\""

is_git_repo || die "Run this from inside a class repo (superproject)."
[[ -d "classlib" ]] || die "Missing submodule directory: classlib"
[[ -d "classlib/.git" || -f "classlib/.git" ]] || die "classlib does not look like a git checkout."

require_attached_head_superproject
require_superproject_main
require_superproject_not_ahead
require_clean_superproject_except_classlib

log "Publishing classlib changes (if any) and updating submodule pointer..."

ensure_classlib_main_ready

if [[ -n "$(/usr/bin/git -C classlib status --porcelain)" ]]; then
  log "Committing classlib working-tree changes on main..."
  /usr/bin/git -C classlib add -A
  /usr/bin/git -C classlib commit -m "${MSG}"
else
  log "No classlib working-tree changes to commit."
fi

log "Pushing classlib main..."
/usr/bin/git -C classlib push origin main

verify_classlib_tracking

NEW_SHA="$(/usr/bin/git -C classlib rev-parse HEAD)"

log "Ensuring submodule checkout is at ${NEW_SHA}..."
/usr/bin/git -C classlib reset --hard "${NEW_SHA}"

if [[ -n "$(/usr/bin/git -C classlib status --porcelain)" ]]; then
  die "classlib still dirty after reset --hard ${NEW_SHA}. Aborting."
fi

RECORDED_SHA="$(/usr/bin/git ls-tree -d HEAD classlib | awk '{print $3}')"

if [[ "${RECORDED_SHA}" == "${NEW_SHA}" ]]; then
  log "No submodule pointer change to commit."
  exit 0
fi

/usr/bin/git add classlib
/usr/bin/git commit -m "Bump classlib submodule: ${MSG}"
/usr/bin/git push

RECORDED_SHA="$(/usr/bin/git ls-tree -d HEAD classlib | awk '{print $3}')"
[[ "${RECORDED_SHA}" == "${NEW_SHA}" ]] || die "Superproject recorded classlib SHA != NEW_SHA after commit."

ok "Superproject now pins classlib at ${NEW_SHA:0:12}"
log "Done."
