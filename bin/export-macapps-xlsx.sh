#!/bin/zsh
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
BEGIN { OFS="," }
# Only process table rows that start with | and are not the separator line
$0 ~ /^\|/ {
  # Skip separator rows like |-----|--------|...|
  if ($0 ~ /^\|[- ]+\|/) next

  line = $0
  # Strip leading and trailing pipes
  sub(/^[[:space:]]*\|/, "", line)
  sub(/\|[[:space:]]*$/, "", line)

  # Split on pipe
  n = split(line, fields, /\|/)

  # Trim and quote each field
  for (i = 1; i <= n; i++) {
    gsub(/^[[:space:]]+/, "", fields[i])
    gsub(/[[:space:]]+$/, "", fields[i])

    # Replace lone checkmark with ASCII "Yes" for CSV to avoid encoding issues
    if (fields[i] == "✓") {
      fields[i] = "Yes"
    }

    gsub(/"/, "\"\"", fields[i])         # escape internal quotes
    fields[i] = "\"" fields[i] "\""      # wrap in double quotes
  }

  # Join with commas
  out = fields[1]
  for (i = 2; i <= n; i++) {
    out = out OFS fields[i]
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
