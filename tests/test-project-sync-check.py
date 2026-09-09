import importlib.util
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
import os
import shutil

SCRIPT = Path(__file__).resolve().parents[1] / 'bin/project-sync-check.py'
spec = importlib.util.spec_from_file_location('project_check', SCRIPT)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)


class ProjectChecks(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)
        (self.home / 'repo').mkdir()
        self.manifest = {'version': 1, 'projects': [{'name': 'Project', 'roots': ['~/repo'], 'aliases': ['Old']}]}

    def test_portability(self):
        self.assertEqual(mod.portable(str(self.home / 'repo'), self.home), '~/repo')
        with self.assertRaises(ValueError):
            mod.portable('/different-user/repo', self.home)
        with self.assertRaises(ValueError):
            mod.local_path('~/../outside', self.home)

    def test_union_and_no_deletion(self):
        messages, changed = mod.reconcile(self.manifest, [{'name': 'Project', 'roots': ['~/new']}], self.home, True)
        self.assertTrue(changed)
        self.assertEqual(self.manifest['projects'][0]['roots'], ['~/repo', '~/new'])
        self.assertTrue(any(x.startswith('ADD FOLDER') for x in messages))

    def test_alias_retired_and_fixed(self):
        self.manifest['projects'][0].update(retiredRoots=['~/old'], fixedRoots=True)
        messages, changed = mod.reconcile(self.manifest, [{'name': 'Old', 'roots': ['~/old', '~/new']}], self.home, True)
        self.assertFalse(changed)
        self.assertTrue(any(x.startswith('RENAME') for x in messages))
        self.assertEqual(len(self.manifest['projects']), 1)

    def test_rename_is_review_not_duplicate_creation(self):
        messages, changed = mod.reconcile(self.manifest, [{'name': 'New name', 'roots': ['~/repo']}], self.home, True)
        self.assertFalse(changed)
        self.assertTrue(any(x.startswith('REVIEW') for x in messages))

    def test_missing_project(self):
        messages, _ = mod.reconcile(self.manifest, [], self.home, False)
        self.assertTrue(messages[0].startswith('ADD PROJECT'))

    def test_additional_folder_order_is_ignored(self):
        self.manifest['projects'][0]['roots'].extend(['~/second', '~/third'])
        for folder in ['second', 'third']:
            (self.home / folder).mkdir()
        for capture in [False, True]:
            with self.subTest(capture=capture):
                messages, changed = mod.reconcile(self.manifest, [
                    {'name': 'Project', 'roots': ['~/repo', '~/third', '~/second']}
                ], self.home, capture)
                self.assertEqual(messages, [])
                self.assertFalse(changed)
                self.assertEqual(self.manifest['projects'][0]['roots'],
                                 ['~/repo', '~/second', '~/third'])

    def test_wrong_primary_folder(self):
        self.manifest['projects'][0]['roots'].append('~/second')
        (self.home / 'second').mkdir()
        messages, _ = mod.reconcile(self.manifest, [{'name': 'Project', 'roots': ['~/second', '~/repo']}], self.home, False)
        self.assertEqual(messages, ['PRIMARY FOLDER: Project: make ~/repo primary'])

    def test_primary_mismatch_with_missing_and_extra_folders(self):
        self.manifest['projects'][0]['roots'].extend(['~/second', '~/missing'])
        for folder in ['second', 'extra']:
            (self.home / folder).mkdir()
        messages, changed = mod.reconcile(self.manifest, [
            {'name': 'Project', 'roots': ['~/second', '~/repo', '~/extra']}
        ], self.home, False)
        self.assertFalse(changed)
        self.assertCountEqual(messages, [
            'NEW FOLDER: Project: ~/extra',
            'ADD FOLDER: Project: ~/missing',
            'MISSING DIRECTORY: Project: ~/missing',
            'PRIMARY FOLDER: Project: make ~/repo primary',
        ])

    def test_missing_primary_folder_needs_adding_first(self):
        self.manifest['projects'][0]['roots'].append('~/second')
        messages, _ = mod.reconcile(self.manifest, [
            {'name': 'Project', 'roots': ['~/second']}
        ], self.home, False)
        self.assertCountEqual(messages, [
            'ADD FOLDER: Project: ~/repo',
            'MISSING DIRECTORY: Project: ~/second',
        ])

    def test_four_machines_contribute_and_receive_union(self):
        manifest = self.home / 'manifest.json'
        manifest.write_text(json.dumps(self.manifest))
        inbox = self.home / 'inbox'
        registry = self.home / 'repositories.conf'
        registry.write_text('current|active|repo|repo||git@example.org:repo.git\n')
        originals = {}
        for machine in ['Mini', 'M5', 'M3', 'Intel']:
            machine_home = self.home / machine
            machine_home.mkdir()
            (machine_home / 'repo').mkdir()
            (machine_home / machine).mkdir()
            (machine_home / ('new-' + machine)).mkdir()
            state = machine_home / 'state.json'
            content = json.dumps({'project-order': ['id', 'new'], 'local-projects': {
                'id': {'name': 'Project', 'rootPaths': [str(machine_home / 'repo'), str(machine_home / machine)]},
                'new': {'name': 'New ' + machine, 'rootPaths': [str(machine_home / ('new-' + machine))]}}})
            state.write_text(content)
            command = ['python3', str(SCRIPT), '--home', str(machine_home), '--machine', machine, '--manifest', str(manifest), '--inbox', str(inbox), '--state', str(state), '--registry', str(registry)]
            result = subprocess.run(command + ['--capture'], capture_output=True, text=True)
            self.assertIn(result.returncode, (0, 1), result.stderr)
            originals[machine] = (state, content, command)
        self.assertEqual(len(list(inbox.glob('*.json'))), 4)
        self.assertFalse((self.home / 'project-observations').exists())
        for machine, (state, content, command) in originals.items():
            result = subprocess.run(command, capture_output=True, text=True)
            self.assertEqual(result.returncode, 1, result.stderr)
            for other in originals:
                if other != machine:
                    self.assertIn('ADD FOLDER: Project: ~/' + other, result.stdout)
                    self.assertIn('ADD PROJECT: New ' + other, result.stdout)
            self.assertEqual(state.read_text(), content)
            subprocess.run(command + ['--capture'], capture_output=True)
        self.assertEqual(len(list(inbox.glob('*.json'))), 4)
        self.assertEqual(json.loads(manifest.read_text()), self.manifest)
        registry.write_text('current|active|repo|repo||git@example.org:changed.git\n')
        result = subprocess.run(originals['Mini'][2], capture_output=True, text=True)
        self.assertIn('REGISTRY REVIEW', result.stdout)
        subprocess.run(originals['Mini'][2] + ['--capture'], capture_output=True)
        registry.write_text('current|active|repo|repo||git@example.org:repo.git\n')
        subprocess.run(originals['Mini'][2] + ['--capture'], capture_output=True)
        self.assertEqual(len(list(inbox.glob('*.json'))), 6)

        # Older observations that merely lack rows added to the authoritative
        # registry do not propose a conflicting addition or modification.
        registry.write_text(
            'current|active|repo|repo||git@example.org:repo.git\n'
            'archived|active|old|old||git@example.org:old.git\n')
        result = subprocess.run(originals['Intel'][2], capture_output=True, text=True)
        self.assertNotIn('REGISTRY REVIEW', result.stdout)

    def test_import_moves_validated_inbox_to_tracked_history(self):
        manifest = self.home / 'manifest.json'
        manifest.write_text(json.dumps(self.manifest))
        inbox = self.home / 'inbox'
        inbox.mkdir()
        observation = {
            'version': 1,
            'machine': 'Intel',
            'projects': self.manifest['projects'],
            'registry': ['current|active|repo|repo||git@example.org:repo.git'],
            'recordedAt': '2026-09-09T12:00:00+00:00',
        }
        source = inbox / 'Intel-example.json'
        source.write_text(json.dumps(observation))
        result = subprocess.run([
            'python3', str(SCRIPT), '--home', str(self.home),
            '--manifest', str(manifest), '--inbox', str(inbox),
            '--import-observations',
        ], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr + result.stdout)
        self.assertIn('IMPORTED 1 project observation', result.stdout)
        self.assertFalse(source.exists())
        destination = self.home / 'project-observations/Intel-example.json'
        self.assertEqual(json.loads(destination.read_text()), observation)

    def test_capture_does_not_dirty_gittracked_until_import(self):
        gittracked = self.home / 'GitTracked'
        reference = gittracked / 'Reference'
        reference.mkdir(parents=True)
        manifest = reference / 'Codex Project Manifest.json'
        manifest.write_text(json.dumps(self.manifest))
        inbox = self.home / 'inbox'
        registry = self.home / 'repositories.conf'
        registry.write_text('current|active|repo|repo||git@example.org:repo.git\n')
        state = self.home / 'state.json'
        state.write_text(json.dumps({'project-order': ['id'], 'local-projects': {
            'id': {'name': 'Project', 'rootPaths': [str(self.home / 'repo')]},
        }}))
        for arguments in [
            ['init', '-q'],
            ['config', 'user.name', 'Test'],
            ['config', 'user.email', 'test@example.org'],
            ['add', '.'],
            ['commit', '-qm', 'fixture'],
        ]:
            subprocess.run(['git', '-C', str(gittracked), *arguments], check=True)

        command = [
            'python3', str(SCRIPT), '--home', str(self.home), '--machine', 'Intel',
            '--manifest', str(manifest), '--inbox', str(inbox),
            '--state', str(state), '--registry', str(registry),
        ]
        result = subprocess.run(command + ['--capture'], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr + result.stdout)
        self.assertIn('no Git working tree was changed', result.stdout)
        status = subprocess.run(
            ['git', '-C', str(gittracked), 'status', '--porcelain', '--untracked-files=all'],
            check=True, capture_output=True, text=True).stdout
        self.assertEqual(status, '')
        self.assertEqual(len(list(inbox.glob('Intel-*.json'))), 1)

        result = subprocess.run([
            'python3', str(SCRIPT), '--home', str(self.home),
            '--manifest', str(manifest), '--inbox', str(inbox),
            '--import-observations',
        ], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr + result.stdout)
        status = subprocess.run(
            ['git', '-C', str(gittracked), 'status', '--porcelain', '--untracked-files=all'],
            check=True, capture_output=True, text=True).stdout
        self.assertRegex(status, r'^\?\? Reference/project-observations/Intel-.*\.json\n$')

    def test_import_conflict_does_not_partially_move_batch(self):
        manifest = self.home / 'manifest.json'
        manifest.write_text(json.dumps(self.manifest))
        inbox = self.home / 'inbox'
        observations = self.home / 'project-observations'
        inbox.mkdir()
        observations.mkdir()

        def observation(machine, recorded_at):
            return {
                'version': 1,
                'machine': machine,
                'projects': self.manifest['projects'],
                'registry': ['current|active|repo|repo||git@example.org:repo.git'],
                'recordedAt': recorded_at,
            }

        first = inbox / 'Intel-first.json'
        conflict = inbox / 'Intel-conflict.json'
        first.write_text(json.dumps(observation('Intel', '2026-09-09T12:00:00+00:00')))
        conflict.write_text(json.dumps(observation('Intel', '2026-09-09T12:01:00+00:00')))
        (observations / conflict.name).write_text(
            json.dumps(observation('Intel', '2026-09-09T11:59:00+00:00')))

        result = subprocess.run([
            'python3', str(SCRIPT), '--home', str(self.home),
            '--manifest', str(manifest), '--inbox', str(inbox),
            '--import-observations',
        ], capture_output=True, text=True)
        self.assertEqual(result.returncode, 2, result.stderr + result.stdout)
        self.assertIn('Conflicting observation filename', result.stderr)
        self.assertTrue(first.exists())
        self.assertTrue(conflict.exists())
        self.assertFalse((observations / first.name).exists())

    def test_invalid_schema(self):
        with self.assertRaises(ValueError):
            mod.load_local({}, self.home)
        self.manifest['projects'].append({'name': 'Old', 'roots': ['~/repo']})
        with self.assertRaises(ValueError):
            mod.validate_manifest(self.manifest, self.home)

    def test_duplicate_name_capture_does_not_poison_observations(self):
        manifest = self.home / 'manifest.json'
        manifest.write_text(json.dumps(self.manifest))
        inbox = self.home / 'inbox'
        registry = self.home / 'repositories.conf'
        registry.write_text('current|active|repo|repo||git@example.org:repo.git\n')
        state = self.home / 'state.json'
        project = {'name': 'Project', 'rootPaths': [str(self.home / 'repo')]}
        valid = json.dumps({'project-order': ['id'], 'local-projects': {'id': project}})
        duplicate = json.dumps({'project-order': ['id', 'duplicate'],
                                'local-projects': {'id': project, 'duplicate': project}})
        command = ['python3', str(SCRIPT), '--home', str(self.home), '--machine', 'M5',
                   '--manifest', str(manifest), '--inbox', str(inbox),
                   '--state', str(state), '--registry', str(registry)]
        for existing_snapshot in [False, True]:
            with self.subTest(existing_snapshot=existing_snapshot):
                if existing_snapshot:
                    state.write_text(valid)
                    result = subprocess.run(command + ['--capture'], capture_output=True, text=True)
                    self.assertEqual(result.returncode, 0, result.stderr + result.stdout)
                before = {path.name: path.read_bytes() for path in inbox.glob('*')}
                state.write_text(duplicate)
                result = subprocess.run(command + ['--capture'], capture_output=True, text=True)
                self.assertEqual(result.returncode, 2, result.stderr + result.stdout)
                self.assertIn('Duplicate/invalid project name or alias: Project', result.stderr)
                self.assertNotIn('RECORDED', result.stdout)
                self.assertEqual(inbox.exists(), existing_snapshot)
                self.assertEqual({path.name: path.read_bytes() for path in inbox.glob('*')}, before)
                self.assertEqual(state.read_text(), duplicate)
                self.assertEqual(json.loads(manifest.read_text()), self.manifest)

                # Read-only checks keep their actionable duplicate diagnostic.
                result = subprocess.run(command, capture_output=True, text=True)
                self.assertEqual(result.returncode, 1, result.stderr + result.stdout)
                self.assertIn('DUPLICATE PROJECT: Project', result.stdout)

                # Once local names are corrected, no shared snapshot poisons checks.
                state.write_text(valid)
                result = subprocess.run(command, capture_output=True, text=True)
                self.assertEqual(result.returncode, 0, result.stderr + result.stdout)

    def test_arrive_depart_hooks_and_failure_status(self):
        fixture_bin = self.home / 'bin'
        fixture_bin.mkdir()
        for name in ['arrive.sh', 'depart.sh']:
            shutil.copyfile(SCRIPT.parent / name, fixture_bin / name)
        (fixture_bin / 'project-sync-check.py').write_text(
            'import os, sys\nprint("PROJECT CHECK", sys.argv[1:])\nsys.exit(int(os.environ.get("CHECK_RC", "0")))\n')
        for name in ['git-repo-sync.sh', 'sync-dev.sh', 'sync-active.sh', 'pr-status']:
            stub = fixture_bin / name
            stub.write_text('#!/bin/sh\necho "STUB ' + name + ' $*"\nexit 0\n')
            stub.chmod(0o755)
        env = dict(os.environ, PATH=str(fixture_bin) + os.pathsep + os.environ['PATH'], ZDOTDIR=str(self.home))
        for name in ['arrive.sh', 'depart.sh']:
            for code in [0, 1, 2]:
                result = subprocess.run(['zsh', '-f', str(fixture_bin / name)], env=dict(env, CHECK_RC=str(code)), capture_output=True, text=True)
                expected = 0 if code in [0, 1] else code
                self.assertEqual(result.returncode, expected, result.stderr + result.stdout)
                self.assertIn('STUB sync-dev.sh', result.stdout)
                self.assertIn('STUB sync-active.sh', result.stdout)
                self.assertEqual('--capture' in result.stdout, name == 'depart.sh')
                if code == 1:
                    self.assertIn('completed with warnings', result.stdout)
                elif code == 2:
                    self.assertIn('Codex project check failed', result.stderr)
                if name == 'arrive.sh':
                    self.assertLess(result.stdout.index('STUB sync-active.sh'), result.stdout.index('PROJECT CHECK'))
                    self.assertEqual(result.stdout.count('STUB git-repo-sync.sh --pull-only'), 1)
                    self.assertLess(result.stdout.index('STUB git-repo-sync.sh'), result.stdout.index('STUB sync-dev.sh'))
        (fixture_bin / 'git-repo-sync.sh').write_text('#!/bin/sh\nexit 1\n')
        result = subprocess.run(['zsh', '-f', str(fixture_bin / 'arrive.sh')], env=env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 1)
        self.assertNotIn('STUB sync-dev.sh', result.stdout)


if __name__ == '__main__':
    unittest.main()
