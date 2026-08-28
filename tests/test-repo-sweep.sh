#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
shared_root="$(CDPATH= cd -- "${script_dir}/.." && pwd -P)"
sweep="${shared_root}/bin/repo-sweep"

test_root="$(mktemp -d "${TMPDIR:-/tmp}/repo-sweep-test.XXXXXX")"
test_root="$(CDPATH= cd -- "$test_root" && pwd -P)"
trap 'rm -rf "$test_root"' EXIT

origin="${test_root}/origin.git"
repo="${test_root}/repo"
writer="${test_root}/writer"
worktree="${test_root}/feature-worktree"
registry="${test_root}/repositories.conf"
output="${test_root}/output.txt"

fail() {
  echo "FAIL: $*" >&2
  [[ -f "$output" ]] && sed -n '1,200p' "$output" >&2
  exit 1
}

expect_status() {
  local expected="$1"
  local pattern="$2"
  shift 2

  set +e
  REPOSITORY_REGISTRY_FILE="$registry" "$sweep" "$@" > "$output" 2>&1
  local actual=$?
  set -e

  [[ "$actual" -eq "$expected" ]] ||
    fail "expected exit ${expected}, got ${actual}: repo-sweep $*"
  if [[ -n "$pattern" ]] && ! grep -Fq -- "$pattern" "$output"; then
    fail "missing output pattern: ${pattern}"
  fi
}

write_registry() {
  printf '%s\n' \
    "current|active|Fixture|${repo}||${origin}" \
    "archived|dev|ArchivedFixture|${test_root}/archived|main|ignored" \
    > "$registry"
}

git init --bare -q "$origin"
git clone -q "$origin" "$repo" 2>/dev/null
git -C "$repo" config user.name "Repo Sweep Test"
git -C "$repo" config user.email "repo-sweep@example.invalid"
printf 'base\n' > "${repo}/base.txt"
git -C "$repo" add base.txt
git -C "$repo" commit -q -m "Initial commit"
git -C "$repo" branch -M main
git -C "$repo" push -q -u origin main
git --git-dir="$origin" symbolic-ref HEAD refs/heads/main

write_registry

expect_status 0 "OK: 1 managed repositories" --local
expect_status 0 "archived" --list
expect_status 2 "no current repositories" --local --group dev

# Each synchronization command must consume its own workflow rows from the
# shared registry. These runs operate only on the disposable local fixture.
printf '%s\n' "current|dev|Fixture|${repo}|main|${origin}" > "$registry"
REPOSITORY_REGISTRY_FILE="$registry" "${shared_root}/bin/sync-dev.sh" --quiet \
  > "$output" 2>&1 || fail "sync-dev registry integration failed"
[[ ! -s "$output" ]] || fail "sync-dev --quiet produced unexpected output"

REPOSITORY_REGISTRY_FILE="$registry" "${shared_root}/bin/sync-dev.sh" \
  > "$output" 2>&1 || fail "sync-dev current-state output failed"
grep -Fq "OK     Fixture (main): already current @" "$output" ||
  fail "sync-dev did not report an already-current repository clearly"

# Updated active repositories report the number of commits fast-forwarded.
sync_writer="${test_root}/sync-writer"
git clone -q "$origin" "$sync_writer"
git -C "$sync_writer" config user.name "Repo Sweep Test"
git -C "$sync_writer" config user.email "repo-sweep@example.invalid"
printf 'sync update\n' > "${sync_writer}/sync-update.txt"
git -C "$sync_writer" add sync-update.txt
git -C "$sync_writer" commit -q -m "Sync update"
git -C "$sync_writer" push -q
printf '%s\n' "current|active|Fixture|${repo}|main|${origin}" > "$registry"
REPOSITORY_REGISTRY_FILE="$registry" "${shared_root}/bin/sync-active.sh" \
  > "$output" 2>&1 || fail "sync-active update-count output failed"
grep -Fq "UPDATED Fixture: +1 ->" "$output" ||
  fail "sync-active did not report the fast-forward commit count"

# A current dev row is sufficient to bootstrap an absent canonical checkout.
dev_clone="${test_root}/dev-clone"
printf '%s\n' \
  "current|dev|CloneFixture|${dev_clone}|main|${origin}" > "$registry"
REPOSITORY_REGISTRY_FILE="$registry" "${shared_root}/bin/sync-dev.sh" --quiet \
  > "$output" 2>&1 || fail "sync-dev failed to clone an absent repository"
[[ ! -s "$output" ]] || fail "sync-dev clone produced output in quiet mode"
[[ -d "${dev_clone}/.git" ]] || fail "sync-dev did not create a Git checkout"
[[ "$(git -C "$dev_clone" branch --show-current)" == "main" ]] ||
  fail "sync-dev cloned the wrong branch"
[[ "$(git -C "$dev_clone" remote get-url origin)" == "$origin" ]] ||
  fail "sync-dev cloned from the wrong origin"

# Never overwrite a pre-existing non-Git path while bootstrapping a dev row.
nonrepo="${test_root}/nonrepo"
mkdir -p "$nonrepo"
printf 'preserve me\n' > "${nonrepo}/sentinel.txt"
printf '%s\n' \
  "current|dev|NonRepoFixture|${nonrepo}|main|${origin}" > "$registry"
set +e
REPOSITORY_REGISTRY_FILE="$registry" "${shared_root}/bin/sync-dev.sh" --quiet \
  > "$output" 2>&1
sync_dev_nonrepo_rc=$?
set -e
[[ "$sync_dev_nonrepo_rc" -ne 0 ]] ||
  fail "sync-dev accepted an existing non-Git path"
grep -Fq "path exists but is not a Git repository" "$output" ||
  fail "sync-dev did not explain the existing non-Git path"
[[ -f "${nonrepo}/sentinel.txt" ]] ||
  fail "sync-dev damaged an existing non-Git path"

printf '%s\n' "current|active|Fixture|${repo}||${origin}" > "$registry"
REPOSITORY_REGISTRY_FILE="$registry" "${shared_root}/bin/sync-active.sh" --quiet \
  > "$output" 2>&1 || fail "sync-active registry integration failed"

printf '%s\n' "current|infrastructure|Fixture|${repo}|main|${origin}" > "$registry"
REPOSITORY_REGISTRY_FILE="$registry" "${shared_root}/bin/git-repo-sync.sh" \
  > "$output" 2>&1 || fail "git-repo-sync registry integration failed"

# Infrastructure synchronization must refuse the wrong branch before staging.
git -C "$repo" switch -q -c wrong-infrastructure-branch
printf 'must remain untracked\n' > "${repo}/guard.txt"
before_guard_head="$(git -C "$repo" rev-parse HEAD)"
set +e
REPOSITORY_REGISTRY_FILE="$registry" "${shared_root}/bin/git-repo-sync.sh" \
  > "$output" 2>&1
guard_rc=$?
set -e
[[ "$guard_rc" -ne 0 ]] || fail "git-repo-sync accepted the wrong branch"
grep -Fq "expected main" "$output" || fail "wrong-branch guard was not reported"
[[ "$(git -C "$repo" rev-parse HEAD)" == "$before_guard_head" ]] ||
  fail "wrong-branch guard changed HEAD"
git -C "$repo" status --porcelain=v1 | grep -Fq '?? guard.txt' ||
  fail "wrong-branch guard staged or removed the untracked file"
rm -f "${repo}/guard.txt"
git -C "$repo" switch -q main
git -C "$repo" branch -D wrong-infrastructure-branch >/dev/null
write_registry

# A final row without a newline must still be parsed, while archived paths stay
# excluded from normal checks.
printf '%s' "current|active|Fixture|${repo}||${origin}" > "$registry"
expect_status 0 "OK: 1 managed repositories" --local
write_registry

printf 'dirty\n' > "${repo}/dirty.txt"
expect_status 1 "DIRTY working tree" --local
rm -f "${repo}/dirty.txt"

printf 'ahead\n' > "${repo}/ahead.txt"
git -C "$repo" add ahead.txt
git -C "$repo" commit -q -m "Local ahead commit"
expect_status 1 "CACHED-AHEAD canonical checkout" --local
git -C "$repo" push -q

git clone -q "$origin" "$writer"
git -C "$writer" config user.name "Repo Sweep Test"
git -C "$writer" config user.email "repo-sweep@example.invalid"
printf 'remote\n' > "${writer}/remote.txt"
git -C "$writer" add remote.txt
git -C "$writer" commit -q -m "Remote advance"
git -C "$writer" push -q
git -C "$repo" fetch -q origin
expect_status 1 "CACHED-BEHIND canonical checkout" --local
git -C "$repo" merge -q --ff-only '@{u}'

# Dormant task branches can retain unpublished work after their worktree is
# gone. Report unpublished commits, but ignore local aliases already reachable
# from a remote-tracking branch.
git -C "$repo" switch -q -c dormant-ahead
printf 'dormant ahead\n' > "${repo}/dormant-ahead.txt"
git -C "$repo" add dormant-ahead.txt
git -C "$repo" commit -q -m "Dormant branch ahead"
git -C "$repo" push -q -u origin dormant-ahead
printf 'unpushed dormant ahead\n' >> "${repo}/dormant-ahead.txt"
git -C "$repo" add dormant-ahead.txt
git -C "$repo" commit -q -m "Unpushed dormant branch commit"
git -C "$repo" switch -q main
expect_status 1 "CACHED-AHEAD dormant branch dormant-ahead" --local
expect_status 1 "AHEAD dormant branch dormant-ahead"

# A live remote deletion must not be hidden by the stale remote-tracking ref in
# this clone.
git -C "$repo" switch -q -c remote-deleted
printf 'remote deleted\n' > "${repo}/remote-deleted.txt"
git -C "$repo" add remote-deleted.txt
git -C "$repo" commit -q -m "Branch later deleted remotely"
git -C "$repo" push -q -u origin remote-deleted
git -C "$repo" switch -q main
git -C "$writer" push -q origin --delete remote-deleted
expect_status 1 "LOCAL-ONLY dormant branch remote-deleted (upstream origin/remote-deleted unavailable from origin)"
git -C "$repo" branch -D remote-deleted >/dev/null

git -C "$repo" switch -q -c local-only
printf 'local only\n' > "${repo}/local-only.txt"
git -C "$repo" add local-only.txt
git -C "$repo" commit -q -m "Local-only dormant branch"
git -C "$repo" switch -q main
expect_status 1 "LOCAL-ONLY dormant branch local-only" --local

git -C "$repo" branch remote-contained main
expect_status 1 "LOCAL-ONLY dormant branch local-only" --local
if grep -Fq "remote-contained" "$output"; then
  fail "remote-contained dormant branch was reported"
fi

git -C "$repo" branch -D dormant-ahead local-only remote-contained >/dev/null
git -C "$repo" push -q origin --delete dormant-ahead

# Git permits a pipe in a branch name, so branch parsing must use a delimiter
# that cannot occur in a ref name.
git -C "$repo" switch -q -c 'pipe|branch'
printf 'pipe branch\n' > "${repo}/pipe-branch.txt"
git -C "$repo" add pipe-branch.txt
git -C "$repo" commit -q -m "Local branch containing a pipe"
git -C "$repo" switch -q main
expect_status 1 "LOCAL-ONLY dormant branch pipe|branch" --local
git -C "$repo" branch -D 'pipe|branch' >/dev/null

# The default remote-aware sweep must not alter refs, the index, or files.
before_refs="$(git -C "$repo" show-ref)"
before_index="$(git hash-object "${repo}/.git/index")"
before_status="$(git -C "$repo" status --porcelain=v1 --untracked-files=normal)"
expect_status 0 "remote tips verified"
after_refs="$(git -C "$repo" show-ref)"
after_index="$(git hash-object "${repo}/.git/index")"
after_status="$(git -C "$repo" status --porcelain=v1 --untracked-files=normal)"
[[ "$before_refs" == "$after_refs" ]] || fail "repo-sweep changed Git refs"
[[ "$before_index" == "$after_index" ]] || fail "repo-sweep changed the Git index"
[[ "$before_status" == "$after_status" ]] || fail "repo-sweep changed the working tree"

# A linked Codex-style worktree needs its own fresh remote-tip check.
git -C "$repo" switch -q -c feature
git -C "$repo" push -q -u origin feature
git -C "$repo" switch -q main
git -C "$repo" worktree add -q "$worktree" feature
git -C "$writer" fetch -q origin
git -C "$writer" switch -q feature
printf 'feature remote\n' > "${writer}/feature-remote.txt"
git -C "$writer" add feature-remote.txt
git -C "$writer" commit -q -m "Advance feature remotely"
git -C "$writer" push -q
expect_status 1 "REMOTE-CHANGED worktree feature"

# Removing a linked worktree directory must not let its unpublished branch
# disappear from the dormant-branch check.
printf 'stale unpublished\n' > "${worktree}/stale-unpublished.txt"
git -C "$worktree" add stale-unpublished.txt
git -C "$worktree" commit -q -m "Unpublished commit in stale worktree"
rm -rf "$worktree"
expect_status 1 "STALE-WORKTREE ${worktree}" --local
expect_status 1 "CACHED-AHEAD dormant branch feature" --local

# Reusing the missing path for an unrelated Git repository must not make the
# original worktree look live or hide its unpublished branch.
git init -q "$worktree"
expect_status 1 "STALE-WORKTREE ${worktree} (path is invalid or reused)" --local
expect_status 1 "CACHED-AHEAD dormant branch feature" --local

# Missing paths, malformed rows, and duplicates are registry-level attention.
printf '%s\n' \
  "current|active|Missing|${test_root}/missing||${origin}" > "$registry"
expect_status 1 "MISSING repository" --local

printf '%s\n' \
  "curent|active|Fixture|${repo}||${origin}" > "$registry"
expect_status 2 "invalid registry status" --list

printf '%s\n' \
  "current|active|Fixture|${repo}||${origin}" \
  "archived|dev|Fixture|${test_root}/archived|main|ignored" > "$registry"
expect_status 2 "duplicate registry name" --list

printf '%s\n' \
  "current|active|Fixture|${repo}||${origin}" \
  "archived|dev|OtherFixture|${repo}|main|ignored" > "$registry"
expect_status 2 "duplicate registry path" --list

# Git inspection failures must never be presented as a clean repository.
printf '%s\n' "current|active|Fixture|${repo}||${origin}" > "$registry"
printf 'corrupt index\n' > "${repo}/.git/index"
expect_status 1 "STATUS-ERROR working tree" --local

echo "PASS: repo-sweep registry, state, remote, and worktree checks"
