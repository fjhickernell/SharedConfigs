# SharedConfigs

This repository contains portable personal configuration and infrastructure
scripts shared through Git across my Macs.

## Contents
- `Brewfile`: Homebrew package list for system parity
- `texmf/`: Local LaTeX styles and macros
- `BibDesk/`: retained BibDesk templates and support-file archive; the live
  Application Support directory remains machine-local
- `bin/`: Utility scripts (e.g., `sync-brew.sh`)
- `settings/managed-links.conf`: Canonical inventory of home-directory links
- `settings/vault-links.conf`: Canonical inventory of deliberate Obsidian-vault links

## Sync Strategy

- Each Mac has a Git checkout at `~/Documents/SharedConfigs`.
- `arrive` and `depart` handle the normal multi-repository synchronization
  workflow. `arrive` first runs `git-repo-sync.sh --pull-only` for both
  infrastructure repositories, then continues without restarting. Changes to
  `arrive` itself take effect on the next invocation.
  This fast-forward-only step never stages, commits, rebases, stashes, or pushes.
  Dirty trees, unpublished/divergent commits, and refresh failures stop arrival
  before development or active synchronization. Publish intended local work
  with `infra save` before retrying. `depart` does not publish infrastructure;
  the existing full `git-repo-sync.sh` workflow remains available separately.
- On a Mac with the old `arrive`, first update its clean SharedConfigs checkout
  with `git -C ~/Documents/SharedConfigs pull --ff-only` to install this behavior.
- Home-directory configuration paths point into this checkout through the
  links declared in `settings/managed-links.conf`.
- GitHub provides published history and remote reconciliation. Documents is
  also managed by iCloud Drive on Mini, so SharedConfigs files can synchronize
  through iCloud. Do not assume `~/Documents` is outside iCloud; check each
  Mac's Documents configuration when relevant.

## Machine Configuration Audit

Run `sharedconfigs-audit` for the managed home-directory links plus Zsh syntax
and clean-startup probes. It is read-only unless `--repair` is explicitly
given; repair mode backs up every displaced path before creating a link.
Manifest entries declare whether they are required or optional and which
machine short names they apply to. Intentional local exceptions live outside
Git in `~/.config/sharedconfigs/link-audit-exemptions.conf` as `name|reason`;
the auditor always reports an active exemption.

Run `machine-audit` for the broader read-only check: managed links, Zsh,
machine identity, essential commands, Obsidian vault wiring, and locally
cached repository state. `machine-audit --full` additionally queries live
remote tips and checks the Brewfile without updating local refs.

When infrastructure changes are ready to publish, send the exact command
`infra save`. It is the short alias for the full Infrastructure Checkpoint
across SharedConfigs and GitTracked.

## Managed Repository Check

`arrive` checks Codex projects against the shared project manifest after
repository synchronization. `depart` records portable project/folder and
repository-registry observations for the other Macs. Findings produce a
nonzero exit and a terminal checklist. See
[Cross-machine project alerts](Notes/project-alignment.md) for the shared
iCloud files, conflict rules, and manual app setup steps.

Run `repo-sweep` to check the current `dev`, `active`, and `infrastructure`
repositories and print only those needing attention, including unpublished
work on linked worktrees or dormant local branches. Codex maintains the shared
scope in `settings/repositories.conf` when asked to add or archive a repository.
