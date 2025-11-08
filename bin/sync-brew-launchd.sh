#!/bin/bash

LOGFILE="$HOME/Library/Logs/syncbrew.log"

echo "===== $(date '+%Y-%m-%d %H:%M:%S %Z') syncbrew job started. =====" >> "$LOGFILE"

START_TIME=$(date +%s)

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

"$HOME/bin/sync-brew.sh" >> "$LOGFILE" 2>&1
STATUS=$?

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))

if [ $STATUS -eq 0 ]; then
  echo "✓  syncbrew job finished successfully. Elapsed time: ${ELAPSED}s." >> "$LOGFILE"
else
  echo "✗  syncbrew job exited with status $STATUS. Elapsed time: ${ELAPSED}s." >> "$LOGFILE"
fi

echo "===== $(date '+%Y-%m-%d %H:%M:%S %Z') syncbrew job done. =====" >> "$LOGFILE"
