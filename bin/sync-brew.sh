#!/bin/zsh

set -euo pipefail

echo "===== $(date '+%Y-%m-%d %H:%M:%S %Z') syncbrew manual run started. ====="

cd "$HOME/Documents/SharedConfigs"

echo "Updating Homebrew..."
brew update

echo "Upgrading installed formulae and casks..."
brew upgrade

echo "Ensuring Brewfile state via brew bundle..."
bundle_failed=0

if [[ -f Brewfile ]]; then
  brew bundle --file="$HOME/Documents/SharedConfigs/Brewfile" || bundle_failed=1
else
  brew bundle || bundle_failed=1
fi

if [[ "$bundle_failed" -eq 1 ]]; then
  echo
  echo "WARNING: brew bundle reported one or more issues."
  echo "This is often non-fatal (e.g., unsupported casks on Intel Macs)."
  echo "Review the messages above for details."
  echo
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
