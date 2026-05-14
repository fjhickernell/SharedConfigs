#!/bin/zsh
set -euo pipefail

cd "$HOME/Documents/SharedConfigs"

git add -A

if ! git diff --cached --quiet --exit-code; then
  git commit -m "SharedConfigs snapshot on $(hostname -s) at $(date '+%Y-%m-%d %H:%M:%S')"
fi

git pull --rebase

git push

echo "SharedConfigs synchronized."