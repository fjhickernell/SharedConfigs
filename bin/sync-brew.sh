#!/bin/zsh

set -euo pipefail

echo "===== $(date '+%Y-%m-%d %H:%M:%S %Z') syncbrew manual run started. ====="

cd "$HOME/Documents/SharedConfigs"

if [[ -f Brewfile ]]; then
  brew bundle --file="$HOME/Documents/SharedConfigs/Brewfile"
else
  brew bundle
fi

echo "Running mas upgrade in manual (interactive) mode."
mas upgrade

echo "===== $(date '+%Y-%m-%d %H:%M:%S %Z') syncbrew manual run finished. ====="
