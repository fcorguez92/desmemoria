// Primitivas de rasterizado a pixel art, compartidas por los generadores de arte
// (tools/rig_*.js y futuros): lienzo de caracteres, formas rellenas con contorno,
// sombreado por cadena de segmentos, ruido determinista, cadenas que arrastran y
// escritura de .sprite. No sabe nada de personajes: eso vive en tools/rig_lib.js.
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

const bbox = (pts, pad = 3) => [Math.min(...pts.map(p => p[0])) - pad, Math.min(...pts.map(p => p[1])) - pad, Math.max(...pts.map(p => p[0])) + pad, Math.max(...pts.map(p => p[1])) + pad];

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

// escribe un .sprite: cada fotograma es un lienzo completo; renderFn(pose) devuelve un Canvas
function writeSprite(file, header, outPath, order, anims, renderFn) {
  let out = header.join(NL) + NL + NL + 'sheet ' + W + 'x' + H + NL + 'out ' + outPath + NL + NL;
  const info = {};
  let animText = '';
  for (const name of order) {
    const a = anims[name];
    info[name] = [a.frames.length, a.fps, a.loop];
    animText += 'anim ' + name + NL;
    a.frames.forEach((p, i) => {
      const r = renderFn(p);
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
  chainTest, chainColor, polyTest, bbox, trailChain, hash2, LIGHT, writeSprite };
