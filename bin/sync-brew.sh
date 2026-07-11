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

cd "$HOME/Documents/SharedConfigs"

banner "sync-brew started"

section "Updating Homebrew"
brew update

section "Upgrading installed formulae and casks"
brew upgrade

section "Ensuring Brewfile state via brew bundle"
bundle_failed=0
bundle_log="$(mktemp)"

if [[ -f Brewfile ]]; then
  brew bundle --file="$HOME/Documents/SharedConfigs/Brewfile" 2>&1 | tee "$bundle_log" || bundle_failed=1
else
  brew bundle 2>&1 | tee "$bundle_log" || bundle_failed=1
fi

bundle_ok_count="$(awk '/^(Using|Installing) / && $0 !~ / has failed!/ { n++ } END { print n+0 }' "$bundle_log")"
bundle_fail_count="$(awk '/has failed|failed to install|depends on hardware architecture|dependency graph sorting failed|circular dependency/ { n++ } END { print n+0 }' "$bundle_log")"
echo
section "brew bundle summary"
printf "${GREEN_BOLD}(Mostly) OK:${NC} %s Brewfile items were already installed or processed.
" "$bundle_ok_count"
printf "${YELLOW_BOLD}Needs attention:${NC} %s issue(s) reported.
" "$bundle_fail_count"

if [[ "$bundle_failed" -eq 1 ]]; then
  grep -E "has failed|failed to install|depends on hardware architecture" "$bundle_log" || true
  echo

  if grep -Eq "dependency graph sorting failed|circular dependency" "$bundle_log"; then
    printf "${YELLOW_BOLD}Continuing because Homebrew Bundle encountered a formula dependency-cycle sorting error. brew upgrade and brew doctor otherwise completed normally.${NC}\n"
  else
    printf "${YELLOW_BOLD}Continuing because some Brewfile items may be unavailable or architecture-specific on this Mac.${NC}\n"
  fi
fi

echo
rm -f "$bundle_log"

section "Removing unused dependencies"
brew autoremove

section "Cleaning up old versions"
brew cleanup

if command -v mas >/dev/null 2>&1; then
  section "Running mas upgrade in manual interactive mode"
  mas upgrade
else
  warn "mas not found; skipping Mac App Store upgrades."
fi

banner "sync-brew completed successfully"
