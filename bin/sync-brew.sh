#!/bin/zsh
set -euo pipefail

# Proceed with the requested sync without Homebrew's upgrade confirmation.
# Export also covers install/upgrade commands invoked by brew bundle.
export HOMEBREW_NO_ASK=1

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

if [[ $# -gt 1 || ( $# -eq 1 && "$1" != "--full" ) ]]; then
  printf 'Usage: %s [--full]\n' "$0" >&2
  exit 2
fi

# Intel Homebrew no longer receives bottles for many formulae. Keep routine
# maintenance short; run --full during an attended formula-maintenance window.
intel_routine=0
if [[ "$(uname -m)" == "x86_64" && $# -eq 0 ]]; then
  intel_routine=1
fi

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

if [[ "${SYNC_BREW_SKIP_UPDATE:-0}" == "1" ]]; then
  section "Using Homebrew metadata updated by regular maintenance"
else
  section "Updating Homebrew"
  brew update
fi
# The explicit update above (or the caller's successful update) covers this run.
export HOMEBREW_NO_AUTO_UPDATE=1

if (( intel_routine )); then
  section "Upgrading outdated casks outside the Brewfile (Intel; formulae deferred)"
else
  section "Upgrading outdated packages outside the Brewfile"
fi
# Bundle owns listed packages, including its per-cask greedy policy.
# Retain coverage for other installed packages without upgrading listed
# packages once here and checking them again during Bundle processing.
for package_type in formula cask; do
  if (( intel_routine )) && [[ "$package_type" == formula ]]; then
    continue
  fi
  typeset -a listed_packages=() extra_packages=()
  if [[ -f Brewfile ]]; then
    listed_output="$(brew bundle list --"$package_type" --file="$PWD/Brewfile")"
    while IFS= read -r package; do
      [[ -z "$package" ]] || listed_packages+=("${package##*/}")
    done <<<"$listed_output"
  fi
  outdated_output="$(brew outdated --quiet --"$package_type")"
  while IFS= read -r package; do
    [[ -n "$package" ]] || continue
    package_name="${package##*/}"
    if (( ${listed_packages[(Ie)$package_name]} == 0 )); then
      extra_packages+=("$package")
    fi
  done <<<"$outdated_output"
  if (( ${#extra_packages} )); then
    brew upgrade --"$package_type" "${extra_packages[@]}"
  fi
done

# Bundle installs missing Store apps; the final mas step owns all Store updates.
# Skip installed IDs so Bundle does not repeat its global outdated check.
# Always exclude the Store edition of TextSniper, including when absent.
if command -v mas >/dev/null 2>&1; then
  installed_mas_apps="$(mas list)"
  installed_mas_ids="$(awk '$1 ~ /^[0-9]+$/ { print $1 }' <<<"$installed_mas_apps" | paste -sd ' ' -)"
  export HOMEBREW_BUNDLE_MAS_SKIP="${HOMEBREW_BUNDLE_MAS_SKIP:+$HOMEBREW_BUNDLE_MAS_SKIP }${installed_mas_ids} 1528890965"
fi

section "Ensuring Brewfile state via brew bundle"
bundle_failed=0
bundle_log="$(mktemp)"
trap 'rm -f "$bundle_log"' EXIT

if [[ -f Brewfile ]]; then
  if (( intel_routine )); then
    # Keep casks, Mac App Store apps, extensions, and npm entries in sync while
    # skipping formula entries that could trigger lengthy source builds.
    formula_skip="$(brew bundle list --formula --file="$PWD/Brewfile" | paste -sd ' ' -)"
    HOMEBREW_BUNDLE_BREW_SKIP="${HOMEBREW_BUNDLE_BREW_SKIP:+$HOMEBREW_BUNDLE_BREW_SKIP }${formula_skip}" \
      brew bundle --file="$PWD/Brewfile" 2>&1 | tee "$bundle_log" || bundle_failed=1
  else
    brew bundle --file="$PWD/Brewfile" 2>&1 | tee "$bundle_log" || bundle_failed=1
  fi
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
if (( intel_routine )); then
  warn "Intel formula upgrades and Brewfile formula installs were deferred; run sync-brew.sh --full in an attended window."
fi

if [[ "$bundle_failed" -eq 1 ]]; then
  grep -E "has failed|failed to install|depends on hardware architecture" "$bundle_log" || true
  echo

  if grep -Eq '^(Installing|Upgrading) .* has failed!$' "$bundle_log"; then
    error "Homebrew Bundle failed to install or upgrade Brewfile items; stopping sync-brew."
    exit 1
  fi

  unrecognized_errors="$(grep '^Error:' "$bundle_log" | grep -Ev 'depends on hardware architecture|dependency graph sorting failed|circular dependency' || true)"

  if [[ -n "$unrecognized_errors" ]]; then
    error "Homebrew Bundle failed unexpectedly; stopping sync-brew."
    printf '%s\n' "$unrecognized_errors" >&2
    exit 1
  elif grep -Eq "dependency graph sorting failed|circular dependency" "$bundle_log"; then
    error "Homebrew Bundle could not sort its dependencies; listed package upgrades are not confirmed."
    exit 1
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
  section "Upgrading Mac App Store apps except TextSniper"
  mas_outdated="$(mas outdated)"
  typeset -a mas_ids=()
  while read -r app_id rest; do
    [[ "$app_id" == <-> ]] || continue
    [[ "$app_id" == 1528890965 ]] && continue
    mas_ids+=("$app_id")
  done <<<"$mas_outdated"
  if (( ${#mas_ids} )); then
    mas upgrade "${mas_ids[@]}"
  else
    printf '%s\n' "No other Mac App Store updates available."
  fi
else
  warn "mas not found; skipping Mac App Store upgrades."
fi

banner "sync-brew completed successfully"
