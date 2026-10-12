#!/usr/bin/env python3
"""Check update ordering and failure handling without changing installed software."""
import os
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class BrewUpdateTests(unittest.TestCase):
    def run_workflow(self, script, fail_update=False, args=(), installed_tap=None,
                     architecture='arm64', bundle_cycle=False, with_mas=False,
                     fail_mas_upgrade=False, failed_steps=(), repo_root=False):
        with tempfile.TemporaryDirectory() as tmp:
            home = Path(tmp)
            config = home / 'Documents/SharedConfigs'
            scripts = config / 'bin'
            scripts.mkdir(parents=True)
            commands = home / 'commands'
            commands.mkdir()
            log = home / 'calls'
            if repo_root:
                (home / 'SoftwareRepositories').mkdir()
            if installed_tap is not None:
                metadata = home / 'casks/texstudio/.metadata'
                metadata.mkdir(parents=True)
                (metadata / 'INSTALL_RECEIPT.json').write_text(
                    json.dumps({'source': {'tap': installed_tap}}))
            for name in ('regular-maintenance.sh', 'sync-brew.sh', 'update-texstudio.sh'):
                shutil.copy2(ROOT / 'bin' / name, scripts / name)
            (config / 'Brewfile').write_text(
                'brew "node"\ncask "texstudio-org/texstudio/texstudio"\nnpm "browser-sync"\n'
                + ('mas "Listed app", id: 111\nmas "Missing app", id: 333\n'
                   if with_mas else ''))

            def command(name, body, directory=commands):
                target = directory / name
                target.write_text('#!/bin/sh\n' + body + '\n')
                target.chmod(0o755)

            command('brew', '''printf '%s|%s\n' "$*" "${HOMEBREW_NO_AUTO_UPDATE:-0}" >> "$CALL_LOG"
if [ "$1" = update ] && [ "${FAIL_UPDATE:-0}" = 1 ]; then exit 7; fi
if [ "$1" = --caskroom ]; then printf '%s\n' "$HOME/casks"; fi
if [ "$1" = bundle ] && [ "$2" = list ]; then
  case "$3" in --formula) echo node ;; --cask) echo texstudio-org/texstudio/texstudio ;; esac
elif [ "$1" = bundle ]; then
  printf 'bundle-formula-skip %s|1\n' "${HOMEBREW_BUNDLE_BREW_SKIP:-}" >> "$CALL_LOG"
  if [ "$TEST_MAS" = 1 ]; then
    printf 'bundle-mas-skip %s|1\n' "$HOMEBREW_BUNDLE_MAS_SKIP" >> "$CALL_LOG"
  fi
  if [ "$BUNDLE_CYCLE" = 1 ]; then
    echo 'Error: dependency graph sorting failed: circular dependency'
    exit 1
  fi
  printf '%s\n' 'Using texstudio'
fi
if [ "$1" = outdated ]; then
  case "$3" in
    --formula) printf '%s\n' node unlisted-formula ;;
    --cask) printf '%s\n' texstudio unlisted-cask ;;
  esac
fi''')
            command('sudo', 'if [ "$1" = -v ]; then exit 0; fi\nexec "$@"')
            command('uname', 'printf "%s\\n" "$TEST_ARCH"')
            if with_mas:
                command('mdutil', 'echo "Indexing enabled."')
                command('mas', '''printf 'mas %s|1\n' "$*" >> "$CALL_LOG"
case "$1" in
  list) printf '%s\n' '111 Listed app (1.0)' '222 Unlisted app (1.0)' '1528890965 TextSniper (1.0)' ;;
  outdated) printf '%s\n' '111 Listed app (1.0 -> 2.0)' '222 Unlisted app (1.0 -> 2.0)' '1528890965 TextSniper (1.0 -> 2.0)' ;;
  upgrade) [ "$FAIL_MAS_UPGRADE" != 1 ] ;;
esac''')
            def maintenance_stub(name, directory=commands):
                command(name,
                        f'printf "step {name}|1\\n" >> "$CALL_LOG"\n'
                        + ('exit 9' if name in failed_steps else 'exit 0'), directory)

            maintenance_stub('sync-active.sh')
            command('npm', 'printf "direct-npm|1\\n" >> "$CALL_LOG"')
            command('npm-globals-sync.sh',
                    'printf "npm-globals-sync|1\\n" >> "$CALL_LOG"', scripts)
            for name in ('update-texlive.sh', 'git-repo-sync.sh', 'sync-dev.sh'):
                maintenance_stub(name, scripts)
            env = os.environ.copy()
            for key in ('HOMEBREW_NO_AUTO_UPDATE', 'SYNC_BREW_SKIP_UPDATE',
                        'HOMEBREW_BUNDLE_MAS_SKIP', 'HOMEBREW_BUNDLE_BREW_SKIP'):
                env.pop(key, None)
            env.update(HOME=str(home), PATH=str(commands) + ':/usr/bin:/bin',
                       CALL_LOG=str(log), FAIL_UPDATE=str(int(fail_update)),
                       TEST_ARCH=architecture, BUNDLE_CYCLE=str(int(bundle_cycle)),
                       TEST_MAS=str(int(with_mas)),
                       FAIL_MAS_UPGRADE=str(int(fail_mas_upgrade)))
            result = subprocess.run(['/bin/zsh', str(scripts / script), *args],
                                    env=env, capture_output=True, text=True)
            calls = log.read_text().splitlines() if log.exists() else []
            return result, calls

    def assert_single_update(self, calls):
        self.assertEqual(sum(row.startswith('update|') for row in calls), 1)
        self.assertTrue(calls[0].startswith('update|'))
        self.assertTrue(all(row.endswith('|1') for row in calls[1:]), calls)

    def test_maintenance_updates_before_texstudio_and_bundle(self):
        result, calls = self.run_workflow('regular-maintenance.sh')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assert_single_update(calls)
        tap = next(i for i, row in enumerate(calls) if row.startswith('tap '))
        bundle = next(i for i, row in enumerate(calls) if row.startswith('bundle'))
        self.assertLess(tap, bundle)

    def test_failed_initial_update_stops_before_installs(self):
        result, calls = self.run_workflow('regular-maintenance.sh', fail_update=True)
        self.assertEqual(result.returncode, 7, result.stderr)
        self.assertEqual(calls, ['update|0'])

    def test_maintenance_collects_failures_and_continues(self):
        result, calls = self.run_workflow(
            'regular-maintenance.sh',
            failed_steps=('update-texlive.sh', 'git-repo-sync.sh'))
        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertIn('Needs attention: update-texlive (exit 9)', result.stdout)
        self.assertIn('Needs attention: git-repo-sync (exit 9)', result.stdout)
        self.assertIn('step sync-dev.sh|1', calls)
        self.assertIn('step sync-active.sh|1', calls)
        self.assertIn('finished with 2 failed step(s)', result.stdout)
        self.assertIn('(exit 1)', result.stdout)
        self.assertNotIn('run finished successfully', result.stdout)

    def test_failed_active_sync_handles_no_matching_class_folders(self):
        result, calls = self.run_workflow(
            'regular-maintenance.sh', failed_steps=('sync-active.sh',), repo_root=True)
        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertNotIn('no matches found', result.stderr)
        self.assertIn('Scan complete.', result.stdout)
        self.assertIn('Needs attention: sync-active (no-push) (exit 9)', result.stdout)
        self.assertIn('finished with 1 failed step(s)', result.stdout)

    def test_maintenance_leaves_npm_to_bundle(self):
        result, calls = self.run_workflow('regular-maintenance.sh')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(any(row.startswith('bundle') for row in calls), calls)
        self.assertFalse(any(row.startswith(('direct-npm|', 'npm-globals-sync|'))
                             for row in calls), calls)

    def test_maintenance_leaves_current_texstudio_upgrade_to_sync(self):
        result, calls = self.run_workflow(
            'regular-maintenance.sh', installed_tap='texstudio-org/texstudio')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(any(row.startswith('upgrade --cask texstudio-org/')
                             for row in calls), calls)
        self.assertTrue(any(row.startswith('bundle --file=') for row in calls), calls)

    def test_sync_upgrades_only_unlisted_packages_outside_bundle(self):
        result, calls = self.run_workflow('sync-brew.sh')
        self.assertEqual(result.returncode, 0, result.stderr)
        upgrades = [row.split('|')[0] for row in calls if row.startswith('upgrade')]
        self.assertEqual(upgrades, ['upgrade --formula unlisted-formula',
                                    'upgrade --cask unlisted-cask'])
        self.assertTrue(any(row.startswith('bundle --file=') for row in calls), calls)

    def test_intel_routine_still_defers_formulae(self):
        result, calls = self.run_workflow('sync-brew.sh', architecture='x86_64')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('upgrade --cask unlisted-cask|1', calls)
        self.assertFalse(any(row.startswith('upgrade --formula') for row in calls))
        self.assertFalse(any(row.startswith('outdated --quiet --formula') for row in calls))
        self.assertIn('bundle-formula-skip node|1', calls)
        # Normal Bundle upgrades npm and extensions; only formulae are skipped.
        self.assertTrue(any(row.startswith('bundle --file=') for row in calls))
        self.assertFalse(any(row.startswith('bundle --no-upgrade') for row in calls))

    def test_intel_full_uses_bundle_for_listed_upgrades(self):
        result, calls = self.run_workflow('sync-brew.sh', args=('--full',),
                                          architecture='x86_64')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('upgrade --formula unlisted-formula|1', calls)
        self.assertIn('bundle-formula-skip |1', calls)
        self.assertFalse(any(row.startswith('bundle --no-upgrade') for row in calls))

    def test_bundle_cycle_does_not_report_success(self):
        result, calls = self.run_workflow('sync-brew.sh', bundle_cycle=True)
        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertIn('listed package upgrades are not confirmed', result.stderr)
        self.assertNotIn('sync-brew completed successfully', result.stdout)

    def test_store_updates_have_one_owner_on_arm_and_intel(self):
        for architecture in ('arm64', 'x86_64'):
            with self.subTest(architecture=architecture):
                result, calls = self.run_workflow(
                    'sync-brew.sh', architecture=architecture, with_mas=True)
                self.assertEqual(result.returncode, 0, result.stderr)
                skip = next(row for row in calls if row.startswith('bundle-mas-skip '))
                skipped_ids = skip.split('|')[0].split()[1:]
                self.assertIn('111', skipped_ids)
                self.assertIn('222', skipped_ids)
                self.assertIn('1528890965', skipped_ids)
                self.assertNotIn('333', skipped_ids)
                self.assertEqual(calls.count('mas outdated|1'), 1)
                self.assertEqual([row for row in calls if row.startswith('mas upgrade')],
                                 ['mas upgrade 111 222|1'])

    def test_store_upgrade_failure_does_not_report_success(self):
        result, calls = self.run_workflow(
            'sync-brew.sh', with_mas=True, fail_mas_upgrade=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn('sync-brew completed successfully', result.stdout)

    def test_prepare_leaves_missing_texstudio_install_to_bundle(self):
        result, calls = self.run_workflow('update-texstudio.sh', args=('--prepare',))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(any(row.startswith(('install ', 'upgrade '))
                             for row in calls), calls)

    def test_standalone_texstudio_keeps_upgrade(self):
        result, calls = self.run_workflow(
            'update-texstudio.sh', installed_tap='texstudio-org/texstudio')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(any(row.startswith('upgrade --cask texstudio-org/')
                            for row in calls), calls)

    def test_standalone_sync_keeps_update(self):
        result, calls = self.run_workflow('sync-brew.sh')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assert_single_update(calls)

    def test_standalone_full_sync_keeps_update(self):
        result, calls = self.run_workflow('sync-brew.sh', args=('--full',))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assert_single_update(calls)


if __name__ == '__main__':
    unittest.main()
