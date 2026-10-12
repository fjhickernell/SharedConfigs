#!/bin/zsh
set -euo pipefail

prepare_only=0
case "${1:-}" in
  --prepare) prepare_only=1 ;;
  '') ;;
  *) echo "Usage: update-texstudio.sh [--prepare]" >&2; exit 2 ;;
esac
if (( $# > 1 )); then
  echo "Usage: update-texstudio.sh [--prepare]" >&2
  exit 2
fi

# The upstream tap replaces the disabled Homebrew/cask version.
# Its cask downloads official releases, checks SHA-256, and removes the
# app's quarantine attribute because upstream does not sign its macOS builds.
TAP="texstudio-org/texstudio"
CASK="${TAP}/texstudio"

brew tap "$TAP"
brew trust "$TAP"

receipt="$(brew --caskroom)/texstudio/.metadata/INSTALL_RECEIPT.json"
if [[ -f "$receipt" ]]; then
  installed_tap=$(/usr/bin/plutil -extract source.tap raw -o - "$receipt")
  if [[ "$installed_tap" != "$TAP" ]]; then
    if /usr/bin/pgrep -x texstudio >/dev/null; then
      echo "Close TeXstudio before migrating its Homebrew installation." >&2
      exit 1
    fi
    echo "Migrating TeXstudio from ${installed_tap} to ${TAP}; preferences are retained."
    # Download and verify before replacing the installed application.
    brew fetch --cask "$CASK"
    brew reinstall --cask --no-ask "$CASK"
  elif (( prepare_only == 0 )); then
    brew upgrade --cask "$CASK"
  fi
elif (( prepare_only == 0 )); then
  brew install --cask "$CASK"
fi
