// Generador de los objetos de habilidad: tres reliquias de recuerdo cristalizado.
//   fila 0 = Dash        remolino de viento azul con cheurones que avanzan
//   fila 1 = Doble salto  ala de luz (tres plumas) con chispas que ascienden
//   fila 2 = Salto pared  mano espectral ambar-verdosa aferrada a un fragmento de piedra
// Todas: lienzo 48x48, 8 fotogramas en bucle, nucleo luminoso, anillo de runas que
// gira y chispas. La luz difusa (halo, charco, motas) es de la escena, no del sprite.
// Uso: node tools/arte_habilidades.js   (escribe art/source/habilidades.sprite)
// Despues: godot --headless --path . --script res://tools/build_sprites.gd
const fs = require('fs');
const path = require('path');

const W = 48, H = 48, FRAMES = 8, CX = 24, CY = 24;
const TAU = Math.PI * 2;
const hash = (a, b, c = 0) => { const x = Math.sin(a * 127.1 + b * 311.7 + c * 74.7) * 43758.5453; return x - Math.floor(x); };
const grid = () => Array.from({ length: H }, () => Array(W).fill('.'));
const put = (g, x, y, c) => { x = Math.round(x); y = Math.round(y); if (x >= 0 && y >= 0 && x < W && y < H) g[y][x] = c; };
const get = (g, x, y) => (x >= 0 && y >= 0 && x < W && y < H) ? g[y][x] : '.';
const disc = (g, x, y, r, c, onlyEmpty = false) => {
  for (let j = Math.floor(y - r); j <= Math.ceil(y + r); j++) for (let i = Math.floor(x - r); i <= Math.ceil(x + r); i++) {
    if (Math.hypot(i - x, j - y) <= r + 0.01 && (!onlyEmpty || get(g, i, j) === '.')) put(g, i, j, c);
  }
};
const line = (g, x0, y0, x1, y1, r, c) => {
  const n = Math.ceil(Math.hypot(x1 - x0, y1 - y0) * 2) + 1;
  for (let k = 0; k <= n; k++) disc(g, x0 + (x1 - x0) * k / n, y0 + (y1 - y0) * k / n, r, c);
};
const bez = (p0, p1, p2, t) => [
  (1 - t) * (1 - t) * p0[0] + 2 * (1 - t) * t * p1[0] + t * t * p2[0],
  (1 - t) * (1 - t) * p0[1] + 2 * (1 - t) * t * p1[1] + t * t * p2[1]];
// angulo mas corto entre dos angulos
const angd = (a, b) => { let d = (a - b) % TAU; if (d < -Math.PI) d += TAU; if (d > Math.PI) d -= TAU; return Math.abs(d); };

// Anillo de runas: 8 marcas que giran 90 grados por bucle (la paridad se conserva) y
// un cometa de luz que da una vuelta completa por bucle. `ramp` = [apagado .. brillante].
function runeRing(g, f, r, ramp) {
  for (let k = 0; k < 48; k++) { // puntos tenues de fondo
    const a = k / 48 * TAU;
    if (k % 2 === 0 && get(g, Math.round(CX + Math.cos(a) * r), Math.round(CY + Math.sin(a) * r)) === '.') put(g, CX + Math.cos(a) * r, CY + Math.sin(a) * r, ramp[0]);
  }
  const head = -f / FRAMES * TAU;
  for (let i = 0; i < 8; i++) {
    const a = i / 8 * TAU + f / FRAMES * (TAU / 4);
    const d = angd(a, head) / Math.PI; // 0..1
    const lvl = d < 0.12 ? 3 : d < 0.3 ? 2 : d < 0.55 ? 1 : 0;
    const c = ramp[Math.max(1, lvl)];
    const ux = Math.cos(a), uy = Math.sin(a), tx = -uy, ty = ux;
    const mx = CX + ux * r, my = CY + uy * r;
    if (i % 2 === 0) { // marca radial: runa tipo "trazo"
      for (const k of [-1.5, -0.5, 0.5, 1.5]) put(g, mx + ux * k, my + uy * k, c);
      put(g, mx + tx * 1.4, my + ty * 1.4, ramp[Math.max(0, lvl - 1)]);
    } else { // marca tangencial: runa tipo "cruz"
      for (const k of [-1.2, 0, 1.2]) put(g, mx + tx * k, my + ty * k, c);
      put(g, mx + ux * 1.2, my + uy * 1.2, ramp[Math.max(0, lvl - 1)]);
    }
  }
}

// Orbe luminoso con degradado hacia el centro.
function orb(g, x, y, r, cols) { // cols: [borde, medio, claro, centro]
  for (let j = Math.floor(y - r - 1); j <= Math.ceil(y + r + 1); j++) for (let i = Math.floor(x - r - 1); i <= Math.ceil(x + r + 1); i++) {
    const d = Math.hypot(i - x, j - y) / r;
    if (d > 1.05) continue;
    put(g, i, j, d > 0.8 ? cols[0] : d > 0.55 ? cols[1] : d > 0.28 ? cols[2] : cols[3]);
  }
}

// ---------------------------------------------------------------- DASH
function frameDash(f) {
  const g = grid();
  // estelas horizontales que corren hacia la derecha
  const streaks = [[13, 0, 9], [19, 17, 7], [30, 9, 10], [36, 25, 8]];
  for (const [y, off, len] of streaks) {
    const x0 = 3 + ((off + 5 * f) % 40);
    for (let k = 0; k < len; k++) {
      const x = x0 + k; if (x > 44) continue;
      const c = k > len - 3 ? 'g' : k > len - 6 ? 'f' : 'e';
      if (Math.hypot(x - CX, y - CY) > 8) put(g, x, y, c);
    }
  }
  // brazos del remolino: espiral de 3 brazos, giro de 120 grados por bucle
  for (let arm = 0; arm < 3; arm++) {
    const th0 = arm * TAU / 3 - f / FRAMES * (TAU / 3);
    for (let s = 0; s <= 1; s += 0.008) {
      const r = 4 + s * 15.5;
      const th = th0 + s * 3.4;
      const x = CX + Math.cos(th) * r, y = CY + Math.sin(th) * r * 0.92;
      const w = 2.2 * (1 - s) + 0.55;
      const c = s < 0.22 ? 'h' : s < 0.5 ? 'g' : s < 0.78 ? 'f' : 'e';
      disc(g, x, y, w, c);
    }
    // filo claro en el borde interior del brazo
    for (let s = 0.05; s <= 0.6; s += 0.012) {
      const r = 4 + s * 15.5, th = th0 + s * 3.4 - 0.18 * (1 - s);
      put(g, CX + Math.cos(th) * r, CY + Math.sin(th) * r * 0.92, s < 0.35 ? 'h' : 'g');
    }
  }
  // cheurones ">" que avanzan por el centro (periodo 16 px, 2 px por fotograma)
  for (const j of [-1, 0, 1]) {
    const xc = CX + 16 * j + 2 * f - 4;
    const d = Math.abs(xc - CX);
    if (d > 18) continue;
    const c = d < 8 ? 'h' : d < 13 ? 'g' : 'f';
    for (let dy = -6; dy <= 6; dy++) {
      const x = xc - Math.abs(dy) * 0.9, y = CY + dy;
      if (Math.hypot(x - CX, y - CY) > 19 || Math.hypot(x - CX, y - CY) < 4.5) continue;
      put(g, x, y, c); put(g, x - 1, y, c === 'h' ? 'g' : 'f');
    }
  }
  // nucleo
  const pulse = [0, 0.3, 0.6, 0.3, 0, 0.3, 0.6, 0.3][f];
  orb(g, CX, CY, 4.4 + pulse, ['f', 'g', 'h', 'h']);
  put(g, CX - 1, CY - 1, 'h'); put(g, CX, CY, 'h');
  // chispas que se desprenden del remolino
  for (let k = 0; k < 6; k++) {
    const ph = (f + k * 1.33) % 8 / 8;
    const th = k * 1.1 + 0.9;
    const r = 6 + ph * 16;
    const x = CX + Math.cos(th + ph * 2.4) * r, y = CY + Math.sin(th + ph * 2.4) * r * 0.92;
    put(g, x, y, ph < 0.4 ? 'h' : ph < 0.75 ? 'g' : 'f');
  }
  runeRing(g, f, 21, ['e', 'f', 'g', 'h']);
  return g;
}

// ---------------------------------------------------------------- DOBLE SALTO
function feather(g, p0, p1, p2, hwMax, f, tones, flap) {
  for (let t = 0; t <= 1; t += 0.003) {
    const [x, y] = bez(p0, p1, p2, t);
    const [x2, y2] = bez(p0, p1, p2, Math.min(1, t + 0.01));
    let dx = x2 - x, dy = y2 - y; const l = Math.hypot(dx, dy) || 1; dx /= l; dy /= l;
    const nx = -dy, ny = dx;
    const hw = hwMax * Math.pow(Math.sin(Math.PI * Math.min(1, t * 1.02 + 0.02)), 0.75) * (1 + flap * 0.1) * (t > 0.9 ? 0.8 : 1);
    for (let u = -hw; u <= hw; u += 0.3) {
      const au = Math.abs(u) / (hw || 1);
      let c;
      if (Math.abs(u) < 0.5) c = tones[3];
      else {
        const stripe = Math.floor(t * 16 - Math.abs(u) * 0.45) % 2 === 0;
        c = au > 0.9 ? tones[0] : au > 0.62 ? (stripe ? tones[1] : tones[0]) : (stripe ? tones[2] : tones[1]);
        if (u < 0 && au < 0.6 && stripe) c = tones[3];
      }
      put(g, x + nx * u, y + ny * u, c);
    }
  }
}
function frameDoble(f) {
  const g = grid();
  const flap = Math.sin(f / FRAMES * TAU);
  const bob = Math.round(flap * 0.8);
  const by = 40 + bob;
  feather(g, [19, by], [11, 30], [7, 21 + bob], 4.2, f, ['e', 'f', 'g', 'h'], -flap);
  feather(g, [20, by], [13, 22], [13, 10 + bob], 5.2, f, ['e', 'f', 'g', 'h'], flap);
  feather(g, [21, by], [22, 20], [31, 6 + bob], 7, f, ['e', 'f', 'g', 'h'], flap);
  // nucleo en la base de las plumas
  const pulse = [0, 0.3, 0.6, 0.3, 0, 0.3, 0.6, 0.3][f];
  orb(g, 21, by - 2, 3.6 + pulse, ['f', 'g', 'h', 'h']);
  // dos rafagas de chispas que ascienden (una cada 4 fotogramas)
  const offs = [-9, -4, 2, 7, 11, -1];
  for (let b = 0; b < 2; b++) {
    const k = (f - 4 * b + 8) % 8;
    if (k > 5) continue;
    for (let i = 0; i < offs.length; i++) {
      const x = 22 + offs[i] + (b ? 3 : 0) + Math.round(Math.sin(i * 2 + k) * 1.2);
      const y = 39 - k * (3 + (i % 3)) - (i % 2) * 2;
      if (y < 1) continue;
      const c = k < 2 ? 'h' : k < 4 ? 'g' : k < 5 ? 'f' : 'e';
      put(g, x, y, c);
      if (k < 3 && i % 2 === 0) { put(g, x, y - 1, 'g'); put(g, x, y + 1, 'f'); }
    }
  }
  runeRing(g, f, 22, ['e', 'f', 'g', 'h']);
  return g;
}

// ---------------------------------------------------------------- SALTO DE PARED
function polyFill(pts, fn) {
  let minY = Infinity, maxY = -Infinity;
  for (const [, y] of pts) { minY = Math.min(minY, y); maxY = Math.max(maxY, y); }
  for (let y = minY; y <= maxY; y++) {
    const xs = [];
    for (let i = 0; i < pts.length; i++) {
      const [x0, y0] = pts[i], [x1, y1] = pts[(i + 1) % pts.length];
      if ((y0 <= y && y1 > y) || (y1 <= y && y0 > y)) xs.push(x0 + (y - y0) * (x1 - x0) / (y1 - y0));
    }
    xs.sort((a, b) => a - b);
    for (let k = 0; k + 1 < xs.length; k += 2) for (let x = Math.ceil(xs[k]); x <= Math.floor(xs[k + 1]); x++) fn(x, y);
  }
}
const STONE = [[12, 31], [14, 25], [21, 22], [30, 23], [36, 27], [37, 35], [32, 41], [20, 42], [14, 39]];
const RUNE = ['..#..', '.###.', '#.#.#', '..#..', '.#.#.', '#...#'];
const stoneMask = new Set();
const stoneBase = grid();
polyFill(STONE, (x, y) => {
  let t = 3;
  if (x - 12 + (y - 22) * 0.5 > 22) t = 2; // sombra abajo a la derecha
  else if (x < 20 && y < 33) t = 4;
  const h = hash(x, y, 5);
  if (h < 0.08) t -= 1; else if (h > 0.96) t += 1;
  put(stoneBase, x, y, String(Math.max(2, Math.min(4, t))));
  stoneMask.add(y * W + x);
});
// grietas y musgo del fragmento
for (const [x, y] of [[29, 26], [30, 28], [30, 30], [31, 32], [24, 38], [25, 40], [17, 33], [16, 35]]) put(stoneBase, x, y, '1');
for (const [x, y] of [[15, 27], [16, 26], [17, 25], [18, 24], [15, 28], [16, 28], [31, 41], [30, 40]]) { if (stoneMask.has(y * W + x)) put(stoneBase, x, y, hash(x, y) < 0.5 ? 'o' : 'n'); }
for (const [x, y] of [[16, 27], [17, 26], [14, 29]]) if (stoneMask.has(y * W + x)) put(stoneBase, x, y, 'p');

const RAMP_AMBER = ['a', 'b', 'c', 'd'];
const level = (f, ph) => Math.max(0, Math.min(3, Math.round(1.4 + 1.6 * Math.sin(TAU * (f / FRAMES - ph)))));

function frameMano(f) {
  const g = grid();
  const bob = [0, 0, -1, -1, -1, 0, 0, 0][f];
  const tight = Math.sin(f / FRAMES * TAU) * 0.5 + 0.5; // 0 abierto .. 1 cerrado
  const sy = bob; // la piedra y la mano flotan juntas; el sprite entero se mueve en la escena
  // piedra
  for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) if (stoneBase[y][x] !== '.') put(g, x, y, stoneBase[y][x]);
  // runa grabada que late
  const L = level(f, 0);
  for (let j = 0; j < RUNE.length; j++) for (let i = 0; i < 5; i++) if (RUNE[j][i] === '#') put(g, 21 + i, 28 + j, RAMP_AMBER[L]);
  if (L >= 2) for (let j = -1; j <= 6; j++) for (let i = -1; i <= 5; i++) {
    const x = 21 + i, y = 28 + j;
    if (!stoneMask.has(y * W + x) || !'1234'.includes(get(g, x, y))) continue;
    const near = [[1, 0], [-1, 0], [0, 1], [0, -1]].some(([dx, dy]) => { const jj = j + dy, ii = i + dx; return jj >= 0 && jj < 6 && ii >= 0 && ii < 5 && RUNE[jj][ii] === '#'; });
    if (near) put(g, x, y, L === 3 ? 'b' : 'a');
  }
  // mano espectral: muneca que se deshace hacia arriba a la derecha, palma y cuatro dedos
  const hand = grid();
  const palmY = 14;
  // palma
  for (let j = -4; j <= 4; j++) for (let i = -7; i <= 7; i++) {
    if ((i / 7) ** 2 + (j / 3.6) ** 2 <= 1) put(hand, 28 + i, palmY + j, 'n');
  }
  // muneca
  line(hand, 33, 12, 40, 5, 2.4, 'n');
  // dedos: nudillo -> falange -> garra hundida en la piedra
  const fingers = [
    { b: [22, 14], k: [19, 18], t: [17, 25] },
    { b: [26, 15], k: [24, 20], t: [22, 27] },
    { b: [30, 15], k: [30, 20], t: [30, 27] },
    { b: [34, 14], k: [36, 19], t: [37, 25] },
  ];
  fingers.forEach((fg, idx) => {
    const sh = Math.round(tight * (idx < 2 ? 1 : -1) * 0.8);
    const dy = Math.round(tight * 1.2);
    const k = [fg.k[0] + sh, fg.k[1]], t = [fg.t[0] + sh, fg.t[1] + dy];
    line(hand, fg.b[0], fg.b[1], k[0], k[1], 1.25, 'n');
    line(hand, k[0], k[1], t[0], t[1], 1.1, 'n');
    fg.kk = k; fg.tt = t;
  });
  // pulgar que abraza el lado izquierdo del fragmento
  const thumbDy = Math.round(tight);
  line(hand, 21, 15, 15, 20, 1.4, 'n');
  line(hand, 15, 20, 13, 28 + thumbDy, 1.2, 'n');
  // luz: el borde superior-izquierdo de cada parte se aclara
  const lit = grid();
  for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) {
    if (hand[y][x] === '.') continue;
    const up = get(hand, x, y - 1) === '.', left = get(hand, x - 1, y) === '.';
    lit[y][x] = (up || left) ? 'o' : (get(hand, x + 1, y) === '.' || get(hand, x, y + 1) === '.') ? 'm' : 'n';
  }
  // volcar la mano sobre la piedra con su contorno
  for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) if (lit[y][x] !== '.') put(g, x, y, lit[y][x]);
  // brillos ambar en nudillos y garras (el recuerdo se filtra por la mano)
  for (const fg of fingers) { put(g, fg.kk[0] - 1, fg.kk[1], 'p'); put(g, fg.tt[0], fg.tt[1], 'd'); put(g, fg.tt[0], fg.tt[1] - 1, 'c'); }
  put(g, 14, 29 + thumbDy, 'd');
  // venas de luz en la palma
  for (let i = 0; i < 5; i++) put(g, 23 + i * 2, palmY - 1 + (i % 2), (i + f) % 4 === 0 ? 'd' : 'p');
  // contorno oscuro externo de todo el conjunto
  const outline = [];
  for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) {
    if (g[y][x] !== '.') continue;
    if ([[1, 0], [-1, 0], [0, 1], [0, -1]].some(([dx, dy]) => { const c = get(g, x + dx, y + dy); return c !== '.'; })) outline.push([x, y]);
  }
  for (const [x, y] of outline) {
    const nearHand = [[1, 0], [-1, 0], [0, 1], [0, -1]].some(([dx, dy]) => 'mnop'.includes(get(g, x + dx, y + dy)));
    put(g, x, y, nearHand ? 'm' : '1');
  }
  // la muneca se deshace en jirones que suben
  for (let k = 0; k < 6; k++) {
    const ph = (f + k * 1.4) % 8 / 8;
    const x = 41 + Math.round(Math.sin(k * 2.1 + ph * 5) * 2) - Math.round(ph * 2);
    const y = 5 - Math.round(ph * 6) + (k % 2);
    if (y < 0) continue;
    put(g, x, y, ph < 0.35 ? 'p' : ph < 0.7 ? 'o' : 'n');
  }
  // chispas ambar que suben de la runa
  for (let k = 0; k < 4; k++) {
    const ph = (f + k * 2) % 8 / 8;
    const x = 22 + k * 3 + Math.round(Math.sin(k + ph * 6) * 1.2);
    const y = Math.round(32 - ph * 30);
    if (y < 1 || get(g, x, y) !== '.') continue;
    put(g, x, y, ph < 0.4 ? 'd' : ph < 0.75 ? 'c' : 'b');
  }
  runeRing(g, f, 22, ['a', 'b', 'c', 'd']);
  return g;
}

// ---------------------------------------------------------------- salida
const NL = String.fromCharCode(10);
const out = [];
out.push('# Generado por tools/arte_habilidades.js: no editar a mano (editar el generador).');
out.push('# Objetos de habilidad: dash (viento azul), doble salto (ala de luz), salto de pared (mano espectral).');
out.push(`sheet ${W}x${H}`);
out.push('out res://game/ability_pickup/ability_sheet.png');
const anims = [['dash', frameDash], ['double_jump', frameDoble], ['wall_jump', frameMano]];
for (const [name, fn] of anims) {
  for (let f = 0; f < FRAMES; f++) {
    out.push(`part ${name}${f}`);
    for (const row of fn(f)) out.push(row.join(''));
  }
}
for (const [name] of anims) {
  out.push(`anim ${name}`);
  for (let f = 0; f < FRAMES; f++) out.push(`frame ${name}${f}`);
}
fs.writeFileSync(path.join(__dirname, '..', 'art', 'source', 'habilidades.sprite'), out.join(NL) + NL);
console.log('art/source/habilidades.sprite escrito');
