# Cross-machine project alerts

`arrive.sh` and `depart.sh` run `python3 bin/project-sync-check.py` through
their own script directory. Python 3 is required. `depart` adds `--capture`.
No running Codex JSON is modified, and no application is restarted.

## Shared data

The canonical project names, primary/additional roots, aliases, fixed-folder exceptions,
and retired paths live in the Obsidian vault at
`GitTracked/Reference/Codex Project Manifest.json`. Any Mac may edit this
manifest through Codex as a reviewed configuration change. The readable
`Project and Repository Inventory.md` should be reconciled at the same time.

The first entry in each project's `roots` is its primary/opening folder.
Additional folders are compared by membership; their order does not need to
match across Macs. In Codex, use **Make primary** when the opening folder is
wrong. Do not ask Fred to reorder additional folders just to match the JSON.

Each departure records the saved project's portable names/roots and the
repository registry in a uniquely named JSON file under the iCloud-synchronized
vault directory `Reference/Codex Project Observations Inbox`, outside every Git
working tree. Identical observations are not repeated. `arrive` reads both this
inbox and the Git-tracked history under
`GitTracked/Reference/project-observations/`. An Infrastructure Checkpoint
moves validated inbox files into that history immediately before its normal
inspection, commit, and push. Files contain no Codex UUIDs, conversations,
credentials, or private course contents. Home paths become `~/` and paths
outside home require an explicit mapping. The current reader uses
`local-projects` and `project-order` from
`~/.codex/.codex-global-state.json`; an unsupported schema fails visibly.

iCloud transports these files between all four Macs, including contributions
made offline; wait for it to finish before expecting another Mac's changes.
Unique filenames prevent independent captures from overwriting one another.
The external inbox prevents `depart` from dirtying GitTracked and blocking the
next `arrive`; GitTracked still provides checkpoint history after `infra save`
imports and publishes pending observations. The check cannot prove that iCloud
has delivered every remote observation.

## What is automatic

- Departure captures configuration observations in the external inbox even if
  later repository sync fails. It never infers a deletion from a missing
  folder or project, and capture alone does not dirty a Git repository.
- Capture validates the local observation before writing it. Duplicate saved
  project names fail visibly without creating a shared file that other Macs
  would reject; reconcile the duplicate names in Codex before capturing again.
- Arrival checks after the existing repository sync so freshly cloned paths
  are available. It does not write an observation.
- All observed additions form a deterministic union over the canonical
  manifest. A stale machine cannot remove another machine's additions.
- Names known as aliases map to the same project. Unknown names that share
  existing roots require review, avoiding accidental duplicate projects.
- Missing projects, roots, directories, a different primary folder, legacy roots, and
  registry differences are printed in the terminal.
- A changed registry on any Mac is recorded and compared on the others.
  Existing `repo-sweep` handles live Git state; this checker compares registry
  configuration, not unregistered changes to a checkout's actual remote.

Exit codes from the checker are: 0 = matching configuration; 1 =
setup/reconciliation needed; 2 = check failed. The `arrive` and `depart`
wrappers report status 1 as a warning and return success when repository sync
succeeds, so project maintenance does not block the wider workflow. Status 2
remains a wrapper failure, as do repository synchronization failures.

## Deliberate modifications

Renames, removals, primary-folder changes, and registry edits are reviewable changes, not
last-writer-wins updates. On whichever Mac originates the change, ask Codex
to update the canonical manifest (aliases for names, `retiredRoots` for removed
paths, `fixedRoots` for explicit single-folder policies), the Markdown inventory,
and `settings/repositories.conf` as applicable. Old observations remain evidence;
retired roots are excluded from the union. Removing an entire project also
requires reconciling its historical observations deliberately; the automatic
capture is additive and will flag it again otherwise.

Fred applies Codex app changes; Codex can edit VS Code workspace files. Neither
app's folder list is automatically changed. Register new Git repositories
separately before expecting `arrive` to clone them; OneDrive handles its own
folders. `infra save` first runs
`python3 ~/Documents/SharedConfigs/bin/project-sync-check.py --import-observations`
to move pending observations into GitTracked, then publishes both
infrastructure repositories. Update SharedConfigs on the next Mac afterward.
`arrive` pulls both infrastructure repositories first via
`git-repo-sync.sh --pull-only`, then continues to the other scripts and
registry without restarting. Changes to `arrive` itself take effect on the
next invocation. Local changes or unpublished/divergent history stop
arrival without staging, committing, stashing, rebasing, or pushing. Install
this version once on Macs still running the old wrapper by fast-forwarding
SharedConfigs manually. `depart` does not publish infrastructure changes.

Validate with `python3 tests/test-project-sync-check.py` and
`zsh -n bin/arrive.sh bin/depart.sh`. Fixtures exercise all four contributing
machines, differing usernames, additive merge, aliases, retired/fixed roots,
registry differences, read-only checks, and wrapper exit handling.
