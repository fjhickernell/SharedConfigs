#!/usr/bin/env bash
set -u
set -o pipefail

export QUARTO_PYTHON=/opt/miniconda3/envs/qmcpy/bin/python

repo_root="/Users/fredhickernell/Documents/SharedConfigs"
target="slides/SIAMUQ2026.qmd"
target_base="SIAMUQ2026"
log="/Users/fredhickernell/Documents/SharedConfigs/.quarto-watch-logs/SIAMUQ2026.render.log"
FAST="0"
render_flags="--no-cache"

export PYTHONPATH="$repo_root/classlib${PYTHONPATH:+:$PYTHONPATH}"

echo "QUARTO_PYTHON=$QUARTO_PYTHON"
echo "PYTHONPATH=$PYTHONPATH"

if [ "$FAST" -eq 0 ]; then
  rm -rf "$repo_root/slides/_freeze" >/dev/null 2>&1 || true
else
  rm -rf "$repo_root/slides/_freeze/$target_base"* >/dev/null 2>&1 || true
fi

( cd "$repo_root/slides" && quarto render "${target#slides/}" $render_flags ) >"$log" 2>&1
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
