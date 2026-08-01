#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat << 'USAGE'
Usage: sync-dev.sh [--quiet|--verbose]

Default:
  - Prints one summary line per repo (UPDATED/OK/SKIP/ERROR)

Flags:
  --quiet     Print only SKIP/ERROR and the final verdict
  --verbose   Print extra git status details
USAGE
}

QUIET=0
VERBOSE=0

for arg in "$@"; do
  case "$arg" in
    --quiet) QUIET=1 ;;
    --verbose) VERBOSE=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "ERROR: unknown argument: $arg" >&2; usage; exit 2 ;;
  esac
done

GREEN_BOLD=$'\033[1;32m'
MAGENTA_BOLD=$'\033[1;35m'
YELLOW_BOLD=$'\033[1;33m'
RED_BOLD=$'\033[1;31m'
NC=$'\033[0m'

timestamp() {
  /bin/date '+%Y-%m-%d %H:%M:%S %Z'
}

error() {
  printf "${RED_BOLD}Error:${NC} %s\n" "$1" >&2
}

timestamp_log() { printf "[%s] %s\n" "$(timestamp)" "$*"; }

banner() { [[ "$QUIET" -eq 0 ]] && printf "\n${GREEN_BOLD}===== [%s] %s =====${NC}\n" "$(timestamp)" "$1"; }
section() { [[ "$QUIET" -eq 0 ]] && printf "\n${MAGENTA_BOLD}--- %s ---${NC}\n" "$1"; }
warn_banner() { printf "\n${YELLOW_BOLD}===== [%s] %s =====${NC}\n" "$(timestamp)" "$1"; }
err_banner() { printf "\n${RED_BOLD}===== [%s] %s =====${NC}\n" "$(timestamp)" "$1" >&2; }

SKIP_COUNT=0
UPDATE_COUNT=0
ERROR_COUNT=0

say() { echo "$*"; }
info() { [[ "$QUIET" -eq 0 ]] && say "$*"; }
ok() { info "${GREEN_BOLD}$*${NC}"; }
warn() { [[ "$QUIET" -eq 0 ]] && say "${YELLOW_BOLD}$*${NC}"; }
err() { say "${RED_BOLD}$*${NC}" >&2; }

shortsha() {
  local s="$1"
  echo "${s:0:12}"
}

is_clean_repo() {
  local repo="$1"
  [[ -z "$(git -C "$repo" status --porcelain)" ]]
}

verbose_status() {
  local repo="$1"
  if [[ "$VERBOSE" -eq 1 && "$QUIET" -eq 0 ]]; then
    git -C "$repo" status -sb || true
  fi
}

sync_repo() {
  local repo="$1"
  local name="$2"
  local branch="$3"

  if [[ ! -d "$repo/.git" && ! -f "$repo/.git" ]]; then
    ERROR_COUNT=$((ERROR_COUNT + 1))
    err "ERROR  ${name}: not a git repo: ${repo}"
    return 0
  fi

  if ! is_clean_repo "$repo"; then
    SKIP_COUNT=$((SKIP_COUNT + 1))
    warn "SKIP   ${name}: dirty working tree"
    verbose_status "$repo"
    return 0
  fi

  local old new count
  old="$(git -C "$repo" rev-parse HEAD)"

  if ! git -C "$repo" fetch --prune origin >/dev/null 2>&1; then
    ERROR_COUNT=$((ERROR_COUNT + 1))
    err "ERROR  ${name}: fetch failed"
    return 0
  fi

  if ! git -C "$repo" checkout "$branch" >/dev/null 2>&1; then
    if ! git -C "$repo" switch "$branch" >/dev/null 2>&1; then
      ERROR_COUNT=$((ERROR_COUNT + 1))
      err "ERROR  ${name}: cannot switch to ${branch}"
      return 0
    fi
  fi

  if ! git -C "$repo" pull --ff-only origin "$branch" >/dev/null 2>&1; then
    ERROR_COUNT=$((ERROR_COUNT + 1))
    err "ERROR  ${name}: pull --ff-only failed"
    return 0
  fi

  new="$(git -C "$repo" rev-parse HEAD)"

  if [[ "$old" != "$new" ]]; then
    count="$(git -C "$repo" rev-list --count "${old}..${new}" 2>/dev/null || echo "?")"
    UPDATE_COUNT=$((UPDATE_COUNT + 1))
    ok "UPDATED ${name} (${branch}) +${count} -> $(shortsha "$new")"
  else
    info "OK     ${name} (${branch}) @ $(shortsha "$new")"
  fi

  verbose_status "$repo"
}

HCL="$HOME/SoftwareRepositories/HickernellAcademicLib"
QMC="$HOME/SoftwareRepositories/QMCSoftware"
QMC_WEBSITE="$HOME/SoftwareRepositories/qmcsoftware-website"
HTA="$HOME/SoftwareRepositories/HickernellTestArchive"

banner "Sync dev started"

sync_repo "$HCL" "HickernellAcademicLib" "main"
sync_repo "$QMC" "QMCSoftware" "develop"
sync_repo "$QMC_WEBSITE" "qmcpy-website" "main"
sync_repo "$HTA" "HickernellTestArchive" "main"

if [[ "$ERROR_COUNT" -gt 0 ]]; then
  err_banner "FAILED: ${ERROR_COUNT} error(s)"
  exit 1
fi

if [[ "$SKIP_COUNT" -gt 0 ]]; then
  warn_banner "INCOMPLETE: ${SKIP_COUNT} skip(s)"
  exit 0
fi

if [[ "$UPDATE_COUNT" -gt 0 ]]; then
  banner "SUCCESS: ${UPDATE_COUNT} standalone repo(s) updated"
  exit 0
fi

banner "SUCCESS: standalone repos already up to date"
exit 0
