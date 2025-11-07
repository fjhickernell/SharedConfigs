#!/bin/zsh
set -euo pipefail

BASE="$HOME/Documents/SharedConfigs/MacApps"
INVENTORY="$BASE/MacAppsInventory.md"
TMP_APPS="$BASE/apps_with_macs.tmp"
APPS_LIST="$BASE/apps_names.tmp"

: > "$TMP_APPS"

for f in "$BASE"/*.applications.txt; do
  if [ ! -f "$f" ]; then
    continue
  fi
  fname="$(basename "$f")"
  mac="UNKNOWN"
  case "$fname" in
    *M2-MacBook-Pro*)
      mac="M2"
      ;;
    *M3-MacBook-Pro*)
      mac="M3"
      ;;
    *Mac-mini*)
      mac="Mini"
      ;;
    *2019-August-MacBook-Pro*)
      mac="Intel"
      ;;
  esac
  awk -v mac="$mac" '{ line=$0; sub(/\.app$/,"",line); print line "," mac }' "$f" >> "$TMP_APPS"
done

cut -d, -f1 "$TMP_APPS" | sort -u > "$APPS_LIST"

OUT="$INVENTORY"

if [ -f "$INVENTORY" ]; then
  awk '
  function trim(s) { gsub(/^ +/,"",s); gsub(/ +$/,"",s); return s }
  FILENAME==ARGV[1] {
    if ($0 !~ /^\|/) next
    split($0, fields, "|")
    app=trim(fields[2])
    if (app=="App" || app=="") next
    usage=trim(fields[8])
    notes=trim(fields[9])
    u[app]=usage
    n[app]=notes
    next
  }
  FILENAME==ARGV[2] {
    app=$1
    apps[++k]=app
    next
  }
  FILENAME==ARGV[3] {
    split($0, parts, ",")
    app=parts[1]
    mac=parts[2]
    row[app,mac]="✓"
    next
  }
  END {
    print "# Mac Applications Inventory"
    print ""
    print "Legend for Macs:"
    print "- M2 = M2 MacBook Pro (home)"
    print "- M3 = M3 MacBook Pro (office)"
    print "- Mini = M4 Mac Mini (home)"
    print "- Intel = Intel MacBook Pro 2019 (home)"
    print ""
    print "Usage categories:"
    print "- Active  = used frequently"
    print "- Rare    = used occasionally or for legacy tasks"
    print "- Ignore  = installed but essentially unused"
    print ""
    print "| App | Source | M2 | M3 | Mini | Intel | Usage | Notes |"
    print "|-----|--------|----|----|------|-------|-------|-------|"
    for (i=1; i<=k; i++) {
      app=apps[i]
      m2=row[app,"M2"]
      m3=row[app,"M3"]
      mini=row[app,"Mini"]
      intel=row[app,"Intel"]
      usage=u[app]
      notes=n[app]
      printf "| %s |  | %s | %s | %s | %s | %s | %s |\n", app, m2, m3, mini, intel, usage, notes
    }
  }
  ' "$INVENTORY" "$APPS_LIST" "$TMP_APPS" > "$OUT"
else
  awk '
  FILENAME==ARGV[1] {
    app=$1
    apps[++k]=app
    next
  }
  FILENAME==ARGV[2] {
    split($0, parts, ",")
    app=parts[1]
    mac=parts[2]
    row[app,mac]="✓"
    next
  }
  END {
    print "# Mac Applications Inventory"
    print ""
    print "Legend for Macs:"
    print "- M2 = M2 MacBook Pro (home)"
    print "- M3 = M3 MacBook Pro (office)"
    print "- Mini = M4 Mac Mini (home)"
    print "- Intel = Intel MacBook Pro 2019 (home)"
    print ""
    print "Usage categories:"
    print "- Active  = used frequently"
    print "- Rare    = used occasionally or for legacy tasks"
    print "- Ignore  = installed but essentially unused"
    print ""
    print "| App | Source | M2 | M3 | Mini | Intel | Usage | Notes |"
    print "|-----|--------|----|----|------|-------|-------|-------|"
    for (i=1; i<=k; i++) {
      app=apps[i]
      m2=row[app,"M2"]
      m3=row[app,"M3"]
      mini=row[app,"Mini"]
      intel=row[app,"Intel"]
      printf "| %s |  | %s | %s | %s | %s |  |  |\n", app, m2, m3, mini, intel
    }
  }
  ' "$APPS_LIST" "$TMP_APPS" > "$OUT"
fi

echo "MacAppsInventory.md updated"
