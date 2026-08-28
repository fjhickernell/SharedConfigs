#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat << 'USAGE'
Usage: sync-dev.sh [--quiet|--verbose]

Default:
  - Clones a registered repository when its path is absent
  - Prints one summary line per repo (CLONED/UPDATED/OK/SKIP/ERROR)

Flags:
  --quiet     Print only SKIP/ERROR and the final verdict
  --verbose   Print extra git status details

Repository scope comes from current "dev" rows in
SharedConfigs/settings/repositories.conf.
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

banner() { [[ "$QUIET" -eq 0 ]] && printf "\n${GREEN_BOLD}===== [%s] %s =====${NC}\n" "$(timestamp)" "$1"; return 0; }
section() { [[ "$QUIET" -eq 0 ]] && printf "\n${MAGENTA_BOLD}--- %s ---${NC}\n" "$1"; return 0; }
warn_banner() { printf "\n${YELLOW_BOLD}===== [%s] %s =====${NC}\n" "$(timestamp)" "$1"; }
err_banner() { printf "\n${RED_BOLD}===== [%s] %s =====${NC}\n" "$(timestamp)" "$1" >&2; }

SKIP_COUNT=0
UPDATE_COUNT=0
ERROR_COUNT=0

say() { echo "$*"; }
info() { [[ "$QUIET" -eq 0 ]] && say "$*"; return 0; }
ok() { info "${GREEN_BOLD}$*${NC}"; return 0; }
warn() { [[ "$QUIET" -eq 0 ]] && say "${YELLOW_BOLD}$*${NC}"; return 0; }
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
  local clone_origin="$4"
  local sync_origin="${5:-}"

  if [[ ! -d "$repo/.git" && ! -f "$repo/.git" ]]; then
    if [[ -e "$repo" ]]; then
      ERROR_COUNT=$((ERROR_COUNT + 1))
      err "ERROR  ${name}: path exists but is not a Git repository: ${repo}"
      return 0
    fi
    if ! mkdir -p -- "$(dirname -- "$repo")"; then
      ERROR_COUNT=$((ERROR_COUNT + 1))
      err "ERROR  ${name}: cannot create parent directory for ${repo}"
      return 0
    fi
    if ! git clone --branch "$branch" -- "$clone_origin" "$repo" >/dev/null 2>&1; then
      ERROR_COUNT=$((ERROR_COUNT + 1))
      err "ERROR  ${name}: clone failed from ${clone_origin}"
      return 0
    fi
    local cloned_head
    cloned_head="$(git -C "$repo" rev-parse HEAD)"
    UPDATE_COUNT=$((UPDATE_COUNT + 1))
    ok "CLONED  ${name} (${branch}) @ $(shortsha "$cloned_head")"
    verbose_status "$repo"
    return 0
  fi

  if ! is_clean_repo "$repo"; then
    SKIP_COUNT=$((SKIP_COUNT + 1))
    warn "SKIP   ${name}: dirty working tree"
    verbose_status "$repo"
    return 0
  fi

  local origin_changed=0
  local actual_origin=""
  if [[ -n "$sync_origin" ]]; then
    if ! actual_origin="$(git -C "$repo" remote get-url origin 2>/dev/null)"; then
      ERROR_COUNT=$((ERROR_COUNT + 1))
      err "ERROR  ${name}: origin remote is missing"
      return 0
    fi
    if [[ "$actual_origin" != "$sync_origin" ]]; then
      if ! git -C "$repo" remote set-url origin "$sync_origin"; then
        ERROR_COUNT=$((ERROR_COUNT + 1))
        err "ERROR  ${name}: cannot retarget origin to ${sync_origin}"
        return 0
      fi
      origin_changed=1
    fi
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
  elif [[ "$origin_changed" -eq 1 ]]; then
    UPDATE_COUNT=$((UPDATE_COUNT + 1))
    ok "UPDATED ${name} (${branch}) origin -> ${sync_origin}"
  else
    info "OK     ${name} (${branch}) @ $(shortsha "$new")"
  fi

  verbose_status "$repo"
}

banner "Sync dev started"

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
repository_registry="${REPOSITORY_REGISTRY_FILE:-${script_dir}/../settings/repositories.conf}"
if [[ ! -r "$repository_registry" ]]; then
  error "cannot read repository registry: ${repository_registry}"
  exit 2
fi
if ! REPOSITORY_REGISTRY_FILE="$repository_registry" \
  "${script_dir}/repo-sweep" --list >/dev/null; then
  error "managed repository registry validation failed"
  exit 2
fi

repo_count=0
while IFS='|' read -r registry_status registry_workflow registry_name \
  registry_path registry_branch registry_origin registry_extra ||
  [[ -n "$registry_status" ]]; do
  [[ -z "$registry_status" || "$registry_status" == \#* ]] && continue
  [[ "$registry_status" == "current" && "$registry_workflow" == "dev" ]] || continue
  if [[ -n "$registry_extra" || -z "$registry_name" || -z "$registry_path" ||
        -z "$registry_branch" || -z "$registry_origin" ]]; then
    error "invalid dev repository row in ${repository_registry}"
    exit 2
  fi
  if [[ "$registry_path" == /* ]]; then
    repo_path="$registry_path"
  else
    repo_path="$HOME/$registry_path"
  fi

  # All registry origins are used when cloning. Preserve the existing policy
  # that only qmcpy has its origin actively normalized after clone;
  # repo-sweep checks every existing checkout's expected origin.
  sync_origin=""
  [[ "$registry_name" == "qmcpy" ]] && sync_origin="$registry_origin"
  sync_repo "$repo_path" "$registry_name" "$registry_branch" \
    "$registry_origin" "$sync_origin"
  repo_count=$((repo_count + 1))
done < "$repository_registry"

if [[ "$repo_count" -eq 0 ]]; then
  error "no current dev repositories are configured"
  exit 2
fi

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
