// Generador del jefe "El Centinela Hueco" (ver tools/rig_lib.js y tools/rig_enemigos.js):
// la armadura vacia de un Custodio de la Orden del Archivo, enorme, de hierro oscuro
// y oxidado, con grietas de brillo ambar y un mazo de piedra y hierro. Cuando se
// agrieta (estado "stagger") dentro se ve una figura palida y encorvada que asoma
// por el pecho y el cuello: el punto debil.
// Usa el mismo esqueleto que el coloso, ampliado (K), y dibuja encima la armadura
// (hombreras, faldon, rodillera, yelmo cerrado, grietas) con la funcion `deco`.
// Todo se dibuja a resolucion nativa: M es el factor de escala del dibujo (las
// longitudes, radios y desplazamientos se multiplican; los pixeles siguen siendo de 1 px).
// Uso: node tools/rig_centinela.js   (escribe art/source/centinela.sprite)
const lib = require('./rig_lib');
const { lerp, ease, pose, keyed, makeStyle, add, mul, sub, norm, dirA, rad, Canvas, polyTest, chainTest, chainColor } = lib;

const M = 2; // escala del dibujo (1 = la version de 192x128 con cuerpo de 56x88)
const W = 192 * M, H = 128 * M;
lib.setCanvas(W, H);
const { OX, OY } = lib.canvasSize();

const K = 1.45; // escala respecto al coloso
const POS = ['hipx', 'hipy', 'nfx', 'nfy', 'ffx', 'ffy', 'fx', 'fy', 'gx', 'gy'];
const sc = (o) => { const r = Object.assign({}, o); for (const k of POS) if (r[k] !== undefined) r[k] *= K * M; return r; };
const frames = (n, fn) => Array.from({ length: n }, (_, i) => fn(i / n, i));
const seq = (keys, n, extra) => Array.from({ length: n }, (_, i) => pose(Object.assign(
  { glow: 0.3, open: 0 }, keyed(keys.map(sc), n === 1 ? 0 : i / (n - 1)), extra || {}, { phase: i * 0.9 })));
function footCycle(s, A, L) {
  if (s < 0.4) { const k = s / 0.4; return [lerp(-A, A * 1.2, ease(k)), -L * Math.sin(Math.PI * k)]; }
  const k = (s - 0.4) / 0.6; return [lerp(A * 1.2, -A, k), 0];
}
const sm = (a) => a.map((v) => v * M);

const S = makeStyle({
  z: M,
  head: 'none', headR: 6.4 * M, headDist: 10 * M, legLen: 17.5 * M, waistLen: 12.5 * M, chestLen: 12.5 * M,
  torsoR: sm([9.5, 10.5, 12, 5]), armLen: 13.4 * M, farArmLen: 13 * M, armR: sm([6.4, 5.6, 5]), farArmR: sm([5.8, 5, 4.5]),
  nearLegR: sm([7.6, 6.4, 5.4, 3.8]), farLegR: sm([7.2, 6.0, 5.0, 3.6]),
  torsoCol: ['3', '2', 'a'], nearLegCol: ['3', '2', 'a'], farLegCol: ['2', '1', '1'],
  nearArmCol: ['3', '2', 'a'], farArmCol: ['2', '1', '1'], handCol: ['3', '2'],
  cape: { on: true, base: 'a', fold: '1', edge: 'b', segs: 4, seg: 9 * M, w0: 6 * M, wk: 1.4 * M, rag: 8 },
  scarf: false, belt: false, pouch: false, noise: 0.12, tunic: 6, shoulderPad: 0,
  weapon: 'maul', weaponLen: 33 * M, maulShaft: sm([2.7, 2.5]), shaftCol: ['3', '2', 'a'], maulHead: sm([9.5, 12]),
});

// ---------- decoracion de la armadura ----------
const LIGHT = norm([-0.55, -0.85]);
const hash2 = (a, b) => { const x = Math.sin(a * 127.1 + b * 311.7) * 43758.5453; return x - Math.floor(x); };
// todas estas formas reciben medidas "de diseno" (1x) y las ampliamos aqui
const shade = (cx, cy, r, hi = '4', mid = '3', lo = '2') => (px, py) => {
  const s = ((px - cx) * LIGHT[0] + (py - cy) * LIGHT[1]) / (r * M);
  return s > 0.4 ? hi : (s < -0.35 ? lo : mid);
};
const ell = (c, rx, ry) => (px, py) => ((px - c[0]) / (rx * M)) ** 2 + ((py - c[1]) / (ry * M)) ** 2 <= 1;
const pale = (c, r) => (px, py) => { const s = ((px - c[0]) * LIGHT[0] + (py - c[1]) * LIGHT[1]) / (r * M); return s > 0.62 ? 'h' : (s > -0.25 ? '4' : '3'); };
const box = (c, r) => [c[0] - r * M, c[1] - r * M, c[0] + r * M, c[1] + r * M];
const at = (o, a, b) => [o[0] + a * M, o[1] + b * M];      // desplazamiento en pixeles (x, y) de diseno
const alongU = (o, u, n, a, b) => add(o, add(mul(u, a * M), mul(n, b * M))); // a lo largo del cuerpo (u) y hacia delante (n)
// bloque de M x M pixeles (un "pixel de diseno")
function dot(out, x, y, c) { for (let i = 0; i < M; i++) for (let j = 0; j < M; j++) out.set(Math.floor(x) + i, Math.floor(y) + j, c); }

function skeleton(p) {
  const hip = add([OX, OY], [p.hipx, p.hipy]);
  const waist = add(hip, mul(dirA(p.lean), S.waistLen));
  const chest = add(waist, mul(dirA(p.lean + p.bend), S.chestLen));
  const neck = add(chest, mul(dirA(p.lean + p.bend + p.head * 0.5), 3 * M));
  const headC = add(neck, mul(dirA(p.lean + p.bend + p.head), S.headDist));
  const shoulder = add(chest, mul(dirA(p.lean + p.bend + 90), -0.5 * M));
  return { hip, waist, chest, neck, headC, shoulder };
}

// mezcla `layer` en `out` solo donde `out` esta vacio (cosas que van detras)
function behind(out, layer) {
  for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) if (out.g[y][x] === '.' && layer.g[y][x] !== '.') out.g[y][x] = layer.g[y][x];
}

// linea de 2 px de grosor (la de 1 px se pierde a este tamano)
function thick(out, a, b, c) { out.line(a, b, c); out.line(add(a, [0, 1]), add(b, [0, 1]), c); }

function crack(out, o, u, n, pts, glow, seed) {
  // grieta con brillo ambar: pts en el sistema del cuerpo [a lo largo de u, b a lo largo de n]
  const P = pts.map(([a, b]) => add(o, add(mul(u, a * M), mul(n, b * M))));
  for (let i = 0; i < P.length - 1; i++) {
    if (glow > 0.2) out.line(add(P[i], [1, 0]), add(P[i + 1], [1, 0]), 'a');
    thick(out, P[i], P[i + 1], glow > 0.35 ? 'c' : 'b');
    if (glow > 0.75 && (i + seed) % 2 === 0) { out.set(Math.floor(P[i][0]), Math.floor(P[i][1]), 'd'); out.set(Math.floor(P[i][0]) + 1, Math.floor(P[i][1]), 'd'); }
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
    const c = add(B.shoulder, add(mul(n, -7 * M), at([0, 0], -1, -4 - 0.5 * (p.pad || 0))));
    L.shape(ell(c, 9, 7.5), shade(c[0], c[1], 9, '3', '2', '1'), box(c, 12), true);
    behind(out, L);
  }

  // faldon de placas sobre la cadera
  if (!p.noSkirt) {
    const a = add(B.hip, mul(u, 4 * M));
    const q = [alongU(a, u, n, 0, 12), alongU(a, u, n, 0, -12), alongU(a, u, n, -11, -14), alongU(a, u, n, -11, 14)];
    out.shape(polyTest(q), shade(a[0], a[1] - 6 * M, 16, '3', '2', '1'), [a[0] - 16 * M, a[1] - 14 * M, a[0] + 16 * M, a[1] + 14 * M], true);
    for (const t of [-0.2, -0.5, -0.8]) thick(out, alongU(a, u, n, t * 11, 13 + t * 2), alongU(a, u, n, t * 11, -13 - t * 2), '1');
  }

  // placas del pecho: bandas horizontales y reborde
  for (const t of [0.25, 0.52, 0.8]) {
    const o = add(B.waist, mul(sub(B.chest, B.waist), t));
    thick(out, add(o, mul(n, -11 * M)), add(o, mul(n, 12 * M)), '1');
    out.line(add(add(o, mul(n, -10 * M)), [0, -1]), add(add(o, mul(n, 10 * M)), [0, -1]), '3');
    out.line(add(add(o, mul(n, -10 * M)), [0, -2]), add(add(o, mul(n, 10 * M)), [0, -2]), '3');
  }

  // pestilla del pecho (abertura con luz cuando se rompe)
  const gap = add(B.chest, add(mul(n, 3 * M), mul(u, -2 * M)));
  if (open > 0.05) {
    out.shape(ell(gap, 7.5 + 4 * open, 8.5 + 6 * open), () => 'c', box(gap, 22), false);
    out.shape(ell(gap, 6 + 4 * open, 7 + 6 * open), () => '1', box(gap, 22), false);
  }

  // cuello: gorjal
  {
    const g = at(B.neck, 0, 1);
    out.shape(ell(g, 8, 4.6), shade(g[0], g[1], 8, '3', '2', 'a'), box(g, 10), true);
  }

  // yelmo cerrado con hendidura (se levanta y echa atras cuando la armadura se abre)
  if (!p.noHelm) {
    const h = at(B.headC, -5 * open, -8 * open);
    const e = ell(h, 7.2, 8);
    const m = (px, py) => e(px, py) && !(py < h[1] - 5.5 * M && Math.abs(px - h[0]) > 5.2 * M);
    out.shape(m, shade(h[0], h[1], 8, '4', '3', '2'), box(h, 11), true);
    // cresta baja de hierro y juntas
    out.line(at(h, -1, -8), at(h, -1, -1), '2'); out.line(at(h, -1, -8), at(h, -1, -1).map((v, i) => v + (i ? 0 : 1)), '2');
    out.line(at(h, 0.5, -8.5), at(h, 0.5, -2), 'a'); out.line(at(h, 0.5, -8.5).map((v, i) => v + (i ? 0 : 1)), at(h, 0.5, -2).map((v, i) => v + (i ? 0 : 1)), 'a');
    thick(out, at(h, -7, 3.5), at(h, 7, 3.5), '1');
    // hendidura: cuatro pixeles de alto, brillo ambar
    const sx = Math.floor(h[0] + 0.5 * M), sy = Math.floor(h[1] - 0.5 * M);
    const glowC = pulse > 0.5 || open > 0.3 ? 'd' : 'c';
    for (let x = sx; x <= sx + 6 * M; x++) {
      out.set(x, sy, '1'); out.set(x, sy + 1, '1');
      const lit = x > sx + 1 * M;
      out.set(x, sy + 2, lit ? glowC : '1'); out.set(x, sy + 3, lit ? glowC : '1');
    }
    for (let x = sx + 2 * M; x <= sx + 5 * M; x++) { out.set(x, sy + 4, '1'); out.set(x, sy + 5, '1'); }
    // grieta del yelmo cuando esta herido
    if (open > 0.3) crack(out, [h[0], h[1]], [0, -1], [1, 0], [[7, -3], [3, -1], [0, 1], [-4, 0]], 0.9, 1);
  }

  // hombrera cercana, grande y con remaches (pad la sube y baja: respira con el pecho)
  if (!p.noPad) {
    const s = at(B.shoulder, -3, -1 - (p.pad || 0));
    out.shape(ell(s, 10, 8.5), shade(s[0], s[1], 10, '4', '3', '2'), box(s, 14), true);
    thick(out, at(s, -10, 3), at(s, 10, 3), '1');
    thick(out, at(s, -9, -2), at(s, 5, -7), '1');
    for (const [dx, dy] of [[-6, -2], [0, -5], [6, -1], [0, 0]]) dot(out, s[0] + dx * M, s[1] + dy * M, 'c');
    // puas de hierro oxidado
    for (const dx of [-8, -1, 6]) {
      const hgt = dx === -1 ? 3 : 1;
      for (let k = 0; k <= hgt * M; k++) { out.set(Math.floor(s[0] + dx * M), Math.floor(s[1] - 8.5 * M - k), k >= hgt * M ? 'b' : 'a'); out.set(Math.floor(s[0] + dx * M) + 1, Math.floor(s[1] - 8.5 * M - k), k >= hgt * M ? 'b' : 'a'); }
    }
  }

  // rodilleras (la rodilla sale del IK con la misma regla que la biblioteca)
  for (const [foot, col] of [[[p.nfx, p.nfy], 'near'], [[p.ffx, p.ffy], 'far']]) {
    const ankle = add([OX, OY], [foot[0], foot[1] - 2.6 * M]);
    const s = lib.ik(B.hip, ankle, S.legLen, S.legLen, (a, b) => (a[0] > b[0] ? a : b));
    const r = col === 'near' ? 5.2 : 4.4;
    out.shape(ell(s.joint, r, r), shade(s.joint[0], s.joint[1], r, col === 'near' ? '4' : '3', col === 'near' ? '3' : '2', col === 'near' ? '2' : '1'), box(s.joint, r + 3), true);
    if (col === 'near') dot(out, s.joint[0], s.joint[1], 'c');
  }

  // oxido: manchas fijas respecto a la cadera (no "nadan" al moverse)
  for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) {
    const v = out.g[y][x];
    if (v !== '2' && v !== '3') continue;
    const hv = hash2(Math.floor((x - B.hip[0]) / 3), Math.floor((y - B.hip[1]) / 3));
    if (hv < 0.07) out.g[y][x] = v === '3' ? 'b' : 'a';
  }

  // grietas con brillo ambar (laten; mas fuertes al atacar y al abrirse)
  const g = clamp01(pulse + 0.4 * open);
  crack(out, B.chest, u, n, [[2, -3], [-2, 1], [-5, -1], [-9, 3], [-12, 2]], g, 0);
  crack(out, B.chest, u, n, [[-3, 7], [-6, 5], [-7, 9]], g * 0.9, 1);
  crack(out, B.hip, u, n, [[4, 5], [1, 8], [-3, 6], [-6, 10]], g * 0.85, 0);
  crack(out, at(B.shoulder, 0, -3), [0, -1], [1, 0], [[3, -2], [0, 1], [-3, 0], [-5, 4]], g * 0.9, 1);
  if (g > 0.45) crack(out, B.neck, u, n, [[-1, -5], [-4, -3], [-6, -6]], g * 0.8, 0);
  // fractura: red de grietas por todo el cuerpo (muerte)
  if (p.frac > 0) {
    const fg = 0.55 + 0.45 * p.frac;
    crack(out, B.waist, u, n, [[8, -8], [3, -2], [-2, -6], [-7, 1]], fg, 1);
    crack(out, B.hip, u, n, [[2, -9], [-3, -2], [2, 3], [-4, 9]], fg, 0);
    crack(out, B.chest, u, n, [[-1, 9], [3, 4], [-1, 0], [4, -6]], fg, 1);
    if (p.frac > 0.5) {
      crack(out, B.waist, u, n, [[-6, 9], [-2, 6], [-4, 2]], fg, 0);
      crack(out, at(B.shoulder, 0, -3), [0, -1], [1, 0], [[-6, 2], [-2, 6], [-5, 9]], fg, 1);
    }
  }
  // figura palida (el cascaron) asomando por el pecho y el cuello
  if (open > 0.05) {
    const e = open;
    // hombros encorvados dentro del pecho
    const hs = add(gap, add(mul(u, 1 * e * M), mul(n, -1 * M)));
    out.shape(ell(hs, 8 * e + 1, 6 * e + 1), pale(hs, 7), box(hs, 10), true);
    // cabeza que sube por el cuello, caida hacia delante
    const hd = add(B.neck, add(mul(u, (3 + 6.5 * e) * M), mul(n, (3 + 3 * e) * M)));
    const hr = 4.8;
    out.shape(ell(hd, hr, hr + 0.4), pale(hd, hr), box(hd, 8), true);
    for (const [ex, ey] of [[0, -1], [1, -1], [2, -1], [0, 0], [1, 0], [2, 0]]) dot(out, hd[0] + ex * M, hd[1] + ey * M, '1');
    dot(out, hd[0] + 2 * M, hd[1] + 0.5 * M, 'u');
    // mano palida aferrada al borde de la placa
    const hand = add(gap, add(mul(n, 7 * M), mul(u, -4 * e * M)));
    out.shape(ell(hand, 2.6, 1.8), () => '4', box(hand, 5), true);
    for (let k = -1; k <= 1; k++) dot(out, hand[0] + k * 1.6 * M, hand[1] + 2.4 * M, '3');
    // luz ambar de las grietas sobre la figura
    thick(out, at(gap, -5 * e, -6 * e), at(gap, -2 * e, 6 * e), 'd');
  }

}
const clamp01 = (v) => Math.max(0, Math.min(1, v));

// ---------- utilidades de dibujo para las acciones ----------
const len = lib.len;
// pinta solo donde esta transparente (polvo, estelas: nunca tapan al jefe ni al mazo)
function paintBehind(out, test, color, box) {
  for (let y = Math.max(0, Math.floor(box[1])); y <= Math.min(H - 1, Math.ceil(box[3])); y++)
    for (let x = Math.max(0, Math.floor(box[0])); x <= Math.min(W - 1, Math.ceil(box[2])); x++)
      if (out.g[y][x] === '.' && test(x + 0.5, y + 0.5)) { const c = color(x, y); if (c !== '.') out.g[y][x] = c; }
}
const GY = H - 1; // fila del suelo
const fract = (v) => v - Math.floor(v);

// polvo y escombros de un golpe en el suelo; tau = fotogramas desde el impacto, str = intensidad
function burst(out, gx, tau, str, rubble = 18) {
  const hw = (20 + 26 * tau) * str * M / 2, hh = (11 + 7 * tau) * str * M / 2;
  const thin = Math.min(0.85, 0.12 * tau); // fraccion de pixeles que se pierden
  paintBehind(out, (x, y) => y <= GY + 1 && ((x - gx) / hw) ** 2 + ((y - (GY - hh * 0.45)) / hh) ** 2 <= 1,
    (x, y) => {
      if (hash2(x * 0.5 | 0, y * 0.5 | 0) < thin) return '.';
      return y < GY - hh * 0.8 ? '4' : (y < GY - hh * 0.3 ? '3' : '2');
    }, [gx - hw - 2, GY - hh * 2, gx + hw + 2, GY]);
  // nubes laterales que ruedan por el suelo
  for (const sgn of [-1, 1]) {
    const cx = gx + sgn * (30 + 34 * tau) * str, r = (7 + 5 * tau) * str * M / 2;
    paintBehind(out, (x, y) => y <= GY + 1 && ((x - cx) / (r * 1.5)) ** 2 + ((y - (GY - r * 0.5)) / r) ** 2 <= 1,
      (x, y) => (hash2(x * 0.5 | 0, (y * 0.5 | 0) + 9) < thin + 0.1 ? '.' : (y < GY - r * 0.7 ? '4' : '3')), [cx - r * 2, GY - r * 2, cx + r * 2, GY]);
  }
  // escombros que saltan (balisticos)
  for (let i = 0; i < rubble; i++) {
    const a = rad(18 + 144 * hash2(i, 3.1)), spd = (6 + 9 * hash2(i, 7.7)) * str;
    const vx = Math.cos(a) * spd, vy = Math.sin(a) * spd * 1.15;
    const x = gx + vx * tau * 1.3 + (hash2(i, 1.3) - 0.5) * 14 * M, h = vy * tau - 1.5 * tau * tau;
    if (h < -2) continue;
    const y = GY - 3 - Math.max(0, h) * M / 1.6;
    const sz = 1 + Math.floor(hash2(i, 5.5) * 3);
    const col = i % 4 === 0 ? 'c' : (i % 3 === 0 ? '4' : (i % 3 === 1 ? '3' : '2'));
    for (let a2 = 0; a2 < sz * M / 1.4; a2++) for (let b2 = 0; b2 < sz * M / 1.4; b2++) out.set(Math.floor(x) + a2, Math.floor(y) + b2, col);
  }
}
// onda de choque rasa que se abre por el suelo (r = radio horizontal en px)
function wave(out, cx, r, fade) {
  for (let k = 0; k < 2; k++) {
    const rr = r - k * 6;
    if (rr < 4) continue;
    for (let a = 0; a <= 180; a += 1.5) {
      const x = cx + Math.cos(rad(a)) * rr, y = GY - 1 - Math.sin(rad(a)) * rr * 0.17 * (1 - k * 0.3);
      if (fade > 0 && hash2(a * 3.1, k + fade * 7) < fade) continue;
      const c = k === 0 ? '4' : '3';
      out.set(Math.floor(x), Math.floor(y), c); out.set(Math.floor(x), Math.floor(y) - 1, c);
      if (k === 0) out.set(Math.floor(x), Math.floor(y) + 1, '2');
    }
  }
}
// grietas en el suelo con brillo ambar alrededor del impacto
function floorCracks(out, gx, n, glow) {
  for (let k = -n; k <= n; k++) {
    const x = gx + k * 7 * M / 2 + (k % 2) * 3;
    const l = 2 + (Math.abs(k) * 3) % 5;
    for (let j = 0; j < l; j++) out.set(Math.floor(x + (j % 2) * 2), GY - j - 1, glow > 0.5 ? (j === 0 ? 'd' : 'c') : 'b');
  }
}
// chispas del impacto (lineas ambar que salen del punto de contacto)
function flash(out, gx, gy, r) {
  for (let a = 200; a <= 340; a += 20) {
    const l = r * (0.6 + 0.4 * hash2(a, 1.7));
    out.line([gx + Math.cos(rad(a)) * 6, gy + Math.sin(rad(a)) * 6], [gx + Math.cos(rad(a)) * l, gy + Math.sin(rad(a)) * l], a % 40 === 0 ? 'd' : 'c');
  }
}
// brasas que suben de las grietas (bucle: dependen de la fase p.phase)
function embers(out, o, phase, n, rise, spread) {
  for (let k = 0; k < n; k++) {
    const fr = fract(phase / (2 * Math.PI) + k / n + 0.13 * hash2(k, 4));
    const x = o[0] + (hash2(k, 2.2) - 0.5) * spread + 4 * Math.sin(fr * 6 + k), y = o[1] - fr * rise;
    if (fr > 0.92) continue;
    dot(out, x, y, fr < 0.35 ? 'd' : (fr < 0.7 ? 'c' : 'b'));
  }
}
// estela del tajo: cinta que se estrecha hacia atras siguiendo los centros de la cabeza del mazo (pts[0] = el mas antiguo)
function swoosh(out, pts, w) {
  const n = pts.length;
  const rs = pts.map((_, i) => 1 + (w - 1) * Math.pow(i / (n - 1), 1.1));
  const bx = pts.map((q) => q[0]), by = pts.map((q) => q[1]);
  paintBehind(out, chainTest(pts, rs), (x, y) => (hash2(x * 0.5 | 0, y * 0.5 | 0) < 0.3 ? '2' : ((x + y) % 4 < 2 ? '4' : '3')),
    [Math.min(...bx) - w, Math.min(...by) - w, Math.max(...bx) + w, Math.max(...by) + w]);
}
// piezas sueltas (armadura que sale despedida)
function plateShape(out, kind, c, rot) {
  const ct = [Math.floor(c[0]), Math.floor(c[1])];
  if (kind === 'pad') {
    out.shape(ell(ct, 10, 8.5), shade(ct[0], ct[1], 10, '4', '3', '2'), box(ct, 14), true);
    thick(out, at(ct, -10, 3), at(ct, 10, 3), '1');
    for (const [dx, dy] of [[-6, -2], [0, -5], [6, -1]]) dot(out, ct[0] + dx * M, ct[1] + dy * M, 'c');
  } else if (kind === 'helm') {
    out.shape(ell(ct, 7.2, 8), shade(ct[0], ct[1], 8, '4', '3', '2'), box(ct, 11), true);
    for (let k = 0; k < 6 * M; k++) {
      const x = ct[0] - 3 * M + Math.floor(k * Math.cos(rot)), y = ct[1] - 0.5 * M + Math.floor(k * Math.sin(rot));
      out.set(x, y, '1'); out.set(x, y + 1, '1'); out.set(x, y + 2, k > 2 ? 'c' : '1'); out.set(x, y + 3, k > 2 ? 'c' : '1');
    }
  } else {
    const a = [ct[0] - 9 * M * Math.cos(rot), ct[1] - 9 * M * Math.sin(rot)], b = [ct[0] + 9 * M * Math.cos(rot), ct[1] + 9 * M * Math.sin(rot)];
    const rr = [3.2 * M, 3.2 * M];
    out.shape(chainTest([a, b], rr), chainColor([a, b], rr, '3', '2', '1'), [Math.min(a[0], b[0]) - 6 * M, Math.min(a[1], b[1]) - 6 * M, Math.max(a[0], b[0]) + 6 * M, Math.max(a[1], b[1]) + 6 * M], true);
    thick(out, a, b, 'a');
  }
}
// trayectoria de una pieza: cae, rebota un poco y se queda en el suelo
function flight(o, v, tau, floorY, spin) {
  let x = o[0], y = o[1], vx = v[0], vy = v[1], r = 0;
  for (let t = 0; t < tau * 4; t++) {
    vy += 1.4; x += vx * 0.25; y += vy * 0.25; r += spin * 0.25;
    if (y > floorY) { y = floorY; if (Math.abs(vy) > 5) { vy = -vy * 0.32; vx *= 0.55; spin *= 0.5; } else { vy = 0; vx *= 0.3; spin *= 0.2; } }
  }
  return [x, y, r];
}

// ---------- construccion de poses ----------
const HL = S.weaponLen + 4 * M;                       // del punto de agarre al centro de la cabeza del mazo
const MH = S.maulHead;                                // [semilargo, semiancho] de la cabeza
const warns = [];
let LABEL = '';
const DEF = { hip: [0, -67], lean: 4, bend: 3, head: 4, nf: [26, 0], ff: [-26, 0], nfa: 0, ffa: 0, glow: 0.3, open: 0, phase: 0, pad: 0, frac: 0,
  capeTx: -1, capeTy: 0.3, capeAmt: 0.25, capeWave: 0.4, H: [-38, 128], blade: -158, grip: 13 };
// El mazo se define por la posicion de su cabeza (H = [px hacia delante, px de altura]) y su angulo (`blade`, 0 = horizontal hacia
// delante, + = apunta hacia abajo, - = hacia arriba): la mano de atras agarra SIEMPRE el extremo del mango (a HL de la cabeza) y la
// de delante `grip` px mas arriba en el mango. Asi el mazo nunca se invierte. `H[1] = 'g'` apoya la cabeza en el suelo (+ `lift` px);
// `F` = [x, altura] fija el punto de agarre en vez de la cabeza y `FS` lo da relativo al hombro (pantalla).
function mk(s) {
  const d = Object.assign({}, DEF, s);
  const p = pose({ glow: d.glow, open: d.open, hipx: d.hip[0], hipy: d.hip[1], lean: d.lean, bend: d.bend, head: d.head,
    nfx: d.nf[0], nfy: d.nf[1], nfa: d.nfa, ffx: d.ff[0], ffy: d.ff[1], ffa: d.ffa,
    capeTx: d.capeTx, capeTy: d.capeTy, capeAmt: d.capeAmt, capeWave: d.capeWave, phase: d.phase, pad: d.pad, frac: d.frac,
    noPad: d.noPad, noHelm: d.noHelm, noSkirt: d.noSkirt });
  const sh = skeleton(p).shoulder;
  const bd = [Math.cos(rad(d.blade)), Math.sin(rad(d.blade))];
  let F;
  if (d.FS) F = add(sh, d.FS);
  else if (d.F) F = [OX + d.F[0], OY - d.F[1]];
  else {
    let hy = d.H[1];
    if (hy === 'g') hy = MH[0] * Math.abs(Math.sin(rad(d.blade))) + MH[1] * Math.abs(Math.cos(rad(d.blade))) + 2 + (d.lift || 0);
    F = sub([OX + d.H[0], OY - hy], mul(bd, HL));
  }
  const fh = add(F, mul(bd, d.grip));
  if (len(sub(F, sh)) > 2 * S.armLen - 0.5) warns.push(LABEL + ': mano de atras fuera de alcance por ' + (len(sub(F, sh)) - 2 * S.armLen).toFixed(1));
  if (len(sub(fh, sh)) > 2 * S.farArmLen - 0.5) warns.push(LABEL + ': mano de delante fuera de alcance por ' + (len(sub(fh, sh)) - 2 * S.farArmLen).toFixed(1));
  p.fx = F[0] - sh[0]; p.fy = F[1] - sh[1]; p.gx = fh[0] - sh[0]; p.gy = fh[1] - sh[1]; p.blade = d.blade;
  p.headPx = add(F, mul(bd, HL)); p.shoulderPx = sh; p.fistPx = F; p.bladeDeg = d.blade;
  return p;
}
const withFx = (p, fn) => { p.post = (o, f) => { deco(o, f, p); if (fn) fn(o, f, p); }; return p; };
const anims = {};
// construye una animacion a partir de n funciones i -> pose
const build = (name, n, fn) => Array.from({ length: n }, (_, i) => { LABEL = name + '_' + i; return fn(i, i / n); });
const tw = (t) => 2 * Math.PI * t;
const clampv = (v, a, b) => Math.max(a, Math.min(b, v));

// ---------- animaciones ----------
const REST = { H: [-38, 128], blade: -158 };       // mazo al hombro

// idle: respira (torso y hombrera con retardo), se balancea, las grietas laten; 12 fotogramas
anims.idle = { fps: 8, loop: true, frames: build('idle', 12, (i, t) => {
  const a = tw(t), b = Math.sin(a), lag = Math.sin(a - 0.8);
  return withFx(mk({ hip: [1.6 * Math.sin(a - 0.4), -67 + 3.2 * b], lean: 4 + 1.4 * b, bend: 3 + 1.6 * b, head: 4 - 2.4 * lag,
    H: [-38 - 1.2 * lag, 128 + 2.4 * lag], blade: -158 + 2.2 * lag, pad: 1.7 * lag, glow: 0.3 + 0.1 * Math.sin(2 * a + 0.3), phase: a,
    capeAmt: 0.25 + 0.08 * b, capeTy: 0.3 + 0.15 * Math.sin(a - 1), capeWave: 0.45 }));
}) };

// walk: paso pesado: la cadera cae al apoyar, la hombrera rebota, las grietas se encienden con cada pisada; 12 fotogramas
anims.walk = { fps: 16, loop: true, frames: build('walk', 12, (i, u) => {
  const nf = footCycle(u % 1, 24, 15), ff = footCycle((u + 0.5) % 1, 24, 15);
  const dn = Math.cos(4 * Math.PI * (u - 0.17)), sw = Math.sin(2 * Math.PI * (u - 0.1));
  const thump = Math.pow(Math.max(0, dn), 5);
  return withFx(mk({ hip: [4 + 1.5 * sw, -67 + 5 * dn], lean: 8 + 1.4 * dn, bend: 3 + 1.5 * thump, head: 4 - 3 * thump,
    nf: [nf[0], nf[1]], ff: [ff[0], ff[1]], nfa: nf[1] < -4 ? 32 : 0, ffa: ff[1] < -4 ? 32 : 0,
    H: [-36 + 3 * sw, 126 + 3 * dn], blade: -158 + 5 * sw, pad: -2.2 * Math.cos(4 * Math.PI * (u - 0.17 + 0.1)),
    glow: 0.35 + 0.35 * thump, capeAmt: 0.5, capeTy: 0.2 + 0.2 * dn, capeWave: 0.5, phase: 4 * Math.PI * u }));
}) };

// windup: se hunde (anticipacion), coge impulso y levanta el mazo por detras hasta lo alto; 10 fotogramas.
// El mazo gira siempre en el mismo sentido: -158 (al hombro) -> -172 (se carga hacia atras) -> -105 (en alto).
const WUP = [
  { hip: [0, -67], lean: 4, bend: 3, head: 4, nf: [26, 0], ff: [-26, 0], H: [-38, 128], blade: -158, glow: 0.35, pad: 0, capeAmt: 0.25 },
  { hip: [-2, -61], lean: 7, bend: 6, head: 8, nf: [30, 0], ff: [-30, 0], H: [-43, 121], blade: -165, glow: 0.45, pad: -1, capeAmt: 0.3 },
  { hip: [-4, -54], lean: 9, bend: 9, head: 11, nf: [33, 0], ff: [-33, 0], H: [-50, 116], blade: -172, glow: 0.55, pad: -2, capeAmt: 0.35, capeTy: 0.6 },
  { hip: [-4, -58], lean: -2, bend: 0, head: 8, nf: [33, 0], ff: [-33, 0], H: [-56, 142], blade: -152, glow: 0.65, pad: 1, capeAmt: 0.4, capeTy: 0.5 },
  { hip: [-3, -62], lean: -7, bend: -3, head: 8, nf: [33, 0], ff: [-33, 0], H: [-56, 166], blade: -136, glow: 0.75, pad: 2, capeAmt: 0.5, capeTy: 0.4 },
  { hip: [-3, -64], lean: -11, bend: -5, head: 9, nf: [33, 0], ff: [-33, 0], H: [-51, 187], blade: -123, glow: 0.85, pad: 2.5, capeAmt: 0.6, capeTy: 0.3 },
  { hip: [-3, -63], lean: -14, bend: -7, head: 10, nf: [33, 0], ff: [-33, 0], H: [-43, 200], blade: -113, glow: 0.92, pad: 3, capeAmt: 0.65, capeTy: 0.2 },
  { hip: [-3, -60], lean: -16, bend: -8, head: 10, nf: [33, 0], ff: [-33, 0], H: [-35, 207], blade: -107, glow: 1, pad: 2, capeAmt: 0.7, capeTy: 0.3 },
  { hip: [-3, -58], lean: -18, bend: -9, head: 11, nf: [33, 0], ff: [-33, 0], H: [-30, 210], blade: -104, glow: 1, pad: 0.5, capeAmt: 0.7, capeTy: 0.5 },
  { hip: [-3, -58], lean: -16, bend: -8, head: 10, nf: [33, 0], ff: [-33, 0], H: [-30, 205], blade: -105, glow: 1, pad: 0, capeAmt: 0.7, capeTy: 0.45 },
];
anims.windup = { fps: 12, loop: false, frames: build('windup', 10, (i) => withFx(mk(Object.assign({ phase: i * 0.9, capeWave: 0.45 }, WUP[i])), (o, f, p) => {
  if (i >= 7) embers(o, add([OX, OY], [10, -150]), i * 0.9, 3, 30, 40);
})) };

// strike: tajo hacia delante y abajo con aceleracion; el fotograma 5 es el IMPACTO (cabeza del mazo a ras de suelo);
// 6 y 7 mantienen la pose y se endereza. El mazo sigue girando en el mismo sentido: -105 -> 66.
const STR = [
  { hip: [-1, -58], lean: -14, bend: -8, head: 8, H: [-22, 208], blade: -99, glow: 1, pad: -1, capeAmt: 0.8, capeTy: 0.4 },
  { hip: [4, -56], lean: -2, bend: -2, head: 2, H: [16, 205], blade: -80, glow: 1, pad: -2, capeAmt: 0.9, capeTy: 0.2 },
  { hip: [12, -54], lean: 14, bend: 4, head: -6, H: [64, 189], blade: -57, glow: 1, pad: -3, capeAmt: 1, capeTy: -0.1 },
  { hip: [20, -52], lean: 30, bend: 8, head: -14, H: [110, 150], blade: -28, glow: 1, pad: -3, capeAmt: 1, capeTy: -0.3 },
  { hip: [26, -50], lean: 44, bend: 12, head: -20, H: [142, 96], blade: 18, glow: 1, pad: -2, capeAmt: 1, capeTy: -0.4 },
  { hip: [35, -48], lean: 54, bend: 14, head: -24, H: [152, 'g'], blade: 66, glow: 1, pad: 0, capeAmt: 0.9, capeTy: -0.1 },
  { hip: [36, -47], lean: 56, bend: 14, head: -24, H: [151, 'g'], blade: 68, glow: 0.9, pad: 2, capeAmt: 0.6, capeTy: 0.4 },
  { hip: [31, -50], lean: 46, bend: 10, head: -14, H: [142, 'g'], blade: 66, lift: 8, glow: 0.7, pad: 1, capeAmt: 0.4, capeTy: 0.6 },
];
{
  LABEL = 'strike';
  const ps = STR.map((s, i) => { LABEL = 'strike_' + i; return mk(Object.assign({ nf: [33, 0], ff: [-33, 0], phase: i * 0.9, capeTx: -1, capeWave: 0.45 }, s)); });
  ps.forEach((p, i) => withFx(p, (o, f) => {
    const tip = p.headPx;
    if (i >= 2 && i <= 4) swoosh(o, [ps[i - 2].headPx, ps[i - 1].headPx, tip], i === 4 ? 26 : 20);
    if (i === 1) swoosh(o, [ps[0].headPx, tip], 10);
    if (i >= 5) {
      const tau = i - 5;
      burst(o, tip[0] + 4, tau, 1, 22);
      floorCracks(o, tip[0] + 4, 5 - tau, 1 - tau * 0.4);
      if (i === 5) flash(o, tip[0] + 4, GY - 4, 40);
    }
  }));
  anims.strike = { fps: 30, loop: false, frames: ps };
}

// crouch: se agazapa para saltar; el mazo recogido al hombro baja con el cuerpo; 5 fotogramas
const CR = [
  { hip: [0, -63], lean: 8, bend: 5, head: 2, nf: [28, 0], ff: [-28, 0], H: [-38, 124], blade: -160, glow: 0.4, pad: -1 },
  { hip: [0, -55], lean: 15, bend: 9, head: -3, nf: [31, 0], ff: [-31, 0], H: [-34, 112], blade: -158, glow: 0.5, pad: -2 },
  { hip: [-1, -46], lean: 23, bend: 12, head: -8, nf: [34, 0], ff: [-34, 0], H: [-28, 98], blade: -156, glow: 0.65, pad: -3 },
  { hip: [-2, -40], lean: 29, bend: 14, head: -11, nf: [36, 0], ff: [-36, 0], H: [-22, 88], blade: -154, glow: 0.85, pad: -3.5 },
  { hip: [-2, -38], lean: 31, bend: 15, head: -12, nf: [36, 0], ff: [-36, 0], H: [-21, 86], blade: -154, glow: 1, pad: -3.5 },
];
anims.crouch = { fps: 10, loop: false, frames: build('crouch', 5, (i) => withFx(mk(Object.assign({ phase: i * 0.9, capeAmt: 0.4 + 0.08 * i, capeTy: 0.5 }, CR[i])))) };

// jump: ascenso; estira y se encoge, mazo al hombro; 3 fotogramas
const JP = [
  { hip: [2, -73], lean: 5, bend: 2, head: 2, nf: [10, -5], ff: [-6, -9], nfa: 10, ffa: 12, H: [-38, 140], blade: -158, glow: 0.7, pad: 3, capeTx: -0.3, capeTy: 1, capeAmt: 0.5 },
  { hip: [2, -70], lean: 10, bend: 6, head: 4, nf: [22, -22], ff: [-8, -30], nfa: 25, ffa: 40, H: [-38, 138], blade: -158, glow: 0.7, pad: 2, capeTx: -0.2, capeTy: 1, capeAmt: 0.45 },
  { hip: [2, -68], lean: 13, bend: 8, head: 5, nf: [25, -26], ff: [-10, -34], nfa: 30, ffa: 45, H: [-37, 134], blade: -157, glow: 0.6, pad: 0, capeTx: 0.1, capeTy: 0.4, capeAmt: 0.4 },
];
anims.jump = { fps: 10, loop: false, frames: build('jump', 3, (i) => withFx(mk(Object.assign({ phase: i * 1.3, capeWave: 0.5 }, JP[i])))) };

// fall: cae con el mazo en alto, listo para estrellarlo; las piernas cuelgan y la capa se levanta; 3 fotogramas (bucle)
anims.fall = { fps: 10, loop: true, frames: build('fall', 3, (i, t) => {
  const a = tw(t), s = Math.sin(a);
  return withFx(mk({ hip: [0, -70 + 2 * s], lean: -9 + 2 * s, bend: -4, head: 8, nf: [20, -5 + 2 * s], ff: [-14, -12 - 3 * s], nfa: 0, ffa: 15,
    H: [-28 + 1.5 * s, 207 + 3 * s], blade: -104 + 2 * s, glow: 0.75 + 0.2 * s, pad: 3 + s, phase: i * 2.1,
    capeTx: 0.3, capeTy: -0.9, capeAmt: 1, capeWave: 0.6 }));
}) };

// land: el cuerpo golpea el suelo (fotograma 1 = IMPACTO con polvo y onda); se levanta absorbiendo el golpe; 6 fotogramas
const LD = [
  { hip: [0, -60], lean: -8, bend: -4, head: 8, nf: [26, 0], ff: [-26, 0], H: [-28, 207], blade: -104, glow: 0.8, pad: 3, capeTx: 0.2, capeTy: -0.7, capeAmt: 0.9 },
  { hip: [2, -37], lean: 20, bend: 10, head: -6, nf: [37, 0], ff: [-37, 0], H: [-22, 186], blade: -108, glow: 1, pad: 4.5, capeTx: -0.5, capeTy: 1, capeAmt: 0.8 },
  { hip: [1, -35], lean: 25, bend: 12, head: -9, nf: [38, 0], ff: [-38, 0], H: [-12, 160], blade: -118, glow: 1, pad: 3, capeTx: -1, capeTy: 0.8, capeAmt: 0.6 },
  { hip: [0, -46], lean: 16, bend: 8, head: -3, nf: [34, 0], ff: [-34, 0], H: [-22, 146], blade: -134, glow: 0.8, pad: -1.5, capeTx: -1, capeTy: 0.6, capeAmt: 0.5 },
  { hip: [0, -57], lean: 9, bend: 5, head: 1, nf: [30, 0], ff: [-30, 0], H: [-31, 135], blade: -148, glow: 0.55, pad: -2, capeTx: -1, capeTy: 0.4, capeAmt: 0.35 },
  { hip: [0, -65], lean: 5, bend: 4, head: 4, nf: [27, 0], ff: [-27, 0], H: [-37, 129], blade: -157, glow: 0.4, pad: 0.5, capeTx: -1, capeTy: 0.3, capeAmt: 0.25 },
];
anims.land = { fps: 18, loop: false, frames: build('land', 6, (i) => withFx(mk(Object.assign({ phase: i * 0.9, capeWave: 0.45 }, LD[i])), (o) => {
  if (i >= 1 && i <= 4) {
    const tau = i - 1;
    burst(o, OX, tau, 1.0, 20);
    burst(o, OX + 44, tau + 0.5, 0.6, 6);
    burst(o, OX - 44, tau + 0.5, 0.6, 6);
    wave(o, OX, 40 + 56 * tau, tau * 0.22);
    if (i <= 2) floorCracks(o, OX, 7 - 2 * tau, 1 - 0.5 * tau);
  }
})) };

// stagger: de rodillas, el mazo apoyado, la armadura abierta y el cascaron palido asomando (punto debil); 8 fotogramas (bucle)
anims.stagger = { fps: 8, loop: true, frames: build('stagger', 8, (i, t) => {
  const a = tw(t), b = Math.sin(a), b2 = Math.sin(2 * a);
  return withFx(mk({ hip: [-6, -38 + 1.4 * b], lean: 14 + 1.6 * b, bend: 8 + 1.2 * b2, head: -6 - 2.8 * b, nf: [43, 0], ff: [-64, -3], ffa: 80,
    H: [105, 'g'], blade: 35, pad: 1.4 * Math.sin(a - 0.7), open: 0.88 + 0.12 * b, glow: 0.82 + 0.18 * b2, phase: a,
    capeTx: -1, capeTy: 0.6, capeAmt: 0.35, capeWave: 0.5 }), (o, f, p) => {
    embers(o, add(skeleton(p).chest, [4, -6]), a, 5, 50, 36);
  });
}) };

// getup: se apoya en el mazo, se incorpora, cierra la armadura y se echa el mazo al hombro; 6 fotogramas
const GU = [
  { hip: [-4, -42], lean: 16, bend: 8, head: -6, nf: [42, 0], ff: [-58, -2], ffa: 70, F: [46, 76], blade: 33, open: 0.7, glow: 0.7 },
  { hip: [-2, -52], lean: 16, bend: 6, head: -2, nf: [38, 0], ff: [-46, 0], ffa: 35, F: [38, 86], blade: 10, open: 0.45, glow: 0.55 },
  { hip: [0, -60], lean: 10, bend: 5, head: 0, nf: [34, 0], ff: [-36, 0], ffa: 10, F: [31, 93], blade: -25, open: 0.22, glow: 0.45 },
  { hip: [0, -65], lean: 6, bend: 4, head: 3, nf: [30, 0], ff: [-30, 0], F: [30, 98], blade: -70, open: 0.08, glow: 0.38 },
  { hip: [0, -67], lean: 5, bend: 3, head: 4, nf: [27, 0], ff: [-27, 0], F: [31, 100], blade: -120, open: 0, glow: 0.35 },
  { hip: [0, -67], lean: 4, bend: 3, head: 4, nf: [26, 0], ff: [-26, 0], F: [31, 100], blade: -157, open: 0, glow: 0.3 },
];
anims.getup = { fps: 10, loop: false, frames: build('getup', 6, (i) => withFx(mk(Object.assign({ phase: i * 0.9, capeTx: -1, capeTy: 0.5, capeAmt: 0.35, capeWave: 0.45, pad: i < 3 ? -1.5 : 0 }, GU[i])))) };

// death: la armadura se resquebraja, sale despedida por piezas y se desploma en un monton de chatarra; 12 fotogramas
const DE = [
  { hip: [-6, -38], lean: 14, bend: 8, head: -6, nf: [43, 0], ff: [-64, -3], ffa: 80, H: [105, 'g'], blade: 35, open: 1, glow: 1, frac: 0.35 },
  { hip: [-6, -37], lean: 20, bend: 10, head: -18, nf: [43, 0], ff: [-64, -3], ffa: 80, H: [110, 'g'], blade: 33, open: 1, glow: 1, frac: 0.6, lift: 4 },
  { hip: [-5, -35], lean: 28, bend: 12, head: -26, nf: [43, 0], ff: [-62, -3], ffa: 80, H: [114, 'g'], blade: 30, open: 1, glow: 1, frac: 0.8, noPad: true, lift: 6 },
  { hip: [-3, -31], lean: 38, bend: 14, head: -30, nf: [42, 0], ff: [-60, -2], ffa: 75, H: [120, 'g'], blade: 22, open: 1, glow: 1, frac: 1, noPad: true, noHelm: true, lift: 8 },
  { hip: [2, -27], lean: 52, bend: 16, head: -28, nf: [40, 0], ff: [-56, -2], ffa: 70, H: [130, 'g'], blade: 16, open: 1, glow: 0.9, frac: 1, noPad: true, noHelm: true, lift: 2 },
  { hip: [10, -21], lean: 66, bend: 14, head: -20, nf: [36, 0], ff: [-52, -2], ffa: 60, H: [142, 'g'], blade: 11, open: 1, glow: 0.7, frac: 1, noPad: true, noHelm: true, noSkirt: true },
  { hip: [18, -16], lean: 78, bend: 10, head: -10, nf: [30, 0], ff: [-48, -2], ffa: 50, H: [152, 'g'], blade: 8, open: 1, glow: 0.5, frac: 1, noPad: true, noHelm: true, noSkirt: true },
  { hip: [22, -13], lean: 84, bend: 6, head: 0, nf: [28, 0], ff: [-46, -2], ffa: 50, H: [158, 'g'], blade: 5, open: 1, glow: 0.35, frac: 1, noPad: true, noHelm: true, noSkirt: true },
];
const DEATH_FIN = DE[7];
const THROWN = [ // pieza, fotograma en que sale, velocidad inicial, giro
  { kind: 'pad', at: 2, v: [-3, -9], spin: 0.32, fy: 17, from: (p) => p.shoulderPx },
  { kind: 'helm', at: 3, v: [9, -7], spin: 0.28, fy: 16, from: (p) => skeleton(p).headC },
  { kind: 'plate', at: 5, v: [-8, -5], spin: 0.2, fy: 8, from: (p) => skeleton(p).hip },
  { kind: 'plate', at: 6, v: [7, -4], spin: -0.15, fy: 8, from: (p) => add(skeleton(p).hip, [6, 10]) },
];
function chatarra(out, n) { // el monton: piezas que se van sumando; n = cuantas
  const hx = OX + 8;
  const items = [
    () => { const a = [hx - 70, GY - 8], b = [hx - 36, GY - 11]; out.shape(chainTest([a, b], [8, 7]), chainColor([a, b], [8, 7], '3', '2', '1'), [hx - 84, GY - 24, hx - 22, GY], true); },
    () => { const a = [hx - 52, GY - 6], b = [hx - 14, GY - 13]; out.shape(chainTest([a, b], [10, 9]), chainColor([a, b], [10, 9], '4', '3', '2'), [hx - 66, GY - 28, hx - 2, GY], true); thick(out, add(a, [8, -6]), add(b, [-6, -5]), 'a'); },
    () => { const c = [hx - 22, GY - 16]; out.shape(polyTest([[c[0] - 22, c[1] + 2], [c[0] + 2, c[1] - 7], [c[0] + 22, c[1] + 1], [c[0] + 4, c[1] + 12]]), shade(c[0], c[1], 22, '4', '3', '2'), [c[0] - 26, c[1] - 11, c[0] + 26, c[1] + 16], true); thick(out, [c[0] - 10, c[1] + 2], [c[0] + 12, c[1] - 1], '1'); },
    () => { const c = [hx + 2, GY - 22]; out.shape(ell(c, 9, 6), shade(c[0], c[1], 16, '4', '3', '2'), box(c, 12), true); crack(out, c, [0, -1], [1, 0], [[2, -3], [-1, 0], [-4, 1]], 0.5, 1); },
    () => { const c = [hx + 20, GY - 14]; out.shape(polyTest([[c[0] - 20, c[1] + 4], [c[0] - 4, c[1] - 9], [c[0] + 20, c[1] - 3], [c[0] + 14, c[1] + 11]]), shade(c[0], c[1], 22, '4', '3', '2'), [c[0] - 24, c[1] - 13, c[0] + 24, c[1] + 15], true); thick(out, [c[0] - 10, c[1] + 1], [c[0] + 12, c[1] - 3], '1'); },
    () => { const a = [hx + 26, GY - 7], b = [hx + 62, GY - 10]; out.shape(chainTest([a, b], [8, 7]), chainColor([a, b], [8, 7], '3', '2', '1'), [hx + 14, GY - 24, hx + 76, GY], true); thick(out, add(a, [4, -4]), add(b, [-4, -5]), 'a'); },
    () => { const c = [hx - 36, GY - 22]; out.shape(ell(c, 4.5, 4.5), shade(c[0], c[1], 9, '4', '3', '2'), box(c, 7), true); dot(out, c[0], c[1], 'c'); },
    () => { const c = [hx + 22, GY - 27]; out.shape(ell(c, 8, 4.5), shade(c[0], c[1], 14, '4', '3', '2'), box(c, 11), true); crack(out, c, [0, -1], [1, 0], [[2, -1], [-2, 2]], 0.4, 0); },
    () => { for (const [dx, dy, c] of [[-60, 3, '3'], [-26, 2, '4'], [26, 2, '3'], [58, 3, '2'], [-4, 3, '3'], [78, 2, '3']]) { dot(out, hx + dx, GY - dy * M, c); dot(out, hx + dx + M, GY - dy * M, c); } },
  ];
  for (let k = 0; k < Math.min(n, items.length); k++) items[k]();
}
function fantasma(out, level) { // el cascaron palido: tumbado sobre la chatarra, se desvanece (level 0 = pleno, 1 = nada)
  const T = new Canvas();
  const hx = OX + 8;
  const hs = [hx + 8, GY - 30];
  T.shape(ell(hs, 9, 5.2), pale(hs, 8), box(hs, 12), true);
  const hd = [hx + 30, GY - 28];
  T.shape(ell(hd, 4.6, 4.8), pale(hd, 5), box(hd, 8), true);
  dot(T, hd[0] + 2 * M, hd[1], '1');
  const hand = [hx + 46, GY - 22];
  T.shape(ell(hand, 2.6, 1.8), () => '4', box(hand, 5), true);
  // luz ambar entre la chatarra
  thick(T, [hx - 6, GY - 22], [hx + 14, GY - 20], 'c');
  for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) if (T.g[y][x] !== '.' && hash2(x, y * 1.7) >= level) out.g[y][x] = T.g[y][x];
}
function motas(out, k, n) { // restos de luz palida que suben cuando se va el cascaron
  for (let j = 0; j < n; j++) {
    const x = OX + 8 + 10 + (hash2(j, 8.1) - 0.5) * 60, y = GY - 36 - k * 8 - hash2(j, 2.3) * 36 - j * 3;
    dot(out, x, y, j % 3 === 0 ? 'h' : (j % 3 === 1 ? '4' : 'g'));
  }
}
function chispas(out, o, i, i0, n, speed) { // lluvia de chispas ambar desde o
  for (let k = 0; k < n; k++) {
    const ls = i0 + Math.floor(hash2(k, 9.1) * 3), tau = i - ls;
    if (tau < 0 || tau > 4) continue;
    const a = rad(200 + 140 * hash2(k, 6.6)), sp = speed * (0.5 + hash2(k, 1.9));
    const x = o[0] + (hash2(k, 3.3) - 0.5) * 36 + Math.cos(a) * sp * tau, y = o[1] + (hash2(k, 4.4) - 0.5) * 24 + Math.sin(a) * sp * tau + 1.4 * tau * tau;
    dot(out, x, y, tau < 2 ? 'd' : (tau < 3 ? 'c' : 'b'));
  }
}
{
  const ps = DE.map((s, i) => { LABEL = 'death_' + i; return mk(Object.assign({ phase: i * 1.1, capeTx: -1, capeTy: 0.7, capeAmt: 0.3, capeWave: 0.5 }, s)); });
  const org = THROWN.map((t) => t.from(ps[t.at]));
  const frames12 = Array.from({ length: 12 }, (_, i) => {
    const p = ps[Math.min(i, 7)];
    p.post = (o, f) => {
      deco(o, f, p);
      if (i >= 8) { // el cuerpo se deshace: se borra a trozos y solo queda el mazo
        const e = i === 8 ? 0.55 : 1;
        for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) if (o.g[y][x] !== '.' && hash2(x * 0.7, y * 0.9) < e) o.g[y][x] = '.';
        lib.drawWeapon(o, S, { blade: DEATH_FIN.blade, phase: 0 }, ps[7].fistPx);
      }
      const sk = skeleton(p);
      if (i >= 1 && i <= 5) chispas(o, sk.chest, i, 1, 14, 9);
      if (i >= 3 && i <= 7) chispas(o, sk.neck, i, 3, 8, 7);
      // piezas despedidas
      THROWN.forEach((t, k) => {
        if (i < t.at) return;
        const q = flight(org[k], t.v, i - t.at + 1, GY - t.fy, t.spin);
        plateShape(o, t.kind, q, q[2]);
      });
      // polvo de los golpes contra el suelo
      if (i === 5) burst(o, OX + 40, 0.5, 0.7, 8);
      if (i === 6) { burst(o, OX + 50, 0.5, 1.1, 12); burst(o, OX + 50, 1.5, 0.6, 6); }
      if (i === 7) burst(o, OX + 60, 1.6, 1.0, 10);
      if (i >= 8 && i <= 9) burst(o, OX + 60, i - 6, 0.9, 6);
      // chatarra
      if (i >= 5) chatarra(o, i === 5 ? 1 : (i === 6 ? 3 : (i === 7 ? 5 : (i === 8 ? 7 : (i === 9 ? 8 : 9)))));
      if (i >= 6) fantasma(o, i === 6 ? 0.55 : (i === 7 ? 0.2 : (i === 8 ? 0.15 : (i === 9 ? 0.4 : (i === 10 ? 0.85 : 1.01)))));
      if (i >= 8 && i <= 10) motas(o, i - 8, i === 8 ? 5 : (i === 9 ? 6 : 3));
      if (i >= 8) { // brasas que se apagan en la chatarra
        const dim = i >= 10 ? 'a' : 'b';
        for (const [dx, dy] of [[-30, 16], [-8, 24], [24, 14], [38, 22]]) { if (i === 11 && dx === 38) continue; dot(o, OX + 8 + dx, GY - dy, i >= 11 ? 'a' : dim); }
      }
    };
    return p;
  });
  anims.death = { fps: 10, loop: false, frames: frames12 };
}

// ---------- salida ----------
const order = ['idle', 'walk', 'windup', 'strike', 'crouch', 'jump', 'fall', 'land', 'stagger', 'getup', 'death'];
const header = [
  '# El Centinela Hueco: armadura vacia de un Custodio de la Orden del Archivo, enorme, de hierro oscuro',
  '# y oxidado, con grietas de brillo ambar y un mazo de piedra y hierro. Se mueve por costumbre; cuando',
  '# se agrieta, dentro se ve una figura palida y encorvada (un cascaron) asomando por el pecho y el cuello.',
  '# Cada fotograma es un lienzo completo de ' + W + 'x' + H + ' con los pies en la fila de abajo.',
  '# Lo genera tools/rig_centinela.js (esqueleto de tools/rig_lib.js); para cambiar el movimiento se',
  '# edita el esqueleto y se regenera, no estos fotogramas a mano.',
  '# Leyenda: ver art/palette.txt. El punto (.) es transparente.'];
for (const w of warns) console.error('AVISO ' + w);
const info = lib.writeSprite('art/source/centinela.sprite', header, 'res://game/boss/centinela_sheet.png', order, anims, S);
console.log(JSON.stringify(info));
const hd = (a, i) => anims[a].frames[i].headPx;
const rp = (a) => { const q = hd(a.split(':')[0], +a.split(':')[1]); return [Math.round(q[0] - OX), Math.round(OY - q[1])]; };
console.log('cabeza mazo: windup:9', rp('windup:9'), 'strike:5', rp('strike:5'));
