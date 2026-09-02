#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
shared_root="$(CDPATH= cd -- "${script_dir}/.." && pwd -P)"
audit="${shared_root}/bin/sharedconfigs-audit"
vault_audit="${shared_root}/bin/vault-links-audit"

test_root="$(mktemp -d "${TMPDIR:-/tmp}/sharedconfigs-audit-test.XXXXXX")"
test_root="$(CDPATH= cd -- "$test_root" && pwd -P)"
trap 'rm -rf "$test_root"' EXIT

fixture_root="${test_root}/SharedConfigs"
fixture_home="${test_root}/home"
fixture_vault="${test_root}/vault"
manifest="${test_root}/managed-links.conf"
vault_manifest="${test_root}/vault-links.conf"
output="${test_root}/output.txt"

mkdir -p \
  "${fixture_root}/source directory" \
  "${fixture_root}/settings" \
  "${fixture_home}" \
  "${fixture_vault}/inside" \
  "${fixture_home}/external"
printf 'shared file\n' > "${fixture_root}/settings/shared.conf"
printf 'external file\n' > "${fixture_home}/external/reference.md"
printf 'vault file\n' > "${fixture_vault}/inside/source.md"

write_manifest() {
  printf '%s\n' \
    'shared-file|core|file|required|all|settings/shared.conf|.config/shared.conf' \
    'shared-directory|core|directory|required|all|source directory|Library/Application Support/Shared Directory' \
    > "$manifest"
}

write_vault_manifest() {
  printf '%s\n' \
    'external-reference|file|home|external/reference.md|Reference/external.md' \
    'internal-reference|file|vault|inside/source.md|Reference/internal.md' \
    > "$vault_manifest"
}

fail() {
  echo "FAIL: $*" >&2
  [[ -f "$output" ]] && sed -n '1,240p' "$output" >&2
  exit 1
}

run_audit() {
  local expected_status="$1"
  local expected_text="$2"
  shift 2

  set +e
  "$audit" \
    --root "$fixture_root" \
    --home "$fixture_home" \
    --manifest "$manifest" \
    --links-only \
    "$@" > "$output" 2>&1
  local actual_status=$?
  set -e

  [[ "$actual_status" -eq "$expected_status" ]] ||
    fail "expected shared audit exit ${expected_status}, got ${actual_status}"
  grep -Fq -- "$expected_text" "$output" ||
    fail "shared audit output did not contain: ${expected_text}"
}

run_vault_audit() {
  local expected_status="$1"
  local expected_text="$2"
  shift 2

  set +e
  "$vault_audit" \
    --root "$fixture_root" \
    --home "$fixture_home" \
    --vault "$fixture_vault" \
    --manifest "$vault_manifest" \
    "$@" > "$output" 2>&1
  local actual_status=$?
  set -e

  [[ "$actual_status" -eq "$expected_status" ]] ||
    fail "expected vault audit exit ${expected_status}, got ${actual_status}"
  grep -Fq -- "$expected_text" "$output" ||
    fail "vault audit output did not contain: ${expected_text}"
}

write_manifest

# Missing destinations are reported, and explicit repair creates both kinds of
# links. A second repair is idempotent and creates no backups.
run_audit 1 'MISSING shared-file:'
[[ ! -e "${fixture_home}/.config" ]] || fail 'read-only audit created a destination parent'
run_audit 0 'REPAIRED: 2 managed link(s).' --repair
[[ -L "${fixture_home}/.config/shared.conf" ]] || fail 'file link was not created'
[[ -L "${fixture_home}/Library/Application Support/Shared Directory" ]] ||
  fail 'directory link was not created'
[[ "${fixture_root}/settings/shared.conf" -ef "${fixture_home}/.config/shared.conf" ]] ||
  fail 'file link resolves to the wrong source'
[[ "${fixture_root}/source directory" -ef "${fixture_home}/Library/Application Support/Shared Directory" ]] ||
  fail 'directory link resolves to the wrong source'
run_audit 0 'OK: 2 managed link(s)' --repair
if find "$fixture_home" -name '*.backup-*' -print -quit | grep -q .; then
  fail 'idempotent repair created a backup'
fi

# A regular destination is preserved before being replaced.
rm "${fixture_home}/.config/shared.conf"
printf 'local value\n' > "${fixture_home}/.config/shared.conf"
run_audit 1 'NOT-SYMLINK shared-file:'
grep -Fq 'local value' "${fixture_home}/.config/shared.conf" || fail 'read-only audit changed a regular destination'
run_audit 0 'REPAIRED shared-file:' --repair --group core
backup_file="$(find "${fixture_home}/.config" -maxdepth 1 -name 'shared.conf.backup-*' -print -quit)"
[[ -n "$backup_file" ]] || fail 'regular destination was not backed up'
grep -Fq 'local value' "$backup_file" || fail 'backup did not preserve regular destination'

# Wrong and dangling symlinks have distinct audit states and are repairable.
wrong_source="${test_root}/wrong.conf"
printf 'wrong\n' > "$wrong_source"
rm "${fixture_home}/.config/shared.conf"
ln -s "$wrong_source" "${fixture_home}/.config/shared.conf"
run_audit 1 'WRONG-TARGET shared-file:'
run_audit 0 'REPAIRED shared-file:' --repair
rm "${fixture_home}/.config/shared.conf"
ln -s "${test_root}/does-not-exist" "${fixture_home}/.config/shared.conf"
run_audit 1 'BROKEN shared-file:'
run_audit 0 'REPAIRED shared-file:' --repair

# A relative link to the right source is accepted by resolved identity.
rm "${fixture_home}/.config/shared.conf"
ln -s '../../SharedConfigs/settings/shared.conf' "${fixture_home}/.config/shared.conf"
run_audit 0 'OK: 2 managed link(s)'

# Repair preflights every selected source and makes no partial changes.
printf '%s\n' \
  'valid|guard|file|required|all|settings/shared.conf|guard/valid.conf' \
  'missing|guard|file|required|all|settings/missing.conf|guard/missing.conf' \
  > "$manifest"
mkdir -p "${fixture_home}/guard"
printf 'preserve\n' > "${fixture_home}/guard/valid.conf"
run_audit 1 'Repair aborted before making changes' --repair --group guard
[[ ! -L "${fixture_home}/guard/valid.conf" ]] || fail 'failed preflight changed a valid destination'
grep -Fq 'preserve' "${fixture_home}/guard/valid.conf" || fail 'failed preflight damaged a destination'

# Unsafe and duplicate manifest entries are invocation errors, never repairs.
printf '%s\n' 'unsafe|core|file|required|all|../outside|target' > "$manifest"
run_audit 2 'MANIFEST-ERROR'
printf '%s\n' \
  'one|core|file|required|all|settings/shared.conf|duplicate' \
  'two|core|file|required|all|settings/shared.conf|duplicate' \
  > "$manifest"
run_audit 2 'duplicate destination'

# Group selection changes only the selected group.
printf '%s\n' \
  'one|first|file|required|all|settings/shared.conf|groups/one' \
  'two|second|file|required|all|settings/shared.conf|groups/two' \
  > "$manifest"
run_audit 0 'REPAIRED: 1 managed link(s).' --repair --group first
[[ -L "${fixture_home}/groups/one" ]] || fail 'selected group was not repaired'
[[ ! -e "${fixture_home}/groups/two" ]] || fail 'unselected group was changed'

# Optional entries are advisory during audit and require explicit inclusion in
# repair mode.
printf '%s\n' \
  'optional-file|optional|file|optional|all|settings/shared.conf|optional/shared.conf' \
  > "$manifest"
run_audit 0 'OPTIONAL-MISSING optional-file:'
run_audit 0 'SKIP optional-file: optional entry' --repair
[[ ! -e "${fixture_home}/optional/shared.conf" ]] || fail 'default repair changed an optional entry'
run_audit 0 'REPAIRED optional-file:' --repair --include-optional
[[ -L "${fixture_home}/optional/shared.conf" ]] || fail 'included optional entry was not repaired'

# Machine selectors use the local preferred short name and skip other Macs.
printf '%s\n' \
  '# Codex machine identity' \
  '- Full identity: Fixture Mac' \
  '- Preferred short name: M5' \
  > "${fixture_home}/.codex-machine.md"
printf '%s\n' \
  'm3-only|machines|file|required|M3|settings/shared.conf|machines/m3.conf' \
  'm5-only|machines|file|required|M5|settings/shared.conf|machines/m5.conf' \
  > "$manifest"
run_audit 0 'REPAIRED: 1 managed link(s).' --repair --all
[[ ! -e "${fixture_home}/machines/m3.conf" ]] || fail 'repair changed another machine entry'
[[ -L "${fixture_home}/machines/m5.conf" ]] || fail 'repair skipped the current machine entry'
rm "${fixture_home}/.codex-machine.md"
run_audit 2 'MACHINE-IDENTITY-ERROR:'
printf '%s\n' \
  '# Codex machine identity' \
  '- Full identity: Fixture Mac' \
  '- Preferred short name: M5' \
  > "${fixture_home}/.codex-machine.md"

# A local exemption is visible and prevents both audit failure and repair.
exemptions="${test_root}/exemptions.conf"
printf '%s\n' 'exempt-file|kept local for fixture' > "$exemptions"
printf '%s\n' \
  'exempt-file|exempt|file|required|all|settings/shared.conf|exempt/shared.conf' \
  > "$manifest"
mkdir -p "${fixture_home}/exempt"
printf 'local exempt value\n' > "${fixture_home}/exempt/shared.conf"
run_audit 0 'EXEMPT exempt-file: kept local for fixture' --exemptions "$exemptions"
run_audit 0 'EXEMPT exempt-file: kept local for fixture' --repair --exemptions "$exemptions"
[[ ! -L "${fixture_home}/exempt/shared.conf" ]] || fail 'repair changed an exempt entry'
grep -Fq 'local exempt value' "${fixture_home}/exempt/shared.conf" || fail 'exempt file was damaged'

# Broad home containers and destinations overlapping the source repository are
# rejected as manifest errors before repair.
mkdir -p "${fixture_home}/Documents"
printf 'untouched\n' > "${fixture_home}/Documents/sentinel.txt"
printf '%s\n' \
  'broad|danger|directory|required|all|source directory|Documents' \
  > "$manifest"
run_audit 2 'protected or overlapping destination: Documents' --repair
grep -Fq 'untouched' "${fixture_home}/Documents/sentinel.txt" || fail 'broad destination guard damaged Documents'

overlap_root="${fixture_home}/Documents/SharedConfigs"
mkdir -p "${overlap_root}/settings"
printf 'overlap source\n' > "${overlap_root}/settings/shared.conf"
printf '%s\n' \
  'overlap|danger|directory|required|all|settings|Documents/SharedConfigs' \
  > "${overlap_root}/manifest.conf"
set +e
"$audit" \
  --root "$overlap_root" \
  --home "$fixture_home" \
  --manifest "${overlap_root}/manifest.conf" \
  --links-only \
  --repair > "$output" 2>&1
overlap_status=$?
set -e
[[ "$overlap_status" -eq 2 ]] || fail 'repository-overlap destination was not rejected'
grep -Fq 'protected or overlapping destination: Documents/SharedConfigs' "$output" ||
  fail 'repository-overlap guard was not reported'
[[ -f "${overlap_root}/settings/shared.conf" ]] || fail 'repository-overlap guard damaged the source'

printf '%s\n' \
  'parent|danger|directory|required|all|source directory|.config/nested' \
  'child|danger|file|required|all|settings/shared.conf|.config/nested/shared.conf' \
  > "$manifest"
run_audit 2 'overlapping destinations: .config/nested and .config/nested/shared.conf' --repair
[[ ! -e "${fixture_home}/.config/nested" ]] || fail 'overlapping destinations changed the home fixture'

escape_root="${test_root}/outside-home"
mkdir -p "$escape_root"
ln -s "$escape_root" "${fixture_home}/redirect"
printf '%s\n' \
  'escaped|danger|file|required|all|settings/shared.conf|redirect/shared.conf' \
  > "$manifest"
run_audit 2 'destination resolves outside the audited home:' --repair
[[ ! -e "${escape_root}/shared.conf" ]] || fail 'symlinked-parent guard wrote outside the home fixture'

mkdir -p "${fixture_home}/canonical-parent"
ln -s "${fixture_home}/canonical-parent" "${fixture_home}/canonical-alias"
printf '%s\n' \
  'canonical-one|danger|file|required|all|settings/shared.conf|canonical-parent/shared.conf' \
  'canonical-two|danger|file|required|all|settings/shared.conf|canonical-alias/shared.conf' \
  > "$manifest"
run_audit 2 'canonical destination overlaps canonical-one' --repair
[[ ! -e "${fixture_home}/canonical-parent/shared.conf" ]] ||
  fail 'canonical destination collision changed the home fixture'

# A failed link command restores the displaced path instead of leaving only a
# backup. PATH injection is confined to this disposable fixture.
printf '%s\n' 'rollback|rollback|file|required|all|settings/shared.conf|rollback/shared.conf' > "$manifest"
mkdir -p "${fixture_home}/rollback" "${test_root}/fake-bin"
printf 'original value\n' > "${fixture_home}/rollback/shared.conf"
printf '#!/bin/sh\nexit 1\n' > "${test_root}/fake-bin/ln"
chmod 755 "${test_root}/fake-bin/ln"
set +e
PATH="${test_root}/fake-bin:${PATH}" "$audit" \
  --root "$fixture_root" \
  --home "$fixture_home" \
  --manifest "$manifest" \
  --links-only \
  --repair > "$output" 2>&1
rollback_status=$?
set -e
[[ "$rollback_status" -eq 1 ]] || fail 'forced link failure returned the wrong status'
grep -Fq 'ROLLED-BACK rollback:' "$output" || fail 'failed repair did not report rollback'
[[ ! -L "${fixture_home}/rollback/shared.conf" ]] || fail 'rollback left a symlink in place'
grep -Fq 'original value' "${fixture_home}/rollback/shared.conf" ||
  fail 'rollback did not restore the displaced file'
if find "${fixture_home}/rollback" -name 'shared.conf.backup-*' -print -quit | grep -q .; then
  fail 'successful rollback left an unnecessary backup'
fi

# An interrupt after ln has created the new link but before the parent records
# success also removes that link and restores the original.
printf '%s\n' 'interrupt|interrupt|file|required|all|settings/shared.conf|interrupt/shared.conf' > "$manifest"
mkdir -p "${fixture_home}/interrupt" "${test_root}/interrupt-bin"
printf 'interrupt original\n' > "${fixture_home}/interrupt/shared.conf"
printf '%s\n' \
  '#!/bin/sh' \
  '/bin/ln "$@"' \
  'kill -TERM "$PPID"' \
  'exit 0' \
  > "${test_root}/interrupt-bin/ln"
chmod 755 "${test_root}/interrupt-bin/ln"
set +e
PATH="${test_root}/interrupt-bin:${PATH}" "$audit" \
  --root "$fixture_root" \
  --home "$fixture_home" \
  --manifest "$manifest" \
  --links-only \
  --repair > "$output" 2>&1
interrupt_status=$?
set -e
[[ "$interrupt_status" -eq 130 ]] || fail 'interrupted repair returned the wrong status'
grep -Fq 'Repair interrupted; restoring the active entry.' "$output" ||
  fail 'interrupted repair did not report restoration'
[[ ! -L "${fixture_home}/interrupt/shared.conf" ]] || fail 'interrupted repair left a symlink'
grep -Fq 'interrupt original' "${fixture_home}/interrupt/shared.conf" ||
  fail 'interrupted repair did not restore the original'

# Vault auditing requires portable relative links and catches absent entries.
write_vault_manifest
mkdir -p "${fixture_vault}/Reference"
ln -s '../../home/external/reference.md' "${fixture_vault}/Reference/external.md"
ln -s '../inside/source.md' "${fixture_vault}/Reference/internal.md"
run_vault_audit 0 'OK: 2 vault link(s).'

rm "${fixture_vault}/Reference/external.md"
run_vault_audit 1 'MISSING external-reference:'
ln -s "${fixture_home}/external/reference.md" "${fixture_vault}/Reference/external.md"
run_vault_audit 1 'ABSOLUTE-TARGET external-reference:'
rm "${fixture_vault}/Reference/external.md"
ln -s '../inside/source.md' "${fixture_vault}/Reference/external.md"
run_vault_audit 1 'WRONG-TARGET external-reference:'
rm "${fixture_vault}/Reference/external.md"
ln -s '../nowhere.md' "${fixture_vault}/Reference/external.md"
run_vault_audit 1 'BROKEN external-reference:'

printf '%s\n' \
  'missing-source|file|home|external/missing.md|Reference/missing.md' \
  > "$vault_manifest"
run_vault_audit 1 'SOURCE-MISSING missing-source:'
printf '%s\n' \
  'wrong-source-type|directory|home|external/reference.md|Reference/type.md' \
  > "$vault_manifest"
run_vault_audit 1 'SOURCE-TYPE wrong-source-type:'
printf '%s\n' \
  'unsafe|file|home|../outside|Reference/unsafe.md' \
  > "$vault_manifest"
run_vault_audit 2 'MANIFEST-ERROR'

# The semantic Zsh check rejects a global chruby activation and accepts the
# same clean-startup fixture once the activation is removed.
pin_home="${test_root}/pin-home"
pin_root="${pin_home}/Documents/SharedConfigs"
pin_manifest="${test_root}/pin-managed-links.conf"
mkdir -p "${pin_root}/bin" "${pin_root}/settings/zsh" "$pin_home"
printf '#!/bin/sh\nexit 0\n' > "${pin_root}/bin/repo-sweep"
printf '#!/bin/sh\nexit 0\n' > "${pin_root}/bin/git-repo-sync.sh"
printf '#!/bin/sh\necho "ruby fixture"\n' > "${pin_root}/bin/ruby"
chmod 755 \
  "${pin_root}/bin/repo-sweep" \
  "${pin_root}/bin/git-repo-sync.sh" \
  "${pin_root}/bin/ruby"
printf '%s\n' 'export PATH="$HOME/Documents/SharedConfigs/bin:$PATH"' \
  > "${pin_root}/settings/zsh/zshenv"
printf '%s\n' '# fixture zprofile' > "${pin_root}/settings/zsh/zprofile"
printf '%s\n' \
  'arrive() { return 0; }' \
  'depart() { return 0; }' \
  'chruby ruby-3.4.1' \
  > "${pin_root}/settings/zsh/zshrc"
printf '%s\n' \
  'zshenv|zsh|file|required|all|settings/zsh/zshenv|.zshenv' \
  'zprofile|zsh|file|required|all|settings/zsh/zprofile|.zprofile' \
  'zshrc|zsh|file|required|all|settings/zsh/zshrc|.zshrc' \
  > "$pin_manifest"
"$audit" --root "$pin_root" --home "$pin_home" --manifest "$pin_manifest" \
  --links-only --repair > "$output" 2>&1 || fail 'could not create Zsh pin fixture links'
set +e
"$audit" --root "$pin_root" --home "$pin_home" --manifest "$pin_manifest" \
  --group zsh > "$output" 2>&1
pin_status=$?
set -e
[[ "$pin_status" -eq 1 ]] || fail 'global chruby pin did not fail the semantic audit'
grep -Fq 'ZSH-RUBY-PIN' "$output" || fail 'global chruby pin was not identified'

printf '%s\n' \
  'arrive() { return 0; }' \
  'depart() { return 0; }' \
  > "${pin_root}/settings/zsh/zshrc"
"$audit" --root "$pin_root" --home "$pin_home" --manifest "$pin_manifest" \
  --group zsh --all > "$output" 2>&1 || fail 'pin-free Zsh fixture did not pass'
grep -Fq 'OK zsh-ruby: no global chruby version activation' "$output" ||
  fail 'pin-free Zsh result was not reported'

# The checked-in manifests themselves must parse successfully. Missing fixture
# destinations are expected, so status 1 proves parsing reached the audit.
set +e
"$audit" \
  --root "$shared_root" \
  --home "$fixture_home" \
  --manifest "${shared_root}/settings/managed-links.conf" \
  --links-only > "$output" 2>&1
checked_manifest_status=$?
set -e
[[ "$checked_manifest_status" -eq 1 ]] || fail 'checked-in managed-link manifest did not parse'
grep -Fq 'MISSING texmf:' "$output" || fail 'checked-in manifest audit did not run'

# The Starship compatibility helper validates help and bad arguments before it
# can invoke Homebrew or repair anything.
"${shared_root}/bin/setup-starship.sh" --help > "$output" 2>&1 ||
  fail 'setup-starship help failed'
grep -Fq 'Usage: setup-starship.sh' "$output" || fail 'setup-starship help was incomplete'
set +e
"${shared_root}/bin/setup-starship.sh" --not-an-option > "$output" 2>&1
starship_usage_status=$?
set -e
[[ "$starship_usage_status" -eq 2 ]] || fail 'setup-starship invalid option returned the wrong status'
grep -Fq 'accepts no arguments' "$output" || fail 'setup-starship invalid option was not explained'

echo 'PASS: shared configuration and vault link audits'
