#!/usr/bin/env zsh
set -euo pipefail

echo "Updating submodules in current repo..."

# --- Update classlib ---
if [ -d "classlib" ]; then
  git -C classlib fetch origin main
  git -C classlib checkout main
  git -C classlib pull --ff-only origin main
fi

# --- Update qmcsoftware (if present) ---
if [ -d "qmcsoftware" ]; then
  git -C qmcsoftware fetch origin develop
  git -C qmcsoftware checkout develop
  git -C qmcsoftware pull --ff-only origin develop
fi

# Commit pointer updates (if any)
git add classlib qmcsoftware 2>/dev/null || true
git commit -m "bump submodules" || echo "No submodule updates to commit"

git push

echo "Done."

