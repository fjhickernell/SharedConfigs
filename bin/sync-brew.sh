#!/bin/zsh
export HOMEBREW_NO_ENV_FILTERING=1
export HOMEBREW_NO_PAGER=1
set -euo pipefail

# --- Configuration -----------------------------------------------------------
REPO_DIR="${REPO_DIR:-$HOME/Documents/SharedConfigs}"
BREWFILE="$REPO_DIR/Brewfile"
SUMMARY_TMP="$(mktemp)"
HOST="$(hostname -s)"

# --- Helpers ----------------------------------------------------------------
note()  { print -P "%F{blue}==>%f $*"; }
good()  { print -P "%F{green}✓%f  $*"; }
warn()  { print -P "%F{yellow}!%f  $*"; }
fail()  { print -P "%F{red}✗%f  $*"; exit 1; }
have()  { command -v "$1" >/dev/null 2>&1; }

icloud_light_check() {
  return 0  # placeholder; leave if you later add an iCloud availability check
}

# --- Git utilities -----------------------------------------------------------
git_ready() {
  [[ -d "$REPO_DIR/.git" ]] && have git
}

git_has_remote() {
  git -C "$REPO_DIR" remote | grep -q .
}

brew_summary_diff() {
  local before="$1" after="$2"
  print "Changes summary:"
  for kind in brew cask mas; do
    local add remove
    add=$(
      diff -U0 <(grep -E "^$kind " "$before" || true) \
                <(grep -E "^$kind " "$after"  || true) \
        | grep '^+' \
        | grep -vE '^\+\+\+|^@@' \
        | sed 's/^+//'
    )
    remove=$(
      diff -U0 <(grep -E "^$kind " "$before" || true) \
                <(grep -E "^$kind " "$after"  || true) \
        | grep '^- ' \
        | sed 's/^-//'
    )
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

# --- Pull from Git (can be skipped) -----------------------------------------
if [[ "${SKIP_GIT_PULL:-0}" != "1" ]]; then
  if git_ready; then
    note "Git repo detected in $REPO_DIR."
    if git_has_remote; then
      note "Pulling latest changes (git pull --rebase)…"
      git -C "$REPO_DIR" pull --rebase --autostash || warn "git pull had issues; continuing."
    else
      warn "No git remote configured; skipping pull."
    fi
  else
    warn "No git repo in $REPO_DIR; skipping git pull."
  fi
else
  warn "SKIP_GIT_PULL=1 — skipping git pull step."
fi

# --- Capture previous Brewfile for diff -------------------------------------
# Use a temp file outside Documents so launchd/TCC can't block it.
PREV_BREWFILE="$(mktemp)"

if [[ -f "$BREWFILE" ]]; then
  if ! cp "$BREWFILE" "$PREV_BREWFILE" 2>/dev/null; then
    warn "Could not copy Brewfile to temp for diff; diffs may be incomplete, continuing."
    : > "$PREV_BREWFILE"
  fi
else
  : > "$PREV_BREWFILE"
fi

# --- Conditionally dump ------------------------------------------------------
if [[ "${DO_BREW_DUMP:-0}" == "1" ]]; then
  note "DO_BREW_DUMP=1 → dumping current system to Brewfile…"
  cd "$REPO_DIR"
  # your earlier version used plain dump; keep that for compatibility
  brew bundle dump --force
else
  note "Not dumping Brewfile on this run (set DO_BREW_DUMP=1 to force)."
fi

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
    git -C "$REPO_DIR" commit -m "Update Brewfile on ${HOST}" -m "$(cat "$SUMMARY_TMP")" \
      || warn "Nothing to commit?"
    if git_has_remote; then
      note "Pushing to remote…"
      git -C "$REPO_DIR" push || warn "git push failed; push manually later."
    fi
  else
    good "No Brewfile changes to commit."
  fi
fi

# --- Apply Brewfile locally -------------------------------------------------
if [[ "${SKIP_APPLY:-0}" != "1" ]]; then
  note "Applying Brewfile to this Mac (brew bundle)…"
  brew bundle --file="$BREWFILE"
else
  warn "SKIP_APPLY=1 — not applying Brewfile on this run."
fi

good "Homebrew packages are synced on ${HOST}."
good "Done."

# --- Cleanup ----------------------------------------------------------------
rm -f "$PREV_BREWFILE" "$SUMMARY_TMP"