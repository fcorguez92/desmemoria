// Generador del logotipo del menú principal: la palabra DESMEMORIA con letras de
// píxeles gordos, en ámbar con relieve, que se deshace hacia el final como un
// recuerdo que se apaga; un brillo azul la recorre y las esquirlas flotan hacia arriba.
// Uso: node tools/arte_titulo.js   (escribe art/source/title_logo.sprite)
const fs = require('fs');
const NL = String.fromCharCode(10);

const W = 456, H = 88, FRAMES = 12;
const S = 7;       // lado de cada píxel de la fuente
const GAP = 7;     // hueco entre letras
const GLYPH_W = 5, GLYPH_H = 7;
const WORD = 'DESMEMORIA';
const FONT = {
  D: ['1111.', '1...1', '1...1', '1...1', '1...1', '1...1', '1111.'],
  E: ['11111', '1....', '1....', '1111.', '1....', '1....', '11111'],
  S: ['.1111', '1....', '1....', '.111.', '....1', '....1', '1111.'],
  M: ['1...1', '11.11', '1.1.1', '1.1.1', '1...1', '1...1', '1...1'],
  O: ['.111.', '1...1', '1...1', '1...1', '1...1', '1...1', '.111.'],
  R: ['1111.', '1...1', '1...1', '1111.', '1.1..', '1..1.', '1...1'],
  I: ['11111', '..1..', '..1..', '..1..', '..1..', '..1..', '11111'],
  A: ['.111.', '1...1', '1...1', '11111', '1...1', '1...1', '1...1'],
};

const hash = (a, b, c) => { const x = Math.sin(a * 127.1 + b * 311.7 + c * 74.7) * 43758.5453; return x - Math.floor(x); };

// celdas de la fuente: [x, y, letra] en unidades de píxel de fuente
const cells = [];
const totalW = WORD.length * GLYPH_W * S + (WORD.length - 1) * GAP;
const ox = Math.floor((W - totalW) / 2), oy = 22;
[...WORD].forEach((ch, li) => {
  FONT[ch].forEach((row, gy) => {
    [...row].forEach((v, gx) => {
      if (v === '1') cells.push({ li, gx, gy, x: ox + li * (GLYPH_W * S + GAP) + gx * S, y: oy + gy * S });
    });
  });
});

// ¿Se ha deshecho esta celda? Cuanto mas a la derecha y abajo, mas probable.
function dissolved(c) {
  const t = Math.max(0, (c.li - 4) / (WORD.length - 5)); // 0 hasta la 5ª letra, 1 en la ultima
  const bias = (c.gy / (GLYPH_H - 1)) * 0.35 + (c.gx / (GLYPH_W - 1)) * 0.15;
  return hash(c.li, c.gx, c.gy) < t * 0.12 + t * bias * 0.4 - 0.03;
}

function frame(f) {
  const g = Array.from({ length: H }, () => Array(W).fill('.'));
  const set = (x, y, ch) => { if (x >= 0 && y >= 0 && x < W && y < H) g[y][x] = ch; };
  const rect = (x0, y0, w, h, ch) => { for (let y = y0; y < y0 + h; y++) for (let x = x0; x < x0 + w; x++) set(x, y, ch); };
  const phase = f / FRAMES;
  const shine = phase * (W + 160) - 80; // posicion del brillo (diagonal)

  // sombra y contorno
  for (const c of cells) {
    if (dissolved(c)) continue;
    rect(c.x + 2, c.y + 3, S, S, '1');
  }
  for (const c of cells) {
    if (dissolved(c)) continue;
    rect(c.x - 1, c.y - 1, S + 2, S + 2, 'a');
  }
  // relleno con relieve: arriba-izquierda claro, abajo-derecha oscuro, degradado vertical
  for (const c of cells) {
    if (dissolved(c)) continue;
    const row = c.gy / (GLYPH_H - 1);
    const base = row < 0.34 ? 'd' : (row < 0.72 ? 'c' : 'b');
    const dark = row < 0.34 ? 'c' : (row < 0.72 ? 'b' : 'a');
    rect(c.x, c.y, S, S, base);
    // bisel
    for (let i = 0; i < S; i++) { set(c.x + i, c.y + S - 1, dark); set(c.x + S - 1, c.y + i, dark); }
    set(c.x, c.y, 'd'); for (let i = 1; i < S - 1; i++) { set(c.x + i, c.y, row < 0.34 ? 'd' : base); set(c.x, c.y + i, row < 0.34 ? 'd' : base); }
    // brillo azul que recorre la palabra en diagonal
    const diag = c.x + c.y * 0.9;
    const dist = Math.abs(diag - shine);
    if (dist < 26) {
      const k = dist < 9 ? 'h' : (dist < 18 ? 'g' : 'f');
      for (let y = c.y + 1; y < c.y + S - 1; y++) for (let x = c.x + 1; x < c.x + S - 1; x++) if ((x + y) % 2 === 0 || dist < 9) set(x, y, k);
    }
  }
  // esquirlas de las celdas deshechas: suben y se apagan
  for (const c of cells) {
    if (!dissolved(c)) continue;
    const seed = hash(c.li, c.gx, c.gy);
    const life = (phase + seed) % 1;            // 0 = recien soltada, 1 = apagada
    const px = Math.round(c.x + S / 2 + Math.sin(seed * 20 + life * 5) * 5 + life * (6 + seed * 10));
    const py = Math.round(c.y - life * (22 + seed * 26));
    const size = life < 0.5 ? 3 : 2;
    if (life > 0.92) continue;
    const ch = life < 0.35 ? (seed < 0.5 ? 'd' : 'c') : (life < 0.7 ? 'b' : (seed < 0.5 ? 'g' : 'f'));
    rect(px, py, size, size, ch);
  }
  return g;
}

const frames = Array.from({ length: FRAMES }, (_, f) => frame(f));
let out = [
  '# Logotipo del menú principal: DESMEMORIA con píxeles gordos en ámbar y relieve; las',
  '# letras se deshacen hacia el final (la memoria que se apaga) y un brillo azul las recorre.',
  '# Lo genera tools/arte_titulo.js; para cambiarlo se edita el script y se regenera.',
  '# Leyenda: ver art/palette.txt.', '',
  'sheet ' + W + 'x' + H, 'out res://game/ui/title_logo.png', ''].join(NL) + NL;
frames.forEach((g, i) => { out += 'part logo' + i + NL + g.map(r => r.join('')).join(NL) + NL + NL; });
out += 'anim shine' + NL + frames.map((_, i) => 'frame logo' + i).join(NL) + NL;
fs.writeFileSync('art/source/title_logo.sprite', out);
console.log('logo: ' + FRAMES + ' fotogramas de ' + W + 'x' + H);
