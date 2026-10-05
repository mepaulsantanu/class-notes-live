// Shared rules for the class-notes pipeline. Plain Node.js, no dependencies.
const fs = require("fs");
const path = require("path");

const ROOT = path.resolve(__dirname, "..");
const P = (...p) => path.join(ROOT, ...p);
const readJSON = (f, fallback) => { try { return JSON.parse(fs.readFileSync(f, "utf8")); } catch { return fallback; } };
const writeJSON = (f, v) => { fs.mkdirSync(path.dirname(f), { recursive: true }); fs.writeFileSync(f, JSON.stringify(v, null, 2) + "\n"); };

// Domains NeoSapien tags on social or personal recordings. Never published.
const SOFT_SKIP = ["Casual / Social","Family","Household","Health & Wellness","Travel","Personal Finance","Hobbies","Journaling","Real Estate","Parenting"];
// Words that mark a recording as social chat even inside a class slot. Kept to clearly
// non-academic talk: marketing lectures legitimately mention movies, agencies, clients,
// placement (product placement), personal selling, travel brands and competitions.
const RED_FLAG = /\bgossip\b|\bbanter\b|\bsnacks?\b|\blunch\b|\bdinner\b|\bbirthday\b|\bgirlfriend\b|\bboyfriend\b|\broommate\b|\bhostel\b|\bgym\b|\bcharger\b|\bparking\b|\bventing\b|kelora|ping me|\binvoice\b/i;
// Section headings and lines removed from minutes before Claude ever sees them.
const OFF_HEAD = /misc|personal|casual|social|banter|gossip|food|snack|lunch|attendance|roll call|technical|logistic|pre-class|administrat|side conversation|gaming|identity inquir|campus|travel|party|photo|payment|fabricat|faculty and peer|faculty discussion|peer mention|course observation|other discussion|institutional|cultural notes|pg student|account issues|interpersonal|family/i;
const OFF_LINE = /gossip|banter|\bjok(e|ed|es|ing)\b|teas(e|ing)|snack|\bfood\b|lunch|\btea\b|parcel|\bgym\b|party|drinks|girlfriend|boyfriend|makeup|eyebrow|hungry|wi-?fi|internet|hotspot|charger|phone number|fake attendance|attendance notes|dhoti|magazine claim|profanit|slapp|sleep|personal trainer|resale value|cricket|instagram page|marwari|stereotyp|kajal|laughter|chaotic|playful/i;

function clean(mom) {
  const out = []; let drop = false;
  for (const l of String(mom || "").split("\n")) {
    const h = l.match(/^#{2,4}\s+(.*)/) || l.match(/^\*\*([^*]{3,60})\*\*\s*$/);
    if (h) { drop = OFF_HEAD.test(h[1]); if (!drop) out.push(l); continue; }
    if (drop || OFF_LINE.test(l)) continue;
    out.push(l);
  }
  return out.join("\n").replace(/\n{3,}/g, "\n\n").trim();
}

// India time helpers (IST = UTC+5:30)
const ist = (iso) => new Date(new Date(iso).getTime() + 330 * 60000);
const dayKey = (iso) => ist(iso).toISOString().slice(0, 10);
const hm = (s) => { const [h, m] = s.split(":").map(Number); return h * 60 + m; };

function slotAt(iso, tt) {
  const t = ist(iso), k = t.toISOString().slice(0, 10);
  if (k < tt.validFrom || k > tt.validTo) return null;
  const wd = t.getUTCDay(), mins = t.getUTCHours() * 60 + t.getUTCMinutes();
  return tt.slots.find(x => x.day === wd && mins >= hm(x.start) - (tt.marginBeforeMin || 10) && mins <= hm(x.end) + (tt.marginAfterMin || 15)) || null;
}

// Decide which course a recording belongs to, or null to keep it off the site.
function courseOf(m, tt, allow) {
  if (allow && new Date(m.started_at) < new Date(allow.cutoff)) return allow.courses[m._id] || null;
  const sl = slotAt(m.started_at, tt);
  if (!sl || !sl.course) return null;
  if ((m.domains || []).some(d => SOFT_SKIP.includes(d))) return null;
  if (RED_FLAG.test([m.title, m.summary, (m.topics || []).join(" ")].join(" "))) return null;
  const dur = (new Date(m.finished_at || m.started_at) - new Date(m.started_at)) / 1000;
  if (dur < 30) return null;
  return sl.course;
}

module.exports = { ROOT, P, readJSON, writeJSON, clean, dayKey, slotAt, courseOf };
