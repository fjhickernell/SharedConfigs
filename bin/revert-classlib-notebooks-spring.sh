#!/usr/bin/env bash
set -euo pipefail

for r in MATH476Spring2026 MATH563Spring2026; do
  (cd ~/SoftwareRepositories/$r && revert-classlib-notebooks.sh)
done
