#!/bin/zsh
set -euo pipefail
export HOMEBREW_NO_PAGER=1

# --- Configuration -----------------------------------------------------------
REPO_DIR="${REPO_DIR:-$HOME/Documents/SharedConfigs}"
BREWFILE="$REPO_DIR/Brewfile"
SUMMARY_TMP="$(mktemp)"
HOST="$(hostname -s)"

note()  { print -P "%F{blue}==>%f $*"; }
good()  { print -P "%F{green}✓%f  $*"; }
warn()  { print -P "%F{yellow}!%f  $*"; }
fail()  { print -P "%F{red}✗%f  $*"; exit 1; }
have()  { command -v "$1" >/dev/null 2>&1; }

# --- iCloud (light) ----------------------------------------------------------
# We had a heavy mdls-based check before; on large SharedConfigs trees it could exit 1.
# This version is fast and never hard-fails. You can skip it with SKIP_ICLOUD_CHECK=1.
icloud_light_check() {
  if [[ "${SKIP_ICLOUD_CHECK:-0}" == "1" ]]; then
    warn "Skipping iCloud check (SKIP_ICLOUD_CHECK=1)."
    return 0
  fi

  note "Light iCloud check for $REPO_DIR…"
  if [[ -d "$REPO_DIR" ]]; then
    good "iCloud folder found. Proceeding."
    return 0
  fi

  warn "iCloud folder not present yet, waiting briefly…"
  for i in {1..10}; do
    sleep 1
    [[ -d "$REPO_DIR" ]] && { good "iCloud folder appeared. Proceeding."; return 0; }
  done

  warn "iCloud folder still not present; continuing anyway."
  return 0
}

# --- Git utilities -----------------------------------------------------------
git_ready()      { [[ -d "$REPO_DIR/.git" ]] && have git; }
git_has_remote() { git -C "$REPO_DIR" remote | grep -q .; }

brew_summary_diff() {
  local before="$1" after="$2"
  print "Changes summary:"
  for kind in brew cask mas; do
    local add remove
    add=$(diff -U0 <(grep -E "^$kind " "$before" || true) <(grep -E "^$kind " "$after" || true) \
            | grep '^+' | grep -vE '^\+\+\+|^@@' | sed 's/^+//')
    remove=$(diff -U0 <(grep -E "^$kind " "$before" || true) <(grep -E "^$kind " "$after" || true) \
               | grep '^- ' | sed 's/^-//')
    [[ -n "$add$remove" ]] || continue
    print "  • ${kind}:"
    [[ -n "$add"    ]] && print -- "$add"    | sed 's/^/      + /'
    [[ -n "$remove" ]] && print -- "$remove" | sed 's/^/      - /'
  done
}

# --- Preconditions -----------------------------------------------------------
[[ -d "$REPO_DIR" ]] || fail "Repo directory not found: $REPO_DIR"
have brew || fail "Homebrew not found. Install from https://brew.sh"

icloud_light_check

# --- Pull from Git -----------------------------------------------------------
if git_ready; then
  note "Git repo detected in $REPO_DIR."
  if git_has_remote; then
    note "Pulling latest changes (git pull --rebase)…"
    git -C "$REPO_DIR" pull --rebase --autostash || warn "git pull had issues; continuing."
  else
    warn "No git remote configured; skipping pull."
  fi
else
  warn "Git repo not initialized; proceeding without Git features."
fi

# --- Capture previous Brewfile for diff -------------------------------------
PREV_BREWFILE="${BREWFILE}.prev.$$"
if [[ -f "$BREWFILE" ]]; then
  cp "$BREWFILE" "$PREV_BREWFILE"
else
  : > "$PREV_BREWFILE"
fi

# --- Dump current system to Brewfile ----------------------------------------
note "Updating Brewfile from current system (brew bundle dump)…"
brew bundle dump --force --describe --file="$BREWFILE"

# --- Show Git diff or file diff ---------------------------------------------
if git_ready; then
  note "Diff of Brewfile (Git):"
  git -C "$REPO_DIR" add -N "$BREWFILE" 2>/dev/null || true
  git -C "$REPO_DIR" diff -- "$BREWFILE" || true
else
  note "Diff of Brewfile:"
  diff -u "$PREV_BREWFILE" "$BREWFILE" || true
fi

# --- Concise summary --------------------------------------------------------
brew_summary_diff "$PREV_BREWFILE" "$BREWFILE" | tee "$SUMMARY_TMP" || true
print

# --- Commit & push if Git is ready ------------------------------------------
if git_ready; then
  if ! git -C "$REPO_DIR" diff --quiet -- "$BREWFILE"; then
    note "Committing Brewfile changes…"
    git -C "$REPO_DIR" add "$BREWFILE"
    git -C "$REPO_DIR" commit -m "Update Brewfile on ${HOST}" -m "$(cat "$SUMMARY_TMP")" || warn "Nothing to commit?"
    if git_has_remote; then
      note "Pushing to remote…"
      git -C "$REPO_DIR" push || warn "git push failed; push manually later."
    fi
  else
    good "No Brewfile changes to commit."
  fi
fi

# --- Apply Brewfile locally -------------------------------------------------
note "Applying Brewfile to this Mac (brew bundle)…"
brew bundle --file="$BREWFILE"

good "Homebrew packages are synced on ${HOST}."
good "Done."

# --- Cleanup ----------------------------------------------------------------
rm -f "$PREV_BREWFILE" "$SUMMARY_TMP"