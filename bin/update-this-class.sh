#!/usr/bin/env zsh
set -euo pipefail

echo "Updating submodules in current repo..."

# --- Update classlib ---
if [ -d "classlib" ]; then
  git -C classlib fetch origin main
  git -C classlib checkout main
  git -C classlib pull --ff-only origin main
fi

# --- Update qmcpy (if present) ---
if [ -d "qmcpy" ]; then
  git -C qmcpy fetch origin develop
  git -C qmcpy checkout develop
  git -C qmcpy pull --ff-only origin develop
fi

# Commit pointer updates (if any)
git add classlib qmcpy 2>/dev/null || true
git commit -m "bump submodules" || echo "No submodule updates to commit"

git push

echo "Done."
