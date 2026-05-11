# Obsidian Vault Wiring (Mac Setup Reference)

**Vault name:** `ObsidianVault`  
**Canonical location:** `~/Documents/SharedConfigs/ObsidianVault`

This document explains how this Obsidian vault is wired to the filesystem and how to set it up on a new Mac.

---

## 1. Design principle

This vault is **not self-contained**.

It acts as:
- a conceptual index
- a navigation layer
- a graph view over real working directories

Most content is accessed via **symbolic links** into SharedConfigs and SoftwareRepositories.

---

## 2. Required directory layout (must exist)

On every Mac using this vault, the following directories **must exist at these exact paths**:

```
~/Documents/SharedConfigs
~/SoftwareRepositories
```

These are part of the standard Mac setup for this environment.

---

## 3. Vault structure (high level)

At the top level, the vault contains:

- `Home.md` – entry point
- `Software/` – links into code repositories
- `Teaching/` – links into course repositories
- `Reference/` – notes and documentation
- `MasterLists/` – tracking and meta-lists
- `MacApps/` – links into app inventories
- `SharedConfigs-Notes/` – notes tied to SharedConfigs

---

## 4. Symbolic links used by this vault

The following paths inside the vault are **symbolic links** and must be recreated on a new Mac.

### Software
```
Software/classlib  → ~/SoftwareRepositories/HickernellClassLib
Software/qmcpy     → ~/SoftwareRepositories/QMCSoftware/qmcpy
```

### Teaching
```
Teaching/MATH476Spring2026 → ~/SoftwareRepositories/MATH476Spring2026
Teaching/MATH565Fall2025   → ~/SoftwareRepositories/MATH565Fall2025
```

### SharedConfigs
```
MacApps             → ~/Documents/SharedConfigs/MacApps
SharedConfigs-Notes → ~/Documents/SharedConfigs/Notes
```

### Reference links
```
Reference/SharedConfigs-README.md
Reference/README_bin.md
Reference/check_app_update_dates.md
Reference/ArtificialIntelligence
```

(All of these resolve into `~/Documents/SharedConfigs`.)

---

## 5. Obsidian configuration assumptions

- No community plugins are used
- No custom themes or CSS snippets
- Core plugins only
- `.obsidian/` syncs via iCloud

This keeps the vault portable and stable across machines.

---

## 6. Wiring procedure on a new Mac

1. Ensure iCloud Drive is fully synced
2. Confirm these directories exist:
   ```
   ~/Documents/SharedConfigs
   ~/SoftwareRepositories
   ```
3. Clone or restore required repositories into `~/SoftwareRepositories`
4. Create the symbolic links listed above
5. Install Obsidian (desktop app)
6. Open Obsidian → Open existing vault → `ObsidianVault`

If links open as folders (not broken), wiring is complete.

---

## 7. Troubleshooting

### Links appear broken in Obsidian
- Check that the target directory exists
- Check that the symlink points to the correct path
- Obsidian does not auto-create missing targets

### Graph view looks incomplete
- Missing repositories are the most common cause
- Confirm symlinks exist and resolve correctly

---

## 8. Philosophy (why this is done)

This setup ensures:
- one canonical copy of files
- no duplication across tools
- Obsidian reflects the real filesystem
- notes remain lightweight and durable

**Obsidian is a map, not the territory.**

---

*Last updated:* 2026-01-03

