#!/bin/bash

LOGFILE="$HOME/Library/Logs/syncbrew.log"
START_TIME=$(date +%s)
START_TEXT="===== $(date '+%Y-%m-%d %H:%M:%S %Z') syncbrew manual run started. ====="

echo "$START_TEXT"
echo "$START_TEXT" >> "$LOGFILE"

brew update && brew upgrade
brew bundle --global || brew bundle --file="$HOME/Documents/SharedConfigs/Brewfile"

STATUS=$?
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))

if [ $STATUS -eq 0 ]; then
  RESULT="✓  syncbrew manual run finished successfully. Elapsed time: ${ELAPSED}s."
else
  RESULT="✗  syncbrew manual run exited with status $STATUS. Elapsed time: ${ELAPSED}s."
fi

echo "$RESULT"
echo "$RESULT" >> "$LOGFILE"

END_TEXT="===== $(date '+%Y-%m-%d %H:%M:%S %Z') syncbrew manual run done. ====="
echo "$END_TEXT"
echo "$END_TEXT" >> "$LOGFILE"
