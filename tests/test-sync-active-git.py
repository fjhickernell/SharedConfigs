"""Exercise Git selection without touching managed repositories or the network."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / 'bin/sync-active.sh'
GIT = shutil.which('git')


class GitSelectionTests(unittest.TestCase):
    def test_path_git_synchronizes_local_repository(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            remote = root / 'remote.git'
            checkout = root / 'checkout'
            subprocess.run([GIT, 'init', '--bare', str(remote)], check=True, capture_output=True)
            subprocess.run([GIT, 'clone', str(remote), str(checkout)], check=True, capture_output=True)
            subprocess.run([GIT, '-C', str(checkout), '-c', 'user.name=Test',
                            '-c', 'user.email=test@example.com', 'commit', '--allow-empty',
                            '-m', 'Fixture'], check=True, capture_output=True)
            subprocess.run([GIT, '-C', str(checkout), 'push', '-u', 'origin', 'HEAD'],
                           check=True, capture_output=True)
            registry = root / 'registry'
            registry.write_text(f'Fixture\t{checkout}\t{remote}\n')
            wrapper_dir = root / 'bin'
            wrapper_dir.mkdir()
            calls = root / 'calls'
            wrapper = wrapper_dir / 'git'
            wrapper.write_text('#!/bin/sh\nprintf "%s\\n" "$*" >> "$TEST_GIT_CALLS"\n'
                               'exec "$TEST_REAL_GIT" "$@"\n')
            wrapper.chmod(0o755)
            env = dict(os.environ, PATH=f'{wrapper_dir}:{os.environ["PATH"]}',
                       SYNC_ACTIVE_REGISTRY_FILE=str(registry), TEST_GIT_CALLS=str(calls),
                       TEST_REAL_GIT=GIT)
            result = subprocess.run(['zsh', str(SCRIPT)], env=env, capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertIn('SUCCESS: all repos already in sync', result.stdout)
            invoked = calls.read_text()
            self.assertIn('--version', invoked)
            self.assertIn('rev-parse --is-inside-work-tree', invoked)
            self.assertIn('fetch', invoked)

    def test_unusable_git_reports_cause_before_repository_work(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            wrapper = root / 'git'
            wrapper.write_text('#!/bin/sh\necho "Xcode license unavailable" >&2\nexit 69\n')
            wrapper.chmod(0o755)
            env = dict(os.environ, PATH=f'{root}:{os.environ["PATH"]}',
                       SYNC_ACTIVE_REGISTRY_FILE=str(root / 'nonexistent-registry'))
            result = subprocess.run(['zsh', str(SCRIPT)], env=env, capture_output=True, text=True)
            self.assertEqual(result.returncode, 2)
            self.assertIn('Git is unavailable:', result.stderr)
            self.assertIn('Xcode license unavailable', result.stderr)
            self.assertNotIn('not a Git repository', result.stderr)
            self.assertNotIn('cannot read registry', result.stderr)


if __name__ == '__main__':
    unittest.main()
