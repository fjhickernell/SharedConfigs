#!/bin/zsh
# MacApps export script — v2025-11-11 (preserves header, skips decorated dividers, ✓→Yes)
set -euo pipefail

BASE="$HOME/Documents/SharedConfigs/MacApps"
MD_FILE="$BASE/MacAppsInventory.md"
CSV_FILE="$BASE/MacAppsInventory.csv"

if [ ! -f "$MD_FILE" ]; then
  echo "ERROR: Cannot find $MD_FILE"
  exit 1
fi

echo "Exporting MacAppsInventory.md to CSV..."

awk '
BEGIN {
  OFS = ","
  header_emitted = 0
}
# Only process table rows that start with |
$0 ~ /^\|/ {
  line = $0

  # Skip pure separator rows like |-----|--------|...|
  if (line ~ /^\|[- ]+\|/) next

  # Strip leading and trailing pipes
  sub(/^[[:space:]]*\|/, "", line)
  sub(/\|[[:space:]]*$/, "", line)

  # Split on pipe
  n = split(line, cells, /\|/)

  # Trim cells
  for (i = 1; i <= n; i++) {
    gsub(/^[[:space:]]+/, "", cells[i])
    gsub(/[[:space:]]+$/, "", cells[i])
  }

  # Detect the TRUE header row (plain names, no decoration)
  if (!header_emitted &&
      n >= 8 &&
      cells[1] == "App" &&
      cells[2] == "Source" &&
      cells[3] == "M2" &&
      cells[4] == "M3" &&
      cells[5] == "Mini" &&
      cells[6] == "Intel" &&
      cells[7] == "Usage" &&
      cells[8] == "Notes") {

    out = "\"" cells[1] "\""
    for (i = 2; i <= n; i++) {
      gsub(/"/, "\"\"", cells[i])
      out = out OFS "\"" cells[i] "\""
    }
    print out
    header_emitted = 1
    next
  }

  # Detect and skip decorated divider header rows like:
  # =====[[[App]]]======== | [[[Source]]] | [[[M2]]] | ...
  # or any row where the header names are present but NOT plain.
  if (n >= 8 &&
      cells[1] ~ /App/   && cells[1] != "App"   &&
      cells[2] ~ /Source/&& cells[2] != "Source"&&
      cells[3] ~ /M2/    && cells[3] != "M2"    &&
      cells[4] ~ /M3/    && cells[4] != "M3"    &&
      cells[5] ~ /Mini/  && cells[5] != "Mini"  &&
      cells[6] ~ /Intel/ && cells[6] != "Intel" &&
      cells[7] ~ /Usage/ && cells[7] != "Usage" &&
      cells[8] ~ /Notes/ && cells[8] != "Notes") {
    next
  }

  # Normal data row: escape and emit
  for (i = 1; i <= n; i++) {
    # Replace lone checkmark with ASCII for Excel
    if (cells[i] == "✓") {
      cells[i] = "Yes"
    }
    gsub(/"/, "\"\"", cells[i])   # escape internal quotes
    cells[i] = "\"" cells[i] "\"" # wrap in double quotes
  }

  out = cells[1]
  for (i = 2; i <= n; i++) {
    out = out OFS cells[i]
  }
  print out
}
' "$MD_FILE" > "$CSV_FILE"

echo "✅ Export complete: $CSV_FILE"

# Try to open in Excel if available
if command -v open >/dev/null 2>&1; then
  open -a "Microsoft Excel" "$CSV_FILE" 2>/dev/null || \
  echo "You can open $CSV_FILE manually in Excel."
else
  echo "Open $CSV_FILE manually in Excel or Numbers."
fi
