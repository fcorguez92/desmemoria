// Generador del jefe "Jacinto, el Ultimo Segador" (ver tools/rig_lib.js y tools/rig_centinela.js):
// un campesino de los bancales, alto y flaco, con sombrero de paja, camisa de lino sucia,
// pantalon de tierra y una hoz de mango largo (guadana). Sigue segando un campo vacio.
// Usa el esqueleto humanoide de la biblioteca ampliado (K) sin arma propia: la hoz, las manos
// y los efectos (estelas con trigo, polvo, paja que sube) se dibujan encima con la funcion `post`.
// Todo a resolucion nativa. Lienzo de 224x128 con los pies en la fila de abajo; la hoja tiene
// 17 filas y un maximo de 8 columnas (unos 15 MB de textura).
// Uso: node tools/rig_jacinto.js   (escribe art/source/jacinto.sprite y art/source/hoz.sprite)
const lib = require('./rig_lib');
const { lerp, ease, pose, makeStyle, add, sub, mul, norm, len, dirA, rad, Canvas, polyTest, chainTest, chainColor, clamp } = lib;

const W = 224, H = 128;
lib.setCanvas(W, H);
const { OX, OY } = lib.canvasSize();
const GY = H - 1; // fila del suelo

const K = 1.75; // escala respecto al caminante
const POS = ['hipx', 'hipy', 'nfx', 'nfy', 'ffx', 'ffy'];
void POS;
const hash2 = (a, b) => { const x = Math.sin(a * 127.1 + b * 311.7) * 43758.5453; return x - Math.floor(x); };
const fract = (v) => v - Math.floor(v);
const warns = [];
let LABEL = '';

const S = makeStyle({
  z: 1.5,
  head: 'bare', headR: 4.6 * K, headDist: 4.4 * K, legLen: 9.4 * K, waistLen: 6.6 * K, chestLen: 6.4 * K,
  torsoR: [3.5 * K, 3.8 * K, 4.2 * K, 2.1 * K], armLen: 9.0 * K, farArmLen: 8.8 * K, armR: [2.3 * K, 1.9 * K, 1.7 * K], farArmR: [2.1 * K, 1.8 * K, 1.6 * K],
  nearLegR: [3.0 * K, 2.5 * K, 2.0 * K, 1.6 * K], farLegR: [2.9 * K, 2.4 * K, 1.9 * K, 1.5 * K],
  torsoCol: ['8', '4', '3'], nearLegCol: ['6', '5', '1'], farLegCol: ['5', '1', '1'],
  nearArmCol: ['8', '4', '3'], farArmCol: ['4', '3', '2'], handCol: ['8', '4'],
  cape: { on: true, base: '5', fold: '1', edge: '6', segs: 3, seg: 6.5 * K, w0: 3.0 * K, wk: 0.9 * K, rag: 6 },
  scarf: false, belt: false, pouch: false, noise: 0.14, tunic: 6, weapon: 'none', eyeGlint: null,
});

function skeleton(p) {
  const hip = add([OX, OY], [p.hipx, p.hipy]);
  const waist = add(hip, mul(dirA(p.lean), S.waistLen));
  const chest = add(waist, mul(dirA(p.lean + p.bend), S.chestLen));
  const neck = add(chest, mul(dirA(p.lean + p.bend + p.head * 0.5), 3 * S.z));
  const headC = add(neck, mul(dirA(p.lean + p.bend + p.head), S.headDist));
  const shoulder = add(chest, mul(dirA(p.lean + p.bend + 90), -0.5 * S.z));
  return { hip, waist, chest, neck, headC, shoulder };
}

// ---------- la hoz ----------
// Mango (guadana) de madera con la hoja en el extremo. `F` = mano de atras (en pantalla); la de delante
// agarra `grip` px mas adelante; el mango sobresale `back` px por detras de F y mide `len` en total.
const BACK = 26, LEN = 82, GRIP = 16, BLADE = 28, CURVE = 0.5;

function scythe(out, a) {
  // a: { F (absoluto), ang (grados del mango, 0 = adelante, -90 = arriba), bdir (grados de la hoja), len, bl }
  const bd = [Math.cos(rad(a.ang)), Math.sin(rad(a.ang))];
  let L = a.len || LEN;
  const Bl = a.bl || BLADE;
  // el mango se acorta (como si girase hacia el espectador) si la punta se saldria del lienzo
  if (bd[1] > 0.05) L = Math.min(L, BACK + Math.max(8, (GY - 4 - a.F[1]) / bd[1]));
  if (bd[1] < -0.05) L = Math.min(L, BACK + Math.max(8, (a.F[1] - 24) / -bd[1]));
  const butt = sub(a.F, mul(bd, BACK)), T = add(a.F, mul(bd, L - BACK));
  out.shape(chainTest([butt, T], [1.5, 1.5]), chainColor([butt, T], [1.5, 1.5], '7', '6', '5'), [Math.min(butt[0], T[0]) - 4, Math.min(butt[1], T[1]) - 4, Math.max(butt[0], T[0]) + 4, Math.max(butt[1], T[1]) + 4], true);
  // casquillo de hierro donde entra la hoja
  out.shape((px, py) => Math.hypot(px - T[0], py - T[1]) <= 2.3, () => '3', [T[0] - 4, T[1] - 4, T[0] + 4, T[1] + 4], true);
  // hoja: media luna que sale del casquillo en la direccion `bdir` y se curva hacia las manos
  const bv = [Math.cos(rad(a.bdir)), Math.sin(rad(a.bdir))];
  const curl = mul(bd, -1);
  const N = 16, C = [];
  for (let i = 0; i <= N; i++) { const s = i / N; C.push(add(add(T, mul(bv, Bl * s)), mul(curl, CURVE * Bl * s * s))); }
  const tan = (i) => norm(sub(C[Math.min(N, i + 1)], C[Math.max(0, i - 1)]));
  const hw = (i) => 3.6 * Math.pow(1 - i / N, 0.8) + 0.9;
  // el filo esta del lado concavo (hacia donde se curva)
  const edgeSign = (i) => { const t = tan(i); const n = [-t[1], t[0]]; return (n[0] * curl[0] + n[1] * curl[1]) >= 0 ? 1 : -1; };
  const left = [], right = [];
  for (let i = 0; i <= N; i++) {
    const t = tan(i), n = [-t[1], t[0]], es = edgeSign(i);
    left.push(add(C[i], mul(n, hw(i) * es)));      // filo
    right.push(add(C[i], mul(n, -hw(i) * es)));    // lomo
  }
  const poly = [...right, ...left.slice().reverse()];
  const nearest = (px, py) => { let bi = 0, bdist = 1e9; for (let i = 0; i <= N; i++) { const d = Math.hypot(px - C[i][0], py - C[i][1]); if (d < bdist) { bdist = d; bi = i; } } return bi; };
  out.shape(polyTest(poly), (px, py) => {
    const bi = nearest(px, py);
    const t = tan(bi), n = [-t[1], t[0]], es = edgeSign(bi);
    const sd = ((px - C[bi][0]) * n[0] + (py - C[bi][1]) * n[1]) * es;
    if (bi >= N - 1) return 'w';
    return sd > 0.35 * hw(bi) ? 'w' : (sd < -0.45 * hw(bi) ? '3' : '4');
  }, lib.bbox(poly, 3), true);
  return { butt, tip: T, bladeTip: C[N], grip: add(a.F, mul(bd, GRIP)) };
}

function hand(out, c) {
  out.shape((px, py) => Math.hypot(px - c[0], py - c[1]) <= 3.3, (px, py) => (((px - c[0]) * -0.55 + (py - c[1]) * -0.85) > 0.5 ? '8' : '4'), [c[0] - 5, c[1] - 5, c[0] + 5, c[1] + 5], true);
}

// ---------- decoracion del cuerpo ----------
function deco(out, p) {
  const B = skeleton(p);
  // pañuelo verde al cuello
  {
    const c = add(B.neck, [-1, 2]);
    out.shape(chainTest([add(c, [-4, 0]), add(c, [4, 1])], [2.4, 2.4]), chainColor([add(c, [-4, 0]), add(c, [4, 1])], [2.4, 2.4], 'o', 'n', 'm'), [c[0] - 8, c[1] - 6, c[0] + 8, c[1] + 6], true);
    // cola del pañuelo
    const t = [c[0] - 4, c[1] + 1];
    out.shape(chainTest([t, add(t, [-4 - 3 * (p.capeAmt || 0), 6])], [1.5, 1.0]), chainColor([t, add(t, [-4, 6])], [1.5, 1.0], 'o', 'n', 'm'), [t[0] - 9, t[1] - 3, t[0] + 3, t[1] + 9], true);
  }
  // sombrero de paja de ala ancha
  const h = add(B.headC, [p.hatDx || 0, -5.2 * 1.5 + (p.hatDy || 0)]);
  const brim = (px, py) => ((px - h[0]) / 15.5) ** 2 + ((py - h[1] - 5) / 3.9) ** 2 <= 1;
  const crown = (px, py) => ((px - h[0] - 0.5) / 8.4) ** 2 + ((py - h[1] + 1.5) / 8.0) ** 2 <= 1 && py < h[1] + 6;
  out.shape(brim, (px, py) => (py > h[1] + 6.4 ? '5' : (hash2(px * 0.5 | 0, py) < 0.18 ? '6' : '7')), [h[0] - 18, h[1] - 3, h[0] + 18, h[1] + 14], true);
  out.shape(crown, (px, py) => { const s = ((px - h[0]) * -0.55 + (py - h[1]) * -0.85) / 8; return s > 0.35 ? '7' : (s < -0.4 ? '5' : '6'); }, [h[0] - 11, h[1] - 12, h[0] + 11, h[1] + 8], true);
  // cinta del sombrero y hebras de paja sueltas
  out.line([h[0] - 7.5, h[1] + 2.6], [h[0] + 8.5, h[1] + 2.6], '5');
  out.line([h[0] - 7.5, h[1] + 3.6], [h[0] + 8.5, h[1] + 3.6], '1');
  for (const dx of [-14, -9, 10, 14]) out.line([h[0] + dx, h[1] + 6], [h[0] + dx + (dx < 0 ? -2 : 2), h[1] + 9 + (hash2(dx, 2) * 2 | 0)], '7');
  // ojo hueco (la mirada de quien espera) y arruga del ceño bajo el ala
  const f = add(B.headC, [4.6, 1.2]);
  out.set(Math.floor(f[0]), Math.floor(f[1]), '1'); out.set(Math.floor(f[0]) + 1, Math.floor(f[1]), '1');
  out.set(Math.floor(f[0]), Math.floor(f[1]) + 1, '1');
  // parches y remiendos de la camisa
  const c1 = add(B.chest, [1, 6]);
  out.shape((px, py) => Math.abs(px - c1[0]) <= 2.6 && Math.abs(py - c1[1]) <= 2.4, () => '6', [c1[0] - 4, c1[1] - 4, c1[0] + 4, c1[1] + 4], true);
  out.line(add(B.hip, [-4, -3]), add(B.hip, [4, -3]), '5');
  out.line(add(B.hip, [-4, -4]), add(B.hip, [4, -4]), '2');
}

// ---------- efectos (solo pintan donde esta vacio, nunca tapan al jefe) ----------
function paintBehind(out, test, color, box) {
  for (let y = Math.max(0, Math.floor(box[1])); y <= Math.min(H - 1, Math.ceil(box[3])); y++)
    for (let x = Math.max(0, Math.floor(box[0])); x <= Math.min(W - 1, Math.ceil(box[2])); x++)
      if (out.g[y][x] === '.' && test(x + 0.5, y + 0.5)) { const c = color(x, y); if (c !== '.') out.g[y][x] = c; }
}
// estela de la hoz: cinta que se estrecha hacia atras; el trigo (d, c, 7) se mezcla con el polvo (4, 3)
function trail(out, pts, w, wheat) {
  const n = pts.length;
  const rs = pts.map((_, i) => 0.8 + (w - 0.8) * Math.pow(i / (n - 1), 1.15));
  const xs = pts.map((q) => q[0]), ys = pts.map((q) => q[1]);
  paintBehind(out, chainTest(pts, rs), (x, y) => {
    const r = hash2(x * 0.5 | 0, y * 0.5 | 0);
    if (r < 0.22) return '.';
    if (wheat && r > 0.62) return r > 0.86 ? 'd' : 'c';
    return (x + y) % 4 < 2 ? '4' : '3';
  }, [Math.min(...xs) - w, Math.min(...ys) - w, Math.max(...xs) + w, Math.max(...ys) + w]);
}
function dust(out, gx, tau, str) {
  const hw = Math.min((16 + 22 * tau) * str, 26), hh = (6 + 6 * tau) * str, thin = Math.min(0.85, 0.15 * tau);
  gx = Math.min(gx, W - 3 - hw);
  paintBehind(out, (x, y) => y <= GY + 1 && ((x - gx) / hw) ** 2 + ((y - (GY - hh * 0.4)) / hh) ** 2 <= 1,
    (x, y) => (hash2(x * 0.5 | 0, y * 0.5 | 0) < thin ? '.' : (y < GY - hh * 0.7 ? '4' : '3')), [gx - hw, GY - hh * 1.4, gx + hw, GY]);
  for (let k = 0; k < 7; k++) {
    const x = gx + (hash2(k, 2.2) - 0.5) * 2 * Math.min((12 + 18 * tau) * str, 24), y = GY - 3 - hash2(k, 5.1) * (6 + 8 * tau) * str;
    out.set(Math.floor(x), Math.floor(y), k % 3 === 0 ? 'd' : (k % 2 ? '3' : '4'));
  }
}
// paja y espigas que suben del suelo
function straw(out, cx, spread, rise, n, phase) {
  for (let k = 0; k < n; k++) {
    const fr = fract(phase + k / n + 0.13 * hash2(k, 4));
    const x = cx + (hash2(k, 2.2) - 0.5) * spread + 3 * Math.sin(fr * 6 + k), y = GY - 2 - fr * rise;
    if (fr > 0.94) continue;
    out.set(Math.floor(x), Math.floor(y), fr < 0.4 ? 'd' : (fr < 0.75 ? 'c' : '7'));
    out.set(Math.floor(x), Math.floor(y) + 1, fr < 0.4 ? 'c' : '6');
  }
}
// campo de trigo que crece alrededor de los pies (release); h en 0..1
function wheat(out, h, span) {
  for (let x = OX - span; x <= OX + span; x += 2) {
    const r = hash2(x, 3.3);
    if (r > 0.12 + 0.88 * h) continue;
    const top = GY - (6 + (14 + 28 * r) * h);
    for (let y = Math.floor(top); y <= GY; y++) if (out.g[y][x] === '.') out.set(x, y, y < top + 4 ? 'd' : (y < top + 10 ? 'c' : '7'));
    // espiga
    if (h > 0.3) {
      for (const [dx, dy, c] of [[0, -2, 'd'], [0, -1, 'd'], [1, 0, 'c'], [-1, 0, 'c'], [1, 2, 'c'], [-1, 2, 'c'], [0, 1, 'd']]) { const yy = Math.floor(top) + dy; if (out.g[yy] && out.g[yy][x + dx] === '.') out.set(x + dx, yy, c); }
    }
  }
}

// ---------- poses ----------
const DEF = { hip: [0, -31], lean: 5, bend: 3, head: 3, nf: [11, 0], ff: [-11, 0], nfa: 0, ffa: 0,
  F: [12, 12], ang: -82, bdir: 8, grip: GRIP, len: LEN, bl: BLADE, tipAt: null, hand: true,
  capeTx: -1, capeTy: 0.3, capeAmt: 0.3, capeWave: 0.4, phase: 0, scythe: true, slung: false, sl: [-10, 4], g: null };
function mk(s) {
  const d = Object.assign({}, DEF, s);
  const p = pose({ hipx: d.hip[0], hipy: d.hip[1], lean: d.lean, bend: d.bend, head: d.head,
    nfx: d.nf[0], nfy: d.nf[1], nfa: d.nfa, ffx: d.ff[0], ffy: d.ff[1], ffa: d.ffa,
    capeTx: d.capeTx, capeTy: d.capeTy, capeAmt: d.capeAmt, capeWave: d.capeWave, phase: d.phase });
  p.hatDx = d.hatDx; p.hatDy = d.hatDy;
  const sh = skeleton(p).shoulder;
  const F = d.F;
  // `anchor: 'g'`: la hoz se agarra por la mano de delante (g) y la de atras (F) hace otra cosa
  const anchorRel = () => (d.slung ? d.sl : (d.anchor === 'g' ? d.g : F));
  let ang = d.ang;
  if (d.tipAt) {
    // el extremo del mango se da en pantalla: el angulo y el largo salen de ahi
    const Fa = add(sh, anchorRel()), tp = [OX + d.tipAt[0], OY + d.tipAt[1]];
    ang = Math.atan2(tp[1] - Fa[1], tp[0] - Fa[0]) * 180 / Math.PI;
    d.len = len(sub(tp, Fa)) + BACK;
  }
  const bd = [Math.cos(rad(ang)), Math.sin(rad(ang))];
  const G = d.g || add(F, mul(bd, d.grip));
  if (len(F) > 2 * S.armLen - 0.5) warns.push(LABEL + ': mano de atras fuera de alcance por ' + (len(F) - 2 * S.armLen).toFixed(1));
  if (len(G) > 2 * S.farArmLen - 0.5 && d.scythe && d.hand) warns.push(LABEL + ': mano de delante fuera de alcance por ' + (len(G) - 2 * S.farArmLen).toFixed(1));
  p.fx = F[0]; p.fy = F[1]; p.gx = G[0]; p.gy = G[1];
  p.sc = { d, ang, sh, A: anchorRel(), G };
  return p;
}
const withFx = (p, fn) => {
  p.post = (o) => {
    const { d, ang, sh, A, G } = p.sc;
    deco(o, p);
    let info = null;
    if (d.scythe && d.slung) {
      const layer = new Canvas();
      info = scythe(layer, { F: add(sh, A), ang, bdir: d.bdir, len: d.len, bl: d.bl });
      for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) if (o.g[y][x] === '.' && layer.g[y][x] !== '.') o.g[y][x] = layer.g[y][x];
    } else if (d.scythe) info = scythe(o, { F: add(sh, A), ang, bdir: d.bdir, len: d.len, bl: d.bl });
    if (d.hand && !d.slung) { hand(o, add(sh, d.F)); hand(o, add(sh, G)); }
    if (fn) fn(o, p, info);
  };
  return p;
};
const build = (name, n, fn) => Array.from({ length: n }, (_, i) => { LABEL = name + '_' + i; return fn(i, i / n); });
const keys = (name, list, extra) => list.map((s, i) => { LABEL = name + '_' + i; return withFx(mk(Object.assign({ phase: i * 0.9 }, extra || {}, s))); });
const tw = (t) => 2 * Math.PI * t;
function footCycle(s, A, L) {
  if (s < 0.4) { const k = s / 0.4; return [lerp(-A, A * 1.2, ease(k)), -L * Math.sin(Math.PI * k)]; }
  const k = (s - 0.4) / 0.6; return [lerp(A * 1.2, -A, k), 0];
}

const anims = {};

// idle: respira apoyado en la hoz; 6 fotogramas
anims.idle = { fps: 7, loop: true, frames: build('idle', 6, (i, t) => {
  const a = tw(t), b = Math.sin(a), lag = Math.sin(a - 0.8);
  return withFx(mk({ hip: [0.6 * Math.sin(a - 0.4), -31 + 0.9 * b], lean: 5 + 0.9 * b, bend: 3 + 1.1 * b, head: 3 - 1.4 * lag,
    F: [12, 12 + 0.7 * b], ang: -82 + 1.6 * lag, phase: a, capeAmt: 0.28 + 0.06 * b, capeTy: 0.3 + 0.12 * Math.sin(a - 1) }));
}) };

// walk: paso largo y cansado, la hoz al hombro; 8 fotogramas
anims.walk = { fps: 14, loop: true, frames: build('walk', 8, (i, u) => {
  const nf = footCycle(u % 1, 13, 8), ff = footCycle((u + 0.5) % 1, 13, 8);
  const dn = Math.cos(4 * Math.PI * (u - 0.17)), sw = Math.sin(2 * Math.PI * (u - 0.1));
  return withFx(mk({ hip: [2 + 0.8 * sw, -31 + 1.8 * dn], lean: 9 + 0.8 * dn, bend: 3, head: 2,
    nf: [nf[0], nf[1]], ff: [ff[0], ff[1]], nfa: nf[1] < -3 ? 28 : 0, ffa: ff[1] < -3 ? 28 : 0,
    F: [10 + 1.5 * sw, 12 + 0.8 * dn], ang: -78 + 4 * sw, capeAmt: 0.55, capeTy: 0.2 + 0.15 * dn, phase: 4 * Math.PI * u }));
}) };

// windup_swing: la hoz atras y baja, el cuerpo se carga para segar; 5 fotogramas (se queda en el ultimo)
anims.windup_swing = { fps: 8, loop: false, frames: keys('windup_swing', [
  { },
  { hip: [-1, -31], lean: 2, bend: 1, head: 2, F: [9, 10], ang: -125, bdir: -35 },
  { hip: [-3, -30], lean: -2, bend: -2, nf: [13, 0], ff: [-13, 0], F: [5, 12], ang: -170, bdir: -80, capeAmt: 0.4 },
  { hip: [-5, -29], lean: -6, bend: -3, head: 4, nf: [15, 0], ff: [-15, 0], F: [1, 15], ang: 172, bdir: -100, capeAmt: 0.5 },
  { hip: [-6, -28], lean: -9, bend: -4, head: 5, nf: [16, 0], ff: [-16, 0], F: [-2, 17], ang: 164, bdir: -106, capeAmt: 0.55 },
]) };

// swing_low: siega rasa hacia delante; el fotograma 2 es el IMPACTO (hoja a ras de suelo, delante)
const SWL = [
  { hip: [-6, -28], lean: -9, bend: -4, head: 5, nf: [16, 0], ff: [-16, 0], F: [-2, 17], ang: 164, bdir: -106 },
  { hip: [0, -28], lean: 8, bend: 3, head: 2, nf: [17, 0], ff: [-17, 0], F: [10, 19], ang: 116, bdir: -40 },
  { hip: [7, -27], lean: 24, bend: 7, head: -6, nf: [20, 0], ff: [-18, 0], F: [18, 14], ang: 52, bdir: 2 },
  { hip: [8, -27], lean: 27, bend: 8, head: -8, nf: [21, 0], ff: [-18, 0], F: [20, 15], ang: 44, bdir: 4 },
  { hip: [5, -29], lean: 16, bend: 5, head: -2, nf: [18, 0], ff: [-15, 0], F: [16, 14], ang: 22, bdir: 20 },
];
{
  const ps = SWL.map((s, i) => { LABEL = 'swing_low_' + i; return mk(Object.assign({ phase: i * 0.9, capeAmt: 0.8 }, s)); });
  const tips = ps.map((p) => { const t = scythe(new Canvas(), { F: add(p.sc.sh, p.sc.d.F), ang: p.sc.ang, bdir: p.sc.d.bdir, len: p.sc.d.len, bl: p.sc.d.bl }); return t.bladeTip; });
  ps.forEach((p, i) => withFx(p, (o, _p, info) => {
    if (i >= 1 && i <= 4) trail(o, i >= 2 ? [tips[i - 2 >= 0 ? i - 2 : 0], tips[i - 1], info.bladeTip] : [tips[0], info.bladeTip], i === 2 ? 14 : 11, true);
    if (i >= 2) dust(o, Math.floor(info.bladeTip[0]), i - 2, 0.9);
  }));
  anims.swing_low = { fps: 26, loop: false, frames: ps };
}

// windup_spin: se agacha y la hoz arrastra por el suelo, detras; 5 fotogramas (se queda en el ultimo)
anims.windup_spin = { fps: 8, loop: false, frames: keys('windup_spin', [
  { },
  { hip: [-1, -28], lean: 10, bend: 5, head: 0, nf: [14, 0], ff: [-14, 0], F: [10, 14], ang: 160, bdir: -100 },
  { hip: [-2, -25], lean: 16, bend: 8, head: -3, nf: [17, 0], ff: [-17, 0], F: [7, 19], ang: 167, bdir: -104 },
  { hip: [-3, -22], lean: 22, bend: 10, head: -5, nf: [19, 0], ff: [-19, 0], F: [4, 23], ang: 172, bdir: -108 },
  { hip: [-3, -21], lean: 24, bend: 11, head: -6, nf: [20, 0], ff: [-20, 0], F: [3, 24], ang: 174, bdir: -110, capeAmt: 0.6 },
], { }) };

// spin: la vuelta entera con la hoz a ras (vista de lado: la punta recorre una elipse); 8 fotogramas, un giro
{
  const R = 80, RY = 11, CY = -30;
  const tipAtTheta = (th) => [8 + R * Math.cos(th), CY + RY * Math.sin(th)];
  const frames = build('spin', 8, (i, t) => {
    const th = tw(t) + 0.3;
    const near = Math.sin(th) > 0; // la punta pasa por delante del cuerpo (hacia el espectador)
    return mk({ hip: [0, -23], lean: 14, bend: 7, head: -3, nf: [19, 0], ff: [-19, 0], phase: i * 0.8, capeAmt: 0.9,
      F: [8 + 4 * Math.cos(th), 16 + 2 * Math.sin(th)], tipAt: tipAtTheta(th), bdir: (Math.atan2(RY * Math.cos(th), -R * Math.sin(th)) * 180 / Math.PI), bl: 14 + 17 * Math.abs(Math.sin(th)), spinT: th, near });
  });
  frames.forEach((p, i) => withFx(p, (o, _p, info) => {
    // la estela de trigo sigue a la punta a lo largo de la elipse
    const th = p.sc.d.spinT;
    const pts = [];
    for (let k = 7; k >= 0; k--) { const a = th - k * 0.2; pts.push([OX + tipAtTheta(a)[0], OY + tipAtTheta(a)[1]]); }
    trail(o, pts, 9, true);
    void info;
  }));
  anims.spin = { fps: 16, loop: true, frames };
}

// step_slash: da un paso largo y siega; el fotograma 3 es el IMPACTO; 6 fotogramas
{
  const ps = keys('step_slash', [
    { hip: [-6, -28], lean: -9, bend: -4, head: 5, nf: [16, 0], ff: [-16, 0], F: [-2, 17], ang: 164, bdir: -106 },
    { hip: [-1, -28], lean: 5, bend: 2, head: 2, nf: [22, -1], ff: [-17, 0], F: [8, 18], ang: 128, bdir: -52 },
    { hip: [8, -27], lean: 17, bend: 5, head: -3, nf: [28, 0], ff: [-21, -3], ffa: 40, F: [15, 17], ang: 84, bdir: -6 },
    { hip: [11, -26], lean: 24, bend: 8, head: -8, nf: [30, 0], ff: [-24, -5], ffa: 60, F: [20, 14], ang: 40, bdir: 4 },
    { hip: [10, -26], lean: 25, bend: 9, head: -9, nf: [30, 0], ff: [-22, -3], ffa: 40, F: [20, 14], ang: 38, bdir: 8 },
    { hip: [9, -28], lean: 18, bend: 6, head: -3, nf: [27, 0], ff: [-14, 0], F: [17, 14], ang: 14, bdir: 22 },
  ], { capeAmt: 0.9 });
  const tips = ps.map((p) => scythe(new Canvas(), { F: add(p.sc.sh, p.sc.d.F), ang: p.sc.ang, bdir: p.sc.d.bdir, len: p.sc.d.len, bl: p.sc.d.bl }).bladeTip);
  ps.forEach((p, i) => withFx(p, (o, _p, info) => {
    if (i >= 1 && i <= 4) trail(o, i >= 2 ? [tips[i - 2], tips[i - 1], info.bladeTip] : [tips[0], info.bladeTip], i >= 3 ? 15 : 11, true);
    if (i >= 3) dust(o, Math.floor(info.bladeTip[0] - 6), i - 3, 0.9);
  }));
  anims.step_slash = { fps: 24, loop: false, frames: ps };
}

// windup_throw: levanta la hoz sobre la cabeza con las dos manos; 4 fotogramas (se queda en el ultimo)
anims.windup_throw = { fps: 7, loop: false, frames: keys('windup_throw', [
  { },
  { hip: [-1, -31], lean: 1, bend: 0, head: 4, F: [8, -3], ang: -115, bdir: -25 },
  { hip: [-3, -30], lean: -4, bend: -2, head: 8, nf: [13, 0], ff: [-13, 0], F: [5, -17], ang: -128, bdir: -38, capeAmt: 0.45 },
  { hip: [-4, -30], lean: -8, bend: -3, head: 10, nf: [14, 0], ff: [-14, 0], F: [3, -22], ang: -140, bdir: -50, capeAmt: 0.5 },
]) };

// throw: suelta la hoz hacia delante; queda con las manos vacias (el ultimo fotograma se mantiene); 3 fotogramas
anims.throw = { fps: 22, loop: false, frames: keys('throw', [
  { hip: [-2, -30], lean: -6, bend: -2, head: 8, nf: [14, 0], ff: [-14, 0], F: [4, -22], ang: -120, bdir: -30, capeAmt: 0.6 },
  { hip: [5, -29], lean: 14, bend: 4, head: -2, nf: [20, 0], ff: [-14, 0], F: [22, -6], ang: -40, bdir: 50, capeAmt: 0.9, scythe: false, g: [19, 0] },
  { hip: [8, -28], lean: 20, bend: 6, head: -4, nf: [22, 0], ff: [-15, 0], F: [24, 0], scythe: false, g: [21, 5], capeAmt: 0.8 },
]) };

// catch: tiende las manos y recoge la hoz que vuelve; 4 fotogramas
anims.catch = { fps: 12, loop: false, frames: keys('catch', [
  { hip: [6, -29], lean: 16, bend: 5, head: -2, nf: [20, 0], ff: [-14, 0], F: [21, -3], scythe: false, g: [19, 2] },
  { hip: [5, -29], lean: 14, bend: 4, head: -2, nf: [20, 0], ff: [-14, 0], F: [21, -4], scythe: false, g: [20, 1] },
  { hip: [4, -30], lean: 12, bend: 4, head: 0, nf: [18, 0], ff: [-13, 0], F: [18, 2], ang: 8, bdir: 100, bl: 28 },
  { hip: [2, -30], lean: 8, bend: 3, head: 2, nf: [14, 0], ff: [-12, 0], F: [14, 8], ang: -50, bdir: 40 },
], { capeAmt: 0.6 }) };

// climb: trepa por el muro (a su derecha); la hoz a la espalda; 6 fotogramas en bucle
anims.climb = { fps: 11, loop: true, frames: build('climb', 6, (i, u) => {
  const a = tw(u), s = Math.sin(a), c = Math.cos(a);
  return withFx(mk({ hip: [6, -34 + 1.2 * c], lean: 4, bend: 2, head: -10, nf: [18, -20 - 6 * s], nfa: 75, ff: [16, -8 + 6 * s], ffa: 75,
    F: [15, -22 - 6 * c], g: [14, -10 + 10 * s], ang: -125, bdir: -70, hand: false, slung: true, capeAmt: 0.2, capeTx: -0.5, capeTy: 1, phase: a, hatDy: 1 }), (o, p) => {
    const sh = p.sc.sh;
    hand(o, add(sh, p.sc.d.F)); hand(o, add(sh, p.sc.d.g));
  });
}) };

// wall_hold: agarrado al muro, encogido, listo para impulsarse; 2 fotogramas en bucle
anims.wall_hold = { fps: 3, loop: true, frames: build('wall_hold', 2, (i) => {
  const b = i ? 0.8 : 0;
  return withFx(mk({ hip: [6, -30 + b], lean: 8, bend: 4, head: -6, nf: [19, -16], nfa: 75, ff: [19, -3], ffa: 75,
    F: [17, -20], g: [15, -11], ang: -125, bdir: -70, hand: false, slung: true, capeAmt: 0.2, capeTx: -0.5, capeTy: 1, phase: i * 2 }), (o, p) => {
    const sh = p.sc.sh;
    hand(o, add(sh, p.sc.d.F)); hand(o, add(sh, p.sc.d.g));
  });
}) };

// dive: se lanza del muro y cae con la hoz por delante; 4 fotogramas (se queda en el ultimo)
anims.dive = { fps: 14, loop: false, frames: keys('dive', [
  { hip: [4, -34], lean: 12, bend: 4, head: -8, nf: [8, -14], nfa: 40, ff: [-4, -8], ffa: 40, F: [14, -14], ang: -30, bdir: 60, capeAmt: 0.9, capeTy: -0.6, capeTx: -0.4 },
  { hip: [5, -34], lean: 28, bend: 8, head: -14, nf: [-6, -16], nfa: 30, ff: [-18, -10], ffa: 30, F: [18, -6], ang: 12, bdir: 100, capeAmt: 1, capeTy: -0.9, capeTx: -0.2 },
  { hip: [6, -33], lean: 38, bend: 10, head: -18, nf: [-10, -14], nfa: 20, ff: [-24, -8], ffa: 20, F: [19, 2], ang: 62, bdir: 150, capeAmt: 1, capeTy: -1, capeTx: 0 },
  { hip: [4, -30], lean: 36, bend: 10, head: -16, nf: [-8, -8], nfa: 10, ff: [-20, -4], ffa: 10, F: [20, 6], ang: 75, bdir: 160, capeAmt: 1, capeTy: -1, capeTx: 0 },
]) };

// summon: alza la hoz con las dos manos y llama a los espantapajaros; la paja sube del suelo; 6 fotogramas (se queda en el ultimo)
anims.summon = { fps: 6, loop: false, frames: build('summon', 6, (i) => {
  const up = clamp(i / 3, 0, 1), e = ease(up);
  return withFx(mk({ hip: [-1 * e, -31 + 1 * e], lean: 5 - 11 * e, bend: 3 - 5 * e, head: 3 + 14 * e, nf: [11 + 3 * e, 0], ff: [-11 - 3 * e, 0],
    F: [12 - 8 * e, 12 - 36 * e], ang: -82 - 10 * e, bdir: 8 - 12 * e, capeAmt: 0.3 + 0.5 * e, capeTy: 0.3 + 0.5 * e, phase: i * 1.1 }), (o) => {
    if (i >= 1) straw(o, OX + 46, 70, 26 + 8 * i, 6 + 2 * i, i * 0.17);
    if (i >= 2) straw(o, OX + 8, 40, 20, 5, i * 0.31 + 0.4);
  });
}) };

// stagger: de rodillas, apoyado en la hoz plantada, jadeando (parry o tras soltar la hoz); 4 fotogramas en bucle
anims.stagger = { fps: 6, loop: true, frames: build('stagger', 4, (i, t) => {
  const b = Math.sin(tw(t));
  return withFx(mk({ hip: [-4, -20 + 0.9 * b], lean: 18 + 1.2 * b, bend: 10 + 1.2 * b, head: -16 - 1.5 * b, nf: [24, 0], ff: [-16, -2], ffa: 78,
    F: [18, 18 + 0.8 * b], ang: -74, bdir: 0, capeAmt: 0.35, capeTx: -1, capeTy: 0.6, phase: tw(t), hatDy: 1 }), (o, p) => {
    void p;
    if (i === 2) { out_motes(o, OX - 30, GY - 62); }
  });
}) };
function out_motes(o, x, y) { for (const [dx, dy] of [[0, 0], [5, -4], [-4, -7]]) o.set(Math.floor(x + dx), Math.floor(y + dy), 'h'); }

// death: se encorva, la hoz baja hasta rozar el suelo y la cabeza cae; queda de pie, vencido; 6 fotogramas (se queda en el ultimo)
anims.death = { fps: 6, loop: false, frames: keys('death', [
  { hip: [-2, -30], lean: 8, bend: 5, head: -2, F: [14, 14], ang: -76, bdir: 6 },
  { hip: [-3, -28], lean: 13, bend: 8, head: -8, F: [15, 17], ang: -56, bdir: 20 },
  { hip: [-3, -26], lean: 18, bend: 11, head: -14, F: [14, 21], ang: -28, bdir: 40 },
  { hip: [-2, -26], lean: 20, bend: 12, head: -20, F: [13, 24], ang: 8, bdir: 70 },
  { hip: [-1, -27], lean: 16, bend: 10, head: -22, F: [12, 25], ang: 38, bdir: 110 },
  { hip: [0, -29], lean: 12, bend: 8, head: -22, F: [10, 24], ang: 62, bdir: 150 },
], { capeAmt: 0.25, capeTy: 0.6 }) };

// release: se acerca al muro (a su derecha), apoya la mano en el, y el campo se llena de trigo un instante; 8 fotogramas
anims.release = { fps: 5, loop: false, frames: build('release', 8, (i) => {
  const e = ease(clamp(i / 3, 0, 1)), h = clamp((i - 2) / 4, 0, 1);
  return withFx(mk({ hip: [4 + 6 * e, -31], lean: 8 + 4 * e, bend: 4 + 2 * e, head: -14 + 18 * e, nf: [12, 0], ff: [-10, 0],
    F: [24 * e + 10 * (1 - e), 12 - 22 * e], g: [12, 22], anchor: 'g', ang: 78, bdir: 140, capeAmt: 0.25, capeTy: 0.5, phase: i, hatDy: 0 }), (o, p, info) => {
    void p; void info;
    wheat(o, h, 70);
    if (i >= 4) straw(o, OX + 8, 120, 40, 8, i * 0.2);
  });
}) };

// ---------- salida ----------
const order = ['idle', 'walk', 'windup_swing', 'swing_low', 'windup_spin', 'spin', 'step_slash', 'windup_throw', 'throw', 'catch', 'climb', 'wall_hold', 'dive', 'summon', 'stagger', 'death', 'release'];
const header = [
  '# Jacinto, el Ultimo Segador: campesino de los bancales, alto y flaco, con sombrero de paja y una hoz de',
  '# mango largo. Sigue segando un campo vacio porque su mujer y su hijo iban a venir a comer.',
  '# Cada fotograma es un lienzo completo de ' + W + 'x' + H + ' con los pies en la fila de abajo.',
  '# Lo genera tools/rig_jacinto.js (esqueleto de tools/rig_lib.js); para cambiar el movimiento se',
  '# edita el esqueleto y se regenera, no estos fotogramas a mano.',
  '# Leyenda: ver art/palette.txt. El punto (.) es transparente.'];
for (const name of order) anims[name].frames.forEach((p, i) => {
  const r = lib.render(p, S);
  const top = r.g[0].some((c) => c !== '.'), left = r.g.some((row) => row[0] !== '.'), right = r.g.some((row) => row[W - 1] !== '.');
  if (top || left || right) warns.push(name + '_' + i + ': toca el borde del lienzo (' + [top ? 'arriba' : '', left ? 'izquierda' : '', right ? 'derecha' : ''].filter(Boolean).join(', ') + ')');
});
for (const w of warns) console.error('AVISO ' + w);
const info = lib.writeSprite('art/source/jacinto.sprite', header, 'res://game/boss/jacinto_sheet.png', order, anims, S);
console.log(JSON.stringify(info));

// ---------- la hoz lanzada: 8 fotogramas girando (72x72, centro en el medio) ----------
{
  const fs = require('fs');
  lib.setCanvas(72, 72);
  const NL = String.fromCharCode(10);
  let parts = '', frames = '';
  for (let k = 0; k < 8; k++) {
    const out = new Canvas();
    const ang = -90 + k * 45;
    const bd = [Math.cos(rad(ang)), Math.sin(rad(ang))];
    scythe(out, { F: add([36, 36], mul(bd, 4)), ang, bdir: ang + 90, len: 44, bl: 19 });
    parts += 'part hoz_' + k + NL + out.g.map((row) => row.join('')).join(NL) + NL + NL;
    frames += 'frame hoz_' + k + NL;
  }
  const head = ['# La hoz de Jacinto lanzada (boomerang): gira sobre si misma. La genera tools/rig_jacinto.js.', '# Leyenda: ver art/palette.txt.'];
  fs.writeFileSync('art/source/hoz.sprite', head.join(NL) + NL + NL + 'sheet 72x72' + NL + 'out res://game/boss/hoz_sheet.png' + NL + NL + parts + 'anim spin' + NL + frames);
}
