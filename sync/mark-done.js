// Step 4: record which recordings each new set of notes covers, so it is not rewritten next run.
const fs = require("fs");
const { P, readJSON, writeJSON } = require("./lib");
const todo = readJSON(P("data/private/todo.json"), []);
const meta = readJSON(P("data/notes/meta.json"), {});
for (const t of todo) {
  if (!fs.existsSync(P(t.noteFile))) { console.log(`mark-done: no notes written for ${t.key}, will retry next run`); continue; }
  const recs = readJSON(P(t.lectureFile), []);
  const [course, day] = t.key.split("_");
  meta[t.key] = { course, day, generatedAt: new Date().toISOString(), coveredUntil: recs.length ? recs[recs.length - 1].started_at : `${day}T23:59:59+05:30` };
}
writeJSON(P("data/notes/meta.json"), meta);
