// Simulador de los saltos del Caminante (aproximación de PlatformerMotor y
// DashComponent, ver core/components/) sobre un mapa de texto. Sirve para
// diseñar y comprobar plataformas: encuentra qué superficies se alcanzan desde
// otra, con qué maniobras y con cuánto margen (en fotogramas y píxeles), con o
// sin dash. No es el motor: la prueba de humo repite en el motor real las
// maniobras que sale de aquí (ver tools/maniobras_puzle.js).
//
// Uso: node tools/sim_saltos.js mapa.map [dash=1|0] fila_inicio col_inicio
//   p. ej.: node tools/sim_saltos.js game/levels/chimenea.map 1 67 3
// Hipótesis: 60 fps, capsula del jugador de 24x48 (suelo con 5 px de apoyo,
// pinchos con 12 px), los pinchos (^ v ~ -) cuentan como peligro siempre.
const fs = require('fs');
const DT = 1 / 60, CELL = 16;
const P = { speed: 300, jump: -900, g: 2250, fallMul: 1.4, cut: 0.5, coyote: 6, dashSpeed: 900, dashFrames: 9, dashCool: 24, hw: 12, hwFloor: 5, hwCeil: 8, hh: 24 };
const SOLID = new Set('TGBC'), PLANK = new Set('S'), HAZ = new Set('^v~-');

function loadMap(path) {
  const rows = fs.readFileSync(path, 'utf8').split('\n').filter((l, i, a) => !(i === a.length - 1 && l === ''));
  const w = Math.max(...rows.map((r) => r.length));
  return { rows, w, h: rows.length, at: (r, c) => (c < 0 || c >= w ? 'B' : (r < 0 ? 'B' : (r >= rows.length ? '.' : (rows[r][c] || '.')))) };
}
const isSolid = (m, r, c) => SOLID.has(m.at(r, c));
const isPlank = (m, r, c) => PLANK.has(m.at(r, c));
const isHaz = (m, r, c) => HAZ.has(m.at(r, c));

function collidesBox(m, x, y) {
  const c0 = Math.floor((x - P.hw) / CELL), c1 = Math.floor((x + P.hw - 0.01) / CELL);
  const r0 = Math.floor((y - P.hh) / CELL), r1 = Math.floor((y + P.hh - 1.0) / CELL);
  for (let r = r0; r <= r1; r++) for (let c = c0; c <= c1; c++) if (isSolid(m, r, c)) return true;
  return false;
}
function hazardOverlap(m, x, y) {
  const c0 = Math.floor((x - P.hw) / CELL), c1 = Math.floor((x + P.hw - 0.01) / CELL);
  const r0 = Math.floor((y - P.hh) / CELL), r1 = Math.floor((y + P.hh - 0.01) / CELL);
  for (let r = r0; r <= r1; r++) for (let c = c0; c <= c1; c++) {
    const ch = m.at(r, c);
    if (!HAZ.has(ch)) continue;
    const bx0 = c * CELL + 2, bx1 = c * CELL + 14;
    const by0 = ch === 'v' ? r * CELL : r * CELL + 7, by1 = ch === 'v' ? r * CELL + 9 : r * CELL + 16;
    if (x + P.hw > bx0 && x - P.hw < bx1 && y + P.hh > by0 && y - P.hh < by1) return true;
  }
  return false;
}

// Simula una maniobra desde de pie en (x0, y0). plan: {d1, d2, delay, hold, k, dashAt, dashDir}
function simulate(m, x0, y0, plan, opts) {
  if (hazardOverlap(m, x0, y0)) return { ok: false, startHazard: true };
  let x = x0, y = y0, vy = 0, onFloor = true, coyote = P.coyote, facing = plan.facing || 1;
  let dashT = 0, dashCd = 0, dashUsed = false, prevHeld = false, left = false;
  for (let f = 0; f < 220; f++) {
    const dir = f < plan.delay ? plan.d1 : (f - plan.delay < plan.k ? plan.d1 : plan.d2);
    const jumpHeld = f >= plan.delay && (f - plan.delay) < plan.hold;
    const pressed = jumpHeld && !prevHeld, released = !jumpHeld && prevHeld;
    prevHeld = jumpHeld;
    if (dir) facing = dir;
    if (onFloor) { vy = 0; coyote = P.coyote; } else { vy += (vy > 0 ? P.g * P.fallMul : P.g) * DT; coyote = Math.max(coyote - 1, 0); }
    if (pressed && coyote > 0) { vy = P.jump; coyote = 0; }
    if (released && vy < 0) vy *= P.cut;
    let vx = dir * P.speed;
    dashCd = Math.max(dashCd - 1, 0);
    if (onFloor) dashUsed = false;
    if (opts.dash && plan.dashAt !== null && f === plan.dashAt && dashT === 0 && dashCd === 0 && !(!onFloor && dashUsed)) {
      dashT = P.dashFrames; dashCd = P.dashCool;
      if (!onFloor) dashUsed = true;
      if (plan.dashDir) facing = plan.dashDir;
    }
    if (dashT > 0) { dashT--; vx = facing * P.dashSpeed; vy = 0; }
    // horizontal
    let nx = x + vx * DT;
    if (collidesBox(m, nx, y)) {
      const s = Math.sign(vx); let t = x;
      for (let i = 0; i < 16; i++) { if (collidesBox(m, t + s, y)) break; t += s; if (Math.abs(t - x) >= Math.abs(vx * DT)) break; }
      nx = t;
      if (dashT > 0) dashT = 0;
    }
    x = nx;
    // vertical
    let ny = y + vy * DT;
    const wasFloor = onFloor;
    onFloor = false;
    if (vy >= 0) {
      const bottomOld = y + P.hh, bottomNew = ny + P.hh;
      const c0 = Math.floor((x - P.hwFloor + 0.01) / CELL), c1 = Math.floor((x + P.hwFloor - 0.01) / CELL);
      let landed = null;
      for (let r = Math.floor(bottomOld / CELL); r <= Math.floor((bottomNew + (wasFloor ? 1 : 0)) / CELL); r++) {
        for (let c = c0; c <= c1; c++) {
          const top = r * CELL;
          const surface = isSolid(m, r, c) || isPlank(m, r, c);
          if (!surface) continue;
          if (bottomOld <= top + 0.5 && bottomNew >= top) landed = landed === null ? top : Math.min(landed, top);
          else if (wasFloor && Math.abs(bottomOld - top) < 0.6) landed = top;
        }
      }
      if (landed !== null) { ny = landed - P.hh; onFloor = true; vy = 0; }
    } else {
      const r = Math.floor((ny - P.hh) / CELL);
      const c0 = Math.floor((x - P.hwCeil + 0.01) / CELL), c1 = Math.floor((x + P.hwCeil - 0.01) / CELL);
      for (let c = c0; c <= c1; c++) if (isSolid(m, r, c)) { ny = (r + 1) * CELL + P.hh; vy = 0; break; }
    }
    y = ny;
    if (!onFloor) left = true;
    if (hazardOverlap(m, x, y)) return { ok: false, hazard: true, x, y, frames: f };
    if (y > m.h * CELL + 400) return { ok: false, fell: true, x, y, frames: f };
    if (onFloor && left) return { ok: true, x, y, frames: f };
  }
  return { ok: false, timeout: true, x, y };
}

// Superficies en las que se puede estar de pie (con 2 celdas libres encima).
function surfaces(m) {
  const out = [];
  const standable = (r, c) => (isSolid(m, r, c) || isPlank(m, r, c)) && !isSolid(m, r - 1, c) && !isHaz(m, r - 1, c) && !isSolid(m, r - 2, c);
  for (let r = 0; r < m.h; r++) {
    let c = 0;
    while (c < m.w) {
      if (standable(r, c)) {
        let c2 = c;
        while (c2 + 1 < m.w && standable(r, c2 + 1)) c2++;
        out.push({ row: r, c0: c, c1: c2, id: out.length });
        c = c2 + 1;
      } else c++;
    }
  }
  return out;
}
// Superficie en la que se acaba de pie; el centro debe quedar al menos 8 px dentro
// de sus bordes (con la cápsula real, más cerca del borde resbala).
function surfaceAt(S, x, y) {
  const row = Math.round((y + P.hh) / CELL);
  return S.find((s) => s.row === row && x >= s.c0 * CELL + 8 && x <= (s.c1 + 1) * CELL - 8);
}

function explore(m, S, from, opts) {
  const edges = [];
  const all = new Map();
  const x0 = from.c0 * CELL + 4, x1 = (from.c1 + 1) * CELL - 4;
  const starts = new Set([x0, x1]);
  const n = Math.max(1, Math.floor((x1 - x0) / 24));
  for (let i = 0; i <= n; i++) starts.add(Math.round(x0 + ((x1 - x0) * i) / n));
  const y = from.row * CELL - P.hh;
  const dashOpts = opts.dash ? [null, 0, 5, 10, 15, 20, 26, 32, 40, 50] : [null];
  for (const sx of starts) for (const d1 of [-1, 0, 1]) for (const d2 of [-1, 0, 1]) for (const delay of [0, 4]) {
    for (const hold of [1, 3, 6, 9, 13, 18, 40]) for (const k of [0, 8, 16, 26, 38]) {
      for (const dashAt of dashOpts) for (const dashDir of (dashAt === null ? [0] : [-1, 1])) {
        const plan = { d1, d2, delay, hold, k, dashAt, dashDir, facing: d1 || 1 };
        const r = simulate(m, sx, y, plan, opts);
        if (!r.ok) continue;
        const to = surfaceAt(S, r.x, r.y);
        if (!to || to.id === from.id) continue;
        const used = dashAt !== null;
        const key = from.id + '>' + to.id + (used ? 'd' : '');
        if (!all.has(key)) all.set(key, []);
        all.get(key).push({ from: from.id, to: to.id, dash: used, plan, sx });
      }
    }
  }
  for (const [key, list] of all) {
    // muestra como mucho 60 candidatos repartidos y elige el de mejor margen
    const step = Math.max(1, Math.floor(list.length / 60));
    let best = null;
    for (let i = 0; i < list.length; i += step) {
      const e = list[i];
      const mg = margins(m, S, from, e, opts);
      const score = Math.min(mg.hold, mg.dash, mg.k) * 100 + mg.pos;
      if (!best || score > best.score) best = { ...e, margin: mg, score };
    }
    edges.push(best);
  }
  return edges;
}

// Cuánto se puede mover cada parámetro de la maniobra sin que falle (en fotogramas / píxeles).
function margins(m, S, from, e, opts) {
  const y = from.row * CELL - P.hh;
  const ok = (sx, plan) => {
    const r = simulate(m, sx, y, plan, opts);
    if (!r.ok) return false;
    const to = surfaceAt(S, r.x, r.y);
    return to && to.id === e.to;
  };
  const win = (fn, lo, hi, stepSize) => {
    let up = 0, down = 0;
    for (let d = stepSize; d <= hi; d += stepSize) { if (fn(d)) up = d; else break; }
    for (let d = stepSize; d <= -lo; d += stepSize) { if (fn(-d)) down = d; else break; }
    return up + down + stepSize;
  };
  const p = e.plan;
  const mg = {};
  mg.hold = win((d) => ok(e.sx, { ...p, hold: Math.max(1, p.hold + d) }), -8, 8, 1);
  mg.k = win((d) => ok(e.sx, { ...p, k: Math.max(0, p.k + d) }), -8, 8, 1);
  mg.dash = p.dashAt === null ? 99 : win((d) => ok(e.sx, { ...p, dashAt: Math.max(0, p.dashAt + d) }), -10, 10, 1);
  mg.pos = win((d) => ok(e.sx + d, p), -30, 30, 2);
  return mg;
}

function analyse(m, dash, startRow, startCol) {
  const S = surfaces(m);
  const graph = {};
  for (const s of S) graph[s.id] = explore(m, S, s, { dash });
  const start = S.find((s) => s.row === startRow && startCol >= s.c0 && startCol <= s.c1);
  const dist = { [start.id]: 0 }, prev = {}, q = [start.id];
  while (q.length) {
    const a = q.shift();
    for (const e of graph[a]) if (!(e.to in dist)) { dist[e.to] = dist[a] + 1; prev[e.to] = e; q.push(e.to); }
  }
  return { S, graph, dist, prev, start };
}
function pathTo(r, id) {
  const out = [];
  let cur = id;
  while (cur !== r.start.id && r.prev[cur]) { out.unshift(r.prev[cur]); cur = r.prev[cur].from; }
  return out;
}
module.exports = { pathTo, margins, loadMap, surfaces, surfaceAt, explore, simulate, analyse, P, CELL };

if (require.main === module) {
  const m = loadMap(process.argv[2]);
  const dash = process.argv[3] !== '0';
  const r = analyse(m, dash, +process.argv[4], +process.argv[5]);
  console.log(r.S.length, 'superficies; alcanzables', Object.keys(r.dist).length);
  for (const s of r.S) console.log(`fila ${s.row} cols ${s.c0}-${s.c1}`, s.id in r.dist ? `ok(${r.dist[s.id]})` : '--');
  const goal = r.S.reduce((a, b) => (b.row < a.row ? b : a));
  if (goal.id in r.dist) {
    console.log('--- camino a la meta (fila ' + goal.row + ')');
    for (const e of pathTo(r, goal.id)) {
      const a = r.S[e.from], b = r.S[e.to], mg = e.margin;
      console.log(`fila ${a.row} c${a.c0}-${a.c1} -> fila ${b.row} c${b.c0}-${b.c1}${e.dash ? ' [DASH]' : ''}  margen: mantener=${mg.hold}f giro=${mg.k}f dash=${mg.dash}f pos=${mg.pos}px`);
    }
  }
}
