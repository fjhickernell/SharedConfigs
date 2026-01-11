#!/usr/bin/env bash
set -euo pipefail

log() {
  /bin/date '+[%Y-%m-%d %H:%M:%S]'" $*"
}

die() {
  log "ERROR: $*"
  exit 1
}

is_git_repo() {
  /usr/bin/git rev-parse --is-inside-work-tree >/dev/null 2>&1
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

MSG="${1:-}"
[[ -n "${MSG}" ]] || die "Usage: publish-classlib-here.sh \"commit message\""

is_git_repo || die "Run this from inside a class repo (superproject)."
[[ -d "classlib" ]] || die "Missing submodule directory: classlib"
[[ -d "classlib/.git" || -f "classlib/.git" ]] || die "classlib does not look like a git checkout."

require_clean_superproject_except_classlib

log "Publishing classlib changes (if any) and updating submodule pointer..."

/usr/bin/git -C classlib fetch origin
if [[ -z "$(/usr/bin/git -C classlib symbolic-ref -q --short HEAD || true)" ]]; then
  /usr/bin/git -C classlib checkout main
fi
/usr/bin/git -C classlib checkout main
/usr/bin/git -C classlib pull --ff-only

if [[ -n "$(/usr/bin/git -C classlib status --porcelain)" ]]; then
  /usr/bin/git -C classlib add -A
  /usr/bin/git -C classlib commit -m "${MSG}"
  /usr/bin/git -C classlib push
else
  log "No classlib working-tree changes to commit."
fi

/usr/bin/git -C classlib fetch origin
/usr/bin/git -C classlib checkout main
/usr/bin/git -C classlib pull --ff-only

NEW_SHA="$(/usr/bin/git -C classlib rev-parse HEAD)"

log "Ensuring submodule checkout is at ${NEW_SHA}..."
/usr/bin/git -C classlib checkout main
/usr/bin/git -C classlib reset --hard "${NEW_SHA}"

if /usr/bin/git diff --quiet --submodule classlib; then
  log "No submodule pointer change to commit."
  exit 0
fi

/usr/bin/git add classlib
/usr/bin/git commit -m "Bump classlib submodule: ${MSG}"
/usr/bin/git push

log "Done."
