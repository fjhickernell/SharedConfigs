#!/bin/zsh
set -euo pipefail

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

LOG_DIR="$HOME/Library/Logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/update-texlive.log"

{
  banner "TeX Live update started"

  export PATH="/Library/TeX/texbin:$PATH"

  if ! command -v tlmgr >/dev/null 2>&1; then
    error "tlmgr not found in PATH. Is MacTeX/TeX Live installed?"
    exit 1
  fi

  section "Running tlmgr update"
  tlmgr update --self --all --reinstall-forcibly-removed

  banner "TeX Live update completed successfully"
} | tee -a "$LOG_FILE"
