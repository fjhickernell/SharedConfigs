#!/bin/zsh

# Install Starship when needed, then repair only its managed configuration
# link. Zsh prompt initialization already lives in the shared zshrc.

set -euo pipefail

script_dir=${0:A:h}

if (( $# > 0 )); then
  if (( $# == 1 )) && [[ "$1" == "-h" || "$1" == "--help" ]]; then
    cat <<'EOF'
Usage: setup-starship.sh

Install Starship if needed, then safely repair its managed configuration link.
EOF
    exit 0
  fi
  print -u2 -r -- "ERROR: setup-starship.sh accepts no arguments."
  exit 2
fi

if ! command -v starship >/dev/null 2>&1; then
  if ! command -v brew >/dev/null 2>&1; then
    print -u2 -r -- "ERROR: Homebrew is required to install Starship."
    exit 1
  fi
  brew install starship
fi

exec "$script_dir/sharedconfigs-audit" --repair --all --links-only --group starship
