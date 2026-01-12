#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat << 'USAGE'
Usage: sync-dev.sh

Pull-only sync for standalone dev repos:
  - ~/SoftwareRepositories/HickernellClassLib (main)
  - ~/SoftwareRepositories/QMCSoftware       (develop)

Behavior:
  - Clean repo: fetch + fast-forward pull to the target branch.
  - Dirty repo: SKIP (do not abort).
  - Hard errors only for missing/non-git repos.
USAGE
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

HCL="$HOME/SoftwareRepositories/HickernellClassLib"
QMC="$HOME/SoftwareRepositories/QMCSoftware"

is_clean_repo() {
  local repo="$1"
  [[ -z "$(git -C "$repo" status --porcelain)" ]]
}

sync_repo() {
  local repo="$1"
  local name="$2"
  local branch="$3"

  echo "===== $name ($branch) ====="

  if [[ ! -d "$repo/.git" ]]; then
    echo "ERROR: $name is not a git repo: $repo" >&2
    return 2
  fi

  if ! is_clean_repo "$repo"; then
    echo "SKIP: $name has uncommitted changes: $repo"
    git -C "$repo" status -sb
    echo
    return 0
  fi

  git -C "$repo" fetch --prune origin
  git -C "$repo" checkout "$branch" >/dev/null 2>&1 || git -C "$repo" switch "$branch"
  git -C "$repo" pull --ff-only origin "$branch"
  git -C "$repo" status -sb
  git -C "$repo" rev-parse HEAD
  echo
}

rc=0
sync_repo "$HCL" "HickernellClassLib" "main" || rc=$?
sync_repo "$QMC" "QMCSoftware" "develop" || rc=$?
exit "$rc"
