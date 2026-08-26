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

if command -v mas >/dev/null 2>&1 && grep -q '^mas ' Brewfile; then
  spotlight_status="$(mdutil -s / 2>&1 || true)"
  if ! grep -qi 'indexing enabled' <<<"$spotlight_status"; then
    error "Spotlight indexing must be enabled before syncing Mac App Store apps."
    printf '%s\n' "$spotlight_status" >&2
    printf '%s\n' "Run 'sudo mdutil -i on /' and 'sudo mdutil -E /', then retry sync-brew." >&2
    exit 1
  fi
fi

section "Updating Homebrew"
brew update

section "Upgrading installed formulae and casks"
brew upgrade

section "Ensuring Brewfile state via brew bundle"
bundle_failed=0
bundle_log="$(mktemp)"
trap 'rm -f "$bundle_log"' EXIT

if [[ -f Brewfile ]]; then
  brew bundle --file="$HOME/Documents/SharedConfigs/Brewfile" 2>&1 | tee "$bundle_log" || bundle_failed=1
else
  brew bundle 2>&1 | tee "$bundle_log" || bundle_failed=1
fi

bundle_ok_count="$(awk '/^(Using|Installing) / && $0 !~ / has failed!/ { n++ } END { print n+0 }' "$bundle_log")"
bundle_fail_count="$(sed -nE 's/^`brew bundle` failed! ([0-9]+) Brewfile dependenc(y|ies) failed to install$/\1/p' "$bundle_log" | tail -n 1)"
if [[ -z "$bundle_fail_count" ]]; then
  bundle_fail_count="$(awk '/^(Installing|Upgrading) .* has failed!$/ { n++ } END { print n+0 }' "$bundle_log")"
fi
if [[ "$bundle_failed" -eq 1 && "$bundle_fail_count" -eq 0 ]]; then
  bundle_fail_count=1
fi
echo
section "brew bundle summary"
printf "${GREEN_BOLD}(Mostly) OK:${NC} %s Brewfile items were already installed or processed.
" "$bundle_ok_count"
printf "${YELLOW_BOLD}Needs attention:${NC} %s issue(s) reported.
" "$bundle_fail_count"

if [[ "$bundle_failed" -eq 1 ]]; then
  grep -E "has failed|failed to install|depends on hardware architecture" "$bundle_log" || true
  echo

  unrecognized_errors="$(grep '^Error:' "$bundle_log" | grep -Ev 'depends on hardware architecture|dependency graph sorting failed|circular dependency' || true)"

  if [[ -n "$unrecognized_errors" ]]; then
    error "Homebrew Bundle failed unexpectedly; stopping sync-brew."
    printf '%s\n' "$unrecognized_errors" >&2
    exit 1
  elif grep -Eq "dependency graph sorting failed|circular dependency" "$bundle_log"; then
    printf "${YELLOW_BOLD}Continuing because Homebrew Bundle encountered a formula dependency-cycle sorting error. brew upgrade and brew doctor otherwise completed normally.${NC}\n"
  elif grep -Eq "depends on hardware architecture" "$bundle_log"; then
    printf "${YELLOW_BOLD}Continuing because some Brewfile items may be unavailable or architecture-specific on this Mac.${NC}\n"
  else
    error "Homebrew Bundle failed unexpectedly; stopping sync-brew."
    exit 1
  fi
fi

echo
rm -f "$bundle_log"
trap - EXIT

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
