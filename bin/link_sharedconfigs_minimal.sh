#!/bin/zsh

# Compatibility entry point for onboarding or repairing a Mac. The canonical
# inventory and all safety checks live in sharedconfigs-audit.

set -euo pipefail

script_dir=${0:A:h}
exec "$script_dir/sharedconfigs-audit" --repair --all "$@"
