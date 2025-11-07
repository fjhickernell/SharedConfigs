#!/bin/zsh
set -euo pipefail
BASE="$HOME/Documents/SharedConfigs/MacApps"
mkdir -p "$BASE"
MAC_ID="$(hostname -s)"
APP_FILE="$BASE/${MAC_ID}.applications.txt"
BREW_FILE="$BASE/${MAC_ID}.brew-casks.txt"
MAS_FILE="$BASE/${MAC_ID}.appstore.txt"
find /Applications ~/Applications -maxdepth 1 -iname "*.app" -prune -print 2>/dev/null | sed 's#.*/##' | sort -f | uniq > "$APP_FILE"
if command -v brew >/dev/null 2>&1; then
  brew list --cask | sort -f > "$BREW_FILE"
fi
if command -v mas >/dev/null 2>&1; then
  mas list > "$MAS_FILE"
fi
