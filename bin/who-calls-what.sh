#!/usr/bin/env bash
set -u
set -o pipefail

BASE="${HOME}/Documents/SharedConfigs"

if [ $# -eq 0 ]; then
  echo "Usage:"
  echo "  who-calls-what.sh <path-relative-to-SharedConfigs>"
  echo
  echo "Examples:"
  echo "  who-calls-what.sh bin"
  echo "  who-calls-what.sh bin/quarto-watch-deck"
  echo "  who-calls-what.sh settings/zsh/zshrc"
  exit 2
fi

TARGET="$1"
FULL_PATH="$BASE/$TARGET"

SEARCH_DIRS=(
  "$BASE/bin"
  "$BASE/settings/zsh"
)

CODE_GLOBS=(
  '*.{sh,bash,zsh,py,pl,rb,js,ts,yml,yaml,json,toml,ini,conf,txt,Makefile}'
  'Makefile'
)

DOC_GLOBS=(
  '*.{md,markdown}'
  'README*'
)

run_rg () {
  local needle="$1"
  local root="$2"
  shift 2
  local -a globs=( "$@" )

  local -a args
  args=( rg -n --no-heading --hidden --glob '!_archive/**' --glob '!*.bak' )

  for g in "${globs[@]}"; do
    args+=( --glob "$g" )
  done

  "${args[@]}" "$needle" "$root" 2>/dev/null || true
}

report_one_file () {
  local full="$1"
  local rel="$2"
  local name
  name="$(basename "$full")"

  echo "Checking inbound references to file: $rel"
  echo

  local any=0
  for dir in "${SEARCH_DIRS[@]}"; do
    local code docs

    code="$(run_rg "$name" "$dir" "${CODE_GLOBS[@]}")"
    docs="$(run_rg "$name" "$dir" "${DOC_GLOBS[@]}")"

    # Drop the file's own self-reference line, if the file is within the searched dir.
    if [ -n "$code" ]; then
      code="$(printf '%s\n' "$code" | rg -v --fixed-strings "$rel:" || true)"
    fi
    if [ -n "$docs" ]; then
      docs="$(printf '%s\n' "$docs" | rg -v --fixed-strings "$rel:" || true)"
    fi

    if [ -n "$code" ]; then
      any=1
      echo "CALLS in ${dir#$BASE/}"
      printf '%s\n' "$code"
      echo
    fi

    if [ -n "$docs" ]; then
      any=1
      echo "DOCS in ${dir#$BASE/}"
      printf '%s\n' "$docs"
      echo
    fi
  done

  if [ "$any" -eq 0 ]; then
    echo "No inbound references found in:"
    printf '  - %s\n' "${SEARCH_DIRS[@]#"$BASE/"}"
  fi
}

scan_directory () {
  local full="$1"
  local rel="$2"

  echo "Scanning directory: $rel"
  echo

  ( cd "$full" ) || exit 1

  local file
  for file in "$full"/*; do
    local base
    base="$(basename "$file")"

    [[ "$base" == "_archive" ]] && continue
    [[ "$base" == *.bak ]] && continue
    [[ -d "$file" ]] && continue

    local relfile="${rel%/}/$base"
    local name="$base"

    local code_hits=0
    local doc_hits=0

    for dir in "${SEARCH_DIRS[@]}"; do
      local code docs

      code="$(run_rg "$name" "$dir" "${CODE_GLOBS[@]}")"
      docs="$(run_rg "$name" "$dir" "${DOC_GLOBS[@]}")"

      # Remove self-reference if it appears as "./<file>:..."
      if [ -n "$code" ]; then
        code="$(printf '%s\n' "$code" | rg -v --fixed-strings "$relfile:" || true)"
      fi
      if [ -n "$docs" ]; then
        docs="$(printf '%s\n' "$docs" | rg -v --fixed-strings "$relfile:" || true)"
      fi

      if [ -n "$code" ]; then
        code_hits=1
      fi
      if [ -n "$docs" ]; then
        doc_hits=1
      fi
    done

    if [ "$code_hits" -eq 1 ]; then
      echo "USED (code): $base"
    elif [ "$doc_hits" -eq 1 ]; then
      echo "MENTIONED (docs only): $base"
    else
      echo "UNUSED: $base"
    fi
  done
}

if [ -f "$FULL_PATH" ]; then
  report_one_file "$FULL_PATH" "$TARGET"
elif [ -d "$FULL_PATH" ]; then
  scan_directory "$FULL_PATH" "$TARGET"
else
  echo "File or directory not found: $TARGET"
  exit 1
fi