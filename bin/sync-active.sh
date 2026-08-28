#!/usr/bin/env zsh
set -euo pipefail

usage() {
  cat <<'EOF'
sync-active.sh [--promote] [--commit] [--push] [--quiet|--verbose] [--health]

Synchronize repositories that are under active development.

Flags:
  --promote   Advance managed course submodules to their upstream tips
  --commit    Commit recognized submodule pointer changes
  --push      Implies --commit and --promote; push pointer commits
  --quiet     Print only SKIP/WARN/ERROR and final verdict
  --verbose   Print extra Git details
  --health    Run repo-health summary (also enabled by --verbose)

Repository scope comes from current "active" rows in
SharedConfigs/settings/repositories.conf.
EOF
}

GREEN_BOLD=$'\033[1;32m'
YELLOW_BOLD=$'\033[1;33m'
RED_BOLD=$'\033[1;31m'
NC=$'\033[0m'

QUIET=0
VERBOSE=0
DO_HEALTH=0
do_promote=0
do_commit=0
do_push=0
SKIP_COUNT=0
UPDATE_COUNT=0
ERROR_COUNT=0

timestamp() { /bin/date '+%Y-%m-%d %H:%M:%S %Z'; }
plain_log() { print -r -- "$*"; }
info() { (( QUIET == 0 )) && plain_log "$*"; return 0; }
vinfo() { (( VERBOSE == 1 && QUIET == 0 )) && plain_log "$*"; return 0; }
ok() { (( QUIET == 0 )) && plain_log "${GREEN_BOLD}$*${NC}"; return 0; }
warn() { plain_log "${YELLOW_BOLD}Warning:${NC} $*"; }
failure() { plain_log "${RED_BOLD}$*${NC}" >&2; }
banner() {
  (( QUIET == 0 )) &&
    printf "\n${GREEN_BOLD}===== [%s] %s =====${NC}\n" "$(timestamp)" "$1"
  return 0
}
warn_banner() {
  printf "\n${YELLOW_BOLD}===== [%s] %s =====${NC}\n" "$(timestamp)" "$1"
}
err_banner() {
  printf "\n${RED_BOLD}===== [%s] %s =====${NC}\n" "$(timestamp)" "$1" >&2
}
shortsha() { print -r -- "${1[1,12]}"; }

for arg in "$@"; do
  case "${arg}" in
    --promote) do_promote=1 ;;
    --commit) do_commit=1 ;;
    --push) do_push=1 ;;
    --quiet) QUIET=1 ;;
    --verbose) VERBOSE=1 ;;
    --health) DO_HEALTH=1 ;;
    --help|-h) usage; exit 0 ;;
    *) failure "ERROR: unknown argument: ${arg}"; usage; exit 2 ;;
  esac
done
if (( do_push == 1 )); then
  do_commit=1
  do_promote=1
fi

# Internal record format: name<TAB>local path<TAB>clone URL<TAB>optional branch.
# Each entry is one record, so repository fields cannot become misaligned.
# Leave branch empty to use the remote default on clone and the checked-out
# branch/upstream thereafter.
typeset -a REPOSITORIES=()

# The legacy tab-delimited override remains available for isolated validation
# and automation. Normal operation reads the shared managed-repository registry.
if [[ -n "${SYNC_ACTIVE_REGISTRY_FILE:-}" ]]; then
  if [[ ! -r "$SYNC_ACTIVE_REGISTRY_FILE" ]]; then
    failure "ERROR: cannot read registry file: ${SYNC_ACTIVE_REGISTRY_FILE}"
    exit 2
  fi
  REPOSITORIES=()
  registry_line=""
  while IFS= read -r registry_line || [[ -n "$registry_line" ]]; do
    [[ -z "$registry_line" || "$registry_line" == \#* ]] && continue
    REPOSITORIES+=("$registry_line")
  done < "$SYNC_ACTIVE_REGISTRY_FILE"
else
  script_dir="${0:A:h}"
  repository_registry="${REPOSITORY_REGISTRY_FILE:-${script_dir:h}/settings/repositories.conf}"
  if [[ ! -r "$repository_registry" ]]; then
    failure "ERROR: cannot read repository registry: ${repository_registry}"
    exit 2
  fi
  if ! REPOSITORY_REGISTRY_FILE="$repository_registry" \
    "${script_dir}/repo-sweep" --list >/dev/null; then
    failure "ERROR: managed repository registry validation failed"
    exit 2
  fi

  registry_status=""
  registry_workflow=""
  registry_name=""
  registry_path=""
  registry_branch=""
  registry_origin=""
  registry_extra=""
  resolved_registry_path=""
  while IFS='|' read -r registry_status registry_workflow registry_name \
    registry_path registry_branch registry_origin registry_extra ||
    [[ -n "$registry_status" ]]; do
    [[ -z "$registry_status" || "$registry_status" == \#* ]] && continue
    [[ "$registry_status" == "current" && "$registry_workflow" == "active" ]] || continue
    if [[ -n "$registry_extra" || -z "$registry_name" || -z "$registry_path" ||
          -z "$registry_origin" ]]; then
      failure "ERROR: invalid active repository row in ${repository_registry}"
      exit 2
    fi
    if [[ "$registry_path" == /* ]]; then
      resolved_registry_path="$registry_path"
    else
      resolved_registry_path="$HOME/$registry_path"
    fi
    REPOSITORIES+=("${registry_name}"$'\t'"${resolved_registry_path}"$'\t'"${registry_origin}"$'\t'"${registry_branch}")
  done < "$repository_registry"
fi

if (( ${#REPOSITORIES} == 0 )); then
  failure "ERROR: no current active repositories are configured"
  exit 2
fi

REPO_NAME=""
REPO_PATH=""
REPO_URL=""
REPO_BRANCH=""
parse_repository_record() {
  local record="$1"
  local -a fields
  fields=("${(@ps:\t:)record}")
  if (( ${#fields} < 3 || ${#fields} > 4 )); then
    failure "ERROR: invalid repository registry record"
    return 1
  fi
  REPO_NAME="${fields[1]}"
  REPO_PATH="${fields[2]}"
  REPO_URL="${fields[3]}"
  REPO_BRANCH="${fields[4]-}"
  if [[ -z "$REPO_NAME" || -z "$REPO_PATH" || -z "$REPO_URL" ]]; then
    failure "ERROR: repository registry requires name, path, and clone URL"
    return 1
  fi
}

REPO_WAS_CLONED=0
ensure_repository_exists() {
  REPO_WAS_CLONED=0
  if [[ -e "$REPO_PATH" ]]; then
    return 0
  fi
  if ! /bin/mkdir -p "${REPO_PATH:h}"; then
    failure "ERROR  ${REPO_NAME}: cannot create parent directory"
    return 1
  fi
  local -a clone_args=(clone)
  [[ -n "$REPO_BRANCH" ]] && clone_args+=(--branch "$REPO_BRANCH")
  clone_args+=("$REPO_URL" "$REPO_PATH")
  vinfo "CLONE  ${REPO_NAME}: ${REPO_URL}"
  if ! /usr/bin/git "${clone_args[@]}" >/dev/null 2>&1; then
    failure "ERROR  ${REPO_NAME}: clone failed from ${REPO_URL}"
    return 1
  fi
  REPO_WAS_CLONED=1
}

validate_repository_and_remote() {
  if [[ ! -d "$REPO_PATH" ]]; then
    failure "ERROR  ${REPO_NAME}: path exists but is not a directory"
    return 1
  fi
  if ! /usr/bin/git -C "$REPO_PATH" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    failure "ERROR  ${REPO_NAME}: path exists but is not a Git repository"
    return 1
  fi
  local actual_top resolved_repo resolved_top actual_url
  actual_top=$(/usr/bin/git -C "$REPO_PATH" rev-parse --show-toplevel 2>/dev/null)
  resolved_repo="${REPO_PATH:A}"
  resolved_top="${actual_top:A}"
  if [[ "$resolved_repo" != "$resolved_top" ]]; then
    failure "ERROR  ${REPO_NAME}: registry path is not the repository root"
    vinfo "       configured: ${REPO_PATH}"
    vinfo "       actual root: ${actual_top}"
    return 1
  fi
  if ! actual_url=$(/usr/bin/git -C "$REPO_PATH" remote get-url origin 2>/dev/null); then
    failure "ERROR  ${REPO_NAME}: origin remote is missing"
    return 1
  fi
  if [[ "$actual_url" != "$REPO_URL" ]]; then
    warn "${REPO_NAME}: origin differs from registry (using existing origin)"
    vinfo "       configured: ${REPO_URL}"
    vinfo "       existing:   ${actual_url}"
  fi
}

typeset -a SUBMODULE_PATHS=()
typeset -a MANAGED_PATHS=()
has_gitlink() {
  local repo="$1" path="$2" entry
  entry=$(/usr/bin/git -C "$repo" ls-files --stage -- "$path" 2>/dev/null || true)
  [[ "$entry" == 160000\ * ]]
}

inspect_submodule_metadata() {
  SUBMODULE_PATHS=()
  MANAGED_PATHS=()
  if ! /usr/bin/git -C "$REPO_PATH" ls-files --error-unmatch -- .gitmodules >/dev/null 2>&1; then
    return 0
  fi
  local record path
  while IFS= read -r -d $'\0' record; do
    [[ -z "$record" ]] && continue
    path="${record#*$'\n'}"
    if has_gitlink "$REPO_PATH" "$path"; then
      SUBMODULE_PATHS+=("$path")
      case "$path" in
        classlib|qmcpy|assets/tests/archive) MANAGED_PATHS+=("$path") ;;
      esac
    else
      warn "${REPO_NAME}: .gitmodules path is not a committed gitlink: ${path}"
    fi
  done < <(/usr/bin/git -C "$REPO_PATH" config -z -f .gitmodules \
    --get-regexp '^submodule\..*\.path$' 2>/dev/null || true)
  return 0
}

status_is_clean() {
  [[ -z "$(/usr/bin/git -C "$REPO_PATH" status --porcelain=v1 -z --untracked-files=normal)" ]]
}

only_recognized_pointer_changes() {
  local record xy path renamed_path
  local status_file
  status_file=$(/usr/bin/mktemp)
  /usr/bin/git -C "$REPO_PATH" status --porcelain=v1 -z \
    --untracked-files=normal >| "$status_file"
  [[ ! -s "$status_file" ]] && { /bin/rm -f "$status_file"; return 0; }

  while IFS= read -r -d $'\0' record; do
    xy="${record[1,2]}"
    path="${record[4,-1]}"
    if [[ "$xy" == *R* || "$xy" == *C* ]]; then
      if ! IFS= read -r -d $'\0' renamed_path; then
        /bin/rm -f "$status_file"
        return 1
      fi
      /bin/rm -f "$status_file"
      return 1
    fi
    if [[ "$xy" == '??' || "$xy" == *D* || "$xy" == *A* ]] ||
       (( ${SUBMODULE_PATHS[(Ie)$path]} == 0 )) ||
       ! has_gitlink "$REPO_PATH" "$path"; then
      /bin/rm -f "$status_file"
      return 1
    fi
  done < "$status_file"
  /bin/rm -f "$status_file"
  return 0
}

prepare_branch() {
  local current
  current=$(/usr/bin/git -C "$REPO_PATH" branch --show-current)
  if [[ -z "$current" ]]; then
    failure "ERROR  ${REPO_NAME}: detached HEAD; configure or check out a branch"
    return 1
  fi
  if [[ -n "$REPO_BRANCH" && "$current" != "$REPO_BRANCH" ]]; then
    failure "ERROR  ${REPO_NAME}: branch ${current} differs from configured ${REPO_BRANCH}"
    return 1
  fi
  if ! /usr/bin/git -C "$REPO_PATH" rev-parse --verify '@{u}' >/dev/null 2>&1; then
    failure "ERROR  ${REPO_NAME}: branch ${current} has no upstream"
    return 1
  fi
}

SYNC_CHANGED=0
SYNC_COMMIT_COUNT=0
fast_forward_sync() {
  SYNC_CHANGED=0
  SYNC_COMMIT_COUNT=0
  local old new
  old=$(/usr/bin/git -C "$REPO_PATH" rev-parse HEAD)
  if ! /usr/bin/git -C "$REPO_PATH" -c fetch.recurseSubmodules=no \
    fetch origin >/dev/null 2>&1; then
    failure "ERROR  ${REPO_NAME}: fetch from origin failed"
    return 1
  fi
  if ! /usr/bin/git -C "$REPO_PATH" merge --ff-only '@{u}' >/dev/null 2>&1; then
    failure "ERROR  ${REPO_NAME}: fast-forward-only update failed"
    return 1
  fi
  new=$(/usr/bin/git -C "$REPO_PATH" rev-parse HEAD)
  if [[ "$old" != "$new" ]]; then
    SYNC_CHANGED=1
    SYNC_COMMIT_COUNT=$(/usr/bin/git -C "$REPO_PATH" rev-list --count "${old}..${new}")
  fi
  return 0
}

pinned_submodule_checkout() {
  (( ${#SUBMODULE_PATHS} == 0 )) && return 0
  if ! /usr/bin/git -C "$REPO_PATH" submodule sync --recursive >/dev/null 2>&1 ||
     ! /usr/bin/git -C "$REPO_PATH" submodule update --init --recursive \
       --checkout >/dev/null 2>&1; then
    failure "ERROR  ${REPO_NAME}: pinned submodule checkout failed"
    return 1
  fi
}

ensure_qmcpy_fetch_policy() {
  local qmcpy_path="${REPO_PATH}/qmcpy"
  [[ -e "$qmcpy_path" ]] || return 0
  /usr/bin/git -C "$qmcpy_path" rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 0
  /usr/bin/git -C "$qmcpy_path" remote get-url origin >/dev/null 2>&1 || return 0
  /usr/bin/git -C "$qmcpy_path" config --unset-all remote.origin.fetch >/dev/null 2>&1 || true
  /usr/bin/git -C "$qmcpy_path" config --add remote.origin.fetch \
    '+refs/heads/develop:refs/remotes/origin/develop'
  /usr/bin/git -C "$qmcpy_path" config --add remote.origin.fetch \
    '+refs/tags/*:refs/tags/*'
  /usr/bin/git -C "$qmcpy_path" fetch --prune origin >/dev/null 2>&1 || true
}

promote_managed_submodules() {
  (( ${#SUBMODULE_PATHS} == 0 )) && return 0
  if (( ${#MANAGED_PATHS} == 0 )); then
    warn "${REPO_NAME}: no promotion rule for its submodules; leaving them pinned"
    return 0
  fi
  if ! command -v update-submodules.sh >/dev/null 2>&1; then
    failure "ERROR  ${REPO_NAME}: managed submodules require update-submodules.sh"
    return 1
  fi
  local old_pwd="$PWD"
  if ! builtin cd "$REPO_PATH"; then
    failure "ERROR  ${REPO_NAME}: cannot enter repository"
    return 1
  fi
  local rc=0
  update-submodules.sh >/dev/null 2>&1 || rc=$?
  builtin cd "$old_pwd"
  if (( rc != 0 )); then
    failure "ERROR  ${REPO_NAME}: update-submodules.sh failed"
    return 1
  fi
}

commit_pointer_changes() {
  status_is_clean && return 0
  if ! only_recognized_pointer_changes; then
    failure "ERROR  ${REPO_NAME}: changes are not limited to submodule pointers"
    return 1
  fi
  if (( do_commit == 0 )); then
    warn "${REPO_NAME}: uncommitted submodule pointer changes (run --commit or --push)"
    return 2
  fi
  local -a changed_paths=()
  local path
  for path in "${SUBMODULE_PATHS[@]}"; do
    if ! /usr/bin/git -C "$REPO_PATH" diff --quiet HEAD -- "$path"; then
      changed_paths+=("$path")
    fi
  done
  (( ${#changed_paths} > 0 )) || return 0
  if ! /usr/bin/git -C "$REPO_PATH" add -- "${changed_paths[@]}" ||
     ! /usr/bin/git -C "$REPO_PATH" commit -m \
       'Update submodule pointers' >/dev/null 2>&1; then
    failure "ERROR  ${REPO_NAME}: pointer commit failed"
    return 1
  fi
  SYNC_CHANGED=1
  SYNC_COMMIT_COUNT=$((SYNC_COMMIT_COUNT + 1))
}

push_if_requested() {
  (( do_push == 0 )) && return 0
  local ahead
  ahead=$(/usr/bin/git -C "$REPO_PATH" rev-list --count '@{u}..HEAD')
  (( ahead == 0 )) && return 0
  if ! /usr/bin/git -C "$REPO_PATH" push >/dev/null 2>&1; then
    failure "ERROR  ${REPO_NAME}: push failed"
    return 1
  fi
  (( SYNC_COMMIT_COUNT == 0 )) && SYNC_COMMIT_COUNT=$ahead
  SYNC_CHANGED=1
}

# Return: 0 current, 10 cloned, 11 updated, 20 skipped, 30 failed.
sync_repository() {
  local record="$1"
  parse_repository_record "$record" || return 30
  ensure_repository_exists || return 30
  validate_repository_and_remote || return 30
  inspect_submodule_metadata

  if ! only_recognized_pointer_changes; then
    failure "SKIP   ${REPO_NAME}: dirty working tree"
    (( VERBOSE == 1 )) &&
      /usr/bin/git -C "$REPO_PATH" status --short >&2 || true
    return 20
  fi
  # Existing pointer changes may only proceed for an explicitly requested commit.
  if ! status_is_clean && (( do_commit == 0 )); then
    failure "SKIP   ${REPO_NAME}: uncommitted submodule pointer changes"
    return 20
  fi

  prepare_branch || return 30
  fast_forward_sync || return 30
  inspect_submodule_metadata
  pinned_submodule_checkout || return 30
  if (( do_promote == 1 )); then
    promote_managed_submodules || return 30
  fi
  if (( ${MANAGED_PATHS[(Ie)qmcpy]} > 0 )); then
    ensure_qmcpy_fetch_policy
  fi
  local commit_rc=0
  commit_pointer_changes || commit_rc=$?
  (( commit_rc == 1 )) && return 30
  (( commit_rc == 2 )) && return 20
  push_if_requested || return 30

  (( VERBOSE == 1 && QUIET == 0 )) &&
    /usr/bin/git -C "$REPO_PATH" status -sb || true
  (( REPO_WAS_CLONED == 1 )) && return 10
  (( SYNC_CHANGED == 1 )) && return 11
  return 0
}

check_submodule_pin_consistency() {
  local submodule_path="$1"
  local display_label="$2"
  local -a repo_names=()
  local -a pins=()
  local record pin
  local count mismatch i ref_pin

  for record in "${REPOSITORIES[@]}"; do
    parse_repository_record "$record" || continue
    /usr/bin/git -C "$REPO_PATH" rev-parse --is-inside-work-tree >/dev/null 2>&1 ||
      continue

    if has_gitlink "$REPO_PATH" "$submodule_path"; then
      pin=$(/usr/bin/git -C "$REPO_PATH" rev-parse "HEAD:${submodule_path}")
      repo_names+=("$REPO_NAME")
      pins+=("$pin")
    fi
  done

  count=${#pins[@]}

  if (( count < 2 )); then
    info "INFO   ${display_label}: ${count} active repo(s); no cross-repo comparison needed"
    return 0
  fi

  ref_pin="${pins[1]}"
  mismatch=0

  for (( i = 2; i <= count; i++ )); do
    [[ "${pins[$i]}" != "$ref_pin" ]] && mismatch=1
  done

  if (( mismatch == 1 )); then
    warn "${display_label} pins differ across active repositories"
    for (( i = 1; i <= count; i++ )); do
      info "       ${repo_names[$i]} @ $(shortsha "${pins[$i]}")"
    done
  else
    info "OK     ${display_label} pins match across ${count} active repos"
    for (( i = 1; i <= count; i++ )); do
      vinfo "       ${repo_names[$i]} @ $(shortsha "${pins[$i]}")"
    done
  fi
}

pins_consistency_check() {
  check_submodule_pin_consistency "classlib" "classlib"
  check_submodule_pin_consistency "qmcpy" "qmcpy"
  check_submodule_pin_consistency "assets/tests/archive" "tests archive"
}

health_summary() {
  (( DO_HEALTH == 1 || VERBOSE == 1 )) || return 0
  (( QUIET == 0 )) || return 0
  if ! command -v repo-health >/dev/null 2>&1; then
    warn "repo-health not on PATH"
    return 0
  fi
  local record line
  for record in "${REPOSITORIES[@]}"; do
    parse_repository_record "$record" || continue
    /usr/bin/git -C "$REPO_PATH" rev-parse --is-inside-work-tree >/dev/null 2>&1 ||
      continue
    line=$(cd "$REPO_PATH" && repo-health --short 2>&1 || true)
    [[ -n "$line" ]] && plain_log "$line"
  done
}

(( do_promote == 1 )) &&
  banner "Sync active repos started (PROMOTE)" ||
  banner "Sync active repos started (PINNED)"

local_record=""
for local_record in "${REPOSITORIES[@]}"; do
  rc=0
  sync_repository "$local_record" || rc=$?
  case "$rc" in
    0) info "OK     ${REPO_NAME}: already current @ $(shortsha "$(/usr/bin/git -C "$REPO_PATH" rev-parse HEAD)")" ;;
    10) UPDATE_COUNT=$((UPDATE_COUNT + 1)); ok "CLONED ${REPO_NAME}: ready @ $(shortsha "$(/usr/bin/git -C "$REPO_PATH" rev-parse HEAD)")" ;;
    11) UPDATE_COUNT=$((UPDATE_COUNT + 1)); ok "UPDATED ${REPO_NAME}: +${SYNC_COMMIT_COUNT} -> $(shortsha "$(/usr/bin/git -C "$REPO_PATH" rev-parse HEAD)")" ;;
    20) SKIP_COUNT=$((SKIP_COUNT + 1)) ;;
    *) ERROR_COUNT=$((ERROR_COUNT + 1)) ;;
  esac
done

pins_consistency_check || true
health_summary || true

if (( ERROR_COUNT > 0 )); then
  err_banner "FAILED: ${ERROR_COUNT} error(s), ${SKIP_COUNT} skip(s)"
  exit 1
elif (( SKIP_COUNT > 0 )); then
  warn_banner "INCOMPLETE RUN: ${SKIP_COUNT} skip condition(s)"
  exit 1
elif (( UPDATE_COUNT > 0 )); then
  banner "SUCCESS: ${UPDATE_COUNT} repository/repositories changed"
else
  banner "SUCCESS: all repos already in sync"
fi
