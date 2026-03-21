#!/usr/bin/env zsh
set -euo pipefail

usage() {
  cat <<'EOF'
sync-class.sh [--promote] [--commit] [--push] [--quiet|--verbose] [--health]

Default (no flags):
  - Pull standalone repos
  - Pull class repos
  - Enforce pinned submodule SHAs (--checkout)
  - No commits, no pushes
  - Concise output (one line per repo)

Flags:
  --promote   Advance submodules to tip (runs update-submodules.sh from PATH)
  --commit    If submodule pointers changed, commit them in each class repo
  --push      Implies --commit and --promote; push the pointer commits
  --quiet     Print only SKIP/WARN/ERROR and final verdict
  --verbose   Print extra details (git status, pin OK line, etc.)
  --health    Run repo-health summary (also enabled by --verbose)
EOF
}

if [[ -t 1 ]]; then
  BOLD=$'\e[1m'
  RED=$'\e[31m'
  YELLOW=$'\e[33m'
  GREEN=$'\e[32m'
  RESET=$'\e[0m'
else
  BOLD=''; RED=''; YELLOW=''; GREEN=''; RESET=''
fi

SKIP_COUNT=0
UPDATE_COUNT=0
ERROR_COUNT=0

QUIET=0
VERBOSE=0
DO_HEALTH=0
do_promote=0
do_commit=0
do_push=0

log() {
  local ts
  ts=$(/bin/date '+%Y-%m-%d %H:%M:%S')
  echo "[$ts] $*"
}

info() { [[ "${QUIET}" -eq 0 ]] && log "$*"; }
vinfo() { [[ "${VERBOSE}" -eq 1 && "${QUIET}" -eq 0 ]] && log "$*"; }
ok() { [[ "${QUIET}" -eq 0 ]] && log "${GREEN}$*${RESET}"; }
warn() { log "${BOLD}${YELLOW}$*${RESET}"; }
skip() { SKIP_COUNT=$((SKIP_COUNT + 1)); log "${BOLD}${RED}$*${RESET}"; }
err() { ERROR_COUNT=$((ERROR_COUNT + 1)); log "${BOLD}${RED}$*${RESET}" >&2; }

shortsha() {
  local s="$1"
  echo "${s:0:12}"
}

verbose_git_status_sb() {
  if [[ "${VERBOSE}" -eq 1 && "${QUIET}" -eq 0 ]]; then
    /usr/bin/git status -sb || true
  fi
  return 0
}

verbose_git_status_short() {
  if [[ "${VERBOSE}" -eq 1 && "${QUIET}" -eq 0 ]]; then
    /usr/bin/git status --short || true
  fi
  return 0
}

is_clean() {
  [[ -z "$(/usr/bin/git status --porcelain)" ]]
}

has_upstream() {
  /usr/bin/git rev-parse --quiet --verify '@{u}' >/dev/null 2>&1
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
  /usr/bin/git -c fetch.recurseSubmodules=no fetch origin >/dev/null 2>&1 || {
    warn "WARNING fetch failed (non-fatal)"
    return 0
  }

  if has_upstream; then
    /usr/bin/git merge --ff-only '@{u}' >/dev/null 2>&1 || {
      warn "WARNING ff-only merge failed (non-fatal)"
      return 0
    }
  else
    warn "WARNING no upstream configured (skipping ff-only merge)"
  fi

  return 0
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
  local name="${repo##*/}"

  if [[ ! -d "${repo}/.git" && ! -f "${repo}/.git" ]]; then
    skip "SKIP   ${name}: not a git repo"
    return 0
  fi

  (
    cd "${repo}"

    if ! is_clean; then
      skip "SKIP   ${name}: dirty working tree"
      verbose_git_status_sb
      return 0
    fi

    if [[ "${name}" == "QMCSoftware" ]]; then
      ensure_qmcsoftware_fetch_policy "${repo}"
    fi

    local old new count
    old=$(/usr/bin/git rev-parse HEAD)

    /usr/bin/git checkout "${branch}" >/dev/null 2>&1 || /usr/bin/git switch "${branch}" >/dev/null 2>&1 || {
      err "ERROR  ${name}: cannot switch to ${branch}"
      return 1
    }

    pull_ff_only

    new=$(/usr/bin/git rev-parse HEAD)

    if [[ "${old}" != "${new}" ]]; then
      count=$(/usr/bin/git rev-list --count "${old}..${new}" 2>/dev/null || echo "?")
      UPDATE_COUNT=$((UPDATE_COUNT + 1))
      ok "UPDATED ${name} (${branch}) +${count} -> $(shortsha "${new}")"
    else
      info "OK     ${name} (${branch}) @ $(shortsha "${new}")"
    fi

    verbose_git_status_sb
    return 0
  )
}

push_if_ahead() {
  if has_upstream; then
    local ahead_count
    ahead_count=$(/usr/bin/git rev-list --count '@{u}..HEAD' 2>/dev/null || echo 0)
    if [[ "${ahead_count}" -gt 0 ]]; then
      /usr/bin/git push >/dev/null 2>&1 || {
        err "ERROR  push failed"
        echo "FAILED"
        return 0
      }
      echo "PUSHED"
      return 0
    fi
    echo "NOOP"
    return 0
  fi

  /usr/bin/git push >/dev/null 2>&1 || {
    err "ERROR  push failed (no upstream configured)"
    echo "FAILED"
    return 0
  }
  echo "PUSHED"
  return 0
}

promote_optional_test_archive() {
  if [[ -d "assets/tests/archive" ]]; then
    /usr/bin/git submodule update --init assets/tests/archive >/dev/null 2>&1 || warn "WARNING tests archive: submodule init failed"
    /usr/bin/git -C assets/tests/archive fetch origin main >/dev/null 2>&1 || warn "WARNING tests archive: fetch failed"
    /usr/bin/git -C assets/tests/archive checkout main >/dev/null 2>&1 || warn "WARNING tests archive: checkout failed"
    /usr/bin/git -C assets/tests/archive pull --ff-only origin main >/dev/null 2>&1 || warn "WARNING tests archive: pull failed"
  fi
  return 0
}

sync_class_repo() {
  local repo="$1"
  local do_promote="$2"
  local do_commit="$3"
  local do_push="$4"
  local name="${repo##*/}"

  if [[ ! -d "${repo}/.git" && ! -f "${repo}/.git" ]]; then
    skip "SKIP   ${name}: missing repo"
    return 0
  fi

  (
    cd "${repo}"

    if ! only_submodule_pointers_dirty; then
      skip "SKIP   ${name}: dirty (non-submodule changes)"
      verbose_git_status_short
      return 0
    fi

    local old new count
    old=$(/usr/bin/git rev-parse HEAD)
    pull_ff_only
    new=$(/usr/bin/git rev-parse HEAD)

    if [[ "${old}" != "${new}" ]]; then
      count=$(/usr/bin/git rev-list --count "${old}..${new}" 2>/dev/null || echo "?")
      UPDATE_COUNT=$((UPDATE_COUNT + 1))
      ok "UPDATED ${name}: pulled +${count} -> $(shortsha "${new}")"
    else
      if [[ "${do_promote}" -eq 1 ]]; then
        info "OK     ${name}: superproject already up to date @ $(shortsha "${new}")"
      else
        info "OK     ${name}: already up to date @ $(shortsha "${new}")"
      fi
    fi

    if [[ "${do_promote}" -eq 1 ]]; then
      if command -v update-submodules.sh >/dev/null 2>&1; then
        if ! update-submodules.sh >/dev/null 2>&1; then
          err "ERROR  ${name}: update-submodules.sh failed"
          return 1
        fi
      else
        skip "SKIP   ${name}: missing update-submodules.sh on PATH"
        return 0
      fi
      promote_optional_test_archive
    else
      /usr/bin/git submodule update --init --recursive --checkout >/dev/null 2>&1 || {
        err "ERROR  ${name}: submodule update failed"
        return 1
      }
    fi

    if [[ -d "qmcsoftware" ]]; then
      ensure_qmcsoftware_fetch_policy "${repo}/qmcsoftware"
    fi

    if ! is_clean; then
      if [[ "${do_commit}" -eq 1 ]]; then
        if only_submodule_pointers_dirty; then
          local cls_sha qmc_sha tst_sha have_tests tests_clause msg
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

          /usr/bin/git add classlib qmcsoftware .gitmodules >/dev/null 2>&1 || {
            err "ERROR  ${name}: git add failed"
            return 1
          }
          if [[ "${have_tests}" -eq 1 ]]; then
            /usr/bin/git add assets/tests/archive >/dev/null 2>&1 || true
          fi
          /usr/bin/git commit -m "${msg}" >/dev/null 2>&1 || {
            err "ERROR  ${name}: git commit failed"
            return 1
          }
          UPDATE_COUNT=$((UPDATE_COUNT + 1))
          ok "UPDATED ${name}: committed pointer update"
        else
          warn "WARNING ${name}: changes not limited to submodule pointers (not committing)"
          /usr/bin/git status --short || true
          return 0
        fi
      else
        warn "WARNING ${name}: uncommitted submodule pointer changes (run --commit or --push)"
        /usr/bin/git status --short || true
        return 0
      fi
    fi

    if [[ "${do_push}" -eq 1 ]]; then
      local result
      result="$(push_if_ahead)"
      if [[ "${result}" == "PUSHED" ]]; then
        ok "UPDATED ${name}: pushed"
      elif [[ "${result}" == "FAILED" ]]; then
        return 1
      else
        vinfo "OK     ${name}: nothing to push"
      fi
    fi

    verbose_git_status_sb
    return 0
  )
}

pins_consistency_check() {
  local repo repo_name
  local ref_repo ref_classlib ref_qmc ref_tests
  local mismatch=0

  typeset -A classlib_sha qmc_sha tests_sha

  is_full_sha() {
    local v="$1"
    [[ ${v} =~ ^[0-9A-Fa-f]{40}$ ]]
  }

  short_or_tag() {
    local v="$1"
    if [[ -z "$v" ]]; then
      echo "-"
    elif is_full_sha "$v"; then
      echo "${v:0:12}"
    else
      echo "$v"
    fi
  }

  for repo in "${CLASS_REPOS[@]}"; do
    repo_name="${repo##*/}"
    if [[ ! -d "${repo}/.git" && ! -f "${repo}/.git" ]]; then
      classlib_sha[$repo_name]="NO_REPO"
      qmc_sha[$repo_name]="NO_REPO"
      tests_sha[$repo_name]="NO_REPO"
      continue
    fi

    classlib_sha[$repo_name]=$(/usr/bin/git -C "${repo}" rev-parse HEAD:classlib 2>/dev/null || echo "MISSING")
    qmc_sha[$repo_name]=$(/usr/bin/git -C "${repo}" rev-parse HEAD:qmcsoftware 2>/dev/null || echo "MISSING")

    if /usr/bin/git -C "${repo}" ls-files --stage -- assets/tests/archive 2>/dev/null | awk '{print $1}' | grep -qx '160000'; then
      tests_sha[$repo_name]=$(/usr/bin/git -C "${repo}" rev-parse HEAD:assets/tests/archive 2>/dev/null || echo "MISSING")
    else
      tests_sha[$repo_name]="-"
    fi
  done

  ref_repo=""
  ref_classlib=""
  ref_qmc=""
  ref_tests=""

  for repo in "${CLASS_REPOS[@]}"; do
    repo_name="${repo##*/}"
    if is_full_sha "${classlib_sha[$repo_name]}" && is_full_sha "${qmc_sha[$repo_name]}"; then
      ref_repo="${repo_name}"
      ref_classlib="${classlib_sha[$repo_name]}"
      ref_qmc="${qmc_sha[$repo_name]}"
      if is_full_sha "${tests_sha[$repo_name]}"; then
        ref_tests="${tests_sha[$repo_name]}"
      fi
      break
    fi
  done

  if [[ -z "${ref_repo}" ]]; then
    warn "WARNING: cannot determine reference submodule pins"
    return 0
  fi

  for repo in "${CLASS_REPOS[@]}"; do
    repo_name="${repo##*/}"

    [[ "${classlib_sha[$repo_name]}" != "${ref_classlib}" ]] && mismatch=1
    [[ "${qmc_sha[$repo_name]}" != "${ref_qmc}" ]] && mismatch=1

    if [[ -n "${ref_tests}" ]]; then
      if [[ "${tests_sha[$repo_name]}" != "-" && "${tests_sha[$repo_name]}" != "NO_REPO" && "${tests_sha[$repo_name]}" != "MISSING" ]]; then
        [[ "${tests_sha[$repo_name]}" != "${ref_tests}" ]] && mismatch=1
      fi
    fi
  done

  printf "%-20s  %-12s  %-12s  %-12s\n" "repo" "classlib" "qmcsoftware" "tests-archive"
  for repo in "${CLASS_REPOS[@]}"; do
    repo_name="${repo##*/}"

    test_display="$(short_or_tag "${tests_sha[$repo_name]}")"
    [[ -z "${test_display}" ]] && test_display="-"

    printf "%-20s  %-12s  %-12s  %-12s\n" \
      "${repo_name}" \
      "$(short_or_tag "${classlib_sha[$repo_name]}")" \
      "$(short_or_tag "${qmc_sha[$repo_name]}")" \
      "${test_display}"
  done

  if (( mismatch )); then
    warn "WARNING: submodule pins differ across class repos"
    warn "Reference: ${ref_repo} (classlib ${ref_classlib:0:12}, qmcsoftware ${ref_qmc:0:12}${ref_tests:+, tests ${ref_tests:0:12}})"
  else
    info "OK: classlib and qmcsoftware pins match across all repos"
    if [[ -n "${ref_tests}" ]]; then
      info "OK: tests archive pins match across repos that contain it"
    else
      info "OK: tests archive not present in reference repo (skipping check)"
    fi
  fi
}

health_summary() {
  local repo repo_name line
  if [[ "${DO_HEALTH}" -ne 1 && "${VERBOSE}" -ne 1 ]]; then
    return 0
  fi

  if ! command -v repo-health >/dev/null 2>&1; then
    warn "NOPE  repo-health not on PATH"
    return 0
  fi

  info "===== Repo health summary ====="
  for repo in "${CLASS_REPOS[@]}"; do
    repo_name="${repo##*/}"
    if [[ -d "${repo}/.git" || -f "${repo}/.git" ]]; then
      (
        cd "${repo}"
        line="$(repo-health --short 2>&1 || true)"
        [[ -n "${line}" ]] && echo "${line}" || warn "NOPE  ${repo_name}  repo-health produced no output"
      )
    else
      warn "NOPE  ${repo_name}  missing repo"
    fi
  done
}

final_verdict() {
  if [[ "${ERROR_COUNT}" -gt 0 ]]; then
    err "===== FAILED: ${ERROR_COUNT} error(s) ====="
    return 1
  fi
  if [[ "${SKIP_COUNT}" -gt 0 ]]; then
    skip "===== INCOMPLETE RUN: ${SKIP_COUNT} SKIP condition(s) ====="
    return 1
  fi
  if [[ "${UPDATE_COUNT}" -gt 0 ]]; then
    ok "===== SUCCESS: ${UPDATE_COUNT} update(s) applied ====="
    return 0
  fi
  ok "===== SUCCESS: all repos already in sync ====="
  return 0
}

for arg in "$@"; do
  case "${arg}" in
    --promote) do_promote=1 ;;
    --commit) do_commit=1 ;;
    --push) do_push=1 ;;
    --quiet) QUIET=1 ;;
    --verbose) VERBOSE=1 ;;
    --health) DO_HEALTH=1 ;;
    --help|-h) usage; exit 0 ;;
    *)
      err "ERROR: unknown argument: ${arg}"
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

# Order matters for pins_consistency_check:
# prefer a repo that includes assets/tests/archive so that submodule can be checked too.
CLASS_REPOS=(
  "$HOME/SoftwareRepositories/MATH476Spring2026"
  "$HOME/SoftwareRepositories/MATH563Spring2026"
  "$HOME/SoftwareRepositories/MATH565Fall2025"
  "$HOME/SoftwareRepositories/SIAMUQ26"
)

if [[ "${do_promote}" -eq 1 ]]; then
  info "===== Sync class started (PROMOTE) ====="
else
  info "===== Sync class started (PINNED) ====="
fi

for spec in "${STANDALONE_REPOS[@]}"; do
  repo="${spec%%:*}"
  branch="${spec##*:}"
  if ! sync_standalone_repo "${repo}" "${branch}"; then
    info "===== Sync class finished ====="
    exit 1
  fi
done

for repo in "${CLASS_REPOS[@]}"; do
  if ! sync_class_repo "${repo}" "${do_promote}" "${do_commit}" "${do_push}"; then
    info "===== Sync class finished ====="
    exit 1
  fi
done

pins_consistency_check || true
health_summary || true

if final_verdict; then
  info "===== Sync class finished ====="
  exit 0
else
  info "===== Sync class finished ====="
  exit 1
fi
