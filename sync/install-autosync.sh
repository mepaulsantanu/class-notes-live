#!/bin/bash
# Installs a macOS background job that runs the sync every 15 minutes while the laptop is awake,
# and once soon after it wakes up if a run was missed while it was asleep.
set -e
cd "$(dirname "$0")/.."
DIR="$(pwd)"
LABEL="com.classnoteslive.sync"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
mkdir -p "$HOME/Library/LaunchAgents"
cat > "$PLIST" <<PL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$LABEL</string>
  <key>ProgramArguments</key><array><string>/bin/bash</string><string>$DIR/sync/sync.sh</string></array>
  <key>WorkingDirectory</key><string>$DIR</string>
  <key>StartCalendarInterval</key>
  <array>
    <dict><key>Minute</key><integer>0</integer></dict>
    <dict><key>Minute</key><integer>15</integer></dict>
    <dict><key>Minute</key><integer>30</integer></dict>
    <dict><key>Minute</key><integer>45</integer></dict>
  </array>
  <key>RunAtLoad</key><true/>
  <key>StandardOutPath</key><string>$DIR/sync/sync.log</string>
  <key>StandardErrorPath</key><string>$DIR/sync/sync.log</string>
</dict>
</plist>
PL
launchctl unload "$PLIST" 2>/dev/null || true
launchctl load -w "$PLIST"
echo "Auto-sync is on. It runs every 15 minutes while your Mac is awake, and catches up when it wakes."
echo "Log file: $DIR/sync/sync.log"
echo "To turn it off later: launchctl unload -w \"$PLIST\""
