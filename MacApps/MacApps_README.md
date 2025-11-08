# 🧭 Mac Applications Inventory

This folder tracks which macOS **Applications** (`.app` bundles) are installed on each of my Macs.  
It produces a central, version-controlled inventory (`MacAppsInventory.md`) and an optional Excel version for filtering.

---

## 📁 Folder structure

```
SharedConfigs/
└── MacApps/
    ├── MacAppsInventory.md         ← Main master table (Markdown)
    ├── MacAppsInventory.xlsx       ← Auto-generated Excel view
    ├── ignore-apps.txt             ← Optional list of apps to exclude
    ├── Freds-Mac-mini.*.txt        ← Lists from dump-mac-apps script
    ├── Freds-2023-M2-MacBook-Pro.*.txt
    ├── … other Macs …
    └── README.md                   ← This file
```

---

## ⚙️ Scripts used

All scripts live in `~/Documents/SharedConfigs/bin/`.

| Script | Purpose |
|-------|---------|
| `dump-mac-apps.sh` | Scans the current Mac for installed apps and writes `.applications.txt`, `.brew-casks.txt`, and `.appstore.txt`. |
| `update-macapps-inventory.sh` | Combines all per-Mac lists into one master table, preserving `Usage` and `Notes`. |
| `export-macapps-xlsx.sh` | Converts the Markdown table into a filterable Excel file using Pandoc. |

---

## 🧩 1. Initial setup (one time)

1. Install Pandoc and mas:

   ```bash
   brew install pandoc mas
   brew-publish
   ```

2. Sign in to the Mac App Store app (mas uses this login).

3. Verify:
   ```bash
   mas account
   ```
   It should display your Apple ID.

---

## 💾 2. Generate app lists on each Mac

On each Mac (M2, M3, Mini, Intel):

```bash
cd ~/Documents/SharedConfigs
git pull
bin/dump-mac-apps.sh
git add MacApps
git commit -m "Update Mac apps list for $(hostname -s)"
git push
```

This creates three text files per Mac:
- `*.applications.txt` – all `.app` bundles in `/Applications` and `~/Applications`
- `*.brew-casks.txt` – GUI apps installed via Homebrew Cask
- `*.appstore.txt` – apps installed from the Mac App Store (via `mas list`)

---

## 🔄 3. Update the master inventory

On **any** Mac:

```bash
cd ~/Documents/SharedConfigs
git pull
bin/update-macapps-inventory.sh
git add MacApps/MacAppsInventory.md
git commit -m "Update Mac apps inventory"
git push
```

- This regenerates `MacAppsInventory.md` from all `.applications.txt` files.  
- It automatically keeps your **Usage** and **Notes** tags for each app.  
- (Future version: will also auto-fill the **Source** column from brew/appstore lists.)

---

## 🏷️ 4. Labeling apps

Edit `MacAppsInventory.md` directly (in any Markdown editor or VS Code).  
You can freely type in the `Usage` and `Notes` columns; they are preserved automatically.

Suggested tags for `Usage`:

| Tag          | Meaning                         |
|--------------|---------------------------------|
| `Active`     | Essential or frequently used    |
| `Rare`       | Occasionally used               |
| `Ignore`     | Unneeded on a new setup         |
| `Ignore (iOS)` | iPhone/iPad app on macOS     |
| `Legacy`     | Old or transitional version     |

Example row:

```markdown
| TeXShop | Manual | ✓ |  | ✓ |  | Active | Main LaTeX editor |
```

---

## 📤 5. Export to Excel

For interactive filtering or sorting:

```bash
cd ~/Documents/SharedConfigs
bin/export-macapps-xlsx.sh
```

This uses `pandoc` to convert `MacAppsInventory.md` → `MacAppsInventory.xlsx`  
and opens it in Excel automatically.

---

## 🧹 6. Optional ignore list

To permanently exclude noisy or iOS-only apps from scans:

1. Edit `MacApps/ignore-apps.txt`, one app name per line (without `.app`).
2. Rerun the dump script:
   ```bash
   cd ~/Documents/SharedConfigs
   bin/dump-mac-apps.sh
   git add MacApps
   git commit -m "Regenerate app list with ignore filter"
   git push
   ```
Apps listed there will not appear in `*.applications.txt` or the inventory.

---

## 🔁 7. Typical refresh cycle

Every few months or after installing new apps:

```bash
# On each Mac
cd ~/Documents/SharedConfigs
git pull
bin/dump-mac-apps.sh
git add MacApps
git commit -m "Refresh Mac apps for $(hostname -s)"
git push

# On one Mac
git pull
bin/update-macapps-inventory.sh
git add MacApps/MacAppsInventory.md
git commit -m "Update Mac apps inventory"
git push
bin/export-macapps-xlsx.sh
```

---

## 🧱 Notes

- `Usage` and `Notes` persist across updates as long as the app name doesn’t change.
- The Excel version is **read-only for convenience**; edit the Markdown file instead.
- All data is stored in iCloud via `SharedConfigs` and synchronized automatically across Macs.

---

_Last updated: 2025-11-07_
