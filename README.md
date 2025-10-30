# SharedConfigs

This repository contains personal configuration files synchronized via iCloud and GitHub across all of my Macs.

## Contents
- `Brewfile`: Homebrew package list for system parity
- `texmf/`: Local LaTeX styles and macros
- `Karabiner/`: Keyboard mappings
- `LaTeXiT/`, `BibDesk/`, etc.
- `bin/`: Utility scripts (e.g., `sync-brew.sh`)

## Sync Strategy
- Files reside in `~/Documents/SharedConfigs` (iCloud Drive)
- Version history tracked with Git
- Remote backup: [GitHub repo](https://github.com/fjhickernell/SharedConfigs)
- Recommended sync script: `bin/sync-brew.sh`
