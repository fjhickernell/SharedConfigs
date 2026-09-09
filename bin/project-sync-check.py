#!/usr/bin/env python3
"""Record portable Codex project additions and report local setup differences."""
import argparse
import json
import os
from pathlib import Path
import re
import sys
import tempfile
import uuid
from datetime import datetime, timezone

VAULT = 'Library/Mobile Documents/iCloud~md~obsidian/Documents/ObsidianVault'
INBOX = 'Reference/Codex Project Observations Inbox'


def read_json(path):
    with path.open() as stream:
        return json.load(stream)


def portable(value, home):
    if not isinstance(value, str):
        raise ValueError('Workspace path is not a string')
    path = Path(value)
    if not path.is_absolute() or '..' in path.parts:
        raise ValueError('Invalid absolute workspace path: ' + value)
    try:
        relative = path.relative_to(home)
    except ValueError:
        raise ValueError('Workspace outside home needs a portable mapping: ' + value)
    return '~/' + relative.as_posix()


def local_path(value, home):
    if not isinstance(value, str) or not value.startswith('~/') or Path(value[2:]).is_absolute() or '..' in Path(value[2:]).parts:
        raise ValueError('Invalid portable path: ' + str(value))
    return home / value[2:]


def validate_manifest(data, home):
    if data.get('version') != 1 or not isinstance(data.get('projects'), list):
        raise ValueError('Unsupported project manifest schema')
    names = set()
    for project in data['projects']:
        if not isinstance(project.get('name'), str) or not project['name'].strip():
            raise ValueError('Project needs a name')
        for name in [project['name']] + project.get('aliases', []):
            if not isinstance(name, str) or name in names:
                raise ValueError('Duplicate/invalid project name or alias: ' + str(name))
            names.add(name)
        roots = project.get('roots')
        if not isinstance(roots, list) or not roots or len(set(roots)) != len(roots):
            raise ValueError('Project needs unique roots with the primary folder first: ' + project['name'])
        for root in roots + project.get('retiredRoots', []):
            local_path(root, home)


def validate_observation(data, home, path):
    validate_manifest(data, home)
    if not isinstance(data.get('registry'), list) or not isinstance(data.get('machine'), str):
        raise ValueError('Invalid observation: ' + path.name)
    if not isinstance(data.get('recordedAt'), str):
        raise ValueError('Observation lacks recordedAt: ' + path.name)


def load_observations(directories, home):
    snapshots = []
    seen = {}
    for directory in directories:
        if not directory.exists():
            continue
        for path in sorted(directory.glob('*.json')):
            if path.is_symlink() or not path.is_file():
                raise ValueError('Observation is not a regular file: ' + path.name)
            observation = read_json(path)
            validate_observation(observation, home, path)
            previous = seen.get(path.name)
            if previous is not None:
                if previous != observation:
                    raise ValueError('Conflicting observation filename: ' + path.name)
                continue
            seen[path.name] = observation
            snapshots.append(observation)
    return snapshots


def import_observations(inbox, observations, home):
    pending = []
    if inbox.exists():
        for path in sorted(inbox.glob('*.json')):
            if path.is_symlink() or not path.is_file():
                raise ValueError('Observation is not a regular file: ' + path.name)
            observation = read_json(path)
            validate_observation(observation, home, path)
            pending.append((path, observation))
    if not pending:
        print('No pending project observations to import.')
        return

    # Validate every source and destination before moving anything, so a
    # conflict cannot leave a partially imported batch.
    for source, observation in pending:
        destination = observations / source.name
        if destination.exists():
            existing = read_json(destination)
            validate_observation(existing, home, destination)
            if existing != observation:
                raise ValueError('Conflicting observation filename: ' + source.name)

    observations.mkdir(parents=True, exist_ok=True)
    for source, observation in pending:
        destination = observations / source.name
        if destination.exists():
            source.unlink()
        else:
            os.replace(source, destination)
    try:
        inbox.rmdir()
    except OSError:
        pass
    print(f'IMPORTED {len(pending)} project observation(s) into GitTracked for checkpointing.')


def load_local(state, home):
    projects = state.get('local-projects')
    order = state.get('project-order')
    if not isinstance(projects, dict) or not isinstance(order, list):
        raise ValueError('Codex saved-project schema unavailable; no snapshot written')
    result = []
    for key in order:
        if not isinstance(key, str):
            raise ValueError('Invalid project-order entry')
        if key.startswith('g-p-'):
            continue  # Cloud ChatGPT projects are outside this inventory.
        project = projects.get(key)
        if not isinstance(project, dict) or not isinstance(project.get('name'), str):
            raise ValueError('Missing saved project record: ' + key)
        roots = project.get('rootPaths')
        if not isinstance(roots, list) or not roots:
            raise ValueError('Missing project roots: ' + project['name'])
        result.append({'name': project['name'], 'roots': list(dict.fromkeys(portable(r, home) for r in roots))})
    return result


def reconcile(manifest, local, home, capture):
    messages = []
    changed = False
    seen = set()
    for actual in local:
        matches = [p for p in manifest['projects'] if actual['name'] in [p['name']] + p.get('aliases', [])]
        if not matches:
            related = [p for p in manifest['projects'] if set(actual['roots']) & set(p['roots'])]
            if related:
                messages.append('REVIEW NAME/GROUPING: ' + actual['name'] + ' shares folders with ' + ', '.join(p['name'] for p in related) + '; update shared manifest explicitly for a rename or separate project')
                continue
            messages.append('NEW PROJECT: ' + actual['name'])
            if capture:
                manifest['projects'].append(dict(actual))
                matches = [manifest['projects'][-1]]
                changed = True
            else:
                continue
        desired = matches[0]
        name = desired['name']
        if name in seen:
            messages.append('DUPLICATE PROJECT: ' + name + ' — reconcile local entries')
        seen.add(name)
        if actual['name'] != name:
            messages.append('RENAME: ' + actual['name'] + ' -> ' + name)
        retired = desired.get('retiredRoots', [])
        for root in actual['roots']:
            if root in retired:
                messages.append('LEGACY ROOT: ' + name + ': ' + root + ' — inspect before removing')
            elif root not in desired['roots']:
                messages.append('NEW FOLDER: ' + name + ': ' + root)
                if capture and not desired.get('fixedRoots', False):
                    desired['roots'].append(root)
                    changed = True
                elif desired.get('fixedRoots', False):
                    messages.append('REVIEW: explicit fixed-folder policy; addition not propagated')
        for root in desired['roots']:
            if root not in actual['roots']:
                messages.append('ADD FOLDER: ' + name + ': ' + root)
            if not local_path(root, home).is_dir():
                messages.append('MISSING DIRECTORY: ' + name + ': ' + root)
        # Codex exposes a primary folder; additional folder order is immaterial.
        primary = desired['roots'][0]
        if primary in actual['roots'] and actual['roots'][0] != primary:
            messages.append('PRIMARY FOLDER: ' + name + ': make ' + primary + ' primary')
    for desired in manifest['projects']:
        if desired['name'] not in seen:
            messages.append('ADD PROJECT: ' + desired['name'] + ': ' + ' -> '.join(desired['roots']))
    return messages, changed


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    actions = parser.add_mutually_exclusive_group()
    actions.add_argument('--capture', action='store_true', help='Record portable observations for all other Macs')
    actions.add_argument('--import-observations', action='store_true', help='Move pending observations into GitTracked for checkpointing')
    parser.add_argument('--home', type=Path, default=Path.home())
    parser.add_argument('--state', type=Path)
    parser.add_argument('--manifest', type=Path)
    parser.add_argument('--inbox', type=Path)
    parser.add_argument('--machine', help='Override machine short name (for fixtures)')
    parser.add_argument('--registry', type=Path)
    args = parser.parse_args()
    home = args.home.absolute()
    state_path = args.state or home / '.codex/.codex-global-state.json'
    manifest_path = args.manifest or home / VAULT / 'GitTracked/Reference/Codex Project Manifest.json'
    try:
        manifest = read_json(manifest_path)
        validate_manifest(manifest, home)
        observations = manifest_path.parent / 'project-observations'
        inbox = args.inbox or home / VAULT / INBOX
        if args.import_observations:
            import_observations(inbox, observations, home)
            return 0
        machine = args.machine
        if not machine:
            identity = (home / '.codex-machine.md').read_text()
            match = re.search(r'Preferred short name:\s*`?([A-Za-z0-9_-]+)', identity)
            if not match:
                raise ValueError('Machine short name unavailable')
            machine = match.group(1)
        if not re.fullmatch(r'[A-Za-z0-9_-]+', machine):
            raise ValueError('Invalid machine short name')
        local = load_local(read_json(state_path), home)
        registry_path = args.registry or Path(__file__).resolve().parents[1] / 'settings/repositories.conf'
        registry = [line.strip() for line in registry_path.read_text().splitlines()
                    if line.strip() and not line.lstrip().startswith('#')]
        for row in registry:
            fields = row.split('|')
            if len(fields) != 6:
                raise ValueError('Invalid repository registry row')
            # Never export credentials embedded in a remote URL.
            remote = fields[5]
            if ('://' in remote and '@' in remote and remote.split('://', 1)[1].split('@', 1)[0] != 'git') or '?' in remote or '#' in remote:
                raise ValueError('Registry remote needs credentials removed before sharing')
        snapshots = load_observations([observations, inbox], home)
        current = {'version': 1, 'machine': machine, 'projects': local, 'registry': registry}
        if args.capture:
            # Readers validate every shared observation, so reject invalid local
            # projects before writing a snapshot that could break other Macs.
            validate_manifest(current, home)
        previous = max((s for s in snapshots if s['machine'] == machine),
                       key=lambda s: s.get('recordedAt', ''), default={})
        if args.capture and not all(previous.get(k) == v for k, v in current.items()):
            inbox.mkdir(parents=True, exist_ok=True)
            current['recordedAt'] = datetime.now(timezone.utc).isoformat()
            # Each observation has a unique filename: offline Macs never overwrite
            # one another's contributions. Canonical edits remain explicit.
            destination = inbox / (machine + '-' + uuid.uuid4().hex + '.json')
            fd, temp = tempfile.mkstemp(prefix='.observation-', dir=inbox)
            try:
                with os.fdopen(fd, 'w') as stream:
                    json.dump(current, stream, indent=2, ensure_ascii=False)
                    stream.write('\n')
                os.replace(temp, destination)
            finally:
                if os.path.exists(temp):
                    os.unlink(temp)
            snapshots.append(current)
            print('RECORDED ' + machine + ' project/folder and repository configuration in the shared iCloud inbox; no Git working tree was changed.')
        messages = []
        # Deterministic additive union. Missing projects/folders never delete a
        # contribution; retiredRoots and aliases encode deliberate decisions.
        latest = {}
        for snapshot in sorted(snapshots, key=lambda s: (s.get('recordedAt', ''), s['machine'])):
            notices, _ = reconcile(manifest, snapshot['projects'], home, True)
            messages.extend(snapshot['machine'] + ': ' + n for n in notices
                            if n.startswith(('REVIEW', 'DUPLICATE')))
            latest[snapshot['machine']] = snapshot
        for other, snapshot in latest.items():
            foreign_rows = [row for row in snapshot['registry'] if row not in registry]
            if other != machine and foreign_rows:
                messages.append('REGISTRY REVIEW: ' + other + ' recorded different repository entries; fetch SharedConfigs and reconcile additions/modifications before cloning.')
                for row in foreign_rows:
                    messages.append('  ' + other + ' registry entry: ' + row)
        notices, _ = reconcile(manifest, local, home, False)
        messages.extend(notices)
        messages = list(dict.fromkeys(messages))
        if messages:
            print('\n'.join(messages))
            print('Project setup needs attention. Codex app folders must be reconciled manually; no app state was edited.')
            print('New repository folders also need a repositories.conf entry; OneDrive folders use OneDrive.')
            return 1
        print('Codex projects match the shared manifest; configured directories exist.')
        return 0
    except (OSError, ValueError, KeyError, TypeError) as error:
        print('PROJECT CHECK FAILED: ' + str(error), file=sys.stderr)
        return 2


if __name__ == '__main__':
    sys.exit(main())
