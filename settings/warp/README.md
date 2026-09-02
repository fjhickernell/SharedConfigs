# Warp Configuration

This directory contains the portable Warp configuration shared across all Macs.

## Shared Files

* `settings.toml`
* `keybindings.yaml`
* `tab_configs/startup_config.toml`

These links are declared in `settings/managed-links.conf`.
`sharedconfigs-audit --group warp --all` verifies them without making changes;
`link_sharedconfigs_minimal.sh` repairs them during onboarding or an explicit
full-link repair.

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
* synchronizes cleanly through the managed Git workflow.

## Maintenance

After modifying Warp settings:

1. Verify the changes behave as expected.
2. Run `sharedconfigs-audit --group warp --all`.
3. Use an Infrastructure Checkpoint to validate, commit, and push the
   SharedConfigs change.
4. Before leaving the Mac, run `depart` for the wider managed development and
   active-repository synchronization.
5. After SharedConfigs is updated through Git on another Mac, restart Warp if
   necessary.

The bootstrap script `link_sharedconfigs_minimal.sh` installs these links automatically on newly configured Macs.
