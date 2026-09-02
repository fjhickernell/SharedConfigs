#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
shared_root="$(CDPATH= cd -- "${script_dir}/.." && pwd -P)"
machine_audit="${shared_root}/bin/machine-audit"

test_root="$(mktemp -d "${TMPDIR:-/tmp}/machine-audit-test.XXXXXX")"
test_root="$(CDPATH= cd -- "$test_root" && pwd -P)"
trap 'rm -rf "$test_root"' EXIT

fixture_home="${test_root}/home"
fixture_root="${fixture_home}/Documents/SharedConfigs"
fixture_bin="${fixture_root}/bin"
fixture_vault="${test_root}/vault"
output="${test_root}/output.txt"

mkdir -p "$fixture_bin" "$fixture_vault"
printf '%s\n' \
  '# Codex machine identity' \
  '- Full identity: Fixture Mac' \
  '- Preferred short name: Fixture' \
  > "${fixture_home}/.codex-machine.md"
printf '%s\n' 'export PATH="$HOME/Documents/SharedConfigs/bin:$PATH"' \
  > "${fixture_home}/.zshenv"
printf '%s\n' 'export PATH="$HOME/Documents/SharedConfigs/bin:$PATH"' \
  > "${fixture_home}/.zprofile"

printf '%s\n' \
  '#!/bin/sh' \
  'exit "${SHARED_STUB_STATUS:-0}"' \
  > "${fixture_bin}/sharedconfigs-audit"
printf '%s\n' \
  '#!/bin/sh' \
  'exit "${VAULT_STUB_STATUS:-0}"' \
  > "${fixture_bin}/vault-links-audit"
printf '%s\n' \
  '#!/bin/sh' \
  'exit "${REPO_STUB_STATUS:-0}"' \
  > "${fixture_bin}/repo-sweep"

for command_name in git conda quarto starship git-repo-sync.sh arrive.sh depart.sh; do
  printf '#!/bin/sh\nexit 0\n' > "${fixture_bin}/${command_name}"
done
printf '%s\n' \
  '#!/bin/sh' \
  'if [ "${1:-}" = "--prefix" ] && [ "${2:-}" = "ruby" ]; then' \
  '  CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P' \
  '  exit 0' \
  'fi' \
  'if [ "${1:-}" = "bundle" ] && [ "${2:-}" = "check" ]; then' \
  '  exit "${BREW_STUB_STATUS:-0}"' \
  'fi' \
  'exit 0' \
  > "${fixture_bin}/brew"
printf '%s\n' \
  '#!/bin/sh' \
  'if [ -f "$HOME/ruby-fail" ]; then exit 9; fi' \
  'echo "ruby fixture 1.0"' \
  > "${fixture_bin}/ruby"
chmod 755 "${fixture_bin}"/*

fail() {
  echo "FAIL: $*" >&2
  [[ -f "$output" ]] && sed -n '1,260p' "$output" >&2
  exit 1
}

run_machine_audit() {
  local expected_status="$1"
  local expected_text="$2"
  shift 2

  set +e
  "$machine_audit" \
    --root "$fixture_root" \
    --home "$fixture_home" \
    --vault "$fixture_vault" \
    "$@" > "$output" 2>&1
  local actual_status=$?
  set -e

  [[ "$actual_status" -eq "$expected_status" ]] ||
    fail "expected machine audit exit ${expected_status}, got ${actual_status}"
  grep -Fq -- "$expected_text" "$output" ||
    fail "machine audit output did not contain: ${expected_text}"
}

run_machine_audit 0 'MACHINE AUDIT CLEAR' --configuration-only
export SHARED_STUB_STATUS=1
run_machine_audit 1 'MACHINE AUDIT NEEDS ATTENTION' --configuration-only
export SHARED_STUB_STATUS=7
run_machine_audit 2 'MACHINE AUDIT ERROR' --configuration-only
unset SHARED_STUB_STATUS
export VAULT_STUB_STATUS=9
run_machine_audit 2 'MACHINE AUDIT ERROR' --configuration-only
unset VAULT_STUB_STATUS
export REPO_STUB_STATUS=1
run_machine_audit 1 'MACHINE AUDIT NEEDS ATTENTION'
export REPO_STUB_STATUS=8
run_machine_audit 2 'MACHINE AUDIT ERROR'
unset REPO_STUB_STATUS
export BREW_STUB_STATUS=1
run_machine_audit 1 'Brewfile dependencies need attention' --full
unset BREW_STUB_STATUS

printf '%s\n' 'exit 42' > "${fixture_home}/.zprofile"
run_machine_audit 1 'COMMAND-PROBE-FAILED: clean login shell exited 42' --configuration-only
if grep -Fq 'COMMAND-MISSING' "$output"; then
  fail 'failed command probe was misreported as individual missing commands'
fi
printf '%s\n' 'export PATH="$HOME/Documents/SharedConfigs/bin:$PATH"' \
  > "${fixture_home}/.zprofile"

touch "${fixture_home}/ruby-fail"
run_machine_audit 1 'RUNTIME-FAILED ruby:' --configuration-only
rm "${fixture_home}/ruby-fail"

set +e
"$machine_audit" --not-an-option > "$output" 2>&1
usage_status=$?
set -e
[[ "$usage_status" -eq 2 ]] || fail 'invalid option did not return status 2'
grep -Fq 'unknown option' "$output" || fail 'invalid option was not explained'

echo 'PASS: machine-audit aggregation and runtime checks'
