#!/usr/bin/env zsh
set -euo pipefail

# ---- color + emphasis -------------------------------------------------
# Enable colors only if stdout is a TTY (so logs in files/CI stay clean)
if [[ -t 1 ]]; then
  BOLD=$'\e[1m'
  DIM=$'\e[2m'
  RED=$'\e[31m'
  YELLOW=$'\e[33m'
  GREEN=$'\e[32m'
  CYAN=$'\e[36m'
  RESET=$'\e[0m'
else
  BOLD=''
  DIM=''
  RED=''
  YELLOW=''
  GREEN=''
  CYAN=''
  RESET=''
fi

SKIP_COUNT=0

log() {
  local ts
  ts=$(/bin/date '+%Y-%m-%d %H:%M:%S')
  echo "[$ts] $*"
}

log_skip() {
  SKIP_COUNT=$((SKIP_COUNT + 1))
  log "${BOLD}${RED}$*${RESET}"
}

log_warn() {
  log "${BOLD}${YELLOW}$*${RESET}"
}

log_ok() {
  log "${GREEN}$*${RESET}"
}

is_clean() {
  [[ -z "$(/usr/bin/git status --porcelain)" ]]
}

path_is_tracked() {
  local p="$1"
  /usr/bin/git ls-files --error-unmatch "$p" >/dev/null 2>&1
}

only_submodule_pointers_dirty() {
  local ws line path allow_tests
  ws="$(/usr/bin/git status --porcelain)"
  [[ -z "${ws}" ]] && return 0

  allow_tests=0
  if path_is_tracked "assets/tests/archive"; then
    allow_tests=1
  fi

  while IFS= read -r line; do
    path="${line##* }"
    if [[ "${path}" == "classlib" || "${path}" == "qmcsoftware" || "${path}" == ".gitmodules" ]]; then
      continue
    fi
    if [[ "${allow_tests}" -eq 1 && "${path}" == "assets/tests/archive" ]]; then
      continue
    fi
    return 1
  done <<< "${ws}"

  return 0
}

pull_ff_only() {
  /usr/bin/git -c fetch.recurseSubmodules=no fetch origin
  /usr/bin/git merge --ff-only '@{u}'
}

ensure_qmcsoftware_fetch_policy() {
  local repo="$1"

  if [[ ! -d "${repo}/.git" && ! -f "${repo}/.git" ]]; then
    return 0
  fi

  (
    cd "${repo}"

    if ! /usr/bin/git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      return 0
    fi

    if /usr/bin/git remote get-url origin >/dev/null 2>&1; then
      /usr/bin/git config --unset-all remote.origin.fetch >/dev/null 2>&1 || true
      /usr/bin/git config --add remote.origin.fetch "+refs/heads/develop:refs/remotes/origin/develop"
      /usr/bin/git config --add remote.origin.fetch "+refs/tags/*:refs/tags/*"
      /usr/bin/git fetch --prune origin >/dev/null 2>&1 || true
    fi
  )
}

sync_standalone_repo() {
  local repo="$1"
  local branch="$2"

  log "Standalone repo: ${repo} (${branch})"
  if [[ ! -d "${repo}/.git" ]]; then
    log_skip "SKIP: not a git repo: ${repo}"
    return 0
  fi

  (
    cd "${repo}"

    if ! is_clean; then
      log_skip "SKIP: dirty working tree in ${repo}"
      /usr/bin/git status --short
      return 0
    fi

    if [[ "${repo##*/}" == "QMCSoftware" ]]; then
      ensure_qmcsoftware_fetch_policy "${repo}"
    fi

    /usr/bin/git checkout "${branch}"
    pull_ff_only
  )
}

push_if_ahead() {
  if /usr/bin/git rev-parse --quiet --verify '@{u}' >/dev/null 2>&1; then
    local ahead_count
    ahead_count=$(/usr/bin/git rev-list --count '@{u}..HEAD')
    if [[ "${ahead_count}" -gt 0 ]]; then
      /usr/bin/git push
    else
      log "No commits to push; skipping git push."
    fi
  else
    /usr/bin/git push
  fi
}

promote_optional_test_archive() {
  if [[ -d "assets/tests/archive" ]]; then
    /usr/bin/git submodule update --init assets/tests/archive
    /usr/bin/git -C assets/tests/archive fetch origin main
    /usr/bin/git -C assets/tests/archive checkout main
    /usr/bin/git -C assets/tests/archive pull --ff-only origin main
  fi
}

sync_class_repo() {
  local repo="$1"
  local do_promote="$2"
  local do_commit="$3"
  local do_push="$4"

  log "Class repo: ${repo}"
  if [[ ! -d "${repo}/.git" ]]; then
    log_skip "SKIP: not a git repo: ${repo}"
    return 0
  fi

  (
    cd "${repo}"

    if ! only_submodule_pointers_dirty; then
      log_skip "SKIP: dirty working tree (non-submodule changes) in ${repo}"
      /usr/bin/git status --short
      return 0
    fi

    pull_ff_only

    if [[ "${do_promote}" -eq 1 ]]; then
      if command -v update-submodules.sh >/dev/null 2>&1; then
        update-submodules.sh || true
      else
        log_skip "SKIP: missing update-submodules.sh on PATH in ${repo}"
        return 0
      fi
      promote_optional_test_archive
    else
      /usr/bin/git submodule update --init --recursive --checkout
    fi

    if [[ -d "qmcsoftware" ]]; then
      ensure_qmcsoftware_fetch_policy "${repo}/qmcsoftware"
    fi

    /usr/bin/git submodule status
    /usr/bin/git status --short

    if ! is_clean; then
      if [[ "${do_commit}" -eq 1 ]]; then
        if only_submodule_pointers_dirty; then
          local msg cls_sha qmc_sha tst_sha have_tests tests_clause
          cls_sha=""
          qmc_sha=""
          tst_sha=""
          have_tests=0
          tests_clause=""

          if [[ -d "classlib/.git" || -f "classlib/.git" ]]; then
            cls_sha=$(/usr/bin/git -C classlib rev-parse --short=12 HEAD 2>/dev/null || true)
          fi
          if [[ -d "qmcsoftware/.git" || -f "qmcsoftware/.git" ]]; then
            qmc_sha=$(/usr/bin/git -C qmcsoftware rev-parse --short=12 HEAD 2>/dev/null || true)
          fi

          if path_is_tracked "assets/tests/archive"; then
            have_tests=1
            if [[ -d "assets/tests/archive/.git" || -f "assets/tests/archive/.git" ]]; then
              tst_sha=$(/usr/bin/git -C assets/tests/archive rev-parse --short=12 HEAD 2>/dev/null || true)
            fi
            tests_clause=", tests ${tst_sha:-na}"
          fi

          msg="Update submodule pointers (classlib ${cls_sha:-na}, qmcsoftware ${qmc_sha:-na}${tests_clause})"

          /usr/bin/git add classlib qmcsoftware .gitmodules
          if [[ "${have_tests}" -eq 1 ]]; then
            /usr/bin/git add assets/tests/archive
          fi
          /usr/bin/git commit -m "${msg}"
        else
          log_skip "SKIP: changes present but not only submodule pointers; not committing"
          /usr/bin/git status --short
          return 0
        fi
      else
        log_warn "Uncommitted submodule pointer changes detected."
        log ""
        log "git status --short:"
        /usr/bin/git status --short
        log ""
        log "Run: sync-class.sh --commit   (or --push)"
        return 0
      fi
    fi

    if [[ "${do_push}" -eq 1 ]]; then
      push_if_ahead
    fi
  )
}

health_summary() {
  local repo repo_name line
  log "===== Repo health summary ====="

  if ! command -v repo-health >/dev/null 2>&1; then
    log_warn "NOPE  repo-health  not on PATH"
    return 0
  fi

  for repo in "${CLASS_REPOS[@]}"; do
    repo_name="${repo##*/}"
    if [[ -d "${repo}/.git" ]]; then
      (
        cd "${repo}"
        line="$(repo-health --short 2>&1 || true)"
        if [[ -z "${line}" ]]; then
          log_warn "NOPE  ${repo_name}  repo-health produced no output"
        else
          echo "${line}"
        fi
      )
    else
      log_warn "NOPE  ${repo_name}  missing repo"
    fi
  done
}

pins_consistency_check() {
  local repo repo_name
  local ref_repo ref_classlib ref_qmc
  local mismatch=0

  typeset -A classlib_sha qmc_sha

  is_full_sha() {
    local v="$1"
    [[ ${v} =~ ^[0-9A-Fa-f]{40}$ ]]
  }

  short_sha() {
    local v="$1"
    if is_full_sha "${v}"; then
      echo "${v:0:12}"
    else
      echo "${v}"
    fi
  }

  for repo in "${CLASS_REPOS[@]}"; do
    repo_name="${repo##*/}"

    if [[ ! -d "${repo}/.git" ]]; then
      classlib_sha[$repo_name]="NO_REPO"
      qmc_sha[$repo_name]="NO_REPO"
      continue
    fi

    classlib_sha[$repo_name]=$(/usr/bin/git -C "${repo}" rev-parse :classlib 2>/dev/null || echo "MISSING")
    qmc_sha[$repo_name]=$(/usr/bin/git -C "${repo}" rev-parse :qmcsoftware 2>/dev/null || echo "MISSING")
  done

  ref_repo=""
  ref_classlib=""
  ref_qmc=""

  for repo in "${CLASS_REPOS[@]}"; do
    repo_name="${repo##*/}"
    if is_full_sha "${classlib_sha[$repo_name]}" && is_full_sha "${qmc_sha[$repo_name]}"; then
      ref_repo="${repo_name}"
      ref_classlib="${classlib_sha[$repo_name]}"
      ref_qmc="${qmc_sha[$repo_name]}"
      break
    fi
  done

  if [[ -z "${ref_repo}" ]]; then
    log_warn "===== WARNING: cannot determine reference submodule pins ====="
    printf "%-20s  %-12s  %-12s\n" "repo" "classlib" "qmcsoftware"
    for repo in "${CLASS_REPOS[@]}"; do
      repo_name="${repo##*/}"
      printf "%-20s  %-12s  %-12s\n" \
        "${repo_name}" \
        "$(short_sha "${classlib_sha[$repo_name]}")" \
        "$(short_sha "${qmc_sha[$repo_name]}")"
    done
    return 0
  fi

  for repo in "${CLASS_REPOS[@]}"; do
    repo_name="${repo##*/}"
    [[ "${classlib_sha[$repo_name]}" != "${ref_classlib}" ]] && mismatch=1
    [[ "${qmc_sha[$repo_name]}" != "${ref_qmc}" ]] && mismatch=1
  done

  if (( mismatch )); then
    log_warn "===== WARNING: submodule pins differ across class repos ====="
    printf "%-20s  %-12s  %-12s\n" "repo" "classlib" "qmcsoftware"
    for repo in "${CLASS_REPOS[@]}"; do
      repo_name="${repo##*/}"
      printf "%-20s  %-12s  %-12s\n" \
        "${repo_name}" \
        "$(short_sha "${classlib_sha[$repo_name]}")" \
        "$(short_sha "${qmc_sha[$repo_name]}")"
    done
    log_warn "Reference: ${ref_repo} (classlib $(short_sha "${ref_classlib}"), qmcsoftware $(short_sha "${ref_qmc}"))"
  else
    log_ok "===== OK: submodule pins consistent across class repos (classlib $(short_sha "${ref_classlib}"), qmcsoftware $(short_sha "${ref_qmc}")) ====="
  fi
}

final_verdict() {
  if [[ "${SKIP_COUNT}" -gt 0 ]]; then
    log_skip "===== INCOMPLETE RUN: ${SKIP_COUNT} SKIP condition(s) encountered (see red SKIP lines above) ====="
  else
    log_ok "===== CLEAN DEPARTURE: no SKIP conditions encountered ====="
  fi
}

usage() {
  cat <<'EOF'
sync-class.sh

Default (no flags):
  - Pull standalone repos
  - Pull class repos
  - Enforce pinned submodule SHAs (--checkout)
  - No commits, no pushes

Flags:
  --promote   Advance submodules to tip (runs update-submodules.sh from PATH)
  --commit    If submodule pointers changed, commit them in each class repo
  --push      Implies --commit and --promote; push the pointer commits
EOF
}

do_promote=0
do_commit=0
do_push=0

for arg in "$@"; do
  case "${arg}" in
    --promote) do_promote=1 ;;
    --commit) do_commit=1 ;;
    --push) do_push=1 ;;
    --help|-h) usage; exit 0 ;;
    *)
      log_warn "ERROR: unknown argument: ${arg}"
      usage
      exit 2
      ;;
  esac
done

if [[ "${do_push}" -eq 1 ]]; then
  do_commit=1
  do_promote=1
fi

STANDALONE_REPOS=(
  "$HOME/SoftwareRepositories/HickernellClassLib:main"
  "$HOME/SoftwareRepositories/QMCSoftware:develop"
)

CLASS_REPOS=(
  "$HOME/SoftwareRepositories/MATH565Fall2025"
  "$HOME/SoftwareRepositories/MATH476Spring2026"
  "$HOME/SoftwareRepositories/MATH563Spring2026"
  "$HOME/SoftwareRepositories/SIAMUQ26"
)

if [[ "${do_promote}" -eq 1 ]]; then
  log "===== Sync class started (PROMOTE: advance submodules to tip) ====="
else
  log "===== Sync class started (PINNED: match class repo submodule SHAs) ====="
fi

for spec in "${STANDALONE_REPOS[@]}"; do
  repo="${spec%%:*}"
  branch="${spec##*:}"
  sync_standalone_repo "${repo}" "${branch}"
done

for repo in "${CLASS_REPOS[@]}"; do
  sync_class_repo "${repo}" "${do_promote}" "${do_commit}" "${do_push}"
done

pins_consistency_check || true
health_summary || true
final_verdict || true

log "===== Sync class finished ====="