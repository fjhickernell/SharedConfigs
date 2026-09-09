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

warn_banner() {
  printf "\n${YELLOW_BOLD}===== [%s] %s =====${NC}\n" "$(timestamp)" "$1"
}

error() {
  printf "${RED_BOLD}Error:${NC} %s\n" "$1" >&2
}

banner "arrive started"
section "Pulling infrastructure repositories"
if ! "${0:A:h}/git-repo-sync.sh" --pull-only; then
  error "arrive stopped: infrastructure refresh failed; development and active repos were not synchronized."
  exit 1
fi
# Continue this invocation; wrapper updates take effect on the next run.

section "Syncing standalone development repos"
sync-dev.sh
rc_dev=$?

section "Syncing active repos"
sync-active.sh
rc_active=$?

section "Checking Codex projects against shared inventory"
python3 "${0:A:h}/project-sync-check.py"
rc_projects=$?

if [[ $rc_dev -ne 0 || $rc_active -ne 0 ]]; then
  error "arrive failed (sync-dev=$rc_dev, sync-active=$rc_active)"
  exit 1
fi

pr_check_failed=false
if command -v pr-status >/dev/null 2>&1; then
  section "Checking PRs that need attention"
  if ! pr-status; then
    pr_check_failed=true
    warn "PR attention check failed; its results are incomplete."
  fi
else
  pr_check_failed=true
  warn "pr-status is unavailable; PR attention was not checked."
fi

if [[ $rc_projects -eq 1 ]]; then
  warn_banner "arrive completed with warnings; Codex project setup needs attention (see findings above)"
elif [[ $rc_projects -ne 0 ]]; then
  error "arrive failed: Codex project check failed (exit $rc_projects)"
  exit "$rc_projects"
elif [[ "$pr_check_failed" == true ]]; then
  warn_banner "arrive sync completed, but the PR attention check was incomplete"
else
  banner "arrive completed successfully"
fi
