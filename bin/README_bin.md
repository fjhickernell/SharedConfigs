# SharedConfigs `bin/` – Script Guide (v1.3)

This README provides a complete reference to all scripts in  
`~/Documents/SharedConfigs/bin`, describing what each script does, when to run it, and how these scripts fit into your multi-Mac workflow.

---

## iCloud + Git Workflow

Your `SharedConfigs` folder lives in **iCloud Drive**, which means:

- **All edits propagate across all Macs automatically** within seconds.  
- Daily syncing of scripts happens via **iCloud**, not Git.  
- **Git is only for periodic snapshots** and version history.

Use Git via `sharedconfigs-save.sh` when:

- You reach a stable configuration point  
- Before travel or major system upgrades  
- After adding new scripts or modifying existing ones  
- You want a reproducible configuration checkpoint  

This hybrid approach gives:

- **iCloud** → instant cross-Mac updates  
- **Git** → safety, history, and rollback  

---

## LaunchAgent Path Requirements

`launchd` does **not** load your shell environment. It cannot see:

```
~/Documents/SharedConfigs/bin
```

Therefore any script run by a LaunchAgent must be placed in:

```
~/bin
```

As of v1.3, only these scripts must reside in `~/bin`:

- `sync-brew.sh`
- `regular-maintenance.sh` (if you ever choose to automate it—currently **manual only**)  

The older `sync-brew-launchd.sh` has been **retired**.

All other scripts stay in SharedConfigs because your `.zshrc` adds:

```
export PATH="$HOME/Documents/SharedConfigs/bin:$PATH"
```

---

## Quick Reference Table

| Script | Category | Purpose |
|--------|----------|---------|
| `brew-publish` | Homebrew | Publish/update canonical Brewfile in SharedConfigs. |
| `dump-mac-apps.sh` | Mac App Inventory | Dump installed apps/casks/MAS apps. |
| `export-macapps-xlsx.sh` | Mac App Inventory | Export inventory to Excel. |
| `link_sharedconfigs_minimal.sh` | Mac Setup | Bring a new Mac online with baseline links. |
| `prep_description_summary.sh` | Teaching | Build templates for project descriptions/summary. |
| `regular-maintenance.sh` | System Maintenance | Run sync-brew, update-texlive, qmcpy sync, etc. |
| `README_bin.md` | Documentation | This file. |
| `setup-starship.sh` | Shell | Install and link shared starship config. |
| `sharedconfigs-save.sh` | Git | Commit and push SharedConfigs snapshots. |
| `setup_matlab_toolboxes.sh` | MATLAB | Install or sync MATLAB toolboxes. |
| `sync-brew.sh` | Homebrew | Sync Homebrew formulae/casks using Brewfile. |
| `sync-qmcpy-env.sh` | Conda | Sync or upgrade the `qmcpy` conda environment. |
| `syncbrew-install.sh` | LaunchAgents | (Legacy) Install sync-brew LaunchAgent — now unused. |
| `texstudio-fixed` | TeX | Launch TeXstudio with stable preference paths. |
| `update-macapps-inventory.sh` | Mac App Inventory | Regenerate `MacAppsInventory.md`. |
| `update-texlive.sh` | TeX | Update TeX Live via tlmgr. |

---

# Detailed Script Descriptions

---

## System Maintenance

### `regular-maintenance.sh`
Your consolidated maintenance driver script.

It currently runs:

- `sync-brew.sh`
- `update-texlive.sh`  
- `sync-qmcpy-env.sh` (optional and commented in/out by you)  

Workflow:

1. **Run manually** (no LaunchAgent):
   ```
   regular-maintenance.sh
   ```
2. It does `sudo -v` and keeps sudo warm.  
3. You will still be prompted by:
   - `tlmgr` (always requires separate authentication)
   - Homebrew (for privileged installs)

This script is now your *primary unified maintenance workflow*.

---

## Homebrew

### `sync-brew.sh`
Synchronizes all Homebrew formulae and casks using your canonical Brewfile.

Shows `Using …` versus `Installing …` for clarity.

Resides in `~/bin` so it can be used in LaunchAgents should you ever re-enable automation.

### `brew-publish`
Creates or updates your “gold standard” Brewfile in SharedConfigs.

Use when:

- Installing or removing software  
- Cleaning up configuration  
- Standardizing all Macs  

---

## SharedConfigs / Git Utilities

### `sharedconfigs-save.sh`
Commit-and-push tool for SharedConfigs:

- Stages all changes  
- Adds timestamp + hostname  
- Pushes to GitHub  
- Does **not** pull first (safer with iCloud)  

### `link_sharedconfigs_minimal.sh`
Initial linking + setup step for a newly configured Mac:

- Ensures `~/bin` exists  
- Adds SharedConfigs/bin to PATH  
- Links starship config and other essentials  

Use once when onboarding a new machine.

---

## Shell / Terminal

### `setup-starship.sh`
Ensures consistent and shared starship setup:

- Installs starship via Homebrew  
- Creates `~/.config`  
- Symlinks shared `starship.toml`  
- Ensures `.zshrc` has `eval "$(starship init zsh)"`  

---

## Mac App Inventory

### `dump-mac-apps.sh`
Collects:

- Finder apps  
- Homebrew casks  
- MAS apps  

Outputs per-Mac lists used to build the inventory.

### `update-macapps-inventory.sh`
Aggregates all dumps and rebuilds:

```
MacAppsInventory.md
```

### `export-macapps-xlsx.sh`
Creates an Excel version of the inventory for filtering and comparison.

---

## Conda / QMCPy

### `sync-qmcpy-env.sh`

The authoritative environment-maintenance tool for QMCPy development and teaching.

At the May 15, August 1, and December 15 checkpoints, update base Conda separately before running this script. Normally start with:

```
conda update --name base conda
```

If Conda advertises a newer release but this command retains the installed version, do not force the release immediately. Inspect the candidate builds and dependencies with `conda search --info`, review configured and prefix pins, and preview the proposed explicit transaction with `conda install --name base --dry-run ...`. Proceed only after checking the dry run for solver compatibility, removals, downgrades, and channel changes.

On 2026-08-06, the M5 upgrade from Conda 26.3.2 to 26.7.0 required `conda-libmamba-solver>=26.4.1`; the reviewed transaction installed solver 26.7.0. The paired transaction was checked with `--dry-run` before installation. This is a dated diagnostic example, not a permanent version-pinned command.

After any base-Conda change, run full `sync-qmcpy-env.sh` validation on the reference machine. That post-Conda report supersedes the earlier reference report for additional Macs with comparable revisions and environment state.

#### **Full compatibility validation (default):**

```
sync-qmcpy-env.sh
```

This refreshes the canonical QMCSoftware and HickernellAcademicLib branches, reinstalls them in editable mode, applies personal requirements, refreshes and validates the `qmcpy` kernel, runs machine-local checks, and then executes the canonical notebooks, stable Quarto fixture, and advisory active-course checks.

Add `--upgrade` at an academic maintenance checkpoint to update the `qmcpy` environment first:

```
sync-qmcpy-env.sh --upgrade
```

#### **Machine-local maintenance and validation:**

```
sync-qmcpy-env.sh --machine-only
sync-qmcpy-env.sh --upgrade --machine-only
```

Machine-only mode performs the same local synchronization, editable installs, kernel verification, imports, version reporting, and `pip check`, but skips notebook, Quarto, and active-course compatibility checks. Use it on an additional Mac only after full compatibility validation has passed for the same QMCSoftware and HickernellAcademicLib revisions and a comparable environment state. Reports make the host, architecture, full repository revisions, interpreters, and package versions conspicuous.

The upgrade option performs a Conda update within the `qmcpy` environment and upgrades the explicitly maintained personal requirements. It never updates base Conda.

Required environment checks use canonical QMCPy notebooks and `python/qmcpy-env-smoke.qmd`. Advisory active course checks use `settings/qmcpy-env.conf`, which is the only file normally changed at a semester transition. Course warnings do not cause feature-branch merges, notebook edits, canonical checkout changes, or a failed environment status.

Successful runs write timestamped and latest validation reports plus a cumulative history under `reports/qmcpy-env/`. Machine-only reports use the top-level status `MACHINE-LOCAL PASS` and mark full compatibility `NOT RUN`; full reports use `PASS` or `PASS WITH COURSE WARNINGS`. Detailed output from a failed course check goes to a timestamped course-warning log instead of overwhelming the console.

**Recommendation:**  
Run full validation again when relevant source revisions change, important Python or dependency versions change materially, representative active-course files change, or the next machine has a materially different architecture. For the current rollout: run full upgrade validation on the M5, machine-only upgrade on the Mini if its revisions and environment are comparable, full upgrade validation on the Intel Mac, and machine-only upgrade on the M3 if it remains comparable to the Apple Silicon reference result.

---

## TeX / TeX Live / TeXstudio

### `update-texlive.sh`
Runs TeX Live package updates:

```
update-texlive.sh
```

Notes:

- Always prompts for the TeX Live password  
- No safe way to suppress this  
- Called automatically inside `regular-maintenance.sh`

### `texstudio-fixed`
A wrapper that:

- Detects latest `/Applications/texstudio-*.app`  
- Launches it with fixed config path  
  `~/Library/Application Support/texstudio/texstudio.ini`  
- Prevents loss of preferences  

Add this script to your Dock instead of TeXstudio.

---

## Teaching Tools

### `prep_description_summary.sh`
Generates boilerplate templates for student project summaries and descriptions.

(Previously `setup-nbstripout.sh` existed, but nbstripout is currently **not used** due to issues and has been removed from the README.)

---

# Updating This README

Whenever you add or modify a script:

1. Update the **Quick Reference Table**  
2. Update the **Detailed Descriptions**  
3. Save the README, then run `sharedconfigs-save.sh` if you want a Git snapshot  

This keeps your scripting environment clear, documented, and future-proof.
