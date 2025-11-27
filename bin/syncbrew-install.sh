#!/bin/zsh

set -e

USER_NAME=$(whoami)

if [ "$USER_NAME" = "fredhickernell" ]; then
  PLIST_BASENAME="com.fredhickernell.syncbrew.plist"
elif [ "$USER_NAME" = "fredjhickernell" ]; then
  PLIST_BASENAME="com.fredjhickernell.syncbrew.plist"
else
  echo "Unknown user: $USER_NAME"
  echo "No matching syncbrew plist template for this user."
  exit 1
fi

SRC="$HOME/Documents/SharedConfigs/LaunchAgents/$PLIST_BASENAME"
DEST_DIR="$HOME/Library/LaunchAgents"
DEST="$DEST_DIR/com.fredhickernell.syncbrew.plist"

echo "User: $USER_NAME"
echo "Using plist template: $SRC"

if [ ! -f "$SRC" ]; then
  echo "Error: plist template not found at $SRC"
  exit 1
fi

mkdir -p "$DEST_DIR"

launchctl unload "$DEST" 2>/dev/null || true

cp "$SRC" "$DEST"

launchctl load "$DEST"

echo "Loaded LaunchAgent:"
launchctl list | grep com.fredhickernell.syncbrew || echo "LaunchAgent loaded; may not show until first run."