# SharedConfigs

This repository contains portable personal configuration and infrastructure
scripts shared through Git across my Macs.

## Contents
- `Brewfile`: Homebrew package list for system parity
- `texmf/`: Local LaTeX styles and macros
  (see the [fh-exam guide](texmf/tex/FredTexDefinitions/fh-exam.md) for paper quizzes and exams)
- `BibDesk/`: retained BibDesk templates and support-file archive; the live
  Application Support directory remains machine-local
- `bin/`: Utility scripts (e.g., `sync-brew.sh`)
- `matlab/`: Shared startup file and Chebfun/GAIL numerical checks
- `settings/managed-links.conf`: Canonical inventory of home-directory links
- `settings/vault-links.conf`: Canonical inventory of deliberate Obsidian-vault links

## Quarto Live Preview

Run `quarto-site-live` from a Quarto website's root directory for automatic
rendering and browser refresh. It prints and remembers a local port for the
project. Use `--no-open` to keep browser opening manual, or `--port PORT` to
choose a port. Stop the session with Ctrl+C before starting another for that site.

The helper watches nested page folders and shared classlib assets. Generated
output and directory-only timestamp changes are ignored, preventing renders
from triggering another render. Verify watcher behavior with
`python3 tests/test-quarto-site-live.py`; the test uses an isolated temporary
site and requires the installed live-preview dependencies.

## Sync Strategy

- Each Mac has a Git checkout at `~/Documents/SharedConfigs`.
- `arrive` and `depart` handle the normal multi-repository synchronization
  workflow. `arrive` first runs `git-repo-sync.sh --pull-only` for both
  infrastructure repositories, then continues without restarting. Changes to
  `arrive` itself take effect on the next invocation.
  This step fetches remote history but never stages, commits, rebases, stashes,
  or pushes. If HEAD matches upstream, local edits are preserved and arrival
  continues. If upstream is ahead, a clean tree is fast-forwarded; a dirty tree
  keeps its index, files, and HEAD unchanged and reports a deferred pull while
  arrival continues. Those remote updates remain uninstalled until later
  reconciliation or the normal morning Git snapshot. Wrong branch, origin, or
  upstream, unfinished or unmerged operations, unpublished/divergent commits,
  and fetch failures still stop arrival before development or active
  synchronization. `depart` does not publish infrastructure;
  its project capture writes to an external iCloud inbox so it does not dirty
  GitTracked. The existing full `git-repo-sync.sh` workflow remains available
  separately.
- `sync-active.sh` uses Git from `PATH` and checks that it runs before
  inspecting or changing repositories. This allows Homebrew Git to work when
  Apple's Git launcher is blocked by an unaccepted Xcode license; that license
  still needs acceptance to restore Apple's compiler and developer tools.
- On a Mac with the old `arrive`, wait for iCloud to deliver the updated script,
  or update a clean SharedConfigs checkout from published history with
  `git -C ~/Documents/SharedConfigs pull --ff-only` to install this behavior.
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

The normal daily morning Dashboard refresh usually supplies the infrastructure
Git snapshot. A same-day machine switch does not require `infra save` merely
because infrastructure files have changed; allow iCloud to finish delivering
the files. For a deliberate publication of significant changes, send the exact
command `infra save`. It is the short alias for the full Infrastructure
Checkpoint across SharedConfigs and GitTracked.

## Managed Repository Check

`arrive` runs `github-attention` after synchronization. It shows every open
issue and pull request (including drafts) in each current GitHub repository
under `fjhickernell` from `settings/repositories.conf`. Student reports
need no assignment, mention, or bug label to appear. For repositories under
another owner or organization, it shows only open issues and PRs mentioning
the authenticated GitHub user. Assignment or a review request alone does not
match that filter.
Results are grouped by repository with titles, authors, assignees, and links;
open items remain visible on repeated arrivals. Archived rows and non-GitHub
origins are excluded. API failures and incomplete searches produce a warning,
while checks continue for the remaining repositories. Run `github-attention`
directly for this read-only check without repository synchronization.
The check still runs after a development or active synchronization failure;
`arrive` then exits with the synchronization error. An infrastructure preflight
failure still stops arrival before the other checks.
The separate `pr-status` command retains its account-wide PR view.

`arrive` checks Codex projects against the shared project manifest after
repository synchronization. `depart` records portable project/folder and
repository-registry observations for the other Macs. Findings produce a
nonzero exit and a terminal checklist. New observations remain outside Git
until `infra save` imports and publishes them. See
[Cross-machine project alerts](Notes/project-alignment.md) for the shared
iCloud files, conflict rules, and manual app setup steps.

Run `repo-sweep` to check the current `dev`, `active`, and `infrastructure`
repositories and print only those needing attention, including unpublished
work on linked worktrees or dormant local branches. Codex maintains the shared
scope in `settings/repositories.conf` when asked to add or archive a repository.
For a flagged dormant branch, run `branch-audit --repo PATH`; it reports cached
ahead/behind state, patch equivalence, related GitHub pull requests, and a safe
recommended action without modifying the branch. Do not pull dormant branches
merely to keep them current. If the sweep reports `REMOTE-UNCERTAIN`, run its
printed full-history fetch first and then the printed branch audit.
