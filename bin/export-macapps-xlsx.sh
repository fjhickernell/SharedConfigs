#!/bin/zsh
set -euo pipefail

BASE="$HOME/Documents/SharedConfigs/MacApps"
MD_FILE="$BASE/MacAppsInventory.md"
XLSX_FILE="$BASE/MacAppsInventory.xlsx"

if ! command -v pandoc >/dev/null 2>&1; then
  echo "Installing pandoc..."
  brew install pandoc
fi

echo "Exporting to Excel..."
pandoc "$MD_FILE" -o "$XLSX_FILE"
open -a "Microsoft Excel" "$XLSX_FILE"
echo "✅ Excel version opened: $XLSX_FILE"
