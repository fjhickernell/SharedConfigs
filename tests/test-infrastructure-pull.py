#!/usr/bin/env python3
"""Exercise pull-only safety against isolated local Git remotes."""
import os
from pathlib import Path
import shutil
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
        return result.stdout

    def local_state(self):
        return {
            'head': self.git('-C', str(self.local), 'rev-parse', 'HEAD'),
            'index': self.git('-C', str(self.local), 'ls-files', '--stage'),
            'status': self.git('-C', str(self.local), 'status', '--porcelain', '--untracked-files=all'),
            'files': {p.name: p.read_bytes() for p in self.local.iterdir() if p.is_file()},
            'stashes': self.git('-C', str(self.local), 'stash', 'list'),
        }

    def add_mixed_local_edits(self):
        (self.local / 'file').write_text('unstaged dashboard edit')
        (self.local / 'staged').write_text('staged version')
        self.git('-C', str(self.local), 'add', 'staged')
        (self.local / 'staged').write_text('later unstaged version')
        (self.local / 'untracked').write_text('untracked note')

    def assert_deferred(self):
        before = self.local_state()
        remote_head = self.git('--git-dir', str(self.remote), 'rev-parse', 'main')
        output = self.run_pull(True)
        self.assertIn('DEFERRED:', output)
        self.assertIn('1 pull(s) deferred', output)
        self.assertNotIn('All configured Git repositories synchronized.', output)
        self.assertEqual(self.local_state(), before)
        self.assertEqual(self.git('-C', str(self.local), 'rev-parse', 'origin/main'), remote_head)
        self.assertEqual(self.git('--git-dir', str(self.remote), 'rev-parse', 'main'), remote_head)

    def test_fast_forward_and_repeat(self):
        self.commit(self.seed, 'remote update')
        self.git('-C', str(self.seed), 'push')
        output = self.run_pull(True)
        remote_head = self.git('--git-dir', str(self.remote), 'rev-parse', 'main')
        self.assertEqual(output.splitlines(), [f'OK     Fixture: fast-forwarded to {remote_head[:12]}'])
        self.assertEqual((self.local / 'file').read_text(), 'remote update')
        output = self.run_pull(True)
        self.assertEqual(output.splitlines(), ['OK     Fixture: published history current'])

    def test_dirty_preserved(self):
        self.add_mixed_local_edits()
        before = self.local_state()
        output = self.run_pull(True)
        self.assertEqual(output.splitlines(), ['OK     Fixture: published history current; local edits preserved'])
        self.assertNotIn('DEFERRED:', output)
        self.assertEqual(self.local_state(), before)

    def test_dirty_behind_deferred_without_autostash(self):
        self.add_mixed_local_edits()
        self.git('-C', str(self.local), 'config', 'merge.autostash', 'true')
        self.commit(self.seed, 'overlapping remote edit')
        self.git('-C', str(self.seed), 'push')
        self.assert_deferred()

    def test_unrelated_staged_change_deferred(self):
        (self.local / 'staged').write_text('keep staged')
        self.git('-C', str(self.local), 'add', 'staged')
        self.commit(self.seed, 'remote update')
        self.git('-C', str(self.seed), 'push')
        self.assert_deferred()

    def test_hidden_untracked_collision_deferred(self):
        (self.local / 'note').write_text('local note')
        self.git('-C', str(self.local), 'config', 'status.showUntrackedFiles', 'no')
        (self.seed / 'note').write_text('remote note')
        self.git('-C', str(self.seed), 'add', 'note')
        self.git('-C', str(self.seed), 'commit', '-m', 'remote note')
        self.git('-C', str(self.seed), 'push')
        self.assert_deferred()

    def test_deleted_file_deferred(self):
        (self.local / 'file').unlink()
        self.commit(self.seed, 'remote update')
        self.git('-C', str(self.seed), 'push')
        self.assert_deferred()

    def test_unmerged_index_without_merge_head_rejected(self):
        blob = self.git('-C', str(self.local), 'rev-parse', 'HEAD:file')
        self.git('-C', str(self.local), 'update-index', '--force-remove', 'file')
        subprocess.run(
            ['git', '-C', str(self.local), 'update-index', '--index-info'],
            input=f'100644 {blob} 1\tfile\n100644 {blob} 2\tfile\n100644 {blob} 3\tfile\n',
            text=True, check=True, capture_output=True,
        )
        self.assertFalse((self.local / '.git/MERGE_HEAD').exists())
        before = self.local_state()
        output = self.run_pull(False)
        self.assertIn('unresolved index conflicts', output)
        self.assertEqual(self.local_state(), before)

    def test_unfinished_operation_rejected(self):
        (self.local / '.git/sequencer').mkdir()
        before = self.local_state()
        output = self.run_pull(False)
        self.assertIn('unfinished Git operation', output)
        self.assertEqual(self.local_state(), before)

    def test_fetch_failure_preserves_dirty_tree(self):
        self.add_mixed_local_edits()
        before = self.local_state()
        self.remote.rename(self.root / 'offline.git')
        self.run_pull(False)
        self.assertEqual(self.local_state(), before)

    def test_ahead_and_divergence_preserved(self):
        self.commit(self.local, 'local update')
        self.add_mixed_local_edits()
        before = self.local_state()
        self.run_pull(False)
        self.commit(self.seed, 'remote update')
        self.git('-C', str(self.seed), 'push')
        self.run_pull(False)
        self.assertEqual(self.local_state(), before)
        self.assertEqual(self.git('--git-dir', str(self.remote), 'rev-parse', 'main'), self.git('-C', str(self.seed), 'rev-parse', 'HEAD'))

    def test_wrong_branch(self):
        self.git('-C', str(self.local), 'checkout', '-b', 'other')
        self.run_pull(False)

    def test_wrong_origin(self):
        self.git('-C', str(self.local), 'remote', 'set-url', 'origin', str(self.seed))
        self.run_pull(False)

    def test_wrong_upstream(self):
        self.git('-C', str(self.local), 'branch', '--unset-upstream')
        self.run_pull(False)

    def test_arrive_continues_after_deferred_pull(self):
        self.add_mixed_local_edits()
        self.commit(self.seed, 'remote update')
        self.git('-C', str(self.seed), 'push')
        before = self.local_state()
        fixture_bin = self.root / 'bin'
        fixture_bin.mkdir()
        for name in ['arrive.sh', 'git-repo-sync.sh', 'repo-sweep']:
            shutil.copy2(SCRIPT.parent / name, fixture_bin / name)
        for name in ['sync-dev.sh', 'sync-active.sh', 'pr-status']:
            stub = fixture_bin / name
            stub.write_text(f'#!/bin/sh\necho "RAN {name}"\n')
            stub.chmod(0o755)
        (fixture_bin / 'project-sync-check.py').write_text('print("RAN project check")\n')
        env = dict(self.env, PATH=str(fixture_bin) + os.pathsep + os.environ['PATH'])
        result = subprocess.run(['zsh', '-f', str(fixture_bin / 'arrive.sh')], env=env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('1 pull(s) deferred', result.stdout)
        for name in ['sync-dev.sh', 'sync-active.sh', 'project check', 'pr-status']:
            self.assertIn(f'RAN {name}', result.stdout)
        self.assertEqual(self.local_state(), before)

if __name__ == '__main__':
    unittest.main()
