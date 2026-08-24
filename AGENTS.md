# SharedConfigs Infrastructure Project Instructions

This repository is one of two entry points for the Infrastructure project. On
some computers `SharedConfigs` is the primary project repository; on others
the primary repository is `GitTracked` (named `GitTrackedObsidian` by
`git-repo-sync.sh`).

## Checkpoint scope and synchronization opt-in

For a Checkpoint requested with either Infrastructure entry point as the
current project, extend the normal project scope to both infrastructure
repositories:

- `~/Documents/SharedConfigs`
- `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/ObsidianVault/GitTracked`

Inspect and validate both repositories, then follow the global Checkpoint
workflow to commit and push their intended changes. After that succeeds, run
`git-repo-sync.sh` as the final synchronization step and report its result.

This project does not opt in to `sync-active.sh`; the active development and
teaching repositories managed by that script are outside an Infrastructure
Checkpoint. This repository-local exception does not apply when another Codex
project merely has either infrastructure repository available in its
workspace or reads files from it during the session-start Dashboard preflight.
