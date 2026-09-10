#!/bin/zsh

set -uo pipefail

# Codex may run this script from a non-login shell that has not loaded the
# Homebrew PATH. Include both Intel and Apple Silicon locations so Git hooks
# can find git-lfs even when it is installed but absent from the caller's PATH.
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

pull_only=false
case "${1:-}" in
  --pull-only) pull_only=true ;;
  '') ;;
  *) echo "Usage: git-repo-sync.sh [--pull-only]" >&2; exit 2 ;;
esac
if (( $# > 1 )); then
  echo "Usage: git-repo-sync.sh [--pull-only]" >&2
  exit 2
fi

typeset -a REPOS=()

script_dir="${0:A:h}"
repository_registry="${REPOSITORY_REGISTRY_FILE:-${script_dir:h}/settings/repositories.conf}"
if [[ ! -r "$repository_registry" ]]; then
  echo "ERROR: cannot read repository registry: ${repository_registry}" >&2
  exit 2
fi
if ! REPOSITORY_REGISTRY_FILE="$repository_registry" \
  "${script_dir}/repo-sweep" --list >/dev/null; then
  echo "ERROR: managed repository registry validation failed" >&2
  exit 2
fi

while IFS='|' read -r registry_status registry_workflow registry_name \
  registry_path registry_branch registry_origin registry_extra ||
  [[ -n "$registry_status" ]]; do
  [[ -z "$registry_status" || "$registry_status" == \#* ]] && continue
  [[ "$registry_status" == "current" && "$registry_workflow" == "infrastructure" ]] || continue
  if [[ -n "$registry_extra" || -z "$registry_name" || -z "$registry_path" ]]; then
    echo "ERROR: invalid infrastructure repository row in ${repository_registry}" >&2
    exit 2
  fi
  if [[ "$registry_path" == /* ]]; then
    resolved_registry_path="$registry_path"
  else
    resolved_registry_path="$HOME/$registry_path"
  fi
  REPOS+=("${resolved_registry_path}|${registry_name}|${registry_branch}|${registry_origin}")
done < "$repository_registry"

if (( ${#REPOS} == 0 )); then
  echo "ERROR: no current infrastructure repositories are configured" >&2
  exit 2
fi

log() {
  local message="$1"
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  echo "[$timestamp] $message"
}

pull_rebase() {
  local name="$1"

  if git pull --rebase; then
    return 0
  fi

  # Do not leave a repository in an interrupted rebase. This is harmless when
  # the pull failed before starting one.
  git rebase --abort >/dev/null 2>&1 || true
  log "FAILED: could not rebase $name; any interrupted rebase was aborted."
  return 1
}

sync_repo() {
  local entry="$1"
  local repo="${entry%%|*}"
  local remainder="${entry#*|}"
  local name="${remainder%%|*}"
  remainder="${remainder#*|}"
  local expected_branch="${remainder%%|*}"
  local expected_origin="${remainder#*|}"
  local exit_code=0
  local lock_dir="${TMPDIR:-/tmp}/git-repo-sync-${name}.lock"
  local current_branch actual_origin upstream

  if [[ "$pull_only" != true ]]; then
    echo
    log "Starting: $name"
  fi

  if [[ ! -d "$repo" ]]; then
    log "FAILED: folder not found: $repo"
    return 1
  fi

  if [[ ! -d "$repo/.git" ]]; then
    log "FAILED: not a Git repository: $repo"
    return 1
  fi

  current_branch=$(git -C "$repo" branch --show-current 2>/dev/null || true)
  if [[ -n "$expected_branch" && "$current_branch" != "$expected_branch" ]]; then
    log "FAILED: $name is on ${current_branch:-detached}; expected $expected_branch."
    return 1
  fi

  actual_origin=$(git -C "$repo" remote get-url origin 2>/dev/null || true)
  if [[ -n "$expected_origin" && "$actual_origin" != "$expected_origin" ]]; then
    log "FAILED: $name origin differs from the managed repository registry."
    return 1
  fi

  upstream=$(git -C "$repo" rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || true)
  if [[ -n "$expected_branch" && "$upstream" != "origin/$expected_branch" ]]; then
    log "FAILED: $name tracks ${upstream:-no upstream}; expected origin/$expected_branch."
    return 1
  fi

  # This lock is machine-local, so it prevents overlapping maintenance jobs
  # without adding synchronization files to iCloud.
  if ! mkdir "$lock_dir" 2>/dev/null; then
    log "FAILED: another local sync appears to be running for $name."
    return 1
  fi

  (
    trap 'rmdir "$lock_dir" 2>/dev/null || true' EXIT

    cd "$repo" || exit 1

    if [[ "$pull_only" == true ]]; then
      # Never let user Git configuration introduce autostashing or recursion.
      for operation in MERGE_HEAD CHERRY_PICK_HEAD REVERT_HEAD rebase-merge rebase-apply sequencer; do
        if [[ -e "$(git rev-parse --git-path "$operation")" ]]; then
          log "FAILED: $name has an unfinished Git operation."
          exit 1
        fi
      done
      local unmerged_entries working_tree_status local_tip upstream_tip
      unmerged_entries=$(git ls-files --unmerged) || exit 1
      if [[ -n "$unmerged_entries" ]]; then
        log "FAILED: $name has unresolved index conflicts."
        exit 1
      fi
      git -c fetch.recurseSubmodules=false fetch --quiet origin || exit 1
      if ! git merge-base --is-ancestor HEAD '@{u}'; then
        log "FAILED: $name has unpublished or divergent commits; resolve before arrival."
        exit 1
      fi
      local_tip=$(git rev-parse HEAD) || exit 1
      upstream_tip=$(git rev-parse '@{u}') || exit 1
      # iCloud may deliver edits while fetching, so inspect the tree afterward.
      working_tree_status=$(git status --porcelain --untracked-files=normal --ignore-submodules=none) || exit 1
      if [[ "$local_tip" == "$upstream_tip" ]]; then
        if [[ -n "$working_tree_status" ]]; then
          printf 'OK     %s: published history current; local edits preserved\n' "$name"
        else
          printf 'OK     %s: published history current\n' "$name"
        fi
        exit 0
      fi
      if [[ -n "$working_tree_status" ]]; then
        log "DEFERRED: $name has remote updates and local edits; leaving files and commits unchanged."
        log "Arrival can continue using current files; reconcile the remote updates at the next daily snapshot or an intentional infra save."
        exit 3
      fi
      git -c merge.autostash=false -c submodule.recurse=false merge --quiet --ff-only '@{u}' || exit 1
      printf 'OK     %s: fast-forwarded to %s\n' "$name" "${upstream_tip[1,12]}"
      exit 0
    fi

    if ! git add -A; then
      log "FAILED: could not stage local changes in $name."
      exit 1
    fi

    if git diff --cached --quiet --exit-code; then
      log "No local changes to commit in $name."
    else
      git commit -m "$name snapshot on $(hostname -s) at $(date '+%Y-%m-%d %H:%M:%S')" ||
        exit 1
    fi

    pull_rebase "$name" || exit 1

    if ! git push; then
      # Another Mac may have pushed after our pull. Integrate once and retry;
      # persistent failures still stop safely and are reported to the caller.
      log "Push did not succeed for $name; rebasing and retrying once."
      pull_rebase "$name" || exit 1
      git push || exit 1
    fi
  ) || exit_code=$?

  if [[ "$pull_only" == true && $exit_code -eq 3 ]]; then
    (( deferred_repo_count += 1 ))
    return 0
  elif [[ $exit_code -eq 0 ]]; then
    if [[ "$pull_only" != true ]]; then
      log "Finished: $name (ok)"
    fi
  else
    log "FAILED: $name (exit $exit_code)"
  fi

  return $exit_code
}

if [[ "$pull_only" != true ]]; then
  log "===== Git repository synchronization started. ====="
fi

overall_exit_code=0
deferred_repo_count=0

for entry in "${REPOS[@]}"; do
  if ! sync_repo "$entry"; then
    overall_exit_code=1
  fi
done

if [[ $overall_exit_code -eq 0 ]]; then
  if [[ "$pull_only" == true && $deferred_repo_count -gt 0 ]]; then
    print -P "%B%F{yellow}Infrastructure refresh completed; $deferred_repo_count pull(s) deferred to preserve local edits. Arrival can continue.%f%b"
  elif [[ "$pull_only" != true ]]; then
    print -P "%B%F{green}All configured Git repositories synchronized.%f%b"
  fi
else
  print -P "%B%F{red}One or more Git repositories failed to synchronize.%f%b"
fi

if [[ "$pull_only" != true ]]; then
  log "===== Git repository synchronization finished. ====="
fi

exit $overall_exit_code
