# syncbrew LaunchAgent — v4 (username‑aware)

**Purpose:**  
Run `~/bin/sync-brew-launchd.sh` automatically on login and once per day to keep Homebrew packages synchronized across all Macs.

---

## Installation (for any Mac)

Different Macs use different short usernames:

- `fredhickernell`
- `fredjhickernell`

Because `launchd` does **not** expand `$HOME`, each plist must contain **hard-coded absolute paths**.  
SharedConfigs therefore contains **two** template plists:

```
LaunchAgents/
  com.fredhickernell.syncbrew.plist       (for user = fredhickernell)
  com.fredjhickernell.syncbrew.plist      (for user = fredjhickernell)
```

### Install or refresh the LaunchAgent

Run the installer script:

```bash
~/Documents/SharedConfigs/bin/syncbrew-install.sh
```

This script:

- Detects your username (`whoami`)
- Chooses the appropriate plist template
- Installs it into:  
  `~/Library/LaunchAgents/com.fredhickernell.syncbrew.plist`
- Reloads the LaunchAgent with `launchctl`

---

## Scripts required in `~/bin`

These are copied automatically by the installer:

| Script | Purpose |
|--------|---------|
| `sync-brew-launchd.sh` | Launchd wrapper: sets PATH, logs output |
| `sync-brew.sh` | Main Homebrew sync logic |
| Canonical versions live in `~/Documents/SharedConfigs/bin` |

---

## Schedule

- `RunAtLoad`: runs at login  
- `StartCalendarInterval` daily at **9:30 AM**

You can edit either plist template if you want another time.

---

## Log file

```
~/Library/Logs/syncbrew.log
```

Check recent runs:

```bash
tail -100 ~/Library/Logs/syncbrew.log
```

Watch live:

```bash
tail -f ~/Library/Logs/syncbrew.log
```

---

## Verify LaunchAgent is running

```bash
launchctl list | grep syncbrew
```

Expected:

```
-    0    com.fredhickernell.syncbrew
```

---

## Notes

- Both plists are stored in Git under SharedConfigs for consistency.
- The installer script handles all username differences.
- Each Mac keeps its own copy of the finalized plist in `~/Library/LaunchAgents`.
