// Step 5: bundle public data for the website. Raw minutes never leave data/private.
const fs = require("fs");
const { P, readJSON, writeJSON } = require("./lib");
const meta = readJSON(P("data/notes/meta.json"), {});
const examnotes = {};
for (const f of fs.readdirSync(P("data/notes")).filter(f => /^[a-z]+_\d{4}-\d{2}-\d{2}\.md$/.test(f))) {
  const key = f.slice(0, -3), [course, day] = key.split("_");
  examnotes[key] = { markdown: fs.readFileSync(P("data/notes", f), "utf8"), course, day, generatedAt: (meta[key] || {}).generatedAt || null, coveredUntil: (meta[key] || {}).coveredUntil || `${day}T23:59:59+05:30` };
}
const out = { generatedAt: new Date().toISOString(), examnotes, announcements: readJSON(P("data/announcements.json"), {}), config: { timetable: readJSON(P("data/timetable.json")) } };
writeJSON(P("docs/data.json"), out);
console.log(`build: ${Object.keys(examnotes).length} notes, ${Object.keys(out.announcements).length} announcements -> docs/data.json`);
