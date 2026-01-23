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

# ---- color + emphasis -------------------------------------------------
if [[ -t 1 ]]; then
  BOLD=$'\e[1m'
  RED=$'\e[31m'
  GREEN=$'\e[32m'
  YELLOW=$'\e[33m'
  RESET=$'\e[0m'
else
  BOLD=''
  RED=''
  GREEN=''
  YELLOW=''
  RESET=''
fi

SKIP_COUNT=0

say_skip() {
  SKIP_COUNT=$((SKIP_COUNT + 1))
  echo "${BOLD}${RED}$*${RESET}"
}

say_err() {
  echo "${BOLD}${RED}$*${RESET}" >&2
}

say_warn() {
  echo "${BOLD}${YELLOW}$*${RESET}"
}

say_ok() {
  echo "${GREEN}$*${RESET}"
}

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
    say_err "ERROR: $name is not a git repo: $repo"
    return 2
  fi

  if ! is_clean_repo "$repo"; then
    say_skip "SKIP: $name has uncommitted changes: $repo"
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

final_verdict() {
  if [[ "$SKIP_COUNT" -gt 0 ]]; then
    say_skip "===== INCOMPLETE RUN: ${SKIP_COUNT} SKIP condition(s) encountered (see red SKIP lines above) ====="
  else
    say_ok "===== CLEAN: no SKIP conditions encountered ====="
  fi
}

rc=0
sync_repo "$HCL" "HickernellClassLib" "main" || rc=$?
sync_repo "$QMC" "QMCSoftware" "develop" || rc=$?

final_verdict
exit "$rc"
