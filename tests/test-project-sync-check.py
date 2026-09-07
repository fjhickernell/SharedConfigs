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

    def test_missing_and_order(self):
        messages, _ = mod.reconcile(self.manifest, [], self.home, False)
        self.assertTrue(messages[0].startswith('ADD PROJECT'))
        self.manifest['projects'][0]['roots'].append('~/second')
        messages, _ = mod.reconcile(self.manifest, [{'name': 'Project', 'roots': ['~/second', '~/repo']}], self.home, False)
        self.assertTrue(any(x.startswith('ORDER') for x in messages))
        self.assertTrue(any(x.startswith('MISSING DIRECTORY') for x in messages))

    def test_four_machines_contribute_and_receive_union(self):
        manifest = self.home / 'manifest.json'
        manifest.write_text(json.dumps(self.manifest))
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
            command = ['python3', str(SCRIPT), '--home', str(machine_home), '--machine', machine, '--manifest', str(manifest), '--state', str(state), '--registry', str(registry)]
            result = subprocess.run(command + ['--capture'], capture_output=True, text=True)
            self.assertIn(result.returncode, (0, 1), result.stderr)
            originals[machine] = (state, content, command)
        observations = self.home / 'project-observations'
        self.assertEqual(len(list(observations.glob('*.json'))), 4)
        for machine, (state, content, command) in originals.items():
            result = subprocess.run(command, capture_output=True, text=True)
            self.assertEqual(result.returncode, 1, result.stderr)
            for other in originals:
                if other != machine:
                    self.assertIn('ADD FOLDER: Project: ~/' + other, result.stdout)
                    self.assertIn('ADD PROJECT: New ' + other, result.stdout)
            self.assertEqual(state.read_text(), content)
            subprocess.run(command + ['--capture'], capture_output=True)
        self.assertEqual(len(list(observations.glob('*.json'))), 4)
        self.assertEqual(json.loads(manifest.read_text()), self.manifest)
        registry.write_text('current|active|repo|repo||git@example.org:changed.git\n')
        result = subprocess.run(originals['Mini'][2], capture_output=True, text=True)
        self.assertIn('REGISTRY REVIEW', result.stdout)
        subprocess.run(originals['Mini'][2] + ['--capture'], capture_output=True)
        registry.write_text('current|active|repo|repo||git@example.org:repo.git\n')
        subprocess.run(originals['Mini'][2] + ['--capture'], capture_output=True)
        self.assertEqual(len(list(observations.glob('*.json'))), 6)

    def test_invalid_schema(self):
        with self.assertRaises(ValueError):
            mod.load_local({}, self.home)
        self.manifest['projects'].append({'name': 'Old', 'roots': ['~/repo']})
        with self.assertRaises(ValueError):
            mod.validate_manifest(self.manifest, self.home)

    def test_arrive_depart_hooks_and_failure_status(self):
        fixture_bin = self.home / 'bin'
        fixture_bin.mkdir()
        for name in ['arrive.sh', 'depart.sh']:
            shutil.copyfile(SCRIPT.parent / name, fixture_bin / name)
        (fixture_bin / 'project-sync-check.py').write_text(
            'import os, sys\nprint("PROJECT CHECK", sys.argv[1:])\nsys.exit(int(os.environ.get("CHECK_RC", "0")))\n')
        for name in ['sync-dev.sh', 'sync-active.sh', 'pr-status']:
            stub = fixture_bin / name
            stub.write_text('#!/bin/sh\necho "STUB ' + name + ' $*"\nexit 0\n')
            stub.chmod(0o755)
        env = dict(os.environ, PATH=str(fixture_bin) + os.pathsep + os.environ['PATH'], ZDOTDIR=str(self.home))
        for name in ['arrive.sh', 'depart.sh']:
            for code in [0, 1, 2]:
                result = subprocess.run(['zsh', '-f', str(fixture_bin / name)], env=dict(env, CHECK_RC=str(code)), capture_output=True, text=True)
                self.assertEqual(result.returncode, code, result.stderr + result.stdout)
                self.assertIn('STUB sync-dev.sh', result.stdout)
                self.assertIn('STUB sync-active.sh', result.stdout)
                self.assertEqual('--capture' in result.stdout, name == 'depart.sh')
                if name == 'arrive.sh':
                    self.assertLess(result.stdout.index('STUB sync-active.sh'), result.stdout.index('PROJECT CHECK'))


if __name__ == '__main__':
    unittest.main()
