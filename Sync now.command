#!/bin/bash
# Double-click to sync right away. Keep this window open until it says "Finished".
cd "$(dirname "$0")"
echo "Syncing your class notes..."
./sync/sync.sh now 2>&1 | tee -a sync/sync.log
echo ""
echo "Finished. You can close this window."
read -n 1 -s -r -p "Press any key to close."
