#!/usr/bin/env bash
set -euo pipefail

if [ ! -d classlib ]; then
  echo "Error: classlib directory not found"
  exit 1
fi

cd classlib

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Error: classlib is not a git repository"
  exit 1
fi

git restore --source=HEAD --staged --worktree classlib/notebooks

echo "Reverted notebooks in classlib/ (figures left as-is)"