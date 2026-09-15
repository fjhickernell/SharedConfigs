#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
shared_root="$(CDPATH= cd -- "${script_dir}/.." && pwd -P)"
audit="${shared_root}/bin/branch-audit"

test_root="$(mktemp -d "${TMPDIR:-/tmp}/branch-audit-test.XXXXXX")"
trap 'rm -rf "$test_root"' EXIT
origin="${test_root}/origin.git"
repo="${test_root}/repo"
writer="${test_root}/writer"
output="${test_root}/output.txt"

fail() {
  echo "FAIL: $*" >&2
  [[ -f "$output" ]] && sed -n '1,200p' "$output" >&2
  exit 1
}

run_expect() {
  local expected="$1"
  shift
  set +e
  "$audit" --repo "$repo" --no-pr "$@" > "$output" 2>&1
  local actual=$?
  set -e
  [[ "$actual" -eq "$expected" ]] ||
    fail "expected exit ${expected}, got ${actual}: branch-audit $*"
}

git init --bare -q "$origin"
git clone -q "$origin" "$repo" 2>/dev/null
git -C "$repo" config user.name "Branch Audit Test"
git -C "$repo" config user.email "branch-audit@example.invalid"
printf 'base\n' > "${repo}/base.txt"
git -C "$repo" add base.txt
git -C "$repo" commit -q -m "Initial commit"
git -C "$repo" branch -M main
git -C "$repo" push -q -u origin main
git --git-dir="$origin" symbolic-ref HEAD refs/heads/main

git -C "$repo" switch -q -c dormant
printf 'published\n' > "${repo}/feature.txt"
git -C "$repo" add feature.txt
git -C "$repo" commit -q -m "Published feature"
git -C "$repo" push -q -u origin dormant
printf 'unpublished\n' >> "${repo}/feature.txt"
git -C "$repo" add feature.txt
git -C "$repo" commit -q -m "Unpublished feature"
git -C "$repo" switch -q main

before_refs="$(git -C "$repo" show-ref)"
before_index="$(git hash-object "${repo}/.git/index")"
before_status="$(git -C "$repo" status --porcelain=v1 --untracked-files=normal)"
run_expect 1 dormant
grep -Fq "cached state: ahead 1" "$output" || fail "ahead state missing"
grep -Fq "0 equivalent, 1 apparently unique" "$output" ||
  fail "patch comparison missing"
grep -Fq "recommendation: preserve and inspect" "$output" ||
  fail "preservation recommendation missing"
grep -Fq "PR: not checked (--no-pr)" "$output" ||
  fail "PR lookup status missing"

after_refs="$(git -C "$repo" show-ref)"
after_index="$(git hash-object "${repo}/.git/index")"
after_status="$(git -C "$repo" status --porcelain=v1 --untracked-files=normal)"
[[ "$before_refs" == "$after_refs" ]] || fail "audit changed Git refs"
[[ "$before_index" == "$after_index" ]] || fail "audit changed the index"
[[ "$before_status" == "$after_status" ]] || fail "audit changed files"

git clone -q "$origin" "$writer"
git -C "$writer" config user.name "Branch Audit Test"
git -C "$writer" config user.email "branch-audit@example.invalid"
git -C "$writer" switch -q dormant
printf 'remote advance\n' >> "${writer}/feature.txt"
git -C "$writer" add feature.txt
git -C "$writer" commit -q -m "Remote feature"
git -C "$writer" push -q
git -C "$repo" fetch -q origin dormant

run_expect 1 dormant
grep -Fq "cached state: diverged (1 ahead, 1 behind)" "$output" ||
  fail "diverged state missing"

git -C "$repo" branch -D dormant >/dev/null

# A rebased remote branch can retain every local patch under different commit
# IDs. Distinguish that safe cleanup candidate from genuinely unique work.
git -C "$repo" switch -q -c superseded main
printf 'equivalent patch\n' > "${repo}/equivalent.txt"
git -C "$repo" add equivalent.txt
git -C "$repo" commit -q -m "Equivalent feature"
git -C "$repo" push -q -u origin superseded
git -C "$repo" switch -q main
git -C "$writer" fetch -q origin
git -C "$writer" switch -q main
printf 'new base\n' > "${writer}/new-base.txt"
git -C "$writer" add new-base.txt
git -C "$writer" commit -q -m "Advance main"
git -C "$writer" push -q origin main
git -C "$writer" switch -q -C superseded main
git -C "$writer" cherry-pick origin/superseded >/dev/null
git -C "$writer" push -q --force origin superseded
git -C "$repo" fetch -q origin superseded

run_expect 1 superseded
grep -Fq "1 equivalent, 0 apparently unique" "$output" ||
  fail "equivalent patch was not recognized"
grep -Fq "delete the obsolete local branch" "$output" ||
  fail "safe cleanup recommendation missing"

git -C "$repo" branch -D superseded >/dev/null
git -C "$repo" branch aligned origin/dormant >/dev/null
run_expect 0 --all
grep -Fq "BRANCH  aligned" "$output" || fail "--all omitted aligned branch"
grep -Fq "do not pull for hygiene" "$output" ||
  fail "behind/aligned guidance missing"

run_expect 2 missing-branch
grep -Fq "local branch not found: missing-branch" "$output" ||
  fail "missing branch error not reported"

echo "PASS: branch-audit classifications, guidance, and read-only behavior"
