#!/usr/bin/env bash
# Build main description, split off refs, and build summary.
# Usage:
#   prep_description_summary.sh main.tex [CUTOFF] [summary.tex]
#
# Defaults:
#   CUTOFF     = 15
#   summary    = summary.tex
#
# Output:
#   main.pdf                  ← from main.tex
#   main_no_refs.pdf          ← first CUTOFF pages
#   main_refs.pdf             ← remaining pages (if any)
#   summary.pdf               ← from summary.tex

set -euo pipefail

# --- args ---------------------------------------------------------------------
if [[ $# -lt 1 ]]; then
  echo "Usage: $(basename "$0") main.tex [CUTOFF] [summary.tex]"
  exit 1
fi

MAIN_TEX="$1"
CUTOFF="${2:-15}"
SUMMARY_TEX="${3:-summary.tex}"

# --- sanity -------------------------------------------------------------------
if [[ ! -f "$MAIN_TEX" ]]; then
  echo "❌ Cannot find main TeX file: $MAIN_TEX"
  exit 1
fi

if [[ ! "$CUTOFF" =~ ^[0-9]+$ ]]; then
  echo "❌ CUTOFF must be an integer; got: $CUTOFF"
  exit 1
fi

# --- names --------------------------------------------------------------------
MAIN_BASE="${MAIN_TEX%.tex}"        # e.g. description_2025
MAIN_PDF="${MAIN_BASE}.pdf"
NOREFS_PDF="${MAIN_BASE}_no_refs.pdf"
REFS_PDF="${MAIN_BASE}_refs.pdf"

# --- check for poppler tools --------------------------------------------------
command -v pdfseparate >/dev/null || { echo "Need poppler: brew install poppler"; exit 1; }
command -v pdfunite    >/dev/null || { echo "Need poppler: brew install poppler"; exit 1; }
command -v pdfinfo     >/dev/null || { echo "Need poppler: brew install poppler"; exit 1; }

# --- 1. build main file -------------------------------------------------------
echo "🛠  Building $MAIN_TEX → $MAIN_PDF"
pdflatex -interaction=nonstopmode "$MAIN_TEX" >/dev/null
bibtex "$MAIN_BASE" >/dev/null || true      # sometimes ok to continue if no .aux
pdflatex -interaction=nonstopmode "$MAIN_TEX" >/dev/null
pdflatex -interaction=nonstopmode "$MAIN_TEX" >/dev/null
echo "✅ Built $MAIN_PDF"

if [[ ! -f "$MAIN_PDF" ]]; then
  echo "❌ Expected PDF not found: $MAIN_PDF"
  exit 1
fi

# --- 2. split main pdf --------------------------------------------------------
echo "📄 Splitting $MAIN_PDF at page $CUTOFF ..."

# separate every page
pdfseparate "$MAIN_PDF" part-%d.pdf

# unite first $CUTOFF pages
pdfunite $(seq -f part-%g.pdf 1 "$CUTOFF") "$NOREFS_PDF"

# figure out total
TOTAL=$(pdfinfo "$MAIN_PDF" | awk '/Pages:/ {print $2}')

# unite the rest if there are pages beyond CUTOFF
if (( TOTAL > CUTOFF )); then
  pdfunite $(seq -f part-%g.pdf $((CUTOFF+1)) "$TOTAL") "$REFS_PDF"
  echo "✅ Created:"
  echo "  $NOREFS_PDF  (pages 1–$CUTOFF)"
  echo "  $REFS_PDF    (pages $((CUTOFF+1))–$TOTAL)"
else
  echo "✅ Created:"
  echo "  $NOREFS_PDF  (pages 1–$CUTOFF or fewer)"
  echo "ℹ️  No refs PDF created because total pages ($TOTAL) ≤ cutoff ($CUTOFF)."
fi

# clean up parts
rm part-*.pdf

# --- 3. build summary ---------------------------------------------------------
if [[ -f "$SUMMARY_TEX" ]]; then
  SUMMARY_BASE="${SUMMARY_TEX%.tex}"
  SUMMARY_PDF="${SUMMARY_BASE}.pdf"

  echo "🛠  Building summary: $SUMMARY_TEX → $SUMMARY_PDF"
  pdflatex -interaction=nonstopmode "$SUMMARY_TEX" >/dev/null
  pdflatex -interaction=nonstopmode "$SUMMARY_TEX" >/dev/null
  echo "✅ Built $SUMMARY_PDF"
else
  echo "⚠️  Summary TeX not found: $SUMMARY_TEX (skipping)"
fi

echo "🎉 Done."