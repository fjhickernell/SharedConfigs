#!/bin/zsh

set -euo pipefail

BOLD_BLUE=$'\033[1;34m'
BOLD_GREEN=$'\033[1;32m'
BOLD_YELLOW=$'\033[1;33m'
BOLD=$'\033[1m'
RESET=$'\033[0m'

bold_green_line() {
  echo "${BOLD_GREEN}$1${RESET}"
}

bold_blue_line() {
  echo "${BOLD_BLUE}$1${RESET}"
}

bold_yellow_line() {
  echo "${BOLD_YELLOW}$1${RESET}"
}

bold_green_line "===== $(date '+%Y-%m-%d %H:%M:%S %Z') syncbrew manual run started. ====="

cd "$HOME/Documents/SharedConfigs"

bold_green_line "Updating Homebrew..."
brew update

bold_green_line "Upgrading installed formulae and casks..."
HOMEBREW_UPGRADE_AUTO_UPDATES_CASKS=1 brew upgrade

bold_green_line "Ensuring Brewfile state via brew bundle..."
bundle_failed=0
bundle_log="$(mktemp)"

if [[ -f Brewfile ]]; then
  brew bundle --file="$HOME/Documents/SharedConfigs/Brewfile" 2>&1 | tee "$bundle_log" || bundle_failed=1
else
  brew bundle 2>&1 | tee "$bundle_log" || bundle_failed=1
fi

bundle_ok_count="$(awk '/^(Using|Installing) / && $0 !~ / has failed!/ { n++ } END { print n+0 }' "$bundle_log")"
bundle_fail_count="$(awk '/has failed|failed to install|depends on hardware architecture/ { n++ } END { print n+0 }' "$bundle_log")"

echo
bold_blue_line "===== brew bundle summary ====="
echo "${BOLD_GREEN}(Mostly) OK:${RESET} $bundle_ok_count Brewfile items were already installed or processed."
echo "${BOLD_YELLOW}Needs attention:${RESET} $bundle_fail_count issue(s) reported."

if [[ "$bundle_failed" -eq 1 ]]; then
  grep -E "has failed|failed to install|depends on hardware architecture" "$bundle_log" || true
  echo
  echo "${BOLD}Continuing because this can be expected on some Macs, e.g. ChatGPT is Apple-Silicon-only.${RESET}"
fi

echo

rm -f "$bundle_log"

bold_green_line "Removing unused dependencies..."
brew autoremove

bold_green_line "Cleaning up old versions..."
brew cleanup

if command -v mas >/dev/null 2>&1; then
  bold_green_line "Running mas upgrade in manual (interactive) mode."
  mas upgrade
else
  bold_yellow_line "mas not found; skipping Mac App Store upgrades."
fi

bold_green_line "===== $(date '+%Y-%m-%d %H:%M:%S %Z') syncbrew manual run finished. ====="
