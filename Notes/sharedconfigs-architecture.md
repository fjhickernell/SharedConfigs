# SharedConfigs Architecture

## Purpose

The `SharedConfigs` repository is the canonical home for my portable macOS configuration.

Its goals are:

* Maintain a consistent working environment across all Macs.
* Version configuration using Git.
* Synchronize configuration through the managed Git workflow.
* Keep application-specific settings in their expected locations by using symbolic links.
* Minimize machine-specific configuration.

The guiding principle is:

> **Share only human-edited configuration. Keep caches, databases, logs, and machine-specific state local.**

---

## Design

### Synchronization

Each Mac has a Git checkout at `~/Documents/SharedConfigs`. The managed
`arrive`/`depart` and infrastructure synchronization workflows move changes
between those checkouts through Git. The Obsidian vault is a separate iCloud
workspace; SharedConfigs itself is not synchronized by iCloud.

---

## Linking Strategy

Applications continue to use their normal configuration locations.

`settings/managed-links.conf` is the single source of truth for symbolic links
from standard macOS locations to files or directories inside SharedConfigs.
`sharedconfigs-audit` checks the inventory without changing anything.
`link_sharedconfigs_minimal.sh` is the compatibility entry point for explicit
repair and onboarding; it delegates to `sharedconfigs-audit --repair`.

This provides three benefits:

* Applications require no special configuration.
* Shared settings are transparent to the application.
* A new Mac can be configured quickly.

---

## Directory vs. File Sharing

Some applications naturally store all portable configuration in a directory.

The `texmf` tree uses a directory link. Live application-support directories
remain machine-local unless an application has been deliberately validated for
whole-directory sharing.

Other applications store only a few configuration files.

Examples:

* Warp
* Zsh startup files (`~/.zshenv`, `~/.zprofile`, and `~/.zshrc`)

These use file links.

The manifest records this distinction as `directory` or `file` for every
entry, and the auditor verifies the source type before any repair begins.
Each entry also declares required versus optional status and either `all` or a
comma-separated set of preferred machine short names. A deliberate local
exception can be recorded, with a reason, in the untracked
`~/.config/sharedconfigs/link-audit-exemptions.conf`; exemptions remain visible
in every audit and are never silently inferred.

---

## Criteria for Sharing

A configuration should normally be shared only if it is:

* Plain text.
* Intended to be edited by users.
* Portable across machines.
* Stable under symbolic links.

Configuration should generally **not** be shared if it contains:

* caches
* logs
* SQLite databases
* lock files
* machine identifiers
* hardware-specific information
* temporary state

---

## Workflow for New Applications

When evaluating whether to add a new application:

1. Inspect its configuration files.
2. Separate preferences from transient state.
3. Share only preferences.
4. Test on one Mac.
5. Verify that the application respects symbolic links.
6. Roll out to remaining Macs.
7. Add the link to `settings/managed-links.conf` and extend the audit fixtures
   when the new case introduces different behavior.

---

## Backup Strategy

When repairing or linking a new application:

* Existing files are renamed with a timestamp.
* The shared version replaces them via a symbolic link.
* Backups are retained until the configuration has been verified on all Macs.
* All declared sources are preflighted before repair begins, preventing a
  missing shared source from causing a partial repair.
* Broad home-directory containers and any destination overlapping the source
  repository are rejected before repair.
* If link creation fails or the process is interrupted, the active entry is
  rolled back to its preserved original when that can be done safely.

---

## Current Shared Applications

* Codex global instructions (`~/.codex/AGENTS.md` → `codex/AGENTS.md`)
* MarkEdit's portable script, style, and settings files
* Starship
* texmf
* Warp
* Zsh startup files (`~/.zshenv`, `~/.zprofile`, and `~/.zshrc`)

Karabiner-Elements, LaTeXiT, and BibDesk's live Application Support directory
are deliberately outside the managed inventory. Karabiner and LaTeXiT are not
part of current workflows. BibDesk remains in use, but its writable support
directory stays local; `BibDesk/` in this repository is retained as an archive,
not as a live link target.

Additional applications should be added conservatively.

The objective is reliability rather than maximizing the number of shared settings.

---

## Philosophy

This repository is not simply a collection of configuration files.

It is the infrastructure that keeps multiple Macs behaving consistently while remaining easy to rebuild, understand, and maintain.
