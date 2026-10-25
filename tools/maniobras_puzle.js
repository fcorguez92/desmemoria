// Exporta, para cada puzle, el camino de maniobras (con su margen) a
// tests/puzzle_plans.json, que la prueba de humo repite en el motor real.
// Hay que volver a ejecutarlo si se cambia un mapa del puzle o la física del salto:
//   node tools/maniobras_puzle.js
//
// Dos tipos de trabajo:
//  - `goal`: el camino de mayor margen desde la salida hasta una superficie (dash).
//  - `legs`: tramos sueltos [fila_origen, col_origen, fila_destino, col_destino] con las
//    habilidades de `skills` (D dash, J doble salto). Solo valen maniobras en las que el
//    segundo salto viene después de soltar el primero (`dj` > `delay` + `hold`), porque la
//    prueba de humo pulsa y suelta Espacio de verdad y no puede repetir un salto aéreo
//    con la tecla aún pulsada.
const fs = require("fs");
const path = require("path");
const sim = require("./sim_saltos.js");
const ROOT = path.join(__dirname, "..");
const LEVELS = path.join(ROOT, "game/levels") + "/";
const jobs = [
  { room: 'Chimenea', map: 'chimenea.map', startRow: 67, startCol: 3, goal: (S) => S.find((s) => s.row === 8) },
  { room: 'Pasarela', map: 'pasarela.map', startRow: 8, startCol: 3, goal: (S) => S.find((s) => s.row === 8 && s.c0 === 77) },
  { room: 'SurcoCiego', map: 'surco_ciego.map', skills: 'DJ', legs: [[31, 33, 24, 37], [24, 37, 11, 50]] },
  { room: 'CruceDelPan', map: 'cruce_del_pan.map', skills: 'DJ', legs: [[31, 20, 23, 30], [23, 30, 10, 42]] },
];

// Mejor maniobra entre dos superficies, con el segundo salto después de soltar el primero.
function bestLeg(m, S, opts, from, to) {
  const x0 = from.c0 * sim.CELL + 4, x1 = (from.c1 + 1) * sim.CELL - 4;
  const n = Math.max(1, Math.floor((x1 - x0) / 24));
  const starts = new Set([x0, x1]);
  for (let i = 0; i <= n; i++) starts.add(Math.round(x0 + ((x1 - x0) * i) / n));
  const y = from.row * sim.CELL - sim.P.hh;
  const found = [];
  for (const plan of sim.planGrid(opts)) {
    if (plan.dj !== undefined && plan.dj <= plan.delay + plan.hold) continue;
    for (const sx of starts) {
      const r = sim.simulate(m, sx, y, plan, opts);
      if (!r.ok) continue;
      const at = sim.surfaceAt(S, r.x, r.y);
      if (at && at.id === to.id) found.push({ from: from.id, to: to.id, plan, sx, dash: plan.dashAt !== null && plan.dashAt !== undefined });
    }
  }
  if (!found.length) throw new Error(`sin maniobra de fila ${from.row} a fila ${to.row}`);
  // Lo mínimo: si basta un salto simple no se usa dash ni doble salto (más robusto en el motor).
  const cost = (e) => (e.dash ? 1 : 0) + (e.plan.dj !== undefined ? 1 : 0);
  const least = Math.min(...found.map(cost));
  for (let i = found.length - 1; i >= 0; i--) if (cost(found[i]) > least) found.splice(i, 1);
  const step = Math.max(1, Math.floor(found.length / 80));
  let best = null;
  for (let i = 0; i < found.length; i += step) {
    const e = found[i];
    e.margin = sim.margins(m, S, from, e, opts);
    e.score = sim.edgeScore(e) * 100 + e.margin.pos;
    if (!best || e.score > best.score) best = e;
  }
  return best;
}

const out = [];
for (const job of jobs) {
  const m = sim.loadMap(LEVELS + job.map);
  let edges;
  let S;
  if (job.legs) {
    S = sim.surfaces(m);
    const sk = sim.skillsOf(job.skills);
    const opts = { dash: sk.includes('D'), dj: sk.includes('J'), wall: sk.includes('W') };
    const pick = (row, col) => S.find((s) => s.row === row && col >= s.c0 && col <= s.c1);
    edges = job.legs.map(([fr, fc, tr, tc]) => {
      const a = pick(fr, fc), b = pick(tr, tc);
      if (!a || !b) throw new Error(`no hay superficie en ${job.room} (${fr},${fc}) o (${tr},${tc})`);
      return bestLeg(m, S, opts, a, b);
    });
  } else {
    const r = sim.analyse(m, true, job.startRow, job.startCol);
    S = r.S;
    edges = sim.pathTo(r, job.goal(r.S).id);
  }
  console.log(job.room, 'aristas', edges.length);
  for (const e of edges) {
    const a = S[e.from], b = S[e.to];
    out.push({
      room: job.room, from: { row: a.row, c0: a.c0, c1: a.c1 }, to: { row: b.row, c0: b.c0, c1: b.c1 },
      sx: e.sx, plan: e.plan, margin: e.margin, dash: e.dash,
    });
  }
}
fs.writeFileSync(process.argv[2] || path.join(ROOT, "tests/puzzle_plans.json"), JSON.stringify(out, null, 1));
console.log('escrito', out.length);
