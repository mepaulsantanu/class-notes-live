#!/bin/bash
# Runs the whole pipeline: fetch from NeoSapien -> filter -> write notes -> build site -> publish.
set -uo pipefail
cd "$(dirname "$0")/.."
export PATH="$HOME/.local/bin:$HOME/.npm-global/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

# Long-lived Claude login for background runs (created once with: claude setup-token).
TOKEN_FILE="$HOME/.config/class-notes/claude-token"
if [ -f "$TOKEN_FILE" ]; then export CLAUDE_CODE_OAUTH_TOKEN="$(tr -d '[:space:]' < "$TOKEN_FILE")"; fi

notify(){ osascript -e "display notification \"$2\" with title \"Class Notes\" subtitle \"$1\"" >/dev/null 2>&1 || true; }
# Problems are announced at most once every 3 hours, so a broken login does not ping you every 15 minutes.
warn_once(){ local f="data/private/.last-warning"; local now; now=$(date +%s); local last=0; [ -f "$f" ] && last=$(cat "$f"); if [ $((now-last)) -gt 10800 ]; then echo "$now" > "$f"; notify "$1" "$2"; fi; }

# Only one sync at a time.
LOCK="data/private/.sync.lock"
mkdir -p data/private
if ! mkdir "$LOCK" 2>/dev/null; then
  if [ -n "$(find "$LOCK" -maxdepth 0 -mmin +30 2>/dev/null)" ]; then rm -rf "$LOCK"; mkdir "$LOCK"; else echo "Another sync is running, skipping."; exit 0; fi
fi
trap 'rm -rf "$LOCK"' EXIT

mkdir -p data/private/inbox data/private/lectures data/notes
# Save Claude usage: during class hours sync at most every 45 minutes, otherwise every 3 hours.
# A long gap (laptop was closed) always triggers a catch-up straight away. "./sync/sync.sh now" forces a run.
OK_FILE="data/private/.last-ok"; NOW=$(date +%s); LAST=0; [ -f "$OK_FILE" ] && LAST=$(cat "$OK_FILE")
DOW=$(date +%u); HM=$((10#$(date +%H)*60+10#$(date +%M)))
if [ "$DOW" -le 6 ] && [ $HM -ge 510 ] && [ $HM -le 1050 ]; then GAP=2700; else GAP=10800; fi
if [ "${1:-}" != "now" ] && [ $((NOW-LAST)) -lt $GAP ]; then exit 0; fi
echo "=== $(date '+%Y-%m-%d %H:%M') sync start ==="
# Look back only to the day before the last successful sync (at most 7 days).
if [ "$LAST" -gt 0 ]; then FROM=$(date -r $((LAST-86400)) +%Y-%m-%d 2>/dev/null || date -d @$((LAST-86400)) +%Y-%m-%d); else FROM=$(date -v-7d +%Y-%m-%d 2>/dev/null || date -d '7 days ago' +%Y-%m-%d); fi
WEEK=$(date -v-7d +%Y-%m-%d 2>/dev/null || date -d '7 days ago' +%Y-%m-%d); [ "$FROM" \< "$WEEK" ] && FROM=$WEEK

# 1. Fetch new recordings (Claude Code + NeoSapien connector)
OUT=$(claude -p "$(sed "s/{{FROM}}/$FROM/" sync/prompts/fetch.md)" \
  --allowedTools "mcp__neosapien__search_memories,mcp__neosapien__get_memory_by_id,Write,Glob" \
  --max-turns 80 2>&1); CODE=$?
echo "$OUT"
if [ $CODE -ne 0 ] || echo "$OUT" | grep -qi "failed to authenticate\|oauth\|login\|unauthorized"; then
  if echo "$OUT" | grep -qi "neosapien"; then warn_once "NeoSapien login expired" "Open Terminal: claude, then /mcp, then reconnect neosapien."
  else warn_once "Claude login expired" "Open Terminal and run: claude setup-token (see SETUP.md)."; fi
  echo "fetch failed"; exit 1
fi

echo "$NOW" > "$OK_FILE"

# 2. Filter to the five courses using the timetable (plain code, no AI)
node sync/classify.js || { warn_once "Sync problem" "Sorting recordings failed. Check sync/sync.log."; exit 1; }

# 3. Write exam notes for finished class days that need them
NEED=$(node -e 'console.log(require("./data/private/todo.json").map(t=>t.key).join(", "))')
if [ -n "$NEED" ]; then
  claude -p "$(cat sync/prompts/notes.md)" --allowedTools "Read,Write,Glob" --max-turns 60 || echo "notes step failed, will retry next run"
  node sync/mark-done.js
fi

# 4. Build the public data file
node sync/build.js || exit 1

# 5. Publish only if something public changed
if [ -n "$(git status --porcelain -- docs data/notes data/announcements.json data/timetable.json)" ]; then
  git add docs data/notes data/announcements.json data/timetable.json
  if git commit -m "Sync $(date '+%Y-%m-%d %H:%M')" && git push; then
    echo "published"
    [ -n "$NEED" ] && notify "Notes published" "$(echo "$NEED" | sed -e 's/sbm_/SBM /g' -e 's/retail_/RTM /g' -e 's/entre_/E\&I /g' -e 's/imc_/IMC /g' -e 's/dsma_/D\&SMA /g')"
  else
    warn_once "Could not publish" "git push failed. Run: gh auth login"
  fi
else
  echo "no changes"
fi
echo "=== sync end ==="
