# syncbrew LaunchAgent template

**Purpose:**  
Run `~/bin/sync-brew-launchd.sh` automatically on login and then every 24 hours  
to keep Homebrew packages synchronized across all Macs.

---

## Installation on any Mac

The plist template uses `$HOME` instead of an absolute `/Users/...` path,  
so it works correctly on any account.

```bash
mkdir -p ~/Library/LaunchAgents ~/bin

# Copy both scripts locally from SharedConfigs
cp ~/Documents/SharedConfigs/bin/sync-brew-launchd.sh ~/bin/
cp ~/Documents/SharedConfigs/bin/sync-brew.sh ~/bin/
chmod +x ~/bin/sync-brew-launchd.sh ~/bin/sync-brew.sh

# Expand $HOME placeholders and install the LaunchAgent
sed "s|\$HOME|$HOME|g"   ~/Documents/SharedConfigs/LaunchAgents/com.fredhickernell.syncbrew.plist   > ~/Library/LaunchAgents/com.fredhickernell.syncbrew.plist

# Reload the LaunchAgent
launchctl unload ~/Library/LaunchAgents/com.fredhickernell.syncbrew.plist 2>/dev/null
launchctl load  ~/Library/LaunchAgents/com.fredhickernell.syncbrew.plist
```

---

## Schedule

- Uses `RunAtLoad` + `StartInterval=86400` → runs once a day (not on every wake)
- Adjust `StartInterval` seconds as desired (e.g., `172800` for every 2 days)

---

## Log file

`~/Library/Logs/syncbrew.log`

---

## Scripts required

| Script | Location | Purpose |
|--------|-----------|----------|
| `sync-brew-launchd.sh` | `~/bin` | Launchd wrapper that sets PATH, runs main script, logs output |
| `sync-brew.sh` | `~/bin` | Main Homebrew sync logic (copied from SharedConfigs) |
| *(Canonical sources)* | `~/Documents/SharedConfigs/bin` | Version-controlled copies of both scripts |

---

## Verification

To confirm the job ran successfully:

```bash
launchctl list | grep syncbrew
tail -20 ~/Library/Logs/syncbrew.log
```

Expected results:
- The log ends with `✓  Homebrew packages are synced…` and `job done`.
- `launchctl list` shows exit code `0`:

  ```
  -   0   com.fredhickernell.syncbrew
  ```

---

## Notes

- Keep this README and `.plist` in `~/Documents/SharedConfigs/LaunchAgents/`
  as canonical copies under Git version control.
- Each Mac should have its own local `~/bin` copies of both scripts.
- If the iCloud “Documents” location denies write permission under launchd,
  the script automatically uses temporary files for diffs instead.
