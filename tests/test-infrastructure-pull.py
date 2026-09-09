#!/usr/bin/env python3
"""Exercise pull-only safety against isolated local Git remotes."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / 'bin/git-repo-sync.sh'

class PullTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.remote = self.root / 'remote.git'
        self.seed = self.root / 'seed'
        self.local = self.root / 'local'
        self.git('init', '--bare', '--initial-branch=main', str(self.remote))
        self.git('clone', str(self.remote), str(self.seed))
        self.configure(self.seed)
        self.commit(self.seed, 'initial')
        self.git('-C', str(self.seed), 'push', '-u', 'origin', 'main')
        self.git('clone', str(self.remote), str(self.local))
        self.configure(self.local)
        self.registry = self.root / 'registry'
        self.registry.write_text(f'current|infrastructure|Fixture|{self.local}|main|{self.remote}\n')
        self.env = dict(os.environ, REPOSITORY_REGISTRY_FILE=str(self.registry), TMPDIR=str(self.root))

    def git(self, *args):
        return subprocess.run(['git', *args], check=True, capture_output=True, text=True).stdout.strip()

    def configure(self, repo):
        self.git('-C', str(repo), 'config', 'user.name', 'Fixture')
        self.git('-C', str(repo), 'config', 'user.email', 'fixture@example.invalid')

    def commit(self, repo, content):
        (repo / 'file').write_text(content)
        self.git('-C', str(repo), 'add', 'file')
        self.git('-C', str(repo), 'commit', '-m', content)

    def run_pull(self, success):
        result = subprocess.run(['zsh', '-f', str(SCRIPT), '--pull-only'], env=self.env, capture_output=True, text=True)
        self.assertEqual(result.returncode == 0, success, result.stdout + result.stderr)
        self.assertFalse((self.root / 'git-repo-sync-Fixture.lock').exists())

    def test_fast_forward_and_repeat(self):
        self.commit(self.seed, 'remote update')
        self.git('-C', str(self.seed), 'push')
        self.run_pull(True)
        self.assertEqual((self.local / 'file').read_text(), 'remote update')
        self.run_pull(True)

    def test_dirty_preserved(self):
        (self.local / 'untracked').write_text('keep')
        before = self.git('-C', str(self.local), 'rev-parse', 'HEAD')
        self.run_pull(False)
        self.assertEqual(self.git('-C', str(self.local), 'rev-parse', 'HEAD'), before)
        self.assertEqual(self.git('-C', str(self.local), 'status', '--porcelain'), '?? untracked')

    def test_ahead_and_divergence_preserved(self):
        self.commit(self.local, 'local update')
        before = self.git('-C', str(self.local), 'rev-parse', 'HEAD')
        self.run_pull(False)
        self.commit(self.seed, 'remote update')
        self.git('-C', str(self.seed), 'push')
        self.run_pull(False)
        self.assertEqual(self.git('-C', str(self.local), 'rev-parse', 'HEAD'), before)
        self.assertEqual(self.git('--git-dir', str(self.remote), 'rev-parse', 'main'), self.git('-C', str(self.seed), 'rev-parse', 'HEAD'))

    def test_wrong_branch(self):
        self.git('-C', str(self.local), 'checkout', '-b', 'other')
        self.run_pull(False)

if __name__ == '__main__':
    unittest.main()
