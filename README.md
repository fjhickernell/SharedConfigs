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
  workflow; `git-repo-sync.sh` handles the infrastructure repositories.
- Home-directory configuration paths point into this checkout through the
  links declared in `settings/managed-links.conf`.
- The GitHub remote provides cross-machine synchronization and history.

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

Run `repo-sweep` to check the current `dev`, `active`, and `infrastructure`
repositories and print only those needing attention, including unpublished
work on linked worktrees or dormant local branches. Codex maintains the shared
scope in `settings/repositories.conf` when asked to add or archive a repository.
