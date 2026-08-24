# SharedConfigs Architecture

## Purpose

The `SharedConfigs` repository is the canonical home for my portable macOS configuration.

Its goals are:

* Maintain a consistent working environment across all Macs.
* Version configuration using Git.
* Synchronize configuration via iCloud Drive.
* Keep application-specific settings in their expected locations by using symbolic links.
* Minimize machine-specific configuration.

The guiding principle is:

> **Share only human-edited configuration. Keep caches, databases, logs, and machine-specific state local.**

---

## Design

### Synchronization

Configuration is synchronized in two ways:

* **Git** provides version history and recovery.
* **iCloud Drive** propagates changes automatically among Macs.

Git answers *what changed*.

iCloud answers *where the change should appear*.

---

## Linking Strategy

Applications continue to use their normal configuration locations.

`link_sharedconfigs_minimal.sh` creates symbolic links from the standard macOS locations to files or directories inside `SharedConfigs`.

This provides three benefits:

* Applications require no special configuration.
* Shared settings are transparent to the application.
* A new Mac can be configured quickly.

---

## Directory vs. File Sharing

Some applications naturally store all portable configuration in a directory.

Examples:

* BibDesk
* LaTeXiT
* texmf

These use directory links.

Other applications store only a few configuration files.

Examples:

* Warp

These use file links.

The helper functions reflect this distinction:

* `link_to()` — directories
* `link_file_to()` — individual files

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
7. Add support to `link_sharedconfigs_minimal.sh`.

---

## Backup Strategy

When linking a new application:

* Existing files are renamed with a timestamp.
* The shared version replaces them via a symbolic link.
* Backups are retained until the configuration has been verified on all Macs.

---

## Current Shared Applications

* BibDesk
* Codex global instructions (`~/.codex/AGENTS.md` → `codex/AGENTS.md`)
* LaTeXiT
* texmf
* Warp

Additional applications should be added conservatively.

The objective is reliability rather than maximizing the number of shared settings.

---

## Philosophy

This repository is not simply a collection of configuration files.

It is the infrastructure that keeps multiple Macs behaving consistently while remaining easy to rebuild, understand, and maintain.
