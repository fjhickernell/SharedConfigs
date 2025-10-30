#!/bin/zsh
# ------------------------------------------------------------------------------
# link_sharedconfigs_minimal.sh — links SharedConfigs items to standard macOS locations
#
# Usage (on each Mac after iCloud downloads SharedConfigs):
#
#   export PATH="$HOME/Documents/bin:$PATH"
#   source ~/.zshrc
#   link_sharedconfigs_minimal.sh
#
# Verification runs automatically at the end, but you can also run manually:
#
#   ls -l ~/Library/texmf
#   ls -l ~/.config/karabiner
#   ls -l ~/Library/Application\ Support/LaTeXiT
#   ls -l ~/Library/Application\ Support/BibDesk
#
# Expected result:
#   Each line shows an arrow (→) pointing to
#   /Users/fredjhickernell/Documents/SharedConfigs/<subfolder>
# ------------------------------------------------------------------------------

set -euo pipefail
ICLOUD_SC="$HOME/Documents/SharedConfigs"

backup_if_needed() {
  local target="$1"
  if [ -L "$target" ]; then
    echo "↺ Removing existing symlink: $target"
    rm -f "$target"
  elif [ -e "$target" ]; then
    local ts; ts=$(date +%Y%m%d-%H%M%S)
    echo "⇢ Backing up existing path: $target → ${target}.backup-${ts}"
    mv "$target" "${target}.backup-${ts}"
  fi
}

link_to() {
  local src="$1"
  local dst="$2"
  if [ ! -d "$src" ]; then
    echo "⚠️  Skipping: source not found → $src"
    return 0
  fi
  mkdir -p "$(dirname "$dst")"
  backup_if_needed "$dst"
  ln -sfn "$src" "$dst"
  echo "✓ Linked: $dst → $src"
}

echo "=== Linking SharedConfigs from iCloud ==="
echo "Source: $ICLOUD_SC"
echo

link_to "$ICLOUD_SC/texmf" "$HOME/Library/texmf"

if [ -d "$ICLOUD_SC/Karabiner" ]; then
  mkdir -p "$HOME/.config"
  link_to "$ICLOUD_SC/Karabiner" "$HOME/.config/karabiner"
  link_to "$ICLOUD_SC/Karabiner" "$HOME/Library/Application Support/Karabiner"
else
  echo "⚠️  Skipping Karabiner: $ICLOUD_SC/Karabiner not found"
fi

if [ -d "$ICLOUD_SC/LaTeXiT-Data" ]; then
  link_to "$ICLOUD_SC/LaTeXiT-Data" "$HOME/Library/Application Support/LaTeXiT"
else
  echo "⚠️  Skipping LaTeXiT: $ICLOUD_SC/LaTeXiT-Data not found"
fi

link_to "$ICLOUD_SC/BibDesk" "$HOME/Library/Application Support/BibDesk"

echo
echo "All requested links processed."
echo
echo "=== Verification ==="
ls -l ~/Library/texmf 2>/dev/null || true
ls -l ~/.config/karabiner 2>/dev/null || true
ls -l ~/Library/Application\ Support/LaTeXiT 2>/dev/null || true
ls -l ~/Library/Application\ Support/BibDesk 2>/dev/null || true
echo
echo "Expected: each line shows an arrow (→) pointing into Documents/SharedConfigs."
echo "Once verified, this Mac is fully linked and syncing configs via iCloud."
echo "Done."