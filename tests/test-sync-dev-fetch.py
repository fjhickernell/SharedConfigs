"""Verify single-fetch development sync against isolated local Git repositories."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / 'bin/sync-dev.sh'
GIT = shutil.which('git')


class DevFetchTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.remote = self.root / 'remote.git'
        self.author = self.root / 'author'
        self.checkout = self.root / 'checkout'
        self.git('init', '--bare', str(self.remote))
        self.git('init', '-b', 'develop', str(self.author))
        self.commit(self.author, 'Initial')
        self.git('-C', str(self.author), 'remote', 'add', 'origin', str(self.remote))
        self.git('-C', str(self.author), 'push', '-u', 'origin', 'develop')
        self.git('clone', '--branch', 'develop', str(self.remote), str(self.checkout))
        # The registry branch must still refresh with a different configured refspec.
        self.git('-C', str(self.checkout), 'config', 'remote.origin.fetch',
                 '+refs/heads/main:refs/remotes/origin/main')
        self.registry = self.root / 'registry'
        self.registry.write_text(
            f'current|dev|Fixture|{self.checkout}|develop|{self.remote}\n')
        commands = self.root / 'commands'
        commands.mkdir()
        self.calls = self.root / 'calls'
        wrapper = commands / 'git'
        wrapper.write_text('#!/bin/sh\nprintf "%s\\n" "$*" >> "$TEST_CALLS"\n'
                           'exec "$TEST_GIT" "$@"\n')
        wrapper.chmod(0o755)
        self.env = dict(os.environ, PATH=f'{commands}:{os.environ["PATH"]}',
                        REPOSITORY_REGISTRY_FILE=str(self.registry),
                        TEST_CALLS=str(self.calls), TEST_GIT=GIT)

    def git(self, *args):
        return subprocess.run([GIT, *args], check=True, capture_output=True,
                              text=True).stdout.strip()

    def commit(self, repo, message):
        self.git('-C', str(repo), '-c', 'user.name=Test',
                 '-c', 'user.email=test@example.com', '-c', 'commit.gpgsign=false',
                 'commit', '--allow-empty', '-m', message)

    def advance_remote(self):
        self.commit(self.author, 'Remote change')
        self.git('-C', str(self.author), 'push', 'origin', 'develop')

    def run_sync(self):
        return subprocess.run(['bash', str(SCRIPT)], env=self.env,
                              capture_output=True, text=True)

    def test_one_fetch_fast_forwards_even_with_narrow_refspec(self):
        self.advance_remote()
        result = self.run_sync()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(self.git('-C', str(self.checkout), 'rev-parse', 'HEAD'),
                         self.git('-C', str(self.author), 'rev-parse', 'HEAD'))
        calls = self.calls.read_text().splitlines()
        self.assertEqual(sum(' fetch ' in row for row in calls), 1)
        self.assertFalse(any(' pull ' in row for row in calls))

    def test_divergence_preserves_local_history(self):
        self.commit(self.checkout, 'Local change')
        original = self.git('-C', str(self.checkout), 'rev-parse', 'HEAD')
        self.advance_remote()
        result = self.run_sync()
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertIn('fast-forward update failed', result.stdout + result.stderr)
        self.assertEqual(self.git('-C', str(self.checkout), 'rev-parse', 'HEAD'), original)

    def test_failed_fetch_does_not_merge_stale_tip(self):
        shutil.rmtree(self.remote)
        original = self.git('-C', str(self.checkout), 'rev-parse', 'HEAD')
        result = self.run_sync()
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertIn('fetch failed', result.stdout + result.stderr)
        self.assertEqual(self.git('-C', str(self.checkout), 'rev-parse', 'HEAD'), original)
        self.assertFalse(any(' merge ' in row for row in self.calls.read_text().splitlines()))


if __name__ == '__main__':
    unittest.main()
