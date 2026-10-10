// Generador del jefe "El Centinela Hueco" (ver tools/rig_lib.js y tools/rig_enemigos.js):
// la armadura vacia de un Custodio de la Orden del Archivo, enorme, de hierro oscuro
// y oxidado, con grietas de brillo ambar y un mazo de piedra y hierro. Cuando se
// agrieta (estado "stagger") dentro se ve una figura palida y encorvada que asoma
// por el pecho y el cuello: el punto debil.
// Usa el mismo esqueleto que el coloso, ampliado (K), y dibuja encima la armadura
// (hombreras, faldon, rodillera, yelmo cerrado, grietas) con la funcion `deco`.
// Uso: node tools/rig_centinela.js   (escribe art/source/centinela.sprite)
const lib = require('./rig_lib');
const { lerp, ease, pose, keyed, makeStyle, add, mul, sub, norm, dirA, rad, Canvas, polyTest, chainTest } = lib;

const W = 192, H = 128;
lib.setCanvas(W, H);
const { OX, OY } = lib.canvasSize();

const K = 1.45; // escala respecto al coloso
const POS = ['hipx', 'hipy', 'nfx', 'nfy', 'ffx', 'ffy', 'fx', 'fy', 'gx', 'gy'];
const sc = (o) => { const r = Object.assign({}, o); for (const k of POS) if (r[k] !== undefined) r[k] *= K; return r; };
const frames = (n, fn) => Array.from({ length: n }, (_, i) => fn(i / n, i));
const seq = (keys, n, extra) => Array.from({ length: n }, (_, i) => pose(Object.assign(
  { glow: 0.3, open: 0 }, keyed(keys.map(sc), n === 1 ? 0 : i / (n - 1)), extra || {}, { phase: i * 0.9 })));
function footCycle(s, A, L) {
  if (s < 0.4) { const k = s / 0.4; return [lerp(-A, A * 1.2, ease(k)), -L * Math.sin(Math.PI * k)]; }
  const k = (s - 0.4) / 0.6; return [lerp(A * 1.2, -A, k), 0];
}

const S = makeStyle({
  head: 'none', headR: 6.4, headDist: 10, legLen: 17.5, waistLen: 12.5, chestLen: 12.5,
  torsoR: [9.5, 10.5, 12, 5], armLen: 13.4, farArmLen: 13, armR: [6.4, 5.6, 5], farArmR: [5.8, 5, 4.5],
  nearLegR: [7.6, 6.4, 5.4, 3.8], farLegR: [7.2, 6.0, 5.0, 3.6],
  torsoCol: ['3', '2', 'a'], nearLegCol: ['3', '2', 'a'], farLegCol: ['2', '1', '1'],
  nearArmCol: ['3', '2', 'a'], farArmCol: ['2', '1', '1'], handCol: ['3', '2'],
  cape: { on: true, base: 'a', fold: '1', edge: 'b', segs: 4, seg: 9, w0: 6, wk: 1.4, rag: 6 },
  scarf: false, belt: false, pouch: false, noise: 0.12, tunic: 6, shoulderPad: 0,
  weapon: 'maul', weaponLen: 33, maulShaft: [2.7, 2.5], shaftCol: ['3', '2', 'a'], maulHead: [9.5, 12],
});

// ---------- decoracion de la armadura ----------
const LIGHT = norm([-0.55, -0.85]);
const hash2 = (a, b) => { const x = Math.sin(a * 127.1 + b * 311.7) * 43758.5453; return x - Math.floor(x); };
const shade = (cx, cy, r, hi = '4', mid = '3', lo = '2') => (px, py) => {
  const s = ((px - cx) * LIGHT[0] + (py - cy) * LIGHT[1]) / r;
  return s > 0.4 ? hi : (s < -0.35 ? lo : mid);
};
const ell = (c, rx, ry) => (px, py) => ((px - c[0]) / rx) ** 2 + ((py - c[1]) / ry) ** 2 <= 1;
const pale = (c, r) => (px, py) => { const s = ((px - c[0]) * LIGHT[0] + (py - c[1]) * LIGHT[1]) / r; return s > 0.62 ? 'h' : (s > -0.25 ? '4' : '3'); };
const box = (c, r) => [c[0] - r, c[1] - r, c[0] + r, c[1] + r];

function skeleton(p) {
  const hip = add([OX, OY], [p.hipx, p.hipy]);
  const waist = add(hip, mul(dirA(p.lean), S.waistLen));
  const chest = add(waist, mul(dirA(p.lean + p.bend), S.chestLen));
  const neck = add(chest, mul(dirA(p.lean + p.bend + p.head * 0.5), 3));
  const headC = add(neck, mul(dirA(p.lean + p.bend + p.head), S.headDist));
  const shoulder = add(chest, mul(dirA(p.lean + p.bend + 90), -0.5));
  return { hip, waist, chest, neck, headC, shoulder };
}

// mezcla `layer` en `out` solo donde `out` esta vacio (cosas que van detras)
function behind(out, layer) {
  for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) if (out.g[y][x] === '.' && layer.g[y][x] !== '.') out.g[y][x] = layer.g[y][x];
}

function crack(out, o, u, n, pts, glow, seed) {
  // grieta con brillo ambar: pts en el sistema del cuerpo [a lo largo de u, b a lo largo de n]
  const P = pts.map(([a, b]) => add(o, add(mul(u, a), mul(n, b))));
  for (let i = 0; i < P.length - 1; i++) {
    if (glow > 0.2) out.line(add(P[i], [1, 0]), add(P[i + 1], [1, 0]), 'a');
    out.line(P[i], P[i + 1], glow > 0.35 ? 'c' : 'b');
    if (glow > 0.75 && (i + seed) % 2 === 0) { out.set(Math.floor(P[i][0]), Math.floor(P[i][1]), 'd'); }
  }
}

function deco(out, f, p) {
  const B = skeleton(p);
  const u = dirA(p.lean + p.bend * 0.5);           // a lo largo del torso (hacia arriba)
  const n = [Math.cos(rad(p.lean + p.bend * 0.5)), Math.sin(rad(p.lean + p.bend * 0.5))]; // hacia delante
  const open = p.open || 0, glow = p.glow === undefined ? 0.3 : p.glow;
  const pulse = clamp01(glow + 0.15 * Math.sin(p.phase * 1.7));

  // hombrera lejana (detras del torso)
  {
    const L = new Canvas();
    const c = add(B.shoulder, add(mul(n, -7), [-1, -4]));
    L.shape(ell(c, 9, 7.5), shade(c[0], c[1], 9, '3', '2', '1'), box(c, 12), true);
    behind(out, L);
  }

  // faldon de placas sobre la cadera
  {
    const a = add(B.hip, mul(u, 4));
    const q = [add(add(a, mul(n, 12)), mul(u, 0)), add(add(a, mul(n, -12)), mul(u, 0)), add(add(a, mul(n, -14)), mul(u, -11)), add(add(a, mul(n, 14)), mul(u, -11))];
    out.shape(polyTest(q), shade(a[0], a[1] - 6, 16, '3', '2', '1'), [a[0] - 16, a[1] - 14, a[0] + 16, a[1] + 14], true);
    for (const t of [-0.2, -0.5, -0.8]) out.line(add(add(a, mul(n, 13 + t * 2)), mul(u, t * 11)), add(add(a, mul(n, -13 - t * 2)), mul(u, t * 11)), '1');
  }

  // placas del pecho: bandas horizontales y reborde
  for (const t of [0.25, 0.52, 0.8]) {
    const o = add(B.waist, mul(sub(B.chest, B.waist), t));
    out.line(add(o, mul(n, -11)), add(o, mul(n, 12)), '1');
    out.line(add(add(o, mul(n, -10)), [0, -1]), add(add(o, mul(n, 10)), [0, -1]), '3');
  }

  // pestilla del pecho (abertura con luz cuando se rompe)
  const gap = add(B.chest, add(mul(n, 3), mul(u, -2)));
  if (open > 0.05) {
    const e = ell(gap, 6 + 4 * open, 7 + 6 * open);
    out.shape(ell(gap, 7.5 + 4 * open, 8.5 + 6 * open), () => 'c', box(gap, 22), false);
    out.shape(e, () => '1', box(gap, 22), false);
  }

  // cuello: gorjal
  {
    const g = add(B.neck, [0, 1]);
    out.shape(ell(g, 8, 4.6), shade(g[0], g[1], 8, '3', '2', 'a'), box(g, 10), true);
  }

  // yelmo cerrado con hendidura (se levanta y echa atras cuando la armadura se abre)
  {
    const h = add(B.headC, [-5 * open, -8 * open]);
    const m = (px, py) => ell(h, 7.2, 8)(px, py) && !(py < h[1] - 5.5 && Math.abs(px - h[0]) > 5.2);
    out.shape(m, shade(h[0], h[1], 8, '4', '3', '2'), box(h, 11), true);
    // cresta baja de hierro y juntas
    out.line([h[0] - 1, h[1] - 8], [h[0] - 1, h[1] - 1], '2');
    out.line([h[0] + 0.5, h[1] - 8.5], [h[0] + 0.5, h[1] - 2], 'a');
    out.line([h[0] - 7, h[1] + 3.5], [h[0] + 7, h[1] + 3.5], '1');
    // hendidura: dos pixeles de alto, brillo ambar
    const sx = Math.floor(h[0] + 0.5), sy = Math.floor(h[1] - 0.5);
    for (let x = sx; x <= sx + 6; x++) { out.set(x, sy, '1'); out.set(x, sy + 1, x > sx + 1 ? (pulse > 0.5 || open > 0.3 ? 'd' : 'c') : '1'); }
    for (let x = sx + 2; x <= sx + 5; x++) out.set(x, sy + 2, '1');
    // grieta del yelmo cuando esta herido
    if (open > 0.3) crack(out, [h[0], h[1]], [0, -1], [1, 0], [[7, -3], [3, -1], [0, 1], [-4, 0]], 0.9, 1);
  }

  // hombrera cercana, grande y con remaches
  {
    const s = add(B.shoulder, [-3, -1]);
    out.shape(ell(s, 10, 8.5), shade(s[0], s[1], 10, '4', '3', '2'), box(s, 14), true);
    out.line([s[0] - 10, s[1] + 3], [s[0] + 10, s[1] + 3], '1');
    out.line([s[0] - 9, s[1] - 2], [s[0] + 5, s[1] - 7], '1');
    for (const [dx, dy] of [[-6, -2], [0, -5], [6, -1], [0, 0]]) out.set(Math.floor(s[0] + dx), Math.floor(s[1] + dy), 'c');
    // puas de hierro oxidado
    for (const dx of [-8, -1, 6]) { out.set(Math.floor(s[0] + dx), Math.floor(s[1] - 9.5 - (dx === -1 ? 2 : 0)), 'b'); out.set(Math.floor(s[0] + dx), Math.floor(s[1] - 8.5), 'a'); }
  }

  // rodilleras (la rodilla sale del IK con la misma regla que la biblioteca)
  for (const [foot, col] of [[[p.nfx, p.nfy], 'near'], [[p.ffx, p.ffy], 'far']]) {
    const ankle = add([OX, OY], [foot[0], foot[1] - 2.6]);
    const s = lib.ik(B.hip, ankle, S.legLen, S.legLen, (a, b) => (a[0] > b[0] ? a : b));
    const r = col === 'near' ? 5.2 : 4.4;
    out.shape(ell(s.joint, r, r), shade(s.joint[0], s.joint[1], r, col === 'near' ? '4' : '3', col === 'near' ? '3' : '2', col === 'near' ? '2' : '1'), box(s.joint, r + 3), true);
    if (col === 'near') out.set(Math.floor(s.joint[0]), Math.floor(s.joint[1]), 'c');
  }

  // oxido: manchas fijas respecto a la cadera (no "nadan" al moverse)
  for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) {
    const v = out.g[y][x];
    if (v !== '2' && v !== '3') continue;
    const hv = hash2(Math.floor((x - B.hip[0]) / 2), Math.floor((y - B.hip[1]) / 2));
    if (hv < 0.07) out.g[y][x] = v === '3' ? 'b' : 'a';
  }

  // grietas con brillo ambar (laten; mas fuertes al atacar y al abrirse)
  const g = clamp01(pulse + 0.4 * open);
  crack(out, B.chest, u, n, [[2, -3], [-2, 1], [-5, -1], [-9, 3], [-12, 2]], g, 0);
  crack(out, B.chest, u, n, [[-3, 7], [-6, 5], [-7, 9]], g * 0.9, 1);
  crack(out, B.hip, u, n, [[4, 5], [1, 8], [-3, 6], [-6, 10]], g * 0.85, 0);
  crack(out, add(B.shoulder, [0, -3]), [0, -1], [1, 0], [[3, -2], [0, 1], [-3, 0], [-5, 4]], g * 0.9, 1);
  if (g > 0.45) crack(out, B.neck, u, n, [[-1, -5], [-4, -3], [-6, -6]], g * 0.8, 0);
  // figura palida (el cascaron) asomando por el pecho y el cuello
  if (open > 0.05) {
    const e = open;
    // hombros encorvados dentro del pecho
    const hs = add(gap, add(mul(u, 1 * e), mul(n, -1)));
    out.shape(ell(hs, 8 * e + 1, 6 * e + 1), pale(hs, 7), box(hs, 10), true);
    // cabeza que sube por el cuello, caida hacia delante
    const hd = add(B.neck, add(mul(u, 3 + 6.5 * e), mul(n, 3 + 3 * e)));
    const hr = 4.8;
    out.shape(ell(hd, hr, hr + 0.4), pale(hd, hr), box(hd, 8), true);
    for (const [ex, ey] of [[0, -1], [1, -1], [2, -1], [0, 0], [1, 0], [2, 0]]) out.set(Math.floor(hd[0] + ex), Math.floor(hd[1] + ey), '1');
    out.set(Math.floor(hd[0] + 1), Math.floor(hd[1] + 0.5), '1'); out.set(Math.floor(hd[0] + 2), Math.floor(hd[1] + 0.5), '1');
    out.set(Math.floor(hd[0] + 2), Math.floor(hd[1] + 0.5), 'u');
    // mano palida aferrada al borde de la placa
    const hand = add(gap, add(mul(n, 7), mul(u, -4 * e)));
    out.shape(ell(hand, 2.6, 1.8), () => '4', box(hand, 5), true);
    for (let k = -1; k <= 1; k++) out.set(Math.floor(hand[0] + k * 1.6), Math.floor(hand[1] + 2.4), '3');
    // luz ambar de las grietas sobre la figura
    out.line(add(gap, [-5 * e, -6 * e]), add(gap, [-2 * e, 6 * e]), 'd');
  }

}
const clamp01 = (v) => Math.max(0, Math.min(1, v));

function slam(grow) {
  // escombros y polvo donde cae la cabeza del mazo, sobre la fila del suelo
  return (out, f, p) => {
    deco(out, f, p);
    const gx = Math.floor(f.tip[0]) + 4, gy = H - 1;
    const pts = [[-14, 0, '3'], [-10, -3, '4'], [-5, -2, '3'], [5, -3, '4'], [10, -2, '3'], [15, 0, '3'], [-19, -6, '2'], [20, -5, '2'], [0, -6, '4'],
      [-8, -9, '3'], [9, -8, '3'], [-3, -12, '2'], [4, -14, '2'], [-14, -13, '3'], [14, -12, '4'], [-22, -9, '2'], [23, -11, '2']];
    for (const [dx, dy, c] of pts) if (Math.abs(dx) <= grow) out.set(gx + dx, gy + dy - Math.floor(grow / 4), c);
    for (let k = -grow; k <= grow; k += 2) { out.set(gx + k, gy, '2'); out.set(gx + k, gy - 1, k % 4 === 0 ? '3' : '2'); }
    for (let i = 0; i < grow * 3; i++) {
      const hx = hash2(i, grow), hy = hash2(grow, i * 3 + 1);
      const dx = Math.round((hx - 0.5) * 2 * grow * 1.5), dy = Math.round(hy * grow * 0.8);
      out.set(gx + dx, gy - dy - 1, i % 3 === 0 ? '4' : (i % 3 === 1 ? '3' : '2'));
    }
    // grietas en el suelo y brillo ambar de la piedra rota
    for (let k = 3; k < grow; k += 5) { out.set(gx + k, gy - 1, 'c'); out.set(gx - k, gy - 1, 'b'); }
  };
}
const withDeco = (arr, fn) => arr.map((p) => Object.assign(p, { post: fn ? fn(p) : (o, f) => deco(o, f, p) }));
const decoAll = (arr) => arr.map((p) => Object.assign(p, { post: (o, f) => deco(o, f, p) }));

// ---------- poses ----------
const idleK = { hipx: 0, hipy: -23, lean: 4, bend: 3, head: 4, nfx: 9, ffx: -9, fx: 9, fy: 6, gx: 2, gy: 12, blade: -158, capeTx: -1, capeTy: 0.3, capeAmt: 0.25, capeWave: 0.4 };
const idleP = (b) => pose(Object.assign({ glow: 0.3, open: 0 }, sc(idleK), {
  hipy: -23 * K + 1.6 * b, lean: 4 + 1.4 * b, bend: 3 + 1.6 * b, fx: 9 * K + 0.5 * b, fy: 6 * K - 0.5 * b }));

const anims = {};
anims.idle = { fps: 6, loop: true, frames: decoAll(frames(8, (t) => {
  const b = Math.sin(t * 2 * Math.PI);
  return Object.assign(idleP(b), { phase: t * 2 * Math.PI, glow: 0.3 + 0.1 * b });
})) };

anims.walk = { fps: 14, loop: true, frames: decoAll(frames(10, (u) => {
  const nf = footCycle(u % 1, 11, 6), ff = footCycle((u + 0.5) % 1, 11, 6);
  const down = Math.cos(4 * Math.PI * (u - 0.17)), sw = Math.sin(2 * Math.PI * (u - 0.1));
  return pose(Object.assign({ glow: 0.35, open: 0 }, sc(idleK), {
    hipx: 1.4, hipy: -23 * K + 2 * down, lean: 8, bend: 3, nfx: nf[0], nfy: nf[1], ffx: ff[0], ffy: ff[1],
    nfa: nf[1] < -2 ? 30 : 0, ffa: ff[1] < -2 ? 30 : 0, fx: 9 * K + 0.7 * sw, fy: 6 * K, gx: (3 - 1.5 * sw) * K, gy: 12 * K,
    blade: -158 + 4 * sw, capeAmt: 0.5, phase: 4 * Math.PI * u }));
})) };

const raised = { hipx: -3, hipy: -21, lean: -16, bend: -8, head: 10, nfx: 11, ffx: -11, fx: 6, fy: -22, gx: 10, gy: -18, blade: -122, capeTx: 0.3, capeTy: 0.5, capeAmt: 0.7, capeWave: 0.4 };
anims.windup = { fps: 8, loop: false, frames: decoAll(seq([
  { t: 0, ...idleK, glow: 0.3 },
  { t: 0.25, hipx: 0, hipy: -22.5, lean: 4, bend: 0, head: 4, nfx: 10, ffx: -10, fx: 8, fy: -2, gx: 5, gy: 6, blade: -135, capeTx: -0.6, capeTy: 0.3, capeAmt: 0.4, capeWave: 0.4, glow: 0.5 },
  { t: 0.55, hipx: -1, hipy: -22, lean: -6, bend: -6, head: 8, nfx: 10, ffx: -10, fx: 8, fy: -14, gx: 8, gy: -8, blade: -118, capeTx: 0, capeTy: 0.5, capeAmt: 0.6, capeWave: 0.4, glow: 0.8 },
  { t: 1, ...raised, glow: 1 },
], 6)) };

const strikeKeys = [
  { t: 0, ...raised, glow: 1 },
  { t: 0.3, hipx: 4, hipy: -20, lean: 14, bend: 6, head: -6, nfx: 13, ffx: -11, fx: 12, fy: -14, gx: 12, gy: -8, blade: -60, capeTx: -1, capeTy: 0, capeAmt: 0.9, capeWave: 0.4, glow: 1 },
  { t: 0.6, hipx: 10, hipy: -17.5, lean: 42, bend: 12, head: -22, nfx: 17, ffx: -12, fx: 22, fy: -6, gx: 18, gy: -2, blade: 56, capeTx: -1, capeTy: -0.2, capeAmt: 1, capeWave: 0.4, glow: 1 },
  { t: 1, hipx: 11, hipy: -17, lean: 46, bend: 12, head: -24, nfx: 17, ffx: -12, fx: 24, fy: -2, gx: 19, gy: 4, blade: 66, capeTx: -1, capeTy: -0.1, capeAmt: 1, capeWave: 0.4, glow: 0.8 },
];
anims.strike = { fps: 24, loop: false, frames: seq(strikeKeys, 6).map((p, i) => Object.assign(p, {
  post: i >= 4 ? (o, f) => slam(i === 4 ? 12 : 18)(o, f, p) : (o, f) => deco(o, f, p) })) };

// agazaparse para saltar: baja la cadera, las piernas se doblan y el mazo se echa atras
anims.crouch = { fps: 10, loop: false, frames: decoAll(seq([
  { t: 0, ...idleK },
  { t: 1, hipx: -2, hipy: -15, lean: 28, bend: 14, head: -10, nfx: 14, ffx: -14, fx: 4, fy: 8, gx: -2, gy: 14, blade: -135, capeTx: -1, capeTy: 0.5, capeAmt: 0.5, capeWave: 0.4 },
], 4, { glow: 0.5 })) };

// en el aire: encogido, mazo alzado
anims.air = { fps: 6, loop: true, frames: decoAll(frames(2, (t, i) => pose(Object.assign({ glow: 0.5 + 0.2 * i, open: 0 }, sc({
  hipx: 0, hipy: -21 - i, lean: 8 + 4 * i, bend: 8, head: 4, nfx: 8 + 3 * i, nfy: -7 - 2 * i, ffx: -5, ffy: -9 - 3 * i, nfa: 30, ffa: 40,
  fx: 7, fy: -12 - 2 * i, gx: 8, gy: -8, blade: -125 + 6 * i, capeTx: 0.3, capeTy: -0.8, capeAmt: 0.9, capeWave: 0.5 }), { phase: i * 1.6 })))) };

// aturdido: de rodillas, armadura abierta, la figura palida asoma (punto debil)
const knelt = { hipx: -3, hipy: -13, lean: 14, bend: 8, head: -6, nfx: 15, nfy: 0, nfa: 0, ffx: -22, ffy: -1, ffa: 80, fx: 8, fy: 20, gx: 4, gy: 14, blade: 18, capeTx: -1, capeTy: 0.6, capeAmt: 0.4, capeWave: 0.5 };
anims.stagger = { fps: 8, loop: true, frames: decoAll(frames(6, (t, i) => {
  const b = Math.sin(t * 2 * Math.PI), b2 = Math.sin(t * 4 * Math.PI);
  return pose(Object.assign({ glow: 0.8 + 0.2 * b2, open: 0.85 + 0.15 * b }, sc(knelt), {
    hipy: -13 * K + 0.9 * b, lean: 14 + 1.5 * b, head: -6 - 2.5 * b, fy: 20 * K + 0.8 * b, phase: t * 2 * Math.PI }));
})) };

// se incorpora: cierra la armadura y recupera la guardia
anims.getup = { fps: 8, loop: false, frames: decoAll(Array.from({ length: 4 }, (_, i) => {
  const t = i / 3, e = ease(t);
  const k = (a, b) => lerp(a, b, e);
  return pose(Object.assign({ glow: lerp(0.8, 0.3, t), open: 0.85 * (1 - t) * (1 - t) }, sc({
    hipx: k(knelt.hipx, idleK.hipx), hipy: k(knelt.hipy, idleK.hipy), nfx: k(knelt.nfx, idleK.nfx), nfy: 0, ffx: k(knelt.ffx, idleK.ffx), ffy: k(knelt.ffy, 0),
    fx: k(knelt.fx, idleK.fx), fy: k(knelt.fy, idleK.fy), gx: k(knelt.gx, idleK.gx), gy: k(knelt.gy, idleK.gy) }), {
    lean: k(knelt.lean, idleK.lean), bend: k(knelt.bend, idleK.bend), head: k(knelt.head, idleK.head), ffa: k(knelt.ffa, 0),
    blade: k(knelt.blade, idleK.blade), capeTx: -1, capeTy: 0.5, capeAmt: 0.4, capeWave: 0.4, phase: i * 0.9 }));
})) };

// ---------- salida ----------
const order = ['idle', 'walk', 'windup', 'strike', 'crouch', 'air', 'stagger', 'getup'];
const header = [
  '# El Centinela Hueco: armadura vacia de un Custodio de la Orden del Archivo, enorme, de hierro oscuro',
  '# y oxidado, con grietas de brillo ambar y un mazo de piedra y hierro. Se mueve por costumbre; cuando',
  '# se agrieta, dentro se ve una figura palida y encorvada (un cascaron) asomando por el pecho y el cuello.',
  '# Cada fotograma es un lienzo completo de ' + W + 'x' + H + ' con los pies en la fila de abajo.',
  '# Lo genera tools/rig_centinela.js (esqueleto de tools/rig_lib.js); para cambiar el movimiento se',
  '# edita el esqueleto y se regenera, no estos fotogramas a mano.',
  '# Leyenda: ver art/palette.txt. El punto (.) es transparente.'];
const info = lib.writeSprite('art/source/centinela.sprite', header, 'res://game/boss/centinela_sheet.png', order, anims, S);
console.log(JSON.stringify(info));
