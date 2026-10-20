// Exporta, para cada puzle, el camino de maniobras (con su margen) a
// tests/puzzle_plans.json, que la prueba de humo repite en el motor real.
// Hay que volver a ejecutarlo si se cambia un mapa del puzle o la física del salto:
//   node tools/maniobras_puzle.js
const fs = require("fs");
const path = require("path");
const sim = require("./sim_saltos.js");
const ROOT = path.join(__dirname, "..");
const LEVELS = path.join(ROOT, "game/levels") + "/";
const jobs = [
  { room: 'Chimenea', map: 'chimenea.map', startRow: 67, startCol: 3, goal: (S) => S.find((s) => s.row === 8) },
  { room: 'Pasarela', map: 'pasarela.map', startRow: 8, startCol: 3, goal: (S) => S.find((s) => s.row === 8 && s.c0 === 77) },
];
const out = [];
for (const job of jobs) {
  const m = sim.loadMap(LEVELS + job.map);
  const r = sim.analyse(m, true, job.startRow, job.startCol);
  const goal = job.goal(r.S);
  const edges = sim.pathTo(r, goal.id);
  console.log(job.room, 'aristas', edges.length);
  for (const e of edges) {
    const a = r.S[e.from], b = r.S[e.to];
    out.push({
      room: job.room, from: { row: a.row, c0: a.c0, c1: a.c1 }, to: { row: b.row, c0: b.c0, c1: b.c1 },
      sx: e.sx, plan: e.plan, margin: e.margin, dash: e.dash,
    });
  }
}
fs.writeFileSync(process.argv[2] || path.join(ROOT, "tests/puzzle_plans.json"), JSON.stringify(out, null, 1));
console.log('escrito', out.length);
