#!/usr/bin/env bash
set -u
set -o pipefail

repo_root="/Users/fredjhickernell/Documents/SharedConfigs"
target="slides/02-estimator.qmd"
target_base="02-estimator"
log="/Users/fredjhickernell/Documents/SharedConfigs/.quarto-watch-logs/02-estimator.render.log"
FAST="0"
render_flags="--no-cache"

if [ "$FAST" -eq 0 ]; then
  rm -rf "$repo_root/slides/_freeze" >/dev/null 2>&1 || true
else
  rm -rf "$repo_root/slides/_freeze/$target_base"* >/dev/null 2>&1 || true
fi

quarto render "$repo_root/$target" $render_flags >"$log" 2>&1
rc=$?

if [ $rc -ne 0 ]; then
  echo "============================================================"
  echo "WARNING: quarto render failed (watch continues)"
  echo "log: $log"
  echo "------------------------------------------------------------"
  tail -n 50 "$log" 2>/dev/null || true
  echo "============================================================"
  exit 0
fi

rm -rf "$repo_root/slides/_site/classlib" >/dev/null 2>&1 || true
mkdir -p "$repo_root/slides/_site/classlib" >/dev/null 2>&1 || true
rsync -a --delete "$repo_root/classlib/" "$repo_root/slides/_site/classlib/" >/dev/null 2>&1 || true

echo "[ok] $(date '+%H:%M:%S')"
exit 0
