#!/usr/bin/env bash
# Usage reminder:
#   ~/Documents/bin/setup-nbstripout.sh "/path/to/repo"

set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: $0 /path/to/repo"
  exit 1
fi

REPO="$1"
echo "=== Running nbstripout setup on repo: $REPO ==="
cd "$REPO"

# Ensure we're inside a Git repo
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Error: '$REPO' is not a Git repository."
  exit 1
fi

# Ensure nbstripout is available in the current Python/env
if ! command -v nbstripout >/dev/null 2>&1; then
  echo "nbstripout not found; installing with pip in $(python -V 2>&1 | awk '{print $1,$2}') ..."
  python -m pip install --upgrade pip
  python -m pip install nbstripout
  hash -r
fi

echo "=== Repo setup: cleaning any local overrides ==="
git config --unset-all filter.nbstripout.clean    || true
git config --unset-all filter.nbstripout.smudge   || true
git config --unset-all filter.nbstripout.required || true
git config --unset-all diff.ipynb.textconv        || true

echo "=== Repo setup: installing nbstripout hook and attributes ==="
# Write standard repo-local config + ensure attributes exist
nbstripout --install --attributes .gitattributes

# Ensure .gitattributes has both filter and diff entries (idempotent)
test -f .gitattributes || touch .gitattributes
grep -q 'filter=nbstripout' .gitattributes || printf '%s\n' '*.ipynb filter=nbstripout' >> .gitattributes
grep -q 'diff=ipynb'      .gitattributes || printf '%s\n' '*.ipynb diff=ipynb'      >> .gitattributes
git add .gitattributes
git commit -m "Ensure nbstripout filter and ipynb diff" || true

echo "=== Verify status ==="
nbstripout --status
git check-attr -a -- ':(glob)**/*.ipynb'

echo "=== One-time: normalize existing notebooks (strip outputs) ==="
git ls-files '*.ipynb' -z | xargs -0 -n1 nbstripout || true
git commit -am "Normalize notebooks (strip outputs once)" || true

echo "=== Done for repo $REPO ==="