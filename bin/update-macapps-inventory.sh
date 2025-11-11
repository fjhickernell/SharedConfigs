#!/bin/zsh
# MacApps inventory updater — v2025-11-10 (family-propagation, ASCII spacer rows)
set -euo pipefail

BASE="$HOME/Documents/SharedConfigs/MacApps"
INVENTORY="$BASE/MacAppsInventory.md"
OUT_TMP="$INVENTORY.tmp"
TMP_APPS="$BASE/apps_with_macs.tmp"
APPS_LIST="$BASE/apps_names.tmp"
APPSTORE_TMP="$BASE/appstore_names.tmp"
HEADER_REPEAT=20   # insert spacer row every 20 rows

mkdir -p "$BASE"
: > "$TMP_APPS"
: > "$APPSTORE_TMP"

# Collect app -> Mac mappings
for f in "$BASE"/*.applications.txt; do
  [ -f "$f" ] || continue
  fname="$(basename "$f")"
  mac="UNKNOWN"
  case "$fname" in
    *M2-MacBook-Pro*)          mac="M2" ;;
    *M3-MacBook-Pro*)          mac="M3" ;;
    *Mac-mini*)                mac="Mini" ;;
    *2019-August-MacBook-Pro*) mac="Intel" ;;
  esac
  awk -v mac="$mac" '{
    line = $0
    sub(/\.app$/, "", line)
    print line "," mac
  }' "$f" >> "$TMP_APPS"
done

# Collect App Store app names
for f in "$BASE"/*.appstore.txt; do
  [ -f "$f" ] || continue
  awk 'NF >= 3 {
    name = $2
    for (i = 3; i < NF; i++) name = name " " $i
    print name
  }' "$f" >> "$APPSTORE_TMP"
done

cut -d, -f1 "$TMP_APPS" | sort -u > "$APPS_LIST"

if [ -f "$INVENTORY" ]; then
  awk -v header_repeat="$HEADER_REPEAT" '
  function trim(s){ gsub(/^ +/,"",s); gsub(/ +$/,"",s); return s }
  function family_key(app, a){
    a = trim(app)
    sub(/\.app$/,"",a)
    if (a ~ /^MATLAB_R[0-9]{4}[ab]?$/)      return "MATLAB"
    if (a ~ /^texstudio-[0-9.]+-osx-m1$/)   return "TeXstudio"
    if (a ~ /^Bartender [0-9]$/)            return "Bartender"
    return a
  }
  function print_header() {
    print "| App | Source | M2 | M3 | Mini | Intel | Usage | Notes |"
    print "|-----|--------|----|----|------|-------|-------|-------|"
  }

  # Existing inventory: preserve per-family Source/Usage/Notes
  FILENAME==ARGV[1] {
    if ($0 !~ /^[[:space:]]*\|/) next
    split($0, fields, "|")
    app = trim(fields[2])
    if (app=="" || app=="App") next
    fam = family_key(app)
    srcval  = trim(fields[3])
    useval  = trim(fields[8])
    noteval = trim(fields[9])
    if (srcval  != "") src[fam] = srcval
    if (useval  != "") u[fam]   = useval
    if (noteval != "") n[fam]   = noteval
    next
  }

  # APPS_LIST: sorted app names
  FILENAME==ARGV[2] {
    app = trim($0)
    if(app=="") next
    apps[++k] = app
    next
  }

  # TMP_APPS: app,mac mapping
  FILENAME==ARGV[3] {
    split($0,parts,",")
    app = trim(parts[1])
    mac = trim(parts[2])
    row[app,mac] = "✓"
    next
  }

  # APPSTORE_TMP: App Store app names
  FILENAME==ARGV[4] {
    appname = trim($0)
    if(appname=="") next
    appstore[appname] = 1
    next
  }

  END {
    print "# Mac Applications Inventory\n"
    print "Legend for Macs:"
    print "- M2 = M2 MacBook Pro (home)"
    print "- M3 = M3 MacBook Pro (office)"
    print "- Mini = M4 Mac Mini (home)"
    print "- Intel = Intel MacBook Pro 2019 (home)\n"
    print "Usage categories:"
    print "- Active  = used frequently"
    print "- Rare    = used occasionally or for legacy tasks"
    print "- Ignore  = installed but essentially unused\n"

    print_header()
    count = 0

    for(i=1;i<=k;i++){
      app  = apps[i]
      fam  = family_key(app)
      m2   = row[app,"M2"]
      m3   = row[app,"M3"]
      mini = row[app,"Mini"]
      intel= row[app,"Intel"]

      source = src[fam]
      if(source=="" && appstore[app]) source="App Store"
      usage = u[fam]
      notes = n[fam]

      printf("| %s | %s | %s | %s | %s | %s | %s | %s |\n",
             app,source,m2,m3,mini,intel,usage,notes)

      count++
      if (count % header_repeat == 0 && i < k) {
        print "|------App------|-Source-|-M2-|-M3-|-Mini-|-Intel-|-Usage-|-Notes-|"
      }
    }
  }' "$INVENTORY" "$APPS_LIST" "$TMP_APPS" "$APPSTORE_TMP" > "$OUT_TMP"
else
  awk -v header_repeat="$HEADER_REPEAT" '
  function trim(s){ gsub(/^ +/,"",s); gsub(/ +$/,"",s); return s }
  function family_key(app, a){
    a = trim(app)
    sub(/\.app$/,"",a)
    if (a ~ /^MATLAB_R[0-9]{4}[ab]?$/)      return "MATLAB"
    if (a ~ /^texstudio-[0-9.]+-osx-m1$/)   return "TeXstudio"
    if (a ~ /^Bartender [0-9]$/)            return "Bartender"
    return a
  }
  function print_header() {
    print "| App | Source | M2 | M3 | Mini | Intel | Usage | Notes |"
    print "|-----|--------|----|----|------|-------|-------|-------|"
  }

  # APPS_LIST: sorted app names
  FILENAME==ARGV[1] {
    app = trim($0)
    if(app=="") next
    apps[++k] = app
    next
  }

  # TMP_APPS: app,mac mapping
  FILENAME==ARGV[2] {
    split($0,parts,",")
    app = trim(parts[1])
    mac = trim(parts[2])
    row[app,mac] = "✓"
    next
  }

  # APPSTORE_TMP: App Store app names
  FILENAME==ARGV[3] {
    appname = trim($0)
    if(appname=="") next
    appstore[appname] = 1
    next
  }

  END {
    print "# Mac Applications Inventory\n"
    print "Legend for Macs:"
    print "- M2 = M2 MacBook Pro (home)"
    print "- M3 = M3 MacBook Pro (office)"
    print "- Mini = M4 Mac Mini (home)"
    print "- Intel = Intel MacBook Pro 2019 (home)\n"
    print "Usage categories:"
    print "- Active  = used frequently"
    print "- Rare    = used occasionally or for legacy tasks"
    print "- Ignore  = installed but essentially unused\n"

    print_header()
    count = 0

    for(i=1;i<=k;i++){
      app  = apps[i]
      m2   = row[app,"M2"]
      m3   = row[app,"M3"]
      mini = row[app,"Mini"]
      intel= row[app,"Intel"]
      source = ""
      if(appstore[app]) source="App Store"

      printf("| %s | %s | %s | %s | %s | %s |  |  |\n",
             app,source,m2,m3,mini,intel)

      count++
      if (count % header_repeat == 0 && i < k) {
        print "|------App------|-Source-|-M2-|-M3-|-Mini-|-Intel-|-Usage-|-Notes-|"
      }
    }
  }' "$APPS_LIST" "$TMP_APPS" "$APPSTORE_TMP" > "$OUT_TMP"
fi

mv "$OUT_TMP" "$INVENTORY"
rm -f "$TMP_APPS" "$APPS_LIST" "$APPSTORE_TMP"
echo "MacAppsInventory.md updated at $INVENTORY (spacer every $HEADER_REPEAT rows)"
