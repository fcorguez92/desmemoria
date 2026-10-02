// Biblioteca del esqueleto que usan tools/rig_caminante.js y tools/rig_enemigos.js:
// una figura lateral (cadera, columna curvada, cabeza, brazos y piernas con
// cinematica inversa, capa con inercia y un arma) que se rasteriza a pixel art.
// Cada personaje se define con un "estilo" (proporciones, colores, cabeza, arma)
// y con poses; la biblioteca solo dibuja.
const fs = require('fs');
const NL = String.fromCharCode(10);

// lienzo y punto de los pies (suelo); lo fija setCanvas()
let W = 112, H = 64, OX = 56, OY = 64;
function setCanvas(w, h) { W = w; H = h; OX = Math.floor(w / 2); OY = h; }
const canvasSize = () => ({ W, H, OX, OY });

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
const hash2 = (a, b) => { const x = Math.sin(a * 127.1 + b * 311.7) * 43758.5453; return x - Math.floor(x); };
function chainColor(pts, rs, hi, mid, lo, noise = 0) {
  return (px, py) => {
    let best = 1e9, bn = [0, 0], br = 1, bi = 0, bt = 0;
    for (let i = 0; i < pts.length - 1; i++) {
      const a = pts[i], b = pts[i + 1];
      const ab = sub(b, a), l2 = ab[0] * ab[0] + ab[1] * ab[1] || 1e-6;
      const t = clamp(((px - a[0]) * ab[0] + (py - a[1]) * ab[1]) / l2, 0, 1);
      const cx = a[0] + ab[0] * t, cy = a[1] + ab[1] * t;
      const d = Math.hypot(px - cx, py - cy);
      if (d < best) { best = d; bn = [px - cx, py - cy]; br = lerp(rs[i], rs[i + 1], t); bi = i; bt = t; }
    }
    const s = (bn[0] * LIGHT[0] + bn[1] * LIGHT[1]) / (br || 1);
    let col = s > 0.35 ? hi : (s < -0.45 ? lo : mid);
    if (noise > 0 && col !== lo && hash2(bi * 5 + Math.floor(bt * 6), Math.floor(s * 3) + 7) < noise) col = col === hi ? mid : lo;
    return col;
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

// ---------- estilos y poses ----------
// Estilo por defecto: el Caminante.
const HERO = {
  legLen: 9.6, waistLen: 7, chestLen: 6.5, headDist: 4.8, headR: 5.6,
  torsoR: [4.4, 4.9, 5.4, 2.6], armLen: 6.8, farArmLen: 6.6,
  armR: [2.9, 2.4, 2.1], farArmR: [2.6, 2.1, 1.9],
  nearLegR: [3.5, 3.0, 2.3, 1.7], farLegR: [3.5, 2.8, 2.3, 1.7],
  torsoCol: ['3', '2', '2'], nearLegCol: ['3', '2', '1'], farLegCol: ['2', '1', '1'],
  nearArmCol: ['3', '2', 'a'], farArmCol: ['2', '1', '1'], handCol: ['3', '2'],
  cape: { on: true, base: '2', fold: '1', edge: '3', segs: 5, seg: 6.2, w0: 2.4, wk: 0.95, rag: 0 },
  scarf: true, belt: true, pouch: true,
  head: 'hood',
  hood: { main: '2', hi: '3', face: '1', mask: ['g', 'f'], eye: ['h', 'g'], trim: ['c', 'b'] },
  weapon: 'dagger', weaponLen: 24,
  shoulderPad: false, strap: null, waistBand: null,
};
function makeStyle(over) {
  const s = Object.assign({}, HERO, over);
  s.cape = Object.assign({}, HERO.cape, (over && over.cape) || {});
  s.hood = Object.assign({}, HERO.hood, (over && over.hood) || {});
  return s;
}

const BASE = {
  hipx: 0, hipy: -18, lean: 14, bend: 4, head: -8,
  nfx: 4, nfy: 0, nfa: 0, ffx: -4, ffy: 0, ffa: 0,
  fx: 9, fy: 9, gx: -5, gy: 9, blade: 95, curve: -48,
  capeTx: -1, capeTy: 0.15, capeAmt: 0.25, capeWave: 0.35,
  scTx: -1, scTy: 0.1, scAmt: 0.5, hoodTy: -0.35,
  phase: 0, ghost: 0, lines: 0, trailFrom: null,
};
function pose(o) { return Object.assign({}, BASE, o); }

// ---------- armas ----------
function drawWeapon(c, S, p, fist) {
  const bd = [Math.cos(rad(p.blade)), Math.sin(rad(p.blade))];
  const bn = [-bd[1], bd[0]];
  const kind = p.noWeapon ? 'none' : S.weapon;
  let tipPt;
  if (kind === 'dagger') {
    // linea central de la hoja: nace del puño y se curva hacia delante (el filo)
    const BL = S.weaponLen, N = 18;
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
    tipPt = cl[N];
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
  } else if (kind === 'knife') {
    // cuchillo pesado y oxidado: hoja recta y ancha
    const L = S.weaponLen;
    const a = add(fist, mul(bd, 1.5)); tipPt = add(fist, mul(bd, L));
    const poly = [add(a, mul(bn, 2.6)), add(add(a, mul(bd, L * 0.75)), mul(bn, 2.4)), add(tipPt, mul(bn, 0.2)), add(add(a, mul(bd, L * 0.75)), mul(bn, -1.6)), add(a, mul(bn, -2.2))];
    c.shape(polyTest(poly), (px, py) => {
      const sd = (px - a[0]) * bn[0] + (py - a[1]) * bn[1];
      const al = (px - a[0]) * bd[0] + (py - a[1]) * bd[1];
      if (al > L - 3) return '4';
      if (((Math.floor(px) * 7 + Math.floor(py) * 3) % 5) === 0 && al > 3) return 'b';
      return sd > 0.7 ? '4' : (sd < -0.6 ? '2' : '3');
    }, bbox(poly), true);
    c.line(add(fist, mul(bn, 3)), add(fist, mul(bn, -3)), 'a');
  } else if (kind === 'spear') {
    const back = 10, L = S.weaponLen;
    const sA = add(fist, mul(bd, -back)), sB = add(fist, mul(bd, L - 8));
    c.shape(chainTest([sA, sB], [1.3, 1.1]), chainColor([sA, sB], [1.3, 1.1], 'c', 'b', 'a'), bbox([sA, sB]), true);
    // punta en hoja
    const hb = add(fist, mul(bd, L - 9)); tipPt = add(fist, mul(bd, L + 1));
    const leaf = [add(hb, mul(bn, 0.6)), add(add(hb, mul(bd, 4)), mul(bn, 2.7)), tipPt, add(add(hb, mul(bd, 4)), mul(bn, -2.7)), add(hb, mul(bn, -0.6))];
    c.shape(polyTest(leaf), (px, py) => {
      const sd = (px - hb[0]) * bn[0] + (py - hb[1]) * bn[1];
      const al = (px - hb[0]) * bd[0] + (py - hb[1]) * bd[1];
      return al > 8 ? 'h' : (sd > 0.5 ? '4' : (sd < -0.5 ? '2' : '3'));
    }, bbox(leaf), true);
    // trapo rojo atado bajo la punta
    const tb = add(hb, mul(bd, -1.2));
    const rag = trailChain(tb, 3, 3.2, [0, 1], [-bd[0] * 0.2 - 0.6, 0.2], 0.6, 0.6, p.phase + 2);
    c.shape(chainTest(rag, [1.4, 1.2, 0.9, 0.6]), chainColor(rag, [1.4, 1.2, 0.9, 0.6], 't', 's', 'r'), bbox(rag), false);
  } else if (kind === 'maul') {
    const back = 6, L = S.weaponLen;
    const sA = add(fist, mul(bd, -back)), sB = add(fist, mul(bd, L));
    c.shape(chainTest([sA, sB], [1.7, 1.6]), chainColor([sA, sB], [1.7, 1.6], 'c', 'b', 'a'), bbox([sA, sB]), true);
    // cabeza: bloque de piedra con bandas de hierro
    const hc = add(fist, mul(bd, L + 4)); tipPt = hc;
    const hl = 6.5, hw2 = 8;
    const blk = [add(add(hc, mul(bd, -hl)), mul(bn, hw2)), add(add(hc, mul(bd, hl)), mul(bn, hw2)), add(add(hc, mul(bd, hl)), mul(bn, -hw2)), add(add(hc, mul(bd, -hl)), mul(bn, -hw2))];
    c.shape(polyTest(blk), (px, py) => {
      const al = (px - hc[0]) * bd[0] + (py - hc[1]) * bd[1];
      const sd = (px - hc[0]) * bn[0] + (py - hc[1]) * bn[1];
      if (Math.abs(al) > hl - 1.5 && Math.abs(al) <= hl) return '1';
      if (Math.abs(al) <= 1.2) return '1';
      const s = ((px - hc[0]) * LIGHT[0] + (py - hc[1]) * LIGHT[1]) / 8;
      return s > 0.3 ? '4' : (s < -0.35 ? '2' : '3');
    }, bbox(blk), true);
    // pinchos oxidados
    for (const sgn of [1, -1]) c.set(Math.floor(hc[0] + bn[0] * (hw2 + 1) * sgn), Math.floor(hc[1] + bn[1] * (hw2 + 1) * sgn), 'b');
  } else if (kind === 'claws') {
    tipPt = add(fist, mul(bd, S.weaponLen));
    for (const da of [-22, 0, 22]) {
      const d = [Math.cos(rad(p.blade + da)), Math.sin(rad(p.blade + da))];
      const t = add(fist, mul(d, S.weaponLen));
      const n = [-d[1], d[0]];
      const poly = [add(fist, mul(n, 1.1)), t, add(fist, mul(n, -1.1))];
      c.shape(polyTest(poly), (px, py) => {
        const al = (px - fist[0]) * d[0] + (py - fist[1]) * d[1];
        return al > S.weaponLen - 3 ? 'u' : '4';
      }, bbox(poly), true);
    }
  } else if (kind === 'shard') {
    const L = S.weaponLen; tipPt = add(fist, mul(bd, L));
    const poly = [add(fist, mul(bn, 1.5)), tipPt, add(fist, mul(bn, -1.5))];
    c.shape(polyTest(poly), (px, py) => {
      const al = (px - fist[0]) * bd[0] + (py - fist[1]) * bd[1];
      return al > L - 3 ? 'u' : (((px - fist[0]) * bn[0] + (py - fist[1]) * bn[1]) > 0 ? '4' : '3');
    }, bbox(poly), true);
  } else {
    tipPt = fist;
  }
  // puño
  c.shape((px, py) => Math.hypot(px - fist[0], py - fist[1]) <= 2.4, (px, py) => ((px - fist[0]) * LIGHT[0] + (py - fist[1]) * LIGHT[1]) > 0 ? S.handCol[0] : S.handCol[1], [fist[0] - 4, fist[1] - 4, fist[0] + 4, fist[1] + 4], true);
  return { tip: tipPt, mid: add(fist, mul(bd, 11)) };
}

// vendas: franjas de tela alrededor de un tramo de miembro
function wrap(c, S, seg, rr) {
  if (!S.wraps) return;
  const a = seg[0], b = seg[1], d = norm(sub(b, a)), n = [-d[1], d[0]];
  for (const t of [0.35, 0.62, 0.88]) {
    const q = add(mul(a, 1 - t), mul(b, t)), r = lerp(rr[0], rr[1], t) * 0.95;
    c.line(add(q, mul(n, r)), add(q, mul(n, -r)), S.wraps[0]);
    c.line(add(add(q, mul(n, r)), mul(d, 1)), add(add(q, mul(n, -r)), mul(d, 1)), S.wraps[1]);
  }
}

// ---------- la figura ----------
function figure(p, S) {
  S = S || HERO;
  const c = new Canvas();
  const O = [OX, OY];
  const hip = add(O, [p.hipx, p.hipy]);
  const waist = add(hip, mul(dirA(p.lean), S.waistLen));
  const chest = add(waist, mul(dirA(p.lean + p.bend), S.chestLen));
  const neck = add(chest, mul(dirA(p.lean + p.bend + p.head * 0.5), 3));
  const headC = add(neck, mul(dirA(p.lean + p.bend + p.head), S.headDist));
  const shoulder = add(chest, mul(dirA(p.lean + p.bend + 90), -0.5));
  const kneeFwd = (a, b) => (a[0] > b[0] ? a : b);

  // ---- capa o harapos (detras de todo)
  const K = S.cape;
  if (K.on) {
    const capeRoot = add(neck, [-1.5, 2]);
    const capeSpine = trailChain(capeRoot, K.segs, K.seg, [0, 1], [p.capeTx, p.capeTy], p.capeAmt, p.capeWave, p.phase);
    const half = i => K.w0 + i * K.wk;
    const left = [], right = [];
    for (let i = 0; i < capeSpine.length; i++) {
      const a = capeSpine[Math.max(0, i - 1)], b = capeSpine[Math.min(capeSpine.length - 1, i + 1)];
      const d = norm(sub(b, a)), n = [-d[1], d[0]];
      left.push(add(capeSpine[i], mul(n, half(i)))); right.push(add(capeSpine[i], mul(n, -half(i))));
    }
    const endD = norm(sub(capeSpine[capeSpine.length - 1], capeSpine[capeSpine.length - 2]));
    const tip = add(capeSpine[capeSpine.length - 1], mul(endD, 3));
    let capePoly;
    if (K.rag > 0) {
      // borde inferior desgarrado: dientes de sierra
      const ends = [];
      const lEnd = left[left.length - 1], rEnd = right[0];
      const nTeeth = K.rag;
      for (let i = 0; i <= nTeeth; i++) {
        const t = i / nTeeth;
        const base = add(mul(lEnd, 1 - t), mul(rEnd, t));
        ends.push(add(base, mul(endD, (i % 2 === 0 ? 4.5 : 1) + (i % 3))));
      }
      capePoly = [...left.slice(0, -1), ...ends, ...right.slice(1).reverse()];
    } else {
      capePoly = [...left, tip, ...right.reverse()];
    }
    c.shape(polyTest(capePoly), () => K.base, bbox(capePoly));
    // pliegues a lo largo de la capa y borde claro del lado de la luz
    for (const f of [0.38, -0.2]) {
      for (let i = 1; i < capeSpine.length - 1; i++) {
        const a = capeSpine[i], b = capeSpine[i + 1];
        const d = norm(sub(b, a)), n = [-d[1], d[0]];
        c.line(add(a, mul(n, half(i) * f)), add(b, mul(n, half(i + 1) * f)), f > 0 ? K.fold : K.edge);
      }
    }
    for (let i = 0; i < left.length - 1; i++) c.line(left[i], left[i + 1], K.edge);
  }

  // estela del tajo
  if (p.trailFrom) {
    const tf = p.trailFrom;
    const cols = S.trailCols || ['f', 'g', 'h'];
    for (let i = 0; i < tf.length - 1; i++) {
      const k = i / Math.max(1, tf.length - 2);
      const col = k > 0.7 ? cols[2] : (k > 0.4 ? cols[1] : cols[0]);
      c.line(tf[i], tf[i + 1], col);
      if (k > 0.4) c.line(add(tf[i], [0, 1]), add(tf[i + 1], [0, 1]), col);
    }
  }

  // ---- pierna lejana
  const legPart = (foot, ang, col, rr) => {
    const ankle = add(O, [foot[0], foot[1] - 2.6]);
    const s = ik(hip, ankle, S.legLen, S.legLen, kneeFwd);
    const toe = add(ankle, [4.2 * Math.cos(rad(ang)), 1.7 + 4.2 * Math.sin(rad(ang))]);
    const pts = [hip, s.joint, s.end, toe];
    c.shape(chainTest(pts, rr), chainColor(pts, rr, col[0], col[1], col[2], S.noise || 0), bbox(pts));
    wrap(c, S, [s.joint, s.end], [rr[1], rr[2]]);
    return s;
  };
  legPart([p.ffx, p.ffy], p.ffa, S.farLegCol, S.farLegR);

  // ---- brazo lejano
  {
    const T = add(shoulder, [p.gx, p.gy]);
    const s = ik(shoulder, T, S.farArmLen, S.farArmLen, (a, b) => (a[1] > b[1] ? a : b));
    const pts = [shoulder, s.joint, s.end];
    c.shape(chainTest(pts, S.farArmR), chainColor(pts, S.farArmR, S.farArmCol[0], S.farArmCol[1], S.farArmCol[2], S.noise || 0), bbox(pts));
    wrap(c, S, [s.joint, s.end], [S.farArmR[1], S.farArmR[2]]);
    if (S.farHand === 'claws') {
      for (const da of [-24, 0, 24]) {
        const a = rad((p.gAng === undefined ? 20 : p.gAng) + da);
        const t = add(s.end, [Math.cos(a) * 6, Math.sin(a) * 6]);
        c.line(s.end, t, '4'); c.set(Math.floor(t[0]), Math.floor(t[1]), 'u');
      }
    }
  }

  // ---- torso (curvado: cadera, cintura, pecho, cuello)
  const tp = [hip, waist, chest, neck], tr = S.torsoR;
  c.shape(chainTest(tp, tr), chainColor(tp, tr, S.torsoCol[0], S.torsoCol[1], S.torsoCol[2], S.noise || 0), bbox(tp));
  if (S.ribs) {
    // costillas marcadas bajo la piel
    for (let k = 0; k < 3; k++) {
      const q = lerp(0.55, 0.9, k / 2);
      const base = add(mul(waist, 1 - q), mul(chest, q));
      const nrm = dirA(p.lean + p.bend + 90);
      c.line(add(base, mul(nrm, 1.0)), add(base, mul(nrm, tr[1] - 0.8)), S.ribs);
    }
  }
  const belt = add(hip, mul(dirA(p.lean), 2.2));
  if (S.belt) {
    c.line(add(belt, [-4, 0]), add(belt, [4, 0]), 'b');
    c.line(add(belt, [-4, -1]), add(belt, [4, -1]), 'a');
    c.line(add(waist, mul(dirA(p.lean + p.bend - 90), 4)), add(belt, [3, 0]), 'a');
  }
  if (S.waistBand) {
    // faja de trapo alrededor de la cintura
    const wb = S.waistBand;
    const wa = add(hip, mul(dirA(p.lean), 0.5)), wc = add(waist, mul(dirA(p.lean + p.bend * 0.5), S.tunic || 1));
    c.shape(chainTest([wa, wc], [tr[0] + 0.8, tr[1] + 0.8]), chainColor([wa, wc], [tr[0] + 0.8, tr[1] + 0.8], wb[0], wb[1], wb[2]), bbox([wa, wc]), true);
  }
  if (S.strap) {
    // tira cruzada sobre el pecho
    c.line(add(chest, mul(dirA(p.lean + p.bend - 90), tr[2] - 0.5)), add(hip, mul(dirA(p.lean + 90), tr[0] - 1)), S.strap);
    c.line(add(chest, mul(dirA(p.lean + p.bend - 90), tr[2] - 1.5)), add(hip, mul(dirA(p.lean + 90), tr[0] - 2)), S.strap);
  }
  if (S.pouch) {
    const pouch = add(belt, [3.4, 2.2]);
    c.shape((px, py) => Math.abs(px - pouch[0]) <= 1.9 && Math.abs(py - pouch[1]) <= 1.7, (px, py) => (py < pouch[1] - 0.6 ? 'c' : 'b'), [pouch[0] - 3, pouch[1] - 3, pouch[0] + 3, pouch[1] + 3], true);
  }

  // ---- pierna cercana
  legPart([p.nfx, p.nfy], p.nfa, S.nearLegCol, S.nearLegR);

  // hombrera de hierro
  if (S.shoulderPad) {
    const r = S.shoulderPad;
    c.shape((px, py) => Math.hypot(px - shoulder[0], py - shoulder[1]) <= r, (px, py) => {
      const s = ((px - shoulder[0]) * LIGHT[0] + (py - shoulder[1]) * LIGHT[1]) / r;
      return s > 0.35 ? '4' : (s < -0.4 ? '2' : '3');
    }, [shoulder[0] - r - 2, shoulder[1] - r - 2, shoulder[0] + r + 2, shoulder[1] + r + 2], true);
    c.set(Math.floor(shoulder[0]), Math.floor(shoulder[1]), 'b');
  }

  // ---- bufanda (azul)
  if (S.scarf) {
    const scarfPts = [add(neck, [-2.2, 0.4]), add(neck, [2, 0.8])];
    c.shape(chainTest(scarfPts, [1.9, 1.9]), () => 'g', bbox(scarfPts));
    const sc = trailChain(add(neck, [-2, 0.5]), 4, 4.6, [0, 1], [p.scTx, p.scTy], p.scAmt, 0.55, p.phase + 1.3);
    const sr = [1.7, 1.5, 1.2, 1.0, 0.8];
    c.shape(chainTest(sc, sr), chainColor(sc, sr, 'h', 'g', 'f'), bbox(sc));
  }

  // ---- cabeza
  const HR = S.headR;
  if (S.head === 'hood') {
    const Hd = S.hood;
    const hoodTip = add(headC, mul(norm([-1, p.hoodTy]), 9.5));
    const hoodBack = [add(headC, [-1, -5.2]), hoodTip, add(headC, [-4.5, 3.5])];
    c.shape(polyTest(hoodBack), () => Hd.main, bbox(hoodBack), true);
    c.shape((px, py) => Math.hypot(px - headC[0], py - headC[1]) <= HR, (px, py) => {
      const s = ((px - headC[0]) * LIGHT[0] + (py - headC[1]) * LIGHT[1]) / HR;
      return s > 0.45 ? Hd.hi : Hd.main;
    }, [headC[0] - 7, headC[1] - 7, headC[0] + 7, headC[1] + 7]);
    const face = add(headC, [2.3, 0.6]);
    const inFace = (px, py) => ((px - face[0]) / 3.2) ** 2 + ((py - face[1]) / 3.9) ** 2 <= 1 && Math.hypot(px - headC[0], py - headC[1]) <= 5.1;
    c.shape(inFace, () => Hd.face, [face[0] - 5, face[1] - 5, face[0] + 5, face[1] + 5], false);
    if (Hd.mask) c.shape((px, py) => inFace(px, py) && py > face[1] + 0.9, (px, py) => (py < face[1] + 1.9 ? Hd.mask[0] : Hd.mask[1]), [face[0] - 5, face[1], face[0] + 5, face[1] + 5], false);
    c.set(Math.floor(face[0] + 1.2), Math.floor(face[1] - 0.3), Hd.eye[0]);
    c.set(Math.floor(face[0] + 0.2), Math.floor(face[1] - 0.3), Hd.eye[1]);
    if (Hd.trim) for (let a = -110, k = 0; a <= 40; a += 13, k++) {
      c.set(Math.floor(headC[0] + Math.cos(rad(a)) * 5.1), Math.floor(headC[1] + Math.sin(rad(a)) * 5.1), k % 2 ? Hd.trim[0] : Hd.trim[1]);
    }
  } else {
    // cabeza desnuda (pálida y sin rostro) o con yelmo
    const inHead = (px, py) => Math.hypot(px - headC[0], py - headC[1]) <= HR;
    c.shape(inHead, (px, py) => {
      const s = ((px - headC[0]) * LIGHT[0] + (py - headC[1]) * LIGHT[1]) / HR;
      return s > 0.4 ? '4' : (s < -0.5 ? '2' : '3');
    }, [headC[0] - HR - 2, headC[1] - HR - 2, headC[0] + HR + 2, headC[1] + HR + 2]);
    const face = add(headC, [HR * 0.38, HR * 0.1]);
    if (S.head === 'bare') {
      // el plano del rostro, liso y un poco mas oscuro: sin rasgos
      c.shape((px, py) => ((px - face[0]) / (HR * 0.5)) ** 2 + ((py - face[1]) / (HR * 0.7)) ** 2 <= 1 && inHead(px, py), () => '3', [face[0] - 6, face[1] - 7, face[0] + 6, face[1] + 7], false);
      // ojo hueco, grieta y una chispa roja que marca hacia donde mira
      c.set(Math.floor(face[0] + 0.5), Math.floor(face[1] - 1.2), '1');
      c.set(Math.floor(face[0] + 0.5), Math.floor(face[1] - 0.2), '1');
      c.set(Math.floor(face[0] + 1.5), Math.floor(face[1] - 1.2), '1');
      c.set(Math.floor(face[0] + 1.5), Math.floor(face[1] - 0.2), '1');
      if (S.eyeGlint) c.set(Math.floor(face[0] + 1.5), Math.floor(face[1] - 0.7), S.eyeGlint);
      c.line([headC[0] - 1, headC[1] - HR + 0.5], [headC[0] + 0.5, headC[1] - 1.5], '2');
    } else if (S.head === 'helm') {
      // yelmo de hierro: casquete, ala, rendija roja y penacho de trapo
      c.shape((px, py) => inHead(px, py) && py < headC[1] + 1.6, (px, py) => {
        const s = ((px - headC[0]) * LIGHT[0] + (py - headC[1]) * LIGHT[1]) / HR;
        return s > 0.35 ? '4' : (s < -0.4 ? '2' : '3');
      }, [headC[0] - HR - 2, headC[1] - HR - 2, headC[0] + HR + 2, headC[1] + 3], false);
      c.line([headC[0] - HR + 0.5, headC[1] + 1.6], [headC[0] + HR - 0.5, headC[1] + 1.6], '1');
      c.line([headC[0] + 0.5, headC[1] + 2.6], [headC[0] + HR - 0.8, headC[1] + 2.6], '1');
      c.set(Math.floor(headC[0] + HR - 2), Math.floor(headC[1] + 2.6), 'u');
      c.set(Math.floor(headC[0] + HR - 3), Math.floor(headC[1] + 2.6), 't');
      const plume = trailChain(add(headC, [-1.5, -HR + 0.5]), 3, 3.4, [0, 1], [-1, -0.2], 0.7, 0.5, p.phase + 0.7);
      c.shape(chainTest(plume, [1.5, 1.3, 1.0, 0.7]), chainColor(plume, [1.5, 1.3, 1.0, 0.7], 't', 's', 'r'), bbox(plume), true);
    }
  }

  // ---- brazo cercano + arma
  const T = add(shoulder, [p.fx, p.fy]);
  const arm = ik(shoulder, T, S.armLen, S.armLen, (a, b) => (a[1] > b[1] ? a : b));
  const apts = [shoulder, arm.joint, arm.end];
  c.shape(chainTest(apts, S.armR), chainColor(apts, S.armR, S.nearArmCol[0], S.nearArmCol[1], S.nearArmCol[2], S.noise || 0), bbox(apts));
  wrap(c, S, [arm.joint, arm.end], [S.armR[1], S.armR[2]]);
  const fist = arm.end;
  const w = drawWeapon(c, S, p, fist);

  c.tip = w.tip; c.mid = w.mid; c.fist = fist; c.head = headC;
  return c;
}

function render(p, S) {
  S = S || HERO;
  const out = new Canvas();
  // imagenes residuales (dash)
  for (let k = p.ghost; k >= 1; k--) {
    const gp = Object.assign({}, p, { ghost: 0, lines: 0, trailFrom: null, hipx: p.hipx - k * 11, nfx: p.nfx - k * 11, ffx: p.ffx - k * 11 });
    const gc = figure(Object.assign(gp, { phase: p.phase }), S);
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
  const f = figure(p, S);
  for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) if (f.g[y][x] !== '.') out.set(x, y, f.g[y][x]);
  out.tip = f.tip; out.mid = f.mid; out.fist = f.fist; out.head = f.head;
  if (p.post) p.post(out, f);
  return out;
}

function keyed(keys, t) {
  t = clamp(t, keys[0].t, keys[keys.length - 1].t);
  let a = keys[0], b = keys[keys.length - 1];
  for (let i = 0; i < keys.length - 1; i++) if (t >= keys[i].t && t <= keys[i + 1].t) { a = keys[i]; b = keys[i + 1]; break; }
  const u = a === b ? 0 : ease((t - a.t) / (b.t - a.t));
  const o = {};
  for (const k of Object.keys(a)) if (k !== "t") o[k] = lerp(a[k], b[k] === undefined ? a[k] : b[k], u);
  return o;
}

// escribe un .sprite: cada fotograma es un lienzo completo
function writeSprite(file, header, outPath, order, anims, S) {
  let out = header.join(NL) + NL + NL + 'sheet ' + W + 'x' + H + NL + 'out ' + outPath + NL + NL;
  const info = {};
  let animText = '';
  for (const name of order) {
    const a = anims[name];
    info[name] = [a.frames.length, a.fps, a.loop];
    animText += 'anim ' + name + NL;
    a.frames.forEach((p, i) => {
      const r = render(p, S);
      const part = name + '_' + i;
      out += 'part ' + part + NL + r.g.map(row => row.join('')).join(NL) + NL + NL;
      animText += 'frame ' + part + NL;
    });
    animText += NL;
  }
  out += animText;
  fs.writeFileSync(file, out);
  return info;
}

module.exports = { setCanvas, canvasSize, rad, dirA, add, sub, mul, len, norm, lerp, ease, clamp, ik, Canvas,
  chainTest, chainColor, polyTest, bbox, trailChain, HERO, makeStyle, BASE, pose, figure, render, keyed, writeSprite };
