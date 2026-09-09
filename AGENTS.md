# SharedConfigs Infrastructure Project Instructions

This repository is one of two entry points for the Infrastructure project. On
some computers `SharedConfigs` is the primary project repository; on others
the primary repository is `GitTracked` (named `GitTrackedObsidian` by
`git-repo-sync.sh`).

## Checkpoint scope and synchronization opt-in

The exact whole-message command `infra save` is the short alias for
`Infrastructure Checkpoint` and follows the same workflow and scope.

For a Checkpoint or Express Checkpoint requested with either Infrastructure
entry point as the current project, extend the normal project scope to both
infrastructure repositories:

- `~/Documents/SharedConfigs`
- `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/ObsidianVault/GitTracked`

Before inspecting those repositories, run
`python3 ~/Documents/SharedConfigs/bin/project-sync-check.py --import-observations`.
This validates and moves pending project snapshots from the external iCloud
inbox into GitTracked so the same Checkpoint reviews and publishes them. Stop
if the import fails.

Inspect both repositories, then follow the matching global Checkpoint workflow
to commit and push their intended changes, including the Express Checkpoint
validation exception when applicable. After that succeeds, run
`git-repo-sync.sh` as the final synchronization step and report its result.

This project does not opt in to `sync-active.sh`; the active development and
teaching repositories managed by that script are outside an Infrastructure
Checkpoint or Express Checkpoint. This repository-local exception does not
apply when another Codex project merely has either infrastructure repository
available in its workspace or reads files from it during the session-start
Dashboard preflight.
