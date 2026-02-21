#!/usr/bin/env bash
set -euo pipefail

LIST="${1:-$HOME/Documents/SharedConfigs/npm-globals.txt}"

if [ ! -f "$LIST" ]; then
  echo "Missing list: $LIST" >&2
  exit 1
fi

while IFS= read -r pkg; do
  [ -z "$pkg" ] && continue
  case "$pkg" in \#*) continue ;; esac
  npm install -g "$pkg"
done < "$LIST"
