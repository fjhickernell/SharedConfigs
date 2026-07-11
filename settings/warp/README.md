# Warp Configuration

This directory contains the portable Warp configuration shared across all Macs.

## Shared Files

* `settings.toml`
* `keybindings.yaml`
* `tab_configs/startup_config.toml`

These files are linked into `~/.warp` by `link_sharedconfigs_minimal.sh`.

## Why These Files?

These files contain user preferences:

* appearance
* fonts
* themes
* keybindings
* startup tab configuration

They are plain-text configuration and have been verified to work correctly through symbolic links.

## Not Shared

The following should remain local to each Mac:

* caches
* logs
* databases
* temporary files
* machine-specific state

If Warp introduces additional configuration files in future releases, evaluate them individually before adding them to `SharedConfigs`.

## Validation History

The shared configuration was validated on:

* M5 MacBook Pro
* M3 MacBook Pro
* Mac mini
* Intel MacBook Pro

Testing confirmed that Warp:

* follows symbolic links correctly,
* updates shared files without replacing the symlink,
* makes minimal edits to `settings.toml`,
* synchronizes cleanly through Git and iCloud Drive.

## Maintenance

After modifying Warp settings:

1. Verify the changes behave as expected.
2. Run `sharedconfigs-save.sh`.
3. Allow iCloud to synchronize.
4. Restart Warp on other Macs if necessary.

The bootstrap script `link_sharedconfigs_minimal.sh` installs these links automatically on newly configured Macs.
