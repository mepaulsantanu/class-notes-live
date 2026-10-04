// Step 2: sort new recordings into courses and decide which class days need exam notes.
const fs = require("fs");
const { P, readJSON, writeJSON, clean, dayKey, courseOf } = require("./lib");

const tt = readJSON(P("data/timetable.json"));
const allow = readJSON(P("data/allowlist.json"), null);
const meta = readJSON(P("data/notes/meta.json"), {});
const inbox = P("data/private/inbox");
const lectures = {};

for (const f of fs.existsSync(inbox) ? fs.readdirSync(inbox).filter(f => f.endsWith(".json")) : []) {
  const m = readJSON(P("data/private/inbox", f));
  if (!m || !m._id || !m.started_at) continue;
  const c = courseOf(m, tt, allow);
  if (!c) continue;
  const key = `${c}_${dayKey(m.started_at)}`;
  (lectures[key] = lectures[key] || []).push({ _id: m._id, title: m.title, started_at: m.started_at, finished_at: m.finished_at, minutes: clean(m.mom || m.summary) });
}

const todo = [];
const now = Date.now();
for (const [key, recs] of Object.entries(lectures)) {
  recs.sort((a, b) => new Date(a.started_at) - new Date(b.started_at));
  writeJSON(P("data/private/lectures", key + ".json"), recs);
  const last = recs[recs.length - 1];
  if (now - new Date(last.finished_at || last.started_at).getTime() < 40 * 60000) continue; // class may still be running
  const noteExists = fs.existsSync(P("data/notes", key + ".md"));
  const covered = meta[key] && meta[key].coveredUntil ? new Date(meta[key].coveredUntil).getTime() : 0;
  const newest = Math.max(...recs.map(r => new Date(r.started_at).getTime()));
  if (!noteExists || newest > covered) todo.push({ key, lectureFile: `data/private/lectures/${key}.json`, noteFile: `data/notes/${key}.md` });
}
writeJSON(P("data/private/todo.json"), todo);
console.log(`classify: ${Object.keys(lectures).length} class days found, ${todo.length} need notes`);
