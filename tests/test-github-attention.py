#!/usr/bin/env python3
"""Verify reminder coverage, pagination, and partial-failure reporting with fake gh."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / 'bin/github-attention'


def item(number, title, pr=False, draft=False):
    result = {'number': number, 'title': title, 'user': {'login': 'student'},
              'assignees': [], 'html_url': f'https://github.com/example/repo/issues/{number}',
              'updated_at': f'2026-10-02T10:00:{number:02d}Z'}
    if pr:
        result['pull_request'] = {}
        result['draft'] = draft
    return result


class AttentionTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.registry = self.root / 'registry'
        self.data = self.root / 'responses.json'
        self.calls = self.root / 'calls.jsonl'
        stub = self.root / 'gh'
        stub.write_text('''#!/usr/bin/env python3
import json, os, pathlib, sys
args = sys.argv[1:]
with open(os.environ['CALLS'], 'a') as out:
    out.write(json.dumps(args) + '\\n')
data = json.loads(pathlib.Path(os.environ['RESPONSES']).read_text())
endpoint = args[args.index('--method') + 2]
key = endpoint
if endpoint == 'search/issues':
    key = next(arg[2:] for arg in args if arg.startswith('q='))
result = data.get(key, {'error': 'unexpected query: ' + key})
if isinstance(result, dict) and 'error' in result:
    print(result['error'], file=sys.stderr)
    sys.exit(1)
print(json.dumps(result))
''')
        stub.chmod(0o755)
        self.env = dict(os.environ, PATH=str(self.root) + os.pathsep + os.environ['PATH'],
                        RESPONSES=str(self.data), CALLS=str(self.calls))

    def run_check(self, rows, responses):
        self.registry.write_text(rows)
        self.data.write_text(json.dumps({'user': {'login': 'fred'}, **responses}))
        return subprocess.run(['python3', str(SCRIPT), '--registry', str(self.registry)],
                              env=self.env, capture_output=True, text=True)

    def row(self, repo, status='current', origin=None):
        return f'{status}|active|{repo}|unused||{origin or "git@github.com:" + repo + ".git"}\n'

    def endpoint(self, repo):
        return f'repos/{repo}/issues?state=open&sort=updated&direction=desc&per_page=100'

    def searches(self, repo):
        return [f'repo:{repo} is:open {qualifier}' for qualifier in
                ['mentions:fred']]

    def test_courses_talks_and_other_repos_include_untagged_items_all_pages(self):
        repos = ['fjhickernell/course', 'fjhickernell/talk', 'fjhickernell/library']
        responses = {self.endpoint(repo): [[item(1, 'Untagged student bug')],
                                          [item(2, 'Student PR', pr=True),
                                           item(3, 'Draft PR', pr=True, draft=True)]]
                     for repo in repos}
        result = self.run_check(''.join(self.row(repo) for repo in repos), responses)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.count('Untagged student bug'), 3)
        self.assertEqual(result.stdout.count('Student PR'), 3)
        self.assertEqual(result.stdout.count('Draft PR [draft]'), 3)
        self.assertIn('9 open items shown', result.stdout)
        for args in map(json.loads, self.calls.read_text().splitlines()):
            self.assertEqual(args[args.index('--method') + 1], 'GET')
            if '--paginate' in args:
                self.assertIn('--slurp', args)

    def test_all_other_owners_use_mentions_only_and_deduplicate(self):
        repos = ['QMCSoftware/qmcpy', 'QMCSoftware/QMCSoftware.github.io',
                 'QMCSoftware/LDData', 'another-user/project']
        responses = {}
        for repo in repos:
            for query in self.searches(repo):
                responses[query] = [{'total_count': 1, 'incomplete_results': False,
                                     'items': [item(4, 'Mentioned issue'),
                                               item(5, 'Mentioned PR', pr=True)]},
                                    {'total_count': 2, 'incomplete_results': False,
                                     'items': [item(4, 'Mentioned issue')]}]
        result = self.run_check(''.join(self.row(repo) for repo in repos), responses)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.count('Mentioned issue'), 4)
        self.assertEqual(result.stdout.count('Mentioned PR'), 4)
        calls = self.calls.read_text()
        self.assertNotIn('/issues?state=', calls)
        self.assertNotIn('assignee:fred', calls)
        self.assertNotIn('review-requested:fred', calls)
        self.assertIn('8 open items shown', result.stdout)

    def test_archived_non_github_and_duplicate_origins(self):
        repo = 'fjhickernell/course'
        rows = (self.row(repo) + self.row('duplicate', origin='https://github.com/fjhickernell/course.git')
                + self.row('fred/old', status='archived')
                + self.row('overleaf', origin='https://git@git.overleaf.com/abc'))
        result = self.run_check(rows, {self.endpoint(repo): [[]]})
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('1 current repositories', result.stdout)
        self.assertIn('Skipped 1 current non-GitHub', result.stdout)
        self.assertEqual(len(self.calls.read_text().splitlines()), 2)

    def test_failure_still_reports_other_repos_and_does_not_claim_clear(self):
        result = self.run_check(self.row('fjhickernell/offline') + self.row('fjhickernell/course'), {
            self.endpoint('fjhickernell/offline'): {'error': 'API unavailable'},
            self.endpoint('fjhickernell/course'): [[item(1, 'Student bug')]]})
        self.assertEqual(result.returncode, 1)
        self.assertIn('Student bug', result.stdout)
        self.assertIn('INCOMPLETE', result.stdout)
        self.assertNotIn('No open issues', result.stdout)
        self.assertIn('API unavailable', result.stderr)

    def test_partial_personal_search_and_search_limit_warn(self):
        repo = 'QMCSoftware/qmcpy'
        mentioned, = self.searches(repo)
        result = self.run_check(self.row(repo), {
            mentioned: [{'total_count': 1001, 'incomplete_results': True,
                         'items': [item(1, 'Mentioned issue')]}]})
        self.assertEqual(result.returncode, 1)
        self.assertIn('Mentioned issue', result.stdout)
        self.assertIn('search results are incomplete', result.stderr)

    def test_auth_failure_stops_before_repository_requests(self):
        result = self.run_check(self.row('fred/course'), {'user': {'error': 'not authenticated'}})
        self.assertEqual(result.returncode, 2)
        self.assertIn('not authenticated', result.stderr)
        self.assertEqual(len(self.calls.read_text().splitlines()), 1)

    def test_arrive_reports_missing_check_as_warning(self):
        import shutil
        shutil.copyfile(ROOT / 'bin/arrive.sh', self.root / 'arrive.sh')
        for name in ['git-repo-sync.sh', 'sync-dev.sh', 'sync-active.sh']:
            stub = self.root / name
            stub.write_text('#!/bin/sh\nexit 0\n')
            stub.chmod(0o755)
        (self.root / 'project-sync-check.py').write_text('')
        result = subprocess.run(['zsh', '-f', str(self.root / 'arrive.sh')],
                                env=self.env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('GitHub issue and PR check was incomplete', result.stdout)
        self.assertNotIn('arrive completed successfully', result.stdout)


if __name__ == '__main__':
    unittest.main()
