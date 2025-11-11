# 🌭 Mac Applications Inventory

This folder tracks which macOS **Applications** (`.app` bundles) are installed on each of my Macs.
It produces a central, version-controlled inventory (`MacAppsInventory.md`) and an optional Excel version for filtering.

---

## 🗁️ Folder structure

```
SharedConfigs/
└── MacApps/
    ├── MacAppsInventory.md         ← Master inventory (Markdown)
    ├── MacAppsInventory.xlsx       ← Auto-generated Excel version
    ├── ignore-apps.txt             ← Optional list of apps to exclude
    ├── Freds-Mac-mini.*.txt        ← Lists from dump-mac-apps script
    ├── Freds-2023-M2-MacBook-Pro.*.txt
    ├── … other Macs …
    └── README.md                   ← This file
```

---

## ⚙️ Scripts used

All scripts live in `~/Documents/SharedConfigs/bin/`.

| Script                        | Purpose                                                                                                          |
| ----------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| `dump-mac-apps.sh`            | Scans the current Mac for installed apps and writes `.applications.txt`, `.brew-casks.txt`, and `.appstore.txt`. |
| `update-macapps-inventory.sh` | Combines all per-Mac lists into one master table, preserving `Usage` and `Notes`.                                |
| `export-macapps-xlsx.sh`      | Converts the Markdown table into a filterable Excel file using Pandoc.                                           |

---

## 🧬 1. Initial setup (one time)

1. Install Pandoc and mas:

   ```bash
   brew install pandoc mas
   brew-publish
   ```
2. Sign in to the Mac App Store app (mas uses this login).
3. Verify:

   ```bash
   mas list
   ```

   It should display a list of installed Mac App Store apps.

---

## 💾 2. Generate app lists on each Mac

On each Mac (M2, M3, Mini, Intel):

```bash
cd ~/Documents/SharedConfigs
git pull
dump-mac-apps.sh
update-macapps-inventory.sh
export-macapps-xlsx.sh
git add MacApps/
git commit -m "Update Mac apps list for $(hostname -s)"
git push
```

This creates three text files per Mac:

* `*.applications.txt` – all `.app` bundles in `/Applications` and `~/Applications`
* `*.brew-casks.txt` – GUI apps installed via Homebrew Cask
* `*.appstore.txt` – apps installed from the Mac App Store (via `mas list`)

Then:

* `update-macapps-inventory.sh` regenerates `MacAppsInventory.md` from all `.applications.txt` files.
* It preserves your **Usage** and **Notes** entries automatically.
* It auto-fills the **Source** column from the brew and App Store lists.
* Finally, `export-macapps-xlsx.sh` converts the Markdown to Excel and opens it automatically.

---

## 🏷️ 3. Labeling apps

Edit `MacAppsInventory.md` directly (in any Markdown editor or VS Code).
You can freely type in the `Usage` and `Notes` columns; they are preserved automatically.

Suggested tags for `Usage`:

| Tag            | Meaning                             |
| -------------- | ----------------------------------- |
| `Active`       | Essential or frequently used        |
| `Rare`         | Occasionally used                   |
| `Ignore`       | Unneeded on a new setup             |
| `Ignore (iOS)` | iPhone/iPad app running under macOS |
| `Legacy`       | Old or transitional version         |

Example row:

```markdown
| TeXShop | Manual | ✓ |  | ✓ |  | Active | Main LaTeX editor |
```

---

## 🧬 4. Grouping apps into families

Many applications come from the same developer or serve similar roles (e.g., browsers, office suites, text editors).
To help with filtering and replacement decisions, you can define **families** in the inventory.

Add a new **Family** column (between “App” and “Source”) or include a `Family:` tag in the **Notes** field.

Example:

```markdown
| App | Family | Source | M2 | M3 | Mini | Intel | Usage | Notes |
|------|---------|---------|----|----|------|--------|--------|-------|
| Pages | Apple Suite | AppStore | ✓ | ✓ | ✓ | ✓ | Active |  |
| Numbers | Apple Suite | AppStore | ✓ | ✓ | ✓ | ✓ | Rare |  |
| Excel | Office Suite | Brew | ✓ |   | ✓ | ✓ | Active | Family: Microsoft Office |
```

The update script preserves these entries automatically.
When exported to Excel, you can filter or group by `Family` to compare alternatives (e.g., Safari vs Chrome, TeXShop vs TeXStudio).

---

## 📊 5. Exporting for filtering or sorting

For interactive filtering or sorting:

```bash
cd ~/Documents/SharedConfigs
bin/export-macapps-xlsx.sh
```

This regenerates `MacAppsInventory.xlsx` and opens it automatically in Excel or Numbers.

---

## 🧹 6. Optional ignore list

To permanently exclude noisy or iOS-only apps from scans:

1. Edit `MacApps/ignore-apps.txt`, one app name per line (without `.app`).
2. Rerun:

   ```bash
   cd ~/Documents/SharedConfigs
   bin/dump-mac-apps.sh
   git add MacApps
   git commit -m "Regenerate app list with ignore filter"
   git push
   ```

Apps listed there will be excluded from `*.applications.txt` and the inventory.

---

## 🧱 Notes

* `Usage`, `Notes`, and `Family` persist across updates as long as app names remain unchanged.
* The Excel version is **read-only for convenience**; edit the Markdown file instead.
* All data lives in iCloud (`SharedConfigs`) and syncs automatically across Macs.

---

*Last updated: 2025-11-11*
