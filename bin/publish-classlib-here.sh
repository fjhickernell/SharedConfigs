#!/usr/bin/env bash
set -euo pipefail

msg_classlib="${1:-}"
msg_repo="${2:-Update classlib submodule}"

if [[ -z "$msg_classlib" ]]; then
  echo 'Usage: publish-classlib-here.sh "classlib commit message" ["repo commit message"]'
  exit 2
fi

top="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "$top" ]]; then
  echo "ERROR: not inside a git repo"
  exit 2
fi

cd "$top"

if [[ ! -e classlib ]]; then
  echo "ERROR: no ./classlib submodule found in $top"
  exit 2
fi

if git status --porcelain | grep -v '^ M classlib$' | grep -q .; then
  echo "ERROR: superproject has uncommitted changes (outside classlib); commit or stash them first"
  exit 2
fi

cd "$top/classlib"
branch="$(git rev-parse --abbrev-ref HEAD)"
if [[ "$branch" != "main" ]]; then
  echo "ERROR: classlib submodule is on branch '$branch' (expected 'main')"
  exit 2
fi

if [[ -z "$(git status --porcelain)" ]]; then
  echo "No changes in classlib submodule."
else
  git add -A
  git commit -m "$msg_classlib"
  git push

  CANON="$HOME/SoftwareRepositories/HickernellClassLib"
  if [[ -d "$CANON/.git" ]]; then
    git -C "$CANON" fetch
    git -C "$CANON" checkout main
    git -C "$CANON" pull --ff-only
  fi
fi

cd "$top"
git submodule update --checkout classlib
git add classlib

if git diff --cached --quiet; then
  echo "No submodule pointer change to commit."
else
  git commit -m "$msg_repo"
  git push
fi
