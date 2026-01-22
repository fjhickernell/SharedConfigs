#!/usr/bin/env bash
set -euo pipefail

sync-dev.sh
sync-class.sh --push
