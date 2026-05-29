#!/bin/zsh

set -euo pipefail

BOLD_BLUE=$'\033[1;34m'
BOLD_GREEN=$'\033[1;32m'
BOLD_YELLOW=$'\033[1;33m'
BOLD=$'\033[1m'
RESET=$'\033[0m'

echo "===== $(date '+%Y-%m-%d %H:%M:%S %Z') syncbrew manual run started. ====="

cd "$HOME/Documents/SharedConfigs"

echo "${BOLD_GREEN}Updating Homebrew...$"
brew update

echo "${BOLD_GREEN}Upgrading installed formulae and casks...$"
HOMEBREW_UPGRADE_AUTO_UPDATES_CASKS=1 brew upgrade

echo "${BOLD_GREEN}Ensuring Brewfile state via brew bundle...$"
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
echo "${BOLD_BLUE}===== brew bundle summary =====${RESET}"
echo "${BOLD_GREEN}(Mostly) OK:${RESET} $bundle_ok_count Brewfile items were already installed or processed."
echo "${BOLD_YELLOW}Needs attention:${RESET} $bundle_fail_count issue(s) reported."

if [[ "$bundle_failed" -eq 1 ]]; then
  grep -E "has failed|failed to install|depends on hardware architecture" "$bundle_log" || true
  echo
  echo "${BOLD}Continuing because this can be expected on some Macs, e.g. ChatGPT is Apple-Silicon-only.${RESET}"
fi

echo

rm -f "$bundle_log"

echo "Removing unused dependencies..."
brew autoremove

echo "Cleaning up old versions..."
brew cleanup

if command -v mas >/dev/null 2>&1; then
  echo "Running mas upgrade in manual (interactive) mode."
  mas upgrade
else
  echo "mas not found; skipping Mac App Store upgrades."
fi

print -P "%B%F{green}===== $(date '+%Y-%m-%d %H:%M:%S %Z') syncbrew manual run finished. =====%f%b"
