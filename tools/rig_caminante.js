// Generador del Caminante: un esqueleto simple (cadera, columna curvada, cabeza,
// brazos y piernas con cinematica inversa, capa y bufanda con inercia, espada
// empunada del reves) que se rasteriza a pixel art por fotograma.
const fs = require('fs');
const NL = String.fromCharCode(10);
const W = 112, H = 64, OX = 56, OY = 64; // lienzo y punto de los pies (suelo)

// ---------- utilidades matematicas ----------
const rad = d => d * Math.PI / 180;
const dirA = a => [Math.sin(rad(a)), -Math.cos(rad(a))]; // 0 = arriba, + = adelante
const add = (a, b) => [a[0] + b[0], a[1] + b[1]];
const sub = (a, b) => [a[0] - b[0], a[1] - b[1]];
const mul = (a, k) => [a[0] * k, a[1] * k];
const len = a => Math.hypot(a[0], a[1]);
const norm = a => { const l = len(a) || 1; return [a[0] / l, a[1] / l]; };
const lerp = (a, b, t) => a + (b - a) * t;
const ease = t => t * t * (3 - 2 * t);
const clamp = (v, a, b) => Math.max(a, Math.min(b, v));

function ik(A, T, l1, l2, pick) {
  let d = len(sub(T, A));
  d = clamp(d, Math.abs(l1 - l2) + 0.01, l1 + l2 - 0.01);
  const dv = norm(sub(T, A));
  const a = (l1 * l1 - l2 * l2 + d * d) / (2 * d);
  const h = Math.sqrt(Math.max(0, l1 * l1 - a * a));
  const base = add(A, mul(dv, a));
  const p = [-dv[1], dv[0]];
  const c1 = add(base, mul(p, h)), c2 = add(base, mul(p, -h));
  const end = add(A, mul(dv, d));
  return { joint: pick(c1, c2), end };
}

// ---------- raster ----------
class Canvas {
  constructor() { this.g = Array.from({ length: H }, () => Array(W).fill('.')); }
  set(x, y, c) { if (x >= 0 && y >= 0 && x < W && y < H) this.g[y][x] = c; }
  get(x, y) { return (x >= 0 && y >= 0 && x < W && y < H) ? this.g[y][x] : '.'; }
  // rellena lo que cumpla test(px,py) (centros de pixel) con color(px,py)
  shape(test, color, box, outline = true) {
    const x0 = Math.max(0, Math.floor(box[0])), y0 = Math.max(0, Math.floor(box[1]));
    const x1 = Math.min(W - 1, Math.ceil(box[2])), y1 = Math.min(H - 1, Math.ceil(box[3]));
    const mask = new Set();
    for (let y = y0; y <= y1; y++) for (let x = x0; x <= x1; x++)
      if (test(x + 0.5, y + 0.5)) mask.add(y * W + x);
    if (outline) {
      for (const k of mask) {
        const x = k % W, y = (k - x) / W;
        for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) {
          const nx = x + dx, ny = y + dy;
          if (!mask.has(ny * W + nx)) this.set(nx, ny, '1');
        }
      }
    }
    for (const k of mask) {
      const x = k % W, y = (k - x) / W;
      this.set(x, y, color(x + 0.5, y + 0.5));
    }
  }
  line(a, b, c) {
    const n = Math.ceil(Math.max(Math.abs(b[0] - a[0]), Math.abs(b[1] - a[1]))) * 2 || 1;
    for (let i = 0; i <= n; i++) { const t = i / n; this.set(Math.floor(lerp(a[0], b[0], t)), Math.floor(lerp(a[1], b[1], t)), c); }
  }
}

// distancia de un punto a una cadena de segmentos con radios
function chainTest(pts, rs) {
  return (px, py) => {
    for (let i = 0; i < pts.length - 1; i++) {
      const a = pts[i], b = pts[i + 1];
      const ab = sub(b, a), l2 = ab[0] * ab[0] + ab[1] * ab[1] || 1e-6;
      const t = clamp(((px - a[0]) * ab[0] + (py - a[1]) * ab[1]) / l2, 0, 1);
      const cx = a[0] + ab[0] * t, cy = a[1] + ab[1] * t;
      const r = lerp(rs[i], rs[i + 1], t);
      if (Math.hypot(px - cx, py - cy) <= r) return true;
    }
    return false;
  };
}
// sombreado: claro hacia arriba-atras (luz), oscuro hacia abajo-delante
const LIGHT = norm([-0.55, -0.85]);
function chainColor(pts, rs, hi, mid, lo) {
  return (px, py) => {
    let best = 1e9, bn = [0, 0], br = 1, bd = 0;
    for (let i = 0; i < pts.length - 1; i++) {
      const a = pts[i], b = pts[i + 1];
      const ab = sub(b, a), l2 = ab[0] * ab[0] + ab[1] * ab[1] || 1e-6;
      const t = clamp(((px - a[0]) * ab[0] + (py - a[1]) * ab[1]) / l2, 0, 1);
      const cx = a[0] + ab[0] * t, cy = a[1] + ab[1] * t;
      const d = Math.hypot(px - cx, py - cy);
      if (d < best) { best = d; bn = [px - cx, py - cy]; br = lerp(rs[i], rs[i + 1], t); bd = d; }
    }
    const s = (bn[0] * LIGHT[0] + bn[1] * LIGHT[1]) / (br || 1);
    if (s > 0.35) return hi;
    if (s < -0.45) return lo;
    return mid;
  };
}
function polyTest(poly) {
  return (px, py) => {
    let inside = false;
    for (let i = 0, j = poly.length - 1; i < poly.length; j = i++) {
      const [xi, yi] = poly[i], [xj, yj] = poly[j];
      if (((yi > py) !== (yj > py)) && (px < (xj - xi) * (py - yi) / (yj - yi) + xi)) inside = !inside;
    }
    return inside;
  };
}
const bbox = pts => [Math.min(...pts.map(p => p[0])) - 3, Math.min(...pts.map(p => p[1])) - 3, Math.max(...pts.map(p => p[0])) + 3, Math.max(...pts.map(p => p[1])) + 3];

// cadena que arrastra (capa, bufanda): cada tramo mezcla gravedad y estela
function trailChain(root, n, seg, grav, trail, amt, wave, phase) {
  const pts = [root];
  let p = root;
  for (let i = 0; i < n; i++) {
    const w = clamp(amt * (0.35 + 0.65 * (i + 1) / n), 0, 1);
    let d = norm(add(mul(norm(grav), 1 - w), mul(norm(trail), w)));
    const ang = Math.atan2(d[1], d[0]) + wave * Math.sin(phase + i * 1.1) * (0.15 + i * 0.18);
    d = [Math.cos(ang), Math.sin(ang)];
    p = add(p, mul(d, seg));
    pts.push(p);
  }
  return pts;
}

// ---------- pose y dibujo del personaje ----------
const BASE = {
  hipx: 0, hipy: -18, lean: 14, bend: 4, head: -8,
  nfx: 4, nfy: 0, nfa: 0, ffx: -4, ffy: 0, ffa: 0,
  fx: 9, fy: 9, gx: -5, gy: 9, blade: 95, curve: -48,
  capeTx: -1, capeTy: 0.15, capeAmt: 0.25, capeWave: 0.35,
  scTx: -1, scTy: 0.1, scAmt: 0.5, hoodTy: -0.35,
  phase: 0, ghost: 0, lines: 0, trailFrom: null,
};
function pose(o) { return Object.assign({}, BASE, o); }

function figure(p) {
  const c = new Canvas();
  const O = [OX, OY];
  const hip = add(O, [p.hipx, p.hipy]);
  const waist = add(hip, mul(dirA(p.lean), 7));
  const chest = add(waist, mul(dirA(p.lean + p.bend), 6.5));
  const neck = add(chest, mul(dirA(p.lean + p.bend + p.head * 0.5), 3));
  const headC = add(neck, mul(dirA(p.lean + p.bend + p.head), 4.8));
  const shoulder = add(chest, mul(dirA(p.lean + p.bend + 90), -0.5));
  const kneeFwd = (a, b) => (a[0] > b[0] ? a : b);

  // ---- capa (detras de todo)
  const capeRoot = add(neck, [-1.5, 2]);
  const capeSpine = trailChain(capeRoot, 5, 6.2, [0, 1], [p.capeTx, p.capeTy], p.capeAmt, p.capeWave, p.phase);
  const half = i => 2.4 + i * 0.95;
  const left = [], right = [];
  for (let i = 0; i < capeSpine.length; i++) {
    const a = capeSpine[Math.max(0, i - 1)], b = capeSpine[Math.min(capeSpine.length - 1, i + 1)];
    const d = norm(sub(b, a)), n = [-d[1], d[0]];
    left.push(add(capeSpine[i], mul(n, half(i)))); right.push(add(capeSpine[i], mul(n, -half(i))));
  }
  const endD = norm(sub(capeSpine[capeSpine.length - 1], capeSpine[capeSpine.length - 2]));
  const tip = add(capeSpine[capeSpine.length - 1], mul(endD, 3));
  const capePoly = [...left, tip, ...right.reverse()];
  c.shape(polyTest(capePoly), () => '2', bbox(capePoly));
  // pliegues a lo largo de la capa y borde claro del lado de la luz
  for (const f of [0.38, -0.2]) {
    for (let i = 1; i < capeSpine.length - 1; i++) {
      const a = capeSpine[i], b = capeSpine[i + 1];
      const d = norm(sub(b, a)), n = [-d[1], d[0]];
      c.line(add(a, mul(n, half(i) * f)), add(b, mul(n, half(i + 1) * f)), f > 0 ? '1' : '3');
    }
  }
  for (let i = 0; i < left.length - 1; i++) c.line(left[i], left[i + 1], '3');

  // estela del tajo
  if (p.trailFrom) {
    const tf = p.trailFrom;
    for (let i = 0; i < tf.length - 1; i++) {
      const k = i / Math.max(1, tf.length - 2);
      const col = k > 0.7 ? 'h' : (k > 0.4 ? 'g' : 'f');
      c.line(tf[i], tf[i + 1], col);
      if (k > 0.4) c.line(add(tf[i], [0, 1]), add(tf[i + 1], [0, 1]), col);
    }
  }

  // ---- pierna lejana
  const legPart = (foot, ang, fillHi, fillMid, fillLo, rKnee) => {
    const ankle = add(O, [foot[0], foot[1] - 2.6]);
    const s = ik(hip, ankle, 9.6, 9.6, kneeFwd);
    const toe = add(ankle, [4.2 * Math.cos(rad(ang)), 1.7 + 4.2 * Math.sin(rad(ang))]);
    const pts = [hip, s.joint, s.end, toe], rs = [3.5, rKnee, 2.3, 1.7];
    c.shape(chainTest(pts, rs), chainColor(pts, rs, fillHi, fillMid, fillLo), bbox(pts));
    return s;
  };
  legPart([p.ffx, p.ffy], p.ffa, '2', '1', '1', 2.8);

  // ---- brazo lejano
  const armFar = (() => {
    const T = add(shoulder, [p.gx, p.gy]);
    const s = ik(shoulder, T, 6.6, 6.6, (a, b) => (a[1] > b[1] ? a : b));
    const pts = [shoulder, s.joint, s.end], rs = [2.6, 2.1, 1.9];
    c.shape(chainTest(pts, rs), chainColor(pts, rs, '2', '1', '1'), bbox(pts));
    return s;
  })();

  // ---- torso (curvado: cadera, cintura, pecho, cuello)
  const tp = [hip, waist, chest, neck], tr = [4.4, 4.9, 5.4, 2.6];
  c.shape(chainTest(tp, tr), chainColor(tp, tr, '3', '2', '2'), bbox(tp));
  // cinturon ambar y correa en diagonal
  const belt = add(hip, mul(dirA(p.lean), 2.2));
  c.line(add(belt, [-4, 0]), add(belt, [4, 0]), 'b');
  c.line(add(belt, [-4, -1]), add(belt, [4, -1]), 'a');
  c.line(add(waist, mul(dirA(p.lean + p.bend - 90), 4)), add(belt, [3, 0]), 'a');
  const pouch = add(belt, [3.4, 2.2]);
  c.shape((px, py) => Math.abs(px - pouch[0]) <= 1.9 && Math.abs(py - pouch[1]) <= 1.7, (px, py) => (py < pouch[1] - 0.6 ? 'c' : 'b'), [pouch[0] - 3, pouch[1] - 3, pouch[0] + 3, pouch[1] + 3], true);

  // ---- pierna cercana
  legPart([p.nfx, p.nfy], p.nfa, '3', '2', '1', 3.0);

  // ---- bufanda (azul) y capucha
  const scarfPts = [add(neck, [-2.2, 0.4]), add(neck, [2, 0.8])];
  c.shape(chainTest(scarfPts, [1.9, 1.9]), () => 'g', bbox(scarfPts));
  const sc = trailChain(add(neck, [-2, 0.5]), 4, 4.6, [0, 1], [p.scTx, p.scTy], p.scAmt, 0.55, p.phase + 1.3);
  const sr = [1.7, 1.5, 1.2, 1.0, 0.8];
  c.shape(chainTest(sc, sr), chainColor(sc, sr, 'h', 'g', 'f'), bbox(sc));

  // capucha: punta que se echa hacia atras
  const hoodTip = add(headC, mul(norm([-1, p.hoodTy]), 9.5));
  const hoodBack = [add(headC, [-1, -5.2]), hoodTip, add(headC, [-4.5, 3.5])];
  c.shape(polyTest([hoodBack[0], hoodBack[1], hoodBack[2]]), (px, py) => '2', bbox(hoodBack), true);
  c.shape((px, py) => Math.hypot(px - headC[0], py - headC[1]) <= 5.6, (px, py) => {
    const s = ((px - headC[0]) * LIGHT[0] + (py - headC[1]) * LIGHT[1]) / 5.6;
    return s > 0.45 ? '3' : '2';
  }, [headC[0] - 7, headC[1] - 7, headC[0] + 7, headC[1] + 7]);
  // rostro en sombra y ojo azul
  const face = add(headC, [2.3, 0.6]);
  c.shape((px, py) => ((px - face[0]) / 3.2) ** 2 + ((py - face[1]) / 3.9) ** 2 <= 1 && Math.hypot(px - headC[0], py - headC[1]) <= 5.1,
    () => '1', [face[0] - 5, face[1] - 5, face[0] + 5, face[1] + 5], false);
  c.shape((px, py) => ((px - face[0]) / 3.2) ** 2 + ((py - face[1]) / 3.9) ** 2 <= 1 && Math.hypot(px - headC[0], py - headC[1]) <= 5.1 && py > face[1] + 0.9,
    (px, py) => (py < face[1] + 1.9 ? 'g' : 'f'), [face[0] - 5, face[1], face[0] + 5, face[1] + 5], false);
  c.set(Math.floor(face[0] + 1.2), Math.floor(face[1] - 0.3), 'h');
  c.set(Math.floor(face[0] + 0.2), Math.floor(face[1] - 0.3), 'g');
  for (let a = -110, k = 0; a <= 40; a += 13, k++) {
    c.set(Math.floor(headC[0] + Math.cos(rad(a)) * 5.1), Math.floor(headC[1] + Math.sin(rad(a)) * 5.1), k % 2 ? 'c' : 'b');
  }

  // ---- brazo cercano + espada empunada del reves
  const T = add(shoulder, [p.fx, p.fy]);
  const arm = ik(shoulder, T, 6.8, 6.8, (a, b) => (a[1] > b[1] ? a : b));
  const apts = [shoulder, arm.joint, arm.end], ar = [2.9, 2.4, 2.1];
  c.shape(chainTest(apts, ar), chainColor(apts, ar, '3', '2', 'a'), bbox(apts));
  // pulsera ambar
  const wr = add(arm.end, mul(norm(sub(arm.joint, arm.end)), -0.2));
  const fist = arm.end;
  const bd = [Math.cos(rad(p.blade)), Math.sin(rad(p.blade))];
  const bn = [-bd[1], bd[0]];
  // linea central de la hoja: nace del puño y se curva hacia delante (el filo)
  const BL = 24, N = 18;
  const cl = [add(fist, mul(bd, 1.2))], tg = [bd];
  for (let i = 1; i <= N; i++) {
    const ang = rad(p.blade + p.curve * Math.pow(i / N, 1.35));
    const t = [Math.cos(ang), Math.sin(ang)];
    cl.push(add(cl[i - 1], mul(t, BL / N))); tg.push(t);
  }
  const hw = i => 2.0 - 1.5 * Math.pow(i / N, 0.9);
  const lft = [], rgt = [];
  for (let i = 0; i <= N; i++) {
    const n = [-tg[i][1], tg[i][0]];
    lft.push(add(cl[i], mul(n, hw(i)))); rgt.push(add(cl[i], mul(n, -hw(i))));
  }
  const tipPt = cl[N];
  const bladePoly = [...lft, add(tipPt, mul(tg[N], 1.8)), ...rgt.reverse()];
  c.shape(polyTest(bladePoly), (px, py) => {
    let bi = 0, bdist = 1e9;
    for (let i = 0; i <= N; i++) { const d = Math.hypot(px - cl[i][0], py - cl[i][1]); if (d < bdist) { bdist = d; bi = i; } }
    const n = [-tg[bi][1], tg[bi][0]];
    const sd = (px - cl[bi][0]) * n[0] + (py - cl[bi][1]) * n[1];
    if (bi >= N - 2) return 'h';
    return sd > 0.45 ? 'g' : (sd < -0.5 ? '3' : '4');
  }, bbox(bladePoly), true);
  // guarda ambar (cruceta) y empunadura
  const gi = 2, gn = [-tg[gi][1], tg[gi][0]];
  c.line(add(cl[gi], mul(gn, 3.6)), add(cl[gi], mul(gn, -3.6)), 'c');
  c.line(add(cl[gi], mul(gn, 2.6)), add(cl[gi], mul(gn, -2.6)), 'd');
  c.set(Math.floor(cl[gi][0] + gn[0] * 3.6), Math.floor(cl[gi][1] + gn[1] * 3.6), 'b');
  c.set(Math.floor(cl[gi][0] - gn[0] * 3.6), Math.floor(cl[gi][1] - gn[1] * 3.6), 'b');
  const pommel = add(fist, mul(bd, -2.6));
  c.shape((px, py) => Math.hypot(px - pommel[0], py - pommel[1]) <= 1.4, () => 'b', [pommel[0] - 3, pommel[1] - 3, pommel[0] + 3, pommel[1] + 3], true);
  c.shape((px, py) => Math.hypot(px - fist[0], py - fist[1]) <= 2.4, (px, py) => ((px - fist[0]) * LIGHT[0] + (py - fist[1]) * LIGHT[1]) > 0 ? '3' : '2', [fist[0] - 4, fist[1] - 4, fist[0] + 4, fist[1] + 4], true);

  c.tip = tipPt; c.mid = cl[9]; c.fist = fist;
  return c;
}

function render(p) {
  const out = new Canvas();
  // imagenes residuales (dash)
  for (let k = p.ghost; k >= 1; k--) {
    const gp = Object.assign({}, p, { ghost: 0, lines: 0, trailFrom: null, hipx: p.hipx - k * 11, nfx: p.nfx - k * 11, ffx: p.ffx - k * 11 });
    const gc = figure(Object.assign(gp, { phase: p.phase }));
    for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) {
      if (gc.g[y][x] === '.') continue;
      const keep = k === 1 ? ((x + y) % 2 === 0) : ((x + 2 * y) % 4 === 0);
      if (keep) out.set(x - 0, y, k === 1 ? 'f' : 'e');
    }
  }
  if (p.lines) {
    for (let i = 0; i < p.lines; i++) {
      const y = 18 + ((i * 17 + p.phase * 7) % 34) | 0;
      const x0 = OX - 38 + ((i * 11) % 9), l = 10 + (i * 5) % 12;
      for (let x = x0; x < x0 + l; x++) out.set(x, y, i % 2 ? 'g' : 'f');
    }
  }
  const f = figure(p);
  for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) if (f.g[y][x] !== '.') out.set(x, y, f.g[y][x]);
  out.tip = f.tip; out.mid = f.mid; out.fist = f.fist;
  return out;
}

// ---------- animaciones ----------
// Referencia: asesino agazapado, muy inclinado hacia delante, con el puño de la
// espada junto al pecho y la hoja curva colgando por debajo y hacia delante; el
// otro brazo echado atras para equilibrar.
function footCycle(s, A, L) { // s en [0,1): devuelve [x, y] de la suela
  if (s < 0.38) { const k = s / 0.38; return [lerp(-A, A * 1.25, ease(k)), -L * Math.sin(Math.PI * k) * (k < 0.5 ? 1.15 : 1)]; }
  const k = (s - 0.38) / 0.62; return [lerp(A * 1.25, -A, k), 0];
}

const anims = {};

// reposo: agazapado y alerta; respira, el peso se mece y la capa ondea
anims.idle = { fps: 10, loop: true, frames: Array.from({ length: 10 }, (_, i) => {
  const t = i / 10, b = Math.sin(t * 2 * Math.PI), s = Math.sin(t * 2 * Math.PI + 1);
  return pose({ hipx: 2.5 + 0.6 * s, hipy: -17.4 + 0.5 * b, lean: 24 + 1.5 * b, bend: 8 + 1.5 * b, head: -16 + 1 * s,
    nfx: 8, ffx: -7, fx: 9 + 0.7 * b, fy: 8 - 0.9 * b, gx: -8 + 0.6 * s, gy: 8 + 0.5 * b, blade: 95 + 3 * b,
    capeTx: -1, capeTy: 0.25, capeAmt: 0.45 + 0.08 * b, capeWave: 0.4, phase: t * 2 * Math.PI,
    scAmt: 0.6 + 0.1 * s, scTy: 0.1 + 0.1 * b, hoodTy: -0.5 });
}) };

// carrera: muy curvado, casi a ras de suelo, brazo libre atras y la daga al pecho
anims.run = { fps: 40, loop: true, frames: Array.from({ length: 14 }, (_, i) => {
  const u = i / 14;
  const nf = footCycle(u % 1, 11.5, 9), ff = footCycle((u + 0.5) % 1, 11.5, 9);
  const down = Math.cos(4 * Math.PI * (u - 0.17));
  const sw = Math.sin(2 * Math.PI * (u - 0.1));
  return pose({ hipx: 4, hipy: -16.6 + 1.5 * down, lean: 52, bend: 17, head: -38 + 1.5 * down,
    nfx: nf[0], nfy: nf[1], ffx: ff[0], ffy: ff[1], nfa: nf[1] < -3 ? 38 : 0, ffa: ff[1] < -3 ? 38 : 0,
    fx: 8.5 + 1.2 * sw, fy: 8 - 1.2 * Math.abs(sw), gx: -11 + 2.5 * sw, gy: 3 - 1.5 * Math.abs(sw), blade: 100 + 5 * sw,
    capeTx: -1, capeTy: -0.32 + 0.1 * down, capeAmt: 1, capeWave: 0.5, phase: 4 * Math.PI * u,
    scTx: -1, scTy: -0.15, scAmt: 1, hoodTy: -0.7, lines: 3 });
}) };

// salto: impulso y piernas recogidas, con la daga siempre junto al pecho
anims.jump = { fps: 24, loop: false, frames: [
  pose({ hipy: -16.5, lean: 28, bend: 10, head: -18, hipx: 2, nfx: 6, nfy: 0, ffx: -6, ffy: 0, fx: 8, fy: 8, gx: -9, gy: 8, blade: 100, capeTy: 0.9, capeTx: -0.4, capeAmt: 0.5, scTy: 0.9, scTx: -0.5, scAmt: 0.6 }),
  pose({ hipy: -19.5, lean: 26, bend: 8, head: -16, hipx: 2, nfx: 7, nfy: -5, ffx: -6, ffy: -7, nfa: 20, ffa: 40, fx: 9, fy: 6, gx: -10, gy: 2, blade: 100, capeTy: 1, capeTx: -0.5, capeAmt: 0.75, scTy: 1, scTx: -0.45, scAmt: 0.8 }),
  pose({ hipy: -20, lean: 22, bend: 8, head: -14, hipx: 2, nfx: 8, nfy: -8, ffx: -6, ffy: -10, nfa: 25, ffa: 45, fx: 9, fy: 5, gx: -10, gy: 1, blade: 100, capeTy: 1, capeTx: -0.6, capeAmt: 0.85, scTy: 1, scTx: -0.55, scAmt: 0.85 }),
  pose({ hipy: -20, lean: 20, bend: 6, head: -12, hipx: 2, nfx: 8, nfy: -9, ffx: -5, ffy: -11, nfa: 30, ffa: 50, fx: 9, fy: 6, gx: -9, gy: 2, blade: 100, capeTy: 0.8, capeTx: -0.8, capeAmt: 0.8, scTy: 0.7, scTx: -0.9, scAmt: 0.8 }),
] };

// caida: cuerpo recogido, capa hacia arriba, daga lista al frente
anims.fall = { fps: 16, loop: true, frames: Array.from({ length: 4 }, (_, i) => {
  const t = i / 4, s = Math.sin(t * 2 * Math.PI);
  return pose({ hipy: -20, lean: 14, bend: 6, head: -8, hipx: 1, nfx: 6, nfy: -2 + s, ffx: -5, ffy: -4 - s, nfa: 15, ffa: 25,
    fx: 10, fy: 2 + s, gx: -10, gy: -3 - s, blade: 98 + 3 * s, capeTy: -1, capeTx: -0.35, capeAmt: 1, capeWave: 0.6, phase: t * 2 * Math.PI,
    scTy: -1, scTx: -0.4, scAmt: 1, hoodTy: -1 });
}) };

// ataque: tajo con la daga del reves. El puño sale del pecho, la muñeca hace girar
// la hoja curva y el golpe sube en arco; todo el cuerpo se lanza y gira.
function keyed(keys, t) {
  let a = keys[0], b = keys[keys.length - 1];
  for (let i = 0; i < keys.length - 1; i++) if (t >= keys[i].t && t <= keys[i + 1].t) { a = keys[i]; b = keys[i + 1]; break; }
  const u = a === b ? 0 : ease((t - a.t) / (b.t - a.t));
  const o = {};
  for (const k of Object.keys(a)) if (k !== 't') o[k] = lerp(a[k], b[k], u);
  return o;
}
const ATT = [
  // listo, agazapado
  { t: 0.00, hipx: 2, hipy: -17.4, lean: 24, bend: 8, head: -16, nfx: 8, ffx: -7, nfy: 0, ffy: 0, fx: 9, fy: 8, gx: -8, gy: 8, blade: 95, capeTx: -1, capeTy: 0.3, capeAmt: 0.5, scTx: -1, scAmt: 0.6 },
  // recoge: el cuerpo se carga hacia atras, el puño va atras y abajo con la hoja a la espalda
  { t: 0.07, hipx: -2, hipy: -16.4, lean: 8, bend: -2, head: -2, nfx: 9, ffx: -9, nfy: 0, ffy: 0, fx: -7, fy: 13, gx: 12, gy: 0, blade: 150, capeTx: 0.2, capeTy: 0.5, capeAmt: 0.7, scTx: 0.2, scAmt: 0.7 },
  // arranca: la cadera empuja, el puño cruza por delante
  { t: 0.14, hipx: 5, hipy: -15.8, lean: 34, bend: 12, head: -22, nfx: 13, ffx: -11, nfy: 0, ffy: 0, fx: 11, fy: 7, gx: -10, gy: 6, blade: 80, capeTx: -1, capeTy: 0.1, capeAmt: 0.9, scTx: -1, scAmt: 0.9 },
  // golpe: brazo extendido, la hoja corta de abajo hacia delante
  { t: 0.22, hipx: 9, hipy: -15, lean: 46, bend: 14, head: -30, nfx: 16, ffx: -13, nfy: 0, ffy: 0, fx: 20, fy: -1, gx: -12, gy: 5, blade: 20, capeTx: -1, capeTy: -0.2, capeAmt: 1, scTx: -1, scAmt: 1 },
  // sigue: el arco asciende y el torso se estira
  { t: 0.34, hipx: 11, hipy: -15.4, lean: 52, bend: 12, head: -34, nfx: 17, ffx: -14, nfy: 0, ffy: 0, fx: 19, fy: -11, gx: -11, gy: 6, blade: -30, capeTx: -1, capeTy: -0.4, capeAmt: 1, scTx: -1, scTy: -0.3, scAmt: 1 },
  // la muñeca vuelve la hoja y el puño baja
  { t: 0.50, hipx: 8, hipy: -16.4, lean: 40, bend: 12, head: -26, nfx: 15, ffx: -12, nfy: 0, ffy: 0, fx: 15, fy: -2, gx: -9, gy: 7, blade: 40, capeTx: -1, capeTy: 0, capeAmt: 0.9, scTx: -1, scAmt: 0.9 },
  { t: 0.72, hipx: 5, hipy: -17, lean: 30, bend: 10, head: -20, nfx: 11, ffx: -8, nfy: 0, ffy: 0, fx: 11, fy: 6, gx: -8, gy: 8, blade: 85, capeTx: -1, capeTy: 0.2, capeAmt: 0.7, scTx: -1, scAmt: 0.8 },
  { t: 1.00, hipx: 2, hipy: -17.4, lean: 24, bend: 8, head: -16, nfx: 8, ffx: -7, nfy: 0, ffy: 0, fx: 9, fy: 8, gx: -8, gy: 8, blade: 95, capeTx: -1, capeTy: 0.3, capeAmt: 0.5, scTx: -1, scAmt: 0.6 },
];
const attFrames = Array.from({ length: 12 }, (_, i) => pose(Object.assign(keyed(ATT, i / 11), { phase: i * 0.8 })));
{
  const tipAt = t => figure(pose(keyed(ATT, clamp(t, 0, 1)))).tip;
  for (let i = 0; i < attFrames.length; i++) {
    const t = i / 11;
    if (i >= 2 && i <= 8) {
      const pts = [];
      for (let k = 0; k <= 12; k++) pts.push(tipAt(t - 0.15 + 0.15 * k / 12));
      attFrames[i].trailFrom = pts;
    }
  }
}
anims.attack = { fps: 40, loop: false, frames: attFrames };

// guardia: puño alto delante del pecho con la hoja curva cubriendo el cuerpo
anims.parry = { fps: 20, loop: false, frames: [
  pose({ hipx: 1, hipy: -17.4, lean: 18, bend: 4, head: -10, nfx: 8, ffx: -8, fx: 6, fy: 2, gx: -4, gy: 8, blade: 100 }),
  pose({ hipx: 0, hipy: -17, lean: 12, bend: 2, head: -6, nfx: 9, ffx: -9, fx: 12, fy: -7, gx: -3, gy: 6, blade: 96 }),
  pose({ hipx: -0.5, hipy: -17, lean: 10, bend: 1, head: -4, nfx: 9, ffx: -9, fx: 14, fy: -9, gx: -2, gy: 5, blade: 94 }),
  pose({ hipx: -0.5, hipy: -17, lean: 10, bend: 1, head: -4, nfx: 9, ffx: -9, fx: 14, fy: -9, gx: -2, gy: 5, blade: 94, capeAmt: 0.35 }),
] };

// golpe recibido: el cuerpo se dobla hacia atras y todo se sacude
anims.hit = { fps: 16, loop: false, frames: [
  pose({ hipx: -3, hipy: -18, lean: -14, bend: -10, head: 12, nfx: 6, ffx: -8, fx: -5, fy: -8, gx: 8, gy: -4, blade: 140, capeTx: 1, capeTy: 0.3, capeAmt: 0.9, scTx: 1, scTy: 0.2, scAmt: 0.9 }),
  pose({ hipx: -5, hipy: -17, lean: -22, bend: -12, head: 14, nfx: 5, ffx: -10, fx: -8, fy: -4, gx: 9, gy: -1, blade: 150, capeTx: 0.8, capeTy: 0.5, capeAmt: 0.9, scTx: 0.8, scAmt: 0.9 }),
  pose({ hipx: -4, hipy: -17.5, lean: -10, bend: -6, head: 8, nfx: 5, ffx: -9, fx: -2, fy: 3, gx: 7, gy: 4, blade: 125, capeTx: 0.2, capeTy: 0.8, capeAmt: 0.6 }),
  pose({ hipx: -1, hipy: -18, lean: 8, bend: 0, head: -4, nfx: 6, ffx: -7, fx: 6, fy: 8, gx: -2, gy: 9, blade: 100, capeTx: -0.4, capeTy: 0.6, capeAmt: 0.4 }),
] };

// dash: casi a ras de suelo, hoja hacia atras, imagenes residuales y lineas
anims.dash = { fps: 40, loop: false, frames: [
  pose({ hipx: -1, hipy: -15.5, lean: 30, bend: 12, head: -18, nfx: 9, ffx: -10, fx: -5, fy: 6, gx: 8, gy: 8, blade: 140, capeTx: -1, capeTy: 0.1, capeAmt: 0.8, scAmt: 0.9 }),
  pose({ hipx: 5, hipy: -13, lean: 64, bend: 14, head: -42, nfx: 15, nfy: -2, nfa: 12, ffx: -18, ffy: -6, ffa: 25, fx: -3, fy: 8, gx: 10, gy: 12, blade: 160, capeTx: -1, capeTy: -0.05, capeAmt: 1, capeWave: 0.25, scAmt: 1, scTy: -0.05, ghost: 1, lines: 4, hoodTy: -0.25 }),
  pose({ hipx: 6, hipy: -12.5, lean: 70, bend: 12, head: -48, nfx: 18, nfy: -3, nfa: 12, ffx: -20, ffy: -7, ffa: 25, fx: -5, fy: 9, gx: 12, gy: 13, blade: 165, capeTx: -1, capeTy: -0.02, capeAmt: 1, capeWave: 0.2, scAmt: 1, scTy: -0.02, ghost: 2, lines: 6, phase: 1, hoodTy: -0.2 }),
  pose({ hipx: 6, hipy: -12.5, lean: 70, bend: 12, head: -48, nfx: 19, nfy: -3, nfa: 12, ffx: -21, ffy: -6, ffa: 25, fx: -6, fy: 9, gx: 12, gy: 13, blade: 165, capeTx: -1, capeTy: 0, capeAmt: 1, capeWave: 0.2, scAmt: 1, scTy: 0, ghost: 2, lines: 6, phase: 2, hoodTy: -0.2 }),
  pose({ hipx: 5, hipy: -13.5, lean: 58, bend: 12, head: -38, nfx: 15, nfy: -2, ffx: -17, ffy: -4, ffa: 20, fx: -1, fy: 8, gx: 9, gy: 11, blade: 150, capeTx: -1, capeTy: 0.1, capeAmt: 1, scAmt: 1, ghost: 1, lines: 3, phase: 3 }),
  pose({ hipx: 3, hipy: -17, lean: 32, bend: 10, head: -20, nfx: 10, ffx: -8, fx: 7, fy: 9, gx: -4, gy: 9, blade: 105, capeTx: -1, capeTy: 0.3, capeAmt: 0.8, scAmt: 0.8 }),
] };

// ---------- salida ----------
const order = ['idle', 'run', 'jump', 'fall', 'attack', 'parry', 'hit', 'dash'];
let out = [
  '# El caminante, un asesino de la memoria: capucha, bufanda de luz azul y una',
  '# espada que empuña del reves (la hoja cuelga por debajo del puño). Cada',
  '# fotograma es un lienzo completo de 112x64 con los pies en la fila de abajo.',
  '# Lo genera el esqueleto de tools/rig_caminante.js (columna curvada, piernas y',
  '# brazos con cinematica inversa, capa y bufanda con inercia); para cambiar el',
  '# movimiento se edita el esqueleto y se regenera, no estos fotogramas a mano.',
  '# Leyenda: ver art/palette.txt. El punto (.) es transparente.', '',
  'sheet 112x64', 'out res://game/player/player_sheet.png', ''].join(NL) + NL;
const info = {};
let animText = '';
for (const name of order) {
  const a = anims[name];
  info[name] = [a.frames.length, a.fps, a.loop];
  animText += 'anim ' + name + NL;
  a.frames.forEach((p, i) => {
    const r = render(p);
    const part = name + '_' + i;
    out += 'part ' + part + NL + r.g.map(row => row.join('')).join(NL) + NL + NL;
    animText += 'frame ' + part + NL;
  });
  animText += NL;
}
out += animText;
fs.writeFileSync(process.argv[2] || 'art/source/player.sprite', out);
console.log(JSON.stringify(info));
