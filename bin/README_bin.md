# SharedConfigs `bin/` – Script Guide (v1.2)

This README provides a complete reference to all scripts in  
`~/Documents/SharedConfigs/bin`, describing what each script does, when to run it, and why it exists.

---

## iCloud + Git Workflow

Your `SharedConfigs` folder lives in **iCloud Drive**, which means:

- **All edits propagate across all Macs automatically** within seconds.
- Day‑to‑day syncing happens via **iCloud**, not Git.
- **Git is used only for periodic snapshots**, not continuous syncing.

Use Git (`sharedconfigs-save.sh`) for:
- Major configuration milestones  
- Before/after travel  
- Before making risky edits  
- Occasional archival checkpoints  

This hybrid model uses:
- **iCloud** → fast, seamless, automatic sync  
- **Git** → backup, history, and version recovery  

---

## LaunchAgent Path Requirements

Because `launchd` does **not** load your shell environment or PATH, it cannot see:

```
~/Documents/SharedConfigs/bin
```

Therefore, *any script invoked by a LaunchAgent must live in*:

```
~/bin
```

Currently those are:

- `sync-brew.sh`
- `sync-brew-launchd.sh`

All other scripts run directly from SharedConfigs because `SharedConfigs/bin` is added to your PATH via `.zshrc`.

---

## Quick Reference Table

| Script | Category | Purpose |
|--------|----------|---------|
| `brew-publish` | Homebrew | Publish/update the canonical Brewfile in SharedConfigs. |
| `dump-mac-apps.sh` | Mac App Inventory | Dump installed apps/casks/App Store apps. |
| `export-macapps-xlsx.sh` | Mac App Inventory | Export the App Inventory to Excel. |
| `link_sharedconfigs_minimal.sh` | Mac Setup | Initial linking/copying of SharedConfigs items on a new Mac. |
| `prep_description_summary.sh` | Teaching | Create project description/summary templates. |
| `README_bin.md` | Documentation | This file. |
| `setup-starship.sh` | Shell | Install starship + link shared `starship.toml`. |
| `sharedconfigs-save.sh` | Git | Stage, commit, and push SharedConfigs changes. |
| `setup_matlab_toolboxes.sh` | MATLAB | Install or sync MATLAB toolboxes. |
| `setup-nbstripout.sh` | Jupyter | Configure `nbstripout` for reproducible notebooks. |
| `sync-brew.sh` | Homebrew | Sync Homebrew using the shared Brewfile. |
| `sync-brew-launchd.sh` | LaunchAgents | Wrapper script used by LaunchAgent for sync-brew. |
| `sync-qmcpy-env.sh` | Conda | Sync or upgrade the `qmcpy` environment. |
| `syncbrew-install.sh` | LaunchAgents | Install the sync-brew LaunchAgent. |
| `texstudio-fixed` | TeX | Launch TeXstudio with correct config path. |
| `update-macapps-inventory.sh` | Mac App Inventory | Rebuild the Inventory Markdown file. |

---

# Detailed Script Descriptions

## Homebrew / Mac Maintenance

### `sync-brew.sh`
Synchronizes Homebrew formulae and casks using your canonical Brewfile.  
Shows `Using ...` vs `Installing ...`.  
Runs correctly under `launchd` when copied into `~/bin`.

### `sync-brew-launchd.sh`
Wrapper executed by LaunchAgent (`com.fredhickernell.syncbrew.plist`).  
Adds timestamps, logging, and safety for unattended runs.  
Must live in `~/bin`.

### `syncbrew-install.sh`
Installs or refreshes the LaunchAgent that runs sync-brew automatically at login and every 24 hours.

### `brew-publish`
Creates/updates the canonical Brewfile in SharedConfigs from a reference Mac.  
Used when defining the “gold standard” Homebrew configuration.

---

## SharedConfigs / Git Utilities

### `sharedconfigs-save.sh`
Your one‑step commit‑and‑push tool for SharedConfigs.  
Stages all changes, uses a timestamped machine-tagged commit message, and pushes to GitHub.

### `link_sharedconfigs_minimal.sh`
Initial “bring this Mac online” script.  
Sets up `~/bin`, links key SharedConfigs files, and establishes basic environment consistency.

---

## Shell / Terminal

### `setup-starship.sh`
Ensures consistent starship prompt across all Macs:

- Creates `~/.config`
- Symlinks shared `starship.toml`
- Installs starship via Homebrew if missing
- Inserts `eval "$(starship init zsh)"` into `.zshrc`

Once set up, editing the shared `starship.toml` updates all machines instantly via iCloud.

---

## Mac App Inventory

### `dump-mac-apps.sh`
Collects:

- Applications folder contents  
- Homebrew casks  
- Mac App Store apps (via `mas list`)  

Outputs per‑Mac text files used to generate the inventory.

### `update-macapps-inventory.sh`
Aggregates per‑Mac dumps and regenerates `MacAppsInventory.md` with checkmarks across Macs.

### `export-macapps-xlsx.sh`
Produces an Excel version of the App Inventory for easier filtering and review.

---

## Jupyter / Teaching

### `setup-nbstripout.sh`
Configures `nbstripout` so that Jupyter notebook outputs do not appear in Git commits.  
Supports your MATH 565 notebook‑checking workflow.

### `prep_description_summary.sh`
Generates boilerplate templates for student project summaries and descriptions.

---

## MATLAB

### `setup_matlab_toolboxes.sh`
Automates MATLAB toolbox installation or synchronization across Macs.

---

## Conda / QMCPy

### `sync-qmcpy-env.sh`

Normal sync:

```
sync-qmcpy-env.sh
```

Upgrade packages:

```
sync-qmcpy-env.sh --upgrade
```

Synchronizes the `qmcpy` Conda environment following your maintenance schedule (Dec / May / Aug).

---

## TeX / TeXstudio

### `texstudio-fixed`
A wrapper that:

- Detects the newest `/Applications/texstudio-*.app`
- Launches it with a fixed configuration path:
  `~/Library/Application Support/texstudio/texstudio.ini`
- Prevents TeXstudio from losing preferences

Your Dock icon should point to this script, not directly to TeXstudio.

---

# Updating This README

Whenever you add or modify a script:

1. Update the **Quick Reference Table**  
2. Update the **Detailed Description**  
3. Save the README and run `sharedconfigs-save.sh` when you want a Git snapshot  

This keeps your scripting environment clear, documented, and future‑proof.

