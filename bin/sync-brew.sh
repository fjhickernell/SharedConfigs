#!/bin/zsh

set -euo pipefail

echo "===== $(date '+%Y-%m-%d %H:%M:%S %Z') syncbrew manual run started. ====="

cd "$HOME/Documents/SharedConfigs"

echo "Updating Homebrew..."
brew update

echo "Upgrading installed formulae and casks..."
brew upgrade

echo "Ensuring Brewfile state via brew bundle..."
if [[ -f Brewfile ]]; then
  brew bundle --file="$HOME/Documents/SharedConfigs/Brewfile"
else
  brew bundle
fi

echo "Removing unused dependencies..."
brew autoremove

echo "Cleaning up old versions..."
brew cleanup

if command -v mas >/dev/null 2>&1; then
  echo "Running mas upgrade in manual (interactive) mode."
  mas upgrade
else
  echo "mas not found; skipping Mac App Store upgrades."
fi

echo "===== $(date '+%Y-%m-%d %H:%M:%S %Z') syncbrew manual run finished. ====="
