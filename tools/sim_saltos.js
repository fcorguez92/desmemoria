// Simulador de los saltos del Caminante (aproximación de PlatformerMotor,
// DashComponent y player.gd, ver core/components/) sobre un mapa de texto. Sirve
// para diseñar y comprobar plataformas: encuentra qué superficies se alcanzan
// desde otra, con qué maniobras y con cuánto margen (en fotogramas y píxeles).
// No es el motor: la prueba de humo repite en el motor real las maniobras que
// sale de aquí (ver tools/maniobras_puzle.js).
//
// Uso: node tools/sim_saltos.js mapa.map HABILIDADES fila_inicio col_inicio [fila_meta] [--roto]
//   HABILIDADES: combinación de D (dash), J (doble salto) y W (Agarre: salto de
//   pared); vacío o 0 = ninguna. 1 se acepta como alias de D (uso antiguo).
//   --roto: las piezas $ (y #) están rotas (no son sólidas); por defecto lo son.
//   p. ej.: node tools/sim_saltos.js game/levels/chimenea.map D 67 3
//
// Física (valores del motor): 60 fps; cápsula de 24x48 (suelo con 5 px de apoyo,
// techo con 8, pinchos con 12); velocidad 300; salto -900 con recorte a la mitad al
// soltar; doble salto -800 (uno por tiempo en el aire); dash 900 px/s durante 9
// fotogramas con enfriamiento de 24 y uno por salto en el aire; pared: caída máxima
// de 120 px/s pulsando hacia ella, salto -850 con empuje lateral de 350 durante 9
// fotogramas, margen de 6 fotogramas tras separarse; el salto de pared no recarga ni
// el dash ni el doble salto.
// Terreno: sólidos T G B C g % (y $ # = + salvo --roto; = y + son compuertas
// cerradas), pared lisa % (sólida, sin agarre), tablones S p (de un solo sentido) y
// peligro ^ v ~ - { } (los laterales con su caja girada) siempre activos.
// NO se modelan las piezas móviles ni con ritmo: las plataformas de carril (< >) y
// los ciclos (y) cuentan como aire. Una ruta que dependa de ellas se prueba en el motor
// (tests/smoke_test.gd), no aquí.
const fs = require('fs');
const DT = 1 / 60, CELL = 16;
const P = {
  speed: 300, jump: -900, g: 2250, fallMul: 1.4, cut: 0.5, coyote: 6,
  dashSpeed: 900, dashFrames: 9, dashCool: 24,
  airJump: -800, wallSlide: 120, wallJump: -850, wallPush: 350, wallLock: 9, wallCoyote: 6,
  hw: 12, hwFloor: 5, hwCeil: 8, hh: 24,
};
const SOLID_BASE = 'TGBCg%', SOLID_BREAKABLE = '$#', SOLID_GATE = '=+';
const PLANK = new Set('Sp'), SMOOTH = new Set('%');
// Cajas de los peligros dentro de su celda: [x0, y0, x1, y1] en píxeles.
const HAZBOX = { '^': [2, 7, 14, 16], '~': [2, 7, 14, 16], '-': [2, 7, 14, 16], v: [2, 0, 14, 9], '{': [0, 2, 9, 14], '}': [7, 2, 16, 14] };
const HAZ = new Set(Object.keys(HAZBOX));

function skillsOf(s) {
  if (s === true || s === 1 || s === '1') return 'D';
  if (!s || s === '0' || s === '-') return '';
  return String(s).toUpperCase().replace(/[^DJW]/g, '');
}

function loadMap(path, opts = {}) {
  const rows = fs.readFileSync(path, 'utf8').split('\n').map((l) => l.replace(/\r$/, '')).filter((l, i, a) => !(i === a.length - 1 && l === ''));
  const w = Math.max(...rows.map((r) => r.length));
  const solid = new Set(SOLID_BASE + SOLID_GATE + (opts.broken ? '' : SOLID_BREAKABLE));
  if (opts.broken) for (const ch of SOLID_BREAKABLE) solid.delete(ch);
  return { rows, w, h: rows.length, solid, at: (r, c) => (c < 0 || c >= w ? 'B' : (r < 0 ? 'B' : (r >= rows.length ? '.' : (rows[r][c] || '.')))) };
}
const isSolid = (m, r, c) => m.solid.has(m.at(r, c));
const isPlank = (m, r, c) => PLANK.has(m.at(r, c));
const isHaz = (m, r, c) => HAZ.has(m.at(r, c));

function collidesBox(m, x, y) {
  const c0 = Math.floor((x - P.hw) / CELL), c1 = Math.floor((x + P.hw - 0.01) / CELL);
  const r0 = Math.floor((y - P.hh) / CELL), r1 = Math.floor((y + P.hh - 1.0) / CELL);
  for (let r = r0; r <= r1; r++) for (let c = c0; c <= c1; c++) if (isSolid(m, r, c)) return true;
  return false;
}
// ¿Hay una pared a la que agarrarse al lado `side` (-1/1)? Alguna baldosa de la
// columna contigua, a la altura del cuerpo, que sea sólida y no lisa.
function grippable(m, x, y, side) {
  const c = Math.floor((x + side * (P.hw + 0.5)) / CELL);
  const r0 = Math.floor((y - P.hh) / CELL), r1 = Math.floor((y + P.hh - 1.0) / CELL);
  for (let r = r0; r <= r1; r++) if (isSolid(m, r, c) && !SMOOTH.has(m.at(r, c))) return true;
  return false;
}
function hazardOverlap(m, x, y) {
  const c0 = Math.floor((x - P.hw) / CELL), c1 = Math.floor((x + P.hw - 0.01) / CELL);
  const r0 = Math.floor((y - P.hh) / CELL), r1 = Math.floor((y + P.hh - 0.01) / CELL);
  for (let r = r0; r <= r1; r++) for (let c = c0; c <= c1; c++) {
    const box = HAZBOX[m.at(r, c)];
    if (!box) continue;
    const bx0 = c * CELL + box[0], bx1 = c * CELL + box[2], by0 = r * CELL + box[1], by1 = r * CELL + box[3];
    if (x + P.hw > bx0 && x - P.hw < bx1 && y + P.hh > by0 && y - P.hh < by1) return true;
  }
  return false;
}

// Simula una maniobra desde de pie en (x0, y0).
// plan: {d1, d2, delay, hold, k, dashAt, dashDir,
//        dj, djHold            (doble salto: fotograma de la pulsación)
//        wj, wjDelay, wjAway, dEnd  (saltos de pared: cuántos, fotogramas agarrado
//                                    antes de saltar, si se sigue empujando hacia fuera
//                                    o se vuelve hacia la pared, dirección al acabar)}
function simulate(m, x0, y0, plan, opts) {
  if (hazardOverlap(m, x0, y0)) return { ok: false, startHazard: true };
  let x = x0, y = y0, vy = 0, vx = 0, onFloor = true, coyote = P.coyote, facing = plan.facing || 1;
  let dashT = 0, dashCd = 0, dashUsed = false, left = false, holdLeft = 0;
  let airJumps = 0, blocked = 0, wallTimer = 0, wallNormal = 0, wallGrab = 0, lock = 0, wjDone = 0, lastNormal = 0;
  const maxFrames = opts.frames || (opts.dj || opts.wall ? 260 : 220);
  for (let f = 0; f < maxFrames; f++) {
    // --- entrada ---
    let released = false;
    if (holdLeft > 0) { holdLeft--; if (holdLeft === 0) released = true; }
    let dir = f < plan.delay ? plan.d1 : (f - plan.delay < plan.k ? plan.d1 : plan.d2);
    const wallPlan = opts.wall && plan.wj > 0;
    if (wallPlan && wjDone > 0) dir = wjDone >= plan.wj ? (plan.dEnd === undefined ? plan.d2 : plan.dEnd) : (plan.wjAway ? lastNormal : -lastNormal);
    // --- estado del suelo y la pared (lo que el motor sabe al empezar el fotograma) ---
    const wallNow = opts.wall && !onFloor && blocked !== 0 && grippable(m, x, y, blocked);
    if (onFloor) { vy = 0; coyote = P.coyote; airJumps = opts.dj ? 1 : 0; wjDone = 0; } else { vy += (vy > 0 ? P.g * P.fallMul : P.g) * DT; coyote = Math.max(coyote - 1, 0); }
    lock = Math.max(lock - 1, 0);
    if (wallNow) {
      wallNormal = -blocked; wallTimer = P.wallCoyote; wallGrab++;
      if (wallPlan && wjDone < plan.wj && lock === 0) dir = blocked; // se mantiene pulsando hacia la pared
      if (dir === blocked && vy > P.wallSlide) vy = P.wallSlide;
    } else { wallTimer = Math.max(wallTimer - 1, 0); wallGrab = 0; }
    // --- salto: suelo (coyote) > pared > aire ---
    const groundPress = f === plan.delay;
    const airPress = opts.dj && plan.dj !== undefined && plan.dj !== null && f === plan.dj;
    const wallPress = wallPlan && !onFloor && wallTimer > 0 && wjDone < plan.wj && wallGrab >= (plan.wjDelay || 0) && wallNow;
    if (groundPress && coyote > 0) { vy = P.jump; coyote = 0; holdLeft = plan.hold; if (plan.hold === 0) released = true; }
    else if (wallPress || (airPress && opts.wall && !onFloor && wallTimer > 0)) {
      vx = wallNormal * P.wallPush; vy = P.wallJump; lock = P.wallLock; wallTimer = 0; facing = wallNormal; lastNormal = wallNormal;
      wjDone++; holdLeft = plan.wjHold || 40; blocked = 0;
    } else if (airPress && !onFloor && airJumps > 0) {
      vy = P.airJump; airJumps--; holdLeft = plan.djHold || 40;
    }
    if (released && vy < 0) vy *= P.cut;
    if (lock === 0) { vx = dir * P.speed; if (dir) facing = dir; }
    // --- dash ---
    dashCd = Math.max(dashCd - 1, 0);
    if (onFloor) dashUsed = false;
    if (opts.dash && plan.dashAt !== null && plan.dashAt !== undefined && f === plan.dashAt && dashT === 0 && dashCd === 0 && !(!onFloor && dashUsed)) {
      dashT = P.dashFrames; dashCd = P.dashCool;
      if (!onFloor) dashUsed = true;
      if (plan.dashDir) facing = plan.dashDir;
    }
    if (dashT > 0) { dashT--; vx = facing * P.dashSpeed; vy = 0; }
    // --- horizontal ---
    let nx = x + vx * DT;
    blocked = 0;
    if (collidesBox(m, nx, y)) {
      const s = Math.sign(vx); let t = x;
      for (let i = 0; i < 16; i++) { if (collidesBox(m, t + s, y)) break; t += s; if (Math.abs(t - x) >= Math.abs(vx * DT)) break; }
      nx = t;
      blocked = s;
      if (dashT > 0) dashT = 0;
    }
    x = nx;
    // --- vertical ---
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

// Reparto determinista de como mucho `n` elementos de la lista.
function thin(list, n) {
  if (list.length <= n) return list;
  const step = list.length / n, out = [];
  for (let i = 0; i < n; i++) out.push(list[Math.floor(i * step)]);
  return out;
}

// Todas las maniobras que se prueban desde una superficie, según las habilidades.
// Sin J ni W es exactamente la rejilla del simulador original (solo dash).
function planGrid(opts) {
  const plans = [];
  const plain = !opts.dj && !opts.wall;
  const dashOpts = opts.dash ? (plain ? [null, 0, 5, 10, 15, 20, 26, 32, 40, 50] : [null, 0, 6, 14, 22, 32, 44]) : [null];
  const holds = plain ? [1, 3, 6, 9, 13, 18, 40] : [3, 9, 18, 40];
  const ks = plain ? [0, 8, 16, 26, 38] : [0, 10, 26, 38];
  const delays = plain ? [0, 4] : [0];
  const djs = opts.dj ? [null, 5, 11, 18, 26, 36, 48] : [null];
  const wjs = opts.wall ? [{ wj: 0 }] : [{ wj: 0 }];
  if (opts.wall) for (const wj of [1, 2, 3, 5]) for (const wjDelay of [0, 8]) for (const wjAway of [true, false]) for (const dEnd of [-1, 1]) wjs.push({ wj, wjDelay, wjAway, dEnd });
  for (const d1 of [-1, 0, 1]) for (const d2 of [-1, 0, 1]) for (const delay of delays) for (const hold of holds) for (const k of ks) {
    for (const dashAt of dashOpts) for (const dashDir of (dashAt === null ? [0] : [-1, 1])) for (const dj of djs) for (const w of wjs) {
      plans.push({ d1, d2, delay, hold, k, dashAt, dashDir, ...(dj === null ? {} : { dj }), ...(w.wj ? w : {}), facing: d1 || 1 });
    }
  }
  return plans;
}

function explore(m, S, from, opts) {
  const edges = [];
  const all = new Map();
  const x0 = from.c0 * CELL + 4, x1 = (from.c1 + 1) * CELL - 4;
  const starts = new Set([x0, x1]);
  const n = Math.max(1, Math.floor((x1 - x0) / 24));
  for (let i = 0; i <= n; i++) starts.add(Math.round(x0 + ((x1 - x0) * i) / n));
  const y = from.row * CELL - P.hh;
  const plain = !opts.dj && !opts.wall;
  const grid = planGrid(opts);
  const startList = plain ? [...starts] : thin([...starts], 8);
  const budget = plain ? Infinity : (opts.budget || 9000);
  for (const sx of startList) for (const plan of thin(grid, budget)) {
    const r = simulate(m, sx, y, plan, opts);
    if (!r.ok) continue;
    const to = surfaceAt(S, r.x, r.y);
    if (!to || to.id === from.id) continue;
    const used = plan.dashAt !== null && plan.dashAt !== undefined;
    const key = from.id + '>' + to.id + (used ? 'd' : '');
    if (!all.has(key)) all.set(key, []);
    all.get(key).push({ from: from.id, to: to.id, dash: used, plan, sx });
  }
  for (const [key, list] of all) {
    // muestra como mucho 60 candidatos repartidos y elige el de mejor margen
    const step = Math.max(1, Math.floor(list.length / 60));
    let best = null;
    for (let i = 0; i < list.length; i += step) {
      const e = list[i];
      const mg = margins(m, S, from, e, opts);
      const score = Math.min(mg.hold, mg.dash, mg.k, mg.dj ?? 99, mg.wj ?? 99) * 100 + mg.pos;
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
  if (p.dj !== undefined) mg.dj = win((d) => ok(e.sx, { ...p, dj: Math.max(0, p.dj + d) }), -10, 10, 1);
  if (p.wj) mg.wj = win((d) => ok(e.sx, { ...p, wjDelay: Math.max(0, (p.wjDelay || 0) + d) }), -8, 8, 1);
  mg.pos = win((d) => ok(e.sx + d, p), -30, 30, 2);
  return mg;
}

// Alcance de superficies desde (startRow, startCol). `skills`: 'DJW' (ver arriba).
function analyse(m, skills, startRow, startCol, extra = {}) {
  const sk = skillsOf(skills);
  const opts = { dash: sk.includes('D'), dj: sk.includes('J'), wall: sk.includes('W'), ...extra };
  const S = surfaces(m);
  const graph = {};
  for (const s of S) graph[s.id] = explore(m, S, s, opts);
  const start = S.find((s) => s.row === startRow && startCol >= s.c0 && startCol <= s.c1);
  if (!start) throw new Error(`no hay superficie en fila ${startRow} columna ${startCol}`);
  // Camino de mayor margen: maximiza el peor tramo (y, a igualdad, usa menos tramos).
  const dist = { [start.id]: 0 }, prev = {}, best = { [start.id]: Infinity };
  let changed = true;
  while (changed) {
    changed = false;
    for (const a of Object.keys(best)) {
      for (const e of graph[a]) {
        const sc = Math.min(best[a], edgeScore(e));
        if (!(e.to in best) || sc > best[e.to] || (sc === best[e.to] && dist[a] + 1 < dist[e.to])) {
          if (e.to === start.id) continue;
          best[e.to] = sc; dist[e.to] = dist[a] + 1; prev[e.to] = e; changed = true;
        }
      }
    }
  }
  return { S, graph, dist, prev, best, start, skills: sk };
}
function edgeScore(e) {
  const g = e.margin;
  return Math.min(g.hold, g.k, g.dash, g.dj ?? 99, g.wj ?? 99, Math.floor(g.pos / 3));
}
function pathTo(r, id) {
  const out = [];
  let cur = id;
  while (cur !== r.start.id && r.prev[cur]) { out.unshift(r.prev[cur]); cur = r.prev[cur].from; }
  return out;
}
module.exports = { edgeScore, pathTo, margins, loadMap, surfaces, surfaceAt, explore, simulate, analyse, skillsOf, planGrid, P, CELL };

if (require.main === module) {
  const args = process.argv.slice(2).filter((a) => !a.startsWith('--'));
  const broken = process.argv.includes('--roto');
  const m = loadMap(args[0], { broken });
  const r = analyse(m, args[1], +args[2], +args[3]);
  console.log(r.S.length, 'superficies; alcanzables', Object.keys(r.dist).length, '(habilidades: ' + (r.skills || 'ninguna') + ')');
  for (const s of r.S) console.log(`fila ${s.row} cols ${s.c0}-${s.c1}`, s.id in r.dist ? `ok(${r.dist[s.id]})` : '--');
  const goal = args[4] !== undefined ? r.S.filter((s) => s.row === +args[4]).sort((a, b) => (b.id in r.dist) - (a.id in r.dist))[0] : r.S.reduce((a, b) => (b.row < a.row ? b : a));
  if (goal && goal.id in r.dist) {
    console.log('--- camino a la meta (fila ' + goal.row + ')');
    for (const e of pathTo(r, goal.id)) {
      const a = r.S[e.from], b = r.S[e.to], mg = e.margin, p = e.plan;
      const extra = (p.dj !== undefined ? ` [DOBLE@${p.dj}]` : '') + (p.wj ? ` [PARED x${p.wj}]` : '');
      console.log(`[${edgeScore(e)}] fila ${a.row} c${a.c0}-${a.c1} -> fila ${b.row} c${b.c0}-${b.c1}${e.dash ? ' [DASH]' : ''}${extra}  margen: mantener=${mg.hold}f giro=${mg.k}f dash=${mg.dash}f doble=${mg.dj ?? "-"}f pared=${mg.wj ?? "-"}f pos=${mg.pos}px`);
    }
  } else console.log('--- meta no alcanzable');
}
