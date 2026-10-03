// Generador del Ancla de Memoria: un monumento de piedra antigua, partido y
// cubierto de musgo, que sostiene un cristal azul con una llama ambar dentro.
// Las runas grabadas pulsan y el cristal parpadea (8 fotogramas en bucle).
// Uso: node tools/arte_ancla.js   (escribe art/source/anchor.sprite)
// Despues: godot --headless --path . --script res://tools/build_sprites.gd
const fs = require('fs');
const path = require('path');

const W = 64, H = 80, FRAMES = 8;
const hash = (a, b, c = 0) => { const x = Math.sin(a * 127.1 + b * 311.7 + c * 74.7) * 43758.5453; return x - Math.floor(x); };

// ---------- parte estatica: piedra, musgo, grietas, cadena ----------
const base = Array.from({ length: H }, () => Array(W).fill('.'));
const stone = new Set(); // pixeles de piedra (para la luz y el contorno)
const put = (x, y, c, isStone = false) => {
  if (x < 0 || y < 0 || x >= W || y >= H) return;
  base[y][x] = c;
  if (isStone) stone.add(y * W + x);
};
const isStone = (x, y) => stone.has(y * W + x);

// tono de la piedra segun posicion: luz a la izquierda arriba, sombra a la derecha
function tone(x, y, shade) {
  let t = x < 24 ? 3 : x < 36 ? 3 : 2;
  if (x >= 40) t = 2;
  t += shade;
  const h = hash(x, y);
  if (h < 0.06) t -= 1; else if (h > 0.97) t += 1;
  return String(Math.max(1, Math.min(4, t)));
}
function block(x0, x1, y0, y1, shade = 0, seams = []) {
  for (let y = y0; y <= y1; y++) for (let x = x0; x <= x1; x++) {
    let c = tone(x, y, shade);
    if (seams.includes(y)) c = '2';
    put(x, y, c, true);
  }
}

// escalones (de abajo arriba)
block(8, 55, 74, 79, -0, [77]);
block(12, 51, 69, 73, 0, [71]);
block(16, 47, 65, 68, 0, [67]);
// juntas verticales escalonadas
for (const [x, y0, y1] of [[20, 74, 76], [33, 77, 79], [44, 74, 76], [28, 69, 70], [41, 71, 73], [24, 65, 66], [38, 67, 68]]) {
  for (let y = y0; y <= y1; y++) put(x, y, '2', true);
}
// esquinas rotas de los escalones
for (const [x, y] of [[8, 74], [9, 74], [8, 75], [55, 74], [54, 74], [12, 69], [51, 69], [50, 69], [47, 65], [16, 65]]) { base[y][x] = '.'; stone.delete(y * W + x); }
// escombros caidos
block(3, 6, 77, 79, 0); block(4, 5, 75, 76, -1); block(57, 60, 78, 79, 0); put(58, 77, '2', true);

// basamento (moldura) y fuste
block(20, 43, 59, 64, 0, [60]);
block(22, 41, 38, 58, 0, [44, 51]);
for (const [x, y0, y1] of [[27, 39, 43], [35, 45, 50], [29, 52, 57], [38, 39, 43], [24, 45, 50]]) for (let y = y0; y <= y1; y++) put(x, y, '2', true);
// losa superior (cuenco)
block(20, 43, 34, 37, 0);
// cuernos que abrazan el cristal
function horn(side, topY, jag) {
  for (let y = topY; y <= 33; y++) {
    const w = 3 + Math.floor((y - topY) * 3 / (33 - topY + 1));
    for (let i = 0; i < w; i++) {
      const x = side < 0 ? 25 - i : 38 + i;
      if (jag && (y + i) % 4 === 0 && y < topY + 3) continue;
      put(x, y, tone(x, y, 0), true);
    }
  }
}
horn(-1, 21, false);
horn(1, 25, true); // el derecho esta partido

// contorno oscuro y borde iluminado
const edge = new Set();
for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) {
  if (!isStone(x, y)) continue;
  const open = (dx, dy) => { const nx = x + dx, ny = y + dy; return nx < 0 || ny < 0 || nx >= W || ny >= H || base[ny][nx] === '.'; };
  if (open(0, -1) || open(-1, 0) || open(1, 0) || open(0, 1)) edge.add(y * W + x);
}
const top = new Set();
for (const k of edge) { const x = k % W, y = (k - x) / W; if (y === 0 || base[y - 1][x] === '.') top.add(k); }
for (const k of edge) { const x = k % W, y = (k - x) / W; base[y][x] = '1'; }
for (const k of top) {
  const x = k % W, y = (k - x) / W;
  if (y + 1 < H && isStone(x, y + 1) && !edge.has((y + 1) * W + x)) base[y + 1][x] = x < 34 ? '4' : '3';
}
// sombra bajo cada saliente
for (const k of edge) {
  const x = k % W, y = (k - x) / W;
  if (y > 0 && base[y - 1][x] !== '.' && !edge.has((y - 1) * W + x) && y < 76) base[y - 1][x] = '2';
}

// grietas
const crack = (pts) => {
  for (let i = 0; i + 1 < pts.length; i++) {
    let [x, y] = pts[i]; const [tx, ty] = pts[i + 1];
    while (x !== tx || y !== ty) {
      if (isStone(x, y) && base[y][x] !== '1') base[y][x] = '1';
      if (y !== ty) y += Math.sign(ty - y); else x += Math.sign(tx - x);
      if (x !== tx && (y - pts[i][1]) % 2 === 0) x += Math.sign(tx - x);
    }
  }
};
crack([[39, 39], [38, 43], [40, 47], [38, 52], [39, 57]]);
crack([[22, 59], [24, 62], [23, 64]]);
crack([[44, 69], [43, 72]]);
crack([[19, 74], [20, 77], [18, 79]]);
crack([[30, 35], [29, 37]]);

// musgo: sobre los bordes superiores de las piedras y chorreando por los lados
const mossy = (x, y) => isStone(x, y) && base[y][x] !== '.';
for (const k of top) {
  const x = k % W, y = (k - x) / W;
  const h = hash(x, y, 7);
  const bias = y > 62 ? 0.62 : y > 40 ? 0.12 : 0.04; // mas musgo abajo
  if (h < bias && y + 1 < H) {
    base[y][x] = 'm';
    if (mossy(x, y + 1) && base[y + 1][x] !== '1') base[y + 1][x] = h < bias * 0.5 ? 'p' : 'o';
    if (h < bias * 0.4 && mossy(x, y + 2) && base[y + 2][x] !== '1') base[y + 2][x] = 'n';
  }
}
// mantas de musgo en las esquinas de los escalones
const patch = (cx, cy, r, seed) => {
  for (let y = cy - r; y <= cy + r; y++) for (let x = cx - r; x <= cx + r; x++) {
    if (!isStone(x, y) || base[y][x] === '.') continue;
    const d = Math.hypot(x - cx, (y - cy) * 1.4);
    if (d < r * (0.6 + 0.5 * hash(x, y, seed))) base[y][x] = hash(x, y, seed + 1) < 0.12 ? 'p' : hash(x, y, seed + 2) < 0.4 ? 'o' : 'n';
  }
};
patch(14, 76, 5, 11); patch(52, 77, 4, 12); patch(18, 71, 3, 13); patch(48, 70, 3, 14); patch(21, 63, 3, 15);
patch(41, 62, 2, 16); patch(26, 38, 2, 17);
// raiz que trepa por el costado izquierdo del fuste
const root = [[11, 79], [12, 77], [13, 75], [14, 73], [16, 71], [17, 69], [18, 67], [19, 65], [20, 63], [21, 61], [21, 59], [22, 57], [22, 55], [23, 53], [22, 51], [22, 49]];
for (let i = 0; i + 1 < root.length; i++) {
  const [x0, y0] = root[i], [x1, y1] = root[i + 1];
  for (let s = 0; s <= 4; s++) {
    const x = Math.round(x0 + (x1 - x0) * s / 4), y = Math.round(y0 + (y1 - y0) * s / 4);
    const wob = Math.round(Math.sin(y * 0.9) * 0.6);
    put(x + wob, y, 'm'); put(x + wob + 1, y, 'n');
    if (hash(x, y, 3) < 0.4) put(x + wob - 1, y, 'm');
  }
}
for (const [x, y] of [[23, 56], [21, 52], [22, 48], [20, 64], [18, 70], [15, 74]]) put(x, y, 'o');
put(22, 47, 'p'); put(21, 60, 'p'); put(17, 68, 'p');
// hojitas sueltas en el suelo
for (const [x, y] of [[2, 79], [1, 78], [61, 79], [62, 78], [8, 79], [56, 79]]) put(x, y, hash(x, y) < 0.5 ? 'n' : 'o');

// cadena rota colgando del cuerno derecho
{
  let y = 29;
  let x = 40;
  for (let i = 0; i < 8; i++) {
    const link = i % 2 === 0 ? ['3', '4'] : ['2', '3'];
    put(x, y, link[0]); put(x, y + 1, link[1]);
    if (i % 2 === 0) { put(x + 1, y, '2'); put(x - 1, y, '1'); }
    y += 2;
    if (i === 3) x = 41;
  }
  put(41, y, '3'); put(42, y + 1, '2'); // ultimo eslabon suelto
}

// ---------- runas ----------
const GLYPHS = [
  ['..#..', '.###.', '#.#.#', '..#..', '.#.#.', '#...#'],
  ['#####', '#...#', '..#..', '.###.', '#...#', '..#..'],
  ['.#...', '.####', '.#..#', '.####', '...#.', '..#..'],
];
const RUNES = [{ g: GLYPHS[0], x: 29, y: 39, ph: 0.0 }, { g: GLYPHS[1], x: 29, y: 46, ph: 0.18 }, { g: GLYPHS[2], x: 29, y: 53, ph: 0.36 }];
// marcas pequenas en el escalon alto: una onda de luz las recorre
const MARKS = [];
for (let i = 0; i < 6; i++) MARKS.push({ x: 18 + i * 5 + (i > 2 ? 1 : 0), y: 66, ph: 0.12 * i });
// y en el basamento, dos trazos
const BASE_MARKS = [{ x: 24, y: 61, w: 3, ph: 0.55 }, { x: 37, y: 61, w: 3, ph: 0.7 }];
const RAMP = ['a', 'b', 'c', 'd'];
const level = (f, ph) => Math.max(0, Math.min(3, Math.round(1.4 + 1.6 * Math.sin(2 * Math.PI * (f / FRAMES - ph)))));

// ---------- fotogramas ----------
function frame(f) {
  const g = base.map(r => r.slice());
  const p = (x, y, c) => { if (x >= 0 && y >= 0 && x < W && y < H) g[y][x] = c; };
  const t = f / FRAMES;
  const flick = [0, 1, 0, -1, 0, 1, 2, 0][f];
  const sway = [0, 1, 1, 0, -1, -1, 0, 0][f];
  const bob = [0, 0, -1, -1, -1, 0, 0, 0][f];

  // luz calida sobre la piedra cercana al cristal (parpadea con la llama)
  const cx = 31.5, cy = 24 + bob;
  const reach = 12 + flick * 0.8;
  for (let y = 34; y <= 45; y++) for (let x = 14; x <= 50; x++) {
    if (!isStone(x, y)) continue;
    const c = g[y][x];
    if (!'1234'.includes(c)) continue;
    const d = Math.hypot(x - cx, (y - cy) * 0.85);
    if (d > reach) continue;
    const k = 1 - d / reach; // 0..1
    const lvl = Math.round(k * 3 + hash(x, y, f) * 0.5 - 0.15);
    if (lvl <= 0) continue;
    g[y][x] = lvl >= 3 ? 'b' : 'a';
    if (c === '4' && lvl >= 2) g[y][x] = 'c';
  }

  // runas: brillan con distinta fase; la luz se derrama un poco por la piedra
  for (const r of RUNES) {
    const L = level(f, r.ph);
    for (let j = 0; j < r.g.length; j++) for (let i = 0; i < 5; i++) {
      if (r.g[j][i] !== '#') continue;
      const x = r.x + i, y = r.y + j;
      p(x, y, RAMP[L]);
    }
    if (L >= 2) {
      for (let j = -1; j <= r.g.length; j++) for (let i = -1; i <= 5; i++) {
        const x = r.x + i, y = r.y + j;
        const inside = j >= 0 && j < r.g.length && i >= 0 && i < 5 && r.g[j][i] === '#';
        if (inside || !isStone(x, y) || !'1234'.includes(g[y][x])) continue;
        const near = [[1, 0], [-1, 0], [0, 1], [0, -1]].some(([dx, dy]) => {
          const jj = j + dy, ii = i + dx; return jj >= 0 && jj < r.g.length && ii >= 0 && ii < 5 && r.g[jj][ii] === '#';
        });
        if (near) p(x, y, L === 3 ? 'b' : 'a');
      }
    }
  }
  for (const m of MARKS) { const L = level(f, m.ph); p(m.x, m.y, RAMP[L]); p(m.x + 1, m.y, RAMP[L]); p(m.x, m.y + 1, RAMP[Math.max(0, L - 1)]); }
  for (const m of BASE_MARKS) { const L = level(f, m.ph); for (let i = 0; i < m.w; i++) p(m.x + i, m.y, RAMP[L]); }

  // hilo de luz que cae del cristal al cuenco
  for (let y = 31 + bob; y <= 33; y++) p(31 + (f % 2), y, y === 33 ? 'c' : (f + y) % 2 ? 'g' : 'f');
  // brillo del cuenco bajo el cristal
  for (let x = 28; x <= 35; x++) { const d = Math.abs(x - 31.5); p(x, 35, d < 2 ? 'd' : d < 3.5 ? 'c' : 'b'); }

  // cristal azul (rombo) con una llama ambar dentro
  const top0 = 5 + bob, bot = 31 + bob, mid = 18 + bob;
  for (let y = top0; y <= bot; y++) {
    const hw = y <= mid ? (y - top0 + 1) * 7.4 / (mid - top0 + 1) : (bot - y + 1) * 7.4 / (bot - mid + 1);
    const n = Math.max(1, Math.round(hw)); // pixeles a cada lado del centro
    for (let i = 0; i < n; i++) {
      const lx = 31 - i, rx = 32 + i;
      const edgeL = i === n - 1, edgeR = i === n - 1;
      const inner = i < n - 1;
      p(lx, y, edgeL ? 'h' : (i === 0 ? 'g' : 'g'));
      p(rx, y, edgeR ? 'g' : (i === 0 ? 'f' : 'f'));
      if (inner && i >= 1) { p(lx, y, 'f'); p(rx, y, 'e'); }
    }
    if (y === top0 || y === bot) { p(31, y, 'h'); p(32, y, 'h'); }
  }
  // arista central luminosa (facetas)
  for (let y = top0 + 2; y <= bot - 2; y++) if ((y + f) % 5 !== 0) { p(31, y, 'h'); }
  // llama: gota ambar que oscila
  const fb = 27 + bob, ft = 13 + bob - Math.max(0, flick) - (f % 3 === 0 ? 1 : 0);
  for (let y = ft; y <= fb; y++) {
    const k = (y - ft) / (fb - ft); // 0 punta .. 1 base
    const w = k < 0.2 ? 1 : k < 0.75 ? 2 : 2;
    const off = Math.round(sway * (1 - k) * 1.2);
    for (let i = 0; i < w; i++) {
      const lx = 31 - i + off, rx = 32 + i + off;
      const outer = i === w - 1 && w > 1;
      p(lx, y, outer ? 'c' : 'd'); p(rx, y, outer ? 'c' : 'd');
    }
    if (k > 0.7 && w >= 2) { p(31 + off, y, 'd'); p(32 + off, y, 'd'); }
    if (k > 0.85) { p(30, y, 'b'); p(33, y, 'b'); }
  }
  // punto blanco-azulado del corazon de la llama
  p(31, fb - 3, 'h'); p(32, fb - 3, 'h');
  // destello que recorre una faceta
  const gl = [[28, 15], [29, 17], [29, 21], [34, 22], [35, 18], [30, 12], [33, 14], [28, 19]][f];
  p(gl[0], gl[1] + bob, 'h');

  // brasas ambar que ascienden por los lados (bucle de 8 fotogramas)
  const embers = [{ x: 27, ph: 0 }, { x: 36, ph: 3 }, { x: 31, ph: 5.5 }, { x: 24, ph: 6.5 }, { x: 39, ph: 1.5 }];
  for (const e of embers) {
    const k = ((f + e.ph) % 8) / 8; // 0..1
    const y = Math.round(30 - k * 28);
    const x = e.x + Math.round(Math.sin((k + e.ph) * 6.28) * 1.5);
    if (y < 1 || y > 40) continue;
    if (g[y][x] === '.') p(x, y, k < 0.35 ? 'd' : k < 0.7 ? 'c' : 'b');
  }
  return g;
}

// ---------- salida ----------
const NL = String.fromCharCode(10);
const out = [];
out.push('# Generado por tools/arte_ancla.js: no editar a mano (editar el generador).');
out.push('# Ancla de Memoria: monumento de piedra con un cristal azul y llama ambar.');
out.push(`sheet ${W}x${H}`);
out.push('out res://game/memory_anchor/anchor_sheet.png');
for (let f = 0; f < FRAMES; f++) {
  out.push(`part f${f}`);
  for (const row of frame(f)) out.push(row.join(''));
}
out.push('anim glow');
for (let f = 0; f < FRAMES; f++) out.push(`frame f${f}`);
fs.writeFileSync(path.join(__dirname, '..', 'art', 'source', 'anchor.sprite'), out.join(NL) + NL);
console.log('art/source/anchor.sprite escrito');
