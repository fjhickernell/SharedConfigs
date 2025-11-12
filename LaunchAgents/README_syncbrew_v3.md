# syncbrew LaunchAgent template

**Purpose:**  
Run `~/bin/sync-brew-launchd.sh` automatically on login and then every 24 hours  
to keep Homebrew packages synchronized across all Macs.

---

## Installation on any Mac

The plist template uses `$HOME` instead of an absolute `/Users/...` path,  
so it works correctly on any account.

Here we

- make the necessary directories, if necessary
- Copy both scripts locally from SharedConfigs
- Expand $HOME placeholders and install the LaunchAgent
- Reload the LaunchAgent

```bash
mkdir -p ~/Library/LaunchAgents ~/bin
cp ~/Documents/SharedConfigs/bin/sync-brew-launchd.sh ~/bin/
cp ~/Documents/SharedConfigs/bin/sync-brew.sh ~/bin/
chmod +x ~/bin/sync-brew-launchd.sh ~/bin/sync-brew.sh
sed "s|\$HOME|$HOME|g"   ~/Documents/SharedConfigs/LaunchAgents/com.fredhickernell.syncbrew.plist   > ~/Library/LaunchAgents/com.fredhickernell.syncbrew.plist
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


---

## 🔍 Checking When Apps Were Last Updated

You can check when apps were last updated in several ways, depending on how they were installed.

### 1. Homebrew Casks
To see when GUI apps installed via Homebrew were last updated:

```bash
ls -lt /usr/local/Caskroom | head -20      # Intel Mac
ls -lt /opt/homebrew/Caskroom | head -20   # Apple Silicon Mac
```
Each folder’s timestamp shows when that cask was last modified (i.e., last updated).  
Example:

```
drwxr-xr-x  4 fredjhickernell  admin  128 Nov  1 09:32 visual-studio-code
```
→ Visual Studio Code last updated on **Nov 1 09:32**.

### 2. App Store (MAS) Apps
If an app like WhatsApp or Pages was installed via the App Store (through `mas` in your Brewfile), it will **not** appear in `Caskroom`.  
Instead, check its bundle directly:

```bash
mdls -name kMDItemVersion -name kMDItemContentModificationDate /Applications/WhatsApp.app
```
This shows both the **version** and the **last modification date** for that app.

### 3. All Applications
To get a quick overview of all apps’ modification dates this command sorts by name of application:

```bash
stat -f "%Sm %N" /Applications/*.app | sort
```
That lists every `.app` bundle in `/Applications` by its last modification date.

This command sorts apps chronologically:

```bash
stat -f "%m %N" /Applications/*.app | sort -n | awk '{ cmd="date -r "$1" \"+%Y-%m-%d %H:%M:%S\""; cmd | getline d; close(cmd); $1=""; print d $0 }'
```


---

