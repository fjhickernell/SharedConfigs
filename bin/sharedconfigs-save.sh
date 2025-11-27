#!/bin/zsh
set -euo pipefail

cd "$HOME/Documents/SharedConfigs"

git add -A

if ! git diff --cached --quiet --exit-code; then
  git commit -m "SharedConfigs snapshot on $(hostname -s) at $(date '+%Y-%m-%d %H:%M:%S')"
  git push
  echo "SharedConfigs saved and pushed."
else
  echo "No changes to commit."
fi