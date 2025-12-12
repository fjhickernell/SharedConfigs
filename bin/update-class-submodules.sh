#!/usr/bin/env zsh
set -euo pipefail

REPOS=(
  "$HOME/SoftwareRepositories/MATH565Fall2025"
  "$HOME/SoftwareRepositories/MATH476Spring2026"
)

TIMESTAMP="$(date +"%Y-%m-%d %H:%M:%S")"
echo "[$TIMESTAMP] Starting classlib submodule updates..."

for repo in "${REPOS[@]}"; do
  echo "------------------------------------------------------------"
  echo "Updating repo: $repo"
  if [ ! -d "$repo" ]; then
    echo "Skipping: directory not found: $repo" >&2
    continue
  fi

  cd "$repo"

  if [ ! -x "./classlib/bin/update-submodules.sh" ]; then
    echo "Skipping: ./classlib/bin/update-submodules.sh not found or not executable in $repo" >&2
    continue
  fi

  echo "Running ./classlib/bin/update-submodules.sh $* ..."
  ./classlib/bin/update-submodules.sh "$@"
  echo "Finished repo: $repo"
done

TIMESTAMP="$(date +"%Y-%m-%d %H:%M:%S")"
echo "[$TIMESTAMP] All done."