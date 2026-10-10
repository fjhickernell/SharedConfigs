#!/usr/bin/env sh
# setup_matlab_toolboxes.sh — install/update Chebfun & GAIL and clean macOS cruft
# Works with macOS bash 3.2, zsh, or /bin/sh.

set -eu

# Use the canonical standalone repository location.
TOOLBOX_DIR="${HOME}/SoftwareRepositories"
mkdir -p "$TOOLBOX_DIR"

# List of "name|url[@branch]" entries (branch optional)
REPOS="
chebfun|https://github.com/chebfun/chebfun.git@master
GAIL_Dev|https://github.com/GailGithub/GAIL_Dev.git@develop
"

echo "Using toolbox directory: $TOOLBOX_DIR"
echo

# Clean common macOS invisibles in a path (recursive)
clean_invisibles() {
  # Do NOT nuke VCS metadata
  find "$1" \
    -name '.DS_Store' -delete -o \
    -name '._*' -delete -o \
    -name 'Icon'"$(printf '\r')" -delete >/dev/null 2>&1 || true
}

# Update or clone a single repo with optional branch
handle_repo() {
  name="$1"
  url="$2"
  branch="$3"
  dest="${TOOLBOX_DIR}/${name}"

  echo "==> $name ($url${branch:+ @ $branch})"

  if [ -d "$dest/.git" ]; then
    git -C "$dest" fetch --prune
    if [ -n "$branch" ]; then
      git -C "$dest" checkout "$branch"
    fi
    git -C "$dest" pull --ff-only
  elif [ -d "$dest" ]; then
    echo "    Found existing non-git directory at $dest — leaving contents in place."
  else
    if [ -n "$branch" ]; then
      git clone --depth=1 --branch "$branch" "$url" "$dest"
    else
      git clone --depth=1 "$url" "$dest"
    fi
  fi

  clean_invisibles "$dest"
  echo
}

# Parse the REPOS list
# Each line: name|url[@branch]
echo "$REPOS" | while IFS= read -r line; do
  [ -z "$line" ] && continue
  case "$line" in \#*) continue ;; esac

  name="${line%%|*}"
  rest="${line#*|}"

  # Split optional @branch
  if printf %s "$rest" | grep -q "@"; then
    url="${rest%@*}"
    branch="${rest##*@}"
  else
    url="$rest"
    branch=""
  fi

  handle_repo "$name" "$url" "$branch"
done

cat <<'EOF'

Done.
• Toolboxes installed/updated under ~/SoftwareRepositories/chebfun and GAIL_Dev.
• Install the shared MATLAB startup link once on each Mac:
  ~/Documents/SharedConfigs/bin/sharedconfigs-audit --repair --group matlab --links-only
  This preserves the existing startup file in a timestamped backup.
• Later SharedConfigs updates automatically update the linked startup file.

Tip: re-run this script any time after upgrading MATLAB.
EOF
