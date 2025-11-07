#!/bin/zsh
set -euo pipefail

BASE="$HOME/Documents/SharedConfigs/MacApps"
INVENTORY="$BASE/MacAppsInventory.md"
TMP="$BASE/tmp_apps_list.txt"

echo "Updating MacAppsInventory from latest scans..."
> "$TMP"

# Gather all known .applications.txt files
for f in "$BASE"/*.applications.txt; do
  [ -f "$f" ] || continue
  MAC="$(basename "$f" .applications.txt)"
  MAC_SHORT="$(echo "$MAC" | sed 's/Freds-//' | sed 's/-Mac.*//')"
  awk -v mac="$MAC_SHORT" '{print $0 "," mac}' "$f" >> "$TMP"
done

# Combine and sort
sort -u "$TMP" -o "$TMP"

# Regenerate Markdown table header
OUT="$BASE/MacAppsInventory.md"
cat > "$OUT" << 'HEADER'
# Mac Applications Inventory

Legend for Macs:
- M2 = M2 MacBook Pro (home)
- M3 = M3 MacBook Pro (office)
- Mini = M4 Mac Mini (home)
- Intel = Intel MacBook Pro 2019 (home)

Usage categories:
- Active  = used frequently
- Rare    = used occasionally or for legacy tasks
- Ignore  = installed but essentially unused

| App | Source | M2 | M3 | Mini | Intel | Usage | Notes |
|-----|--------|----|----|------|-------|-------|-------|
HEADER

# Create rows
awk -F, '
{
  app=$1; mac=$2;
  row[app][mac]="✓";
}
END {
  PROCINFO["sorted_in"]="@ind_str_asc";
  for (a in row) {
    printf "| %s |  | %s | %s | %s | %s |  |  |\n", a, row[a]["2023-M2-MacBook-Pro"], row[a]["M3"], row[a]["Mac-mini"], row[a]["Intel-MacBook-Pro-2019"];
  }
}' "$TMP" >> "$OUT"

echo "✅ Inventory regenerated at $OUT"
