This document tracks the status of core software, SharedConfigs integration, and script behavior across all four Macs.

Macs:
- **M2 MBP** (home office)
- **M3 MBP** (work office)
- **M4 Mini** (family room)
- **Intel MBP 2019** (bedroom)

SharedConfigs is the source of truth. Use this file to log or check each Mac’s alignment.

---

## SharedConfigs Sync Status

### General Guidelines
- SharedConfigs lives in iCloud for instant sync.
- Git snapshots are taken occasionally using sharedconfigs-save.sh.
- Do not store repos inside SharedConfigs; store configs only.

### Confirm the following on each Mac:
- `~/Documents/SharedConfigs` exists and is up-to-date.
- `~/bin` contains symlinks or copies of SharedConfigs/bin scripts as needed.
- Starship prompt picks up `settings/terminal/starship.toml`.
- MarkEdit preview files in SharedConfigs/settings/ are in place.

---

## Script Behavior (Cross-Mac)

### regular-maintenance.sh
- `sudo -v` suppresses repeated mas prompts.
- tlmgr always requires its own password prompt.
- Homebrew privileged updates still require password.

### sync-qmcpy-env.sh
- Activates qmcpy environment.
- Pulls develop branch of QMCSoftware.
- Performs editable install.

### sync-brew (previous LaunchAgent workflow deprecated)
- All syncbrew LaunchAgents removed as of 2025-12-04.
- New maintenance is run manually or via regular-maintenance.sh.

---

## Warp Terminal

- Enable “Use agent” in bottom bar to restore AI features.
- Agent panel includes slash commands, voice input, context toggles, and image attachments.
- Terminal prompt comes from starship, not Warp’s AI mode.

---

## Keyboard Mapping Issue (External Windows Keyboard)
Fix requires:
1. Quit Karabiner.
2. Delete keyboard prefs:
   - `~/Library/Preferences/com.apple.keyboardservicesd.plist`
   - `~/Library/Preferences/com.apple.KeyboardSettings.extension.plist`
3. `defaults delete -g com.apple.keyboard.modifiermapping`
4. Restart daemons:
   - `killall -u $USER cfprefsd`
   - `killall -u $USER keyboardservicesd`
5. Sign out or reboot.
6. Plug keyboard back in → run Keyboard Setup Assistant → select ANSI → remap Option/Command.

---

## Wi-Fi Troubleshooting (Hickmansion vs Hacienda)

### Xfinity Gateway (Hickmansion)
- Solid white: healthy.
- Blinking green: connection issue.
- If Eeros show “No Internet” → reboot gateway.

### Eero Mesh (Hacienda)
- White: healthy.
- Red: lost Internet.
- Blinking blue: setup mode.
- If devices can’t connect: reboot Eeros.

---

## Notes for Testing Student Installations
- Perform clean Test User account installations after Dec 15 each year.
- Verify notebook execution under standard environment.