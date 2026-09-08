#!/usr/bin/env zsh
set -uo pipefail

GREEN_BOLD=$'\033[1;32m'
MAGENTA_BOLD=$'\033[1;35m'
YELLOW_BOLD=$'\033[1;33m'
RED_BOLD=$'\033[1;31m'
NC=$'\033[0m'

timestamp() {
  /bin/date '+%Y-%m-%d %H:%M:%S %Z'
}

banner() {
  printf "\n${GREEN_BOLD}===== [%s] %s =====${NC}\n" "$(timestamp)" "$1"
}

section() {
  printf "\n${MAGENTA_BOLD}--- %s ---${NC}\n" "$1"
}

warn() {
  printf "${YELLOW_BOLD}Warning:${NC} %s\n" "$1"
}

error() {
  printf "${RED_BOLD}Error:${NC} %s\n" "$1" >&2
}

banner "depart started"

section "Recording Codex project additions for other Macs"
python3 "${0:A:h}/project-sync-check.py" --capture
rc_projects=$?

section "Syncing standalone development repos"
sync-dev.sh
rc_dev=$?

section "Syncing and pushing active repos"
sync-active.sh --push
rc_class=$?

if [[ $rc_dev -ne 0 || $rc_class -ne 0 ]]; then
  error "depart failed (sync-dev=$rc_dev, sync-active=$rc_class)"
  exit 1
fi

if [[ $rc_projects -eq 1 ]]; then
  warn "depart completed with warnings; review the Codex project findings above."
elif [[ $rc_projects -ne 0 ]]; then
  error "depart failed: Codex project check failed (exit $rc_projects)"
  exit "$rc_projects"
else
  banner "depart completed successfully"
fi
