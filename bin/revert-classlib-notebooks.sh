#!/usr/bin/env bash
set -euo pipefail

if [ ! -d classlib ]; then
  echo "Error: classlib directory not found"
  exit 1
fi

if ! git -C classlib rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Error: classlib is not a git repository"
  exit 1
fi

if [ -n "$(git -C classlib diff --cached --name-only)" ]; then
  echo "Error: classlib has staged changes; aborting"
  exit 1
fi

git -C classlib restore --source=HEAD --staged --worktree classlib/notebooks

echo "Reverted notebooks in classlib/notebooks (figures left as-is)"
