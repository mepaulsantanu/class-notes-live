#!/bin/bash
# Runs the whole pipeline: fetch from NeoSapien -> filter -> write notes -> build site -> publish.
set -uo pipefail
cd "$(dirname "$0")/.."
# cron starts with a bare PATH; add the usual places node and claude live on a Mac.
export PATH="$HOME/.local/bin:$HOME/.npm-global/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

# Only one sync at a time (a wake-up run and a manual run can overlap).
LOCK="data/private/.sync.lock"
mkdir -p data/private
if ! mkdir "$LOCK" 2>/dev/null; then
  # Clear a lock left behind if the laptop was closed mid-run more than 30 minutes ago.
  if [ -n "$(find "$LOCK" -maxdepth 0 -mmin +30 2>/dev/null)" ]; then rm -rf "$LOCK"; mkdir "$LOCK"; else echo "Another sync is running, skipping."; exit 0; fi
fi
trap 'rm -rf "$LOCK"' EXIT

echo "=== $(date '+%Y-%m-%d %H:%M') sync start ==="
mkdir -p data/private/inbox data/private/lectures data/notes
# Look back 7 days, so a few days with the laptop closed are still caught up.
FROM=$(date -v-7d +%Y-%m-%d 2>/dev/null || date -d '7 days ago' +%Y-%m-%d)

# 1. Fetch new recordings (Claude Code + NeoSapien connector)
claude -p "$(sed "s/{{FROM}}/$FROM/" sync/prompts/fetch.md)" \
  --allowedTools "mcp__neosapien__search_memories,mcp__neosapien__get_memory_by_id,Write,Glob" \
  --max-turns 80 || { echo "fetch failed"; exit 1; }

# 2. Filter to the five courses using the timetable (plain code, no AI)
node sync/classify.js || exit 1

# 3. Write exam notes for finished class days that need them
if [ "$(node -e 'console.log(require("./data/private/todo.json").length)')" != "0" ]; then
  claude -p "$(cat sync/prompts/notes.md)" --allowedTools "Read,Write,Glob" --max-turns 60 || echo "notes step failed, will retry next run"
  # 4. Remember what each note covers
  node sync/mark-done.js
fi

# 5. Build the public data file
node sync/build.js || exit 1

# 6. Publish only if something public changed
if [ -n "$(git status --porcelain -- docs data/notes data/announcements.json data/timetable.json)" ]; then
  git add docs data/notes data/announcements.json data/timetable.json
  git commit -m "Sync $(date '+%Y-%m-%d %H:%M')" && git push
  echo "published"
else
  echo "no changes"
fi
echo "=== sync end ==="
