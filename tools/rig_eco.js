// Generador del Eco (el recuerdo que deja el Caminante al morir): la silueta del
// propio Caminante agazapado, recoloreada en azul frío y deshaciéndose por abajo
// como un recuerdo que se apaga. Reutiliza el esqueleto de tools/rig_lib.js.
// Uso: node tools/rig_eco.js   (escribe art/source/echo.sprite)
const lib = require('./rig_lib');
const { pose } = lib;
const NL = String.fromCharCode(10);
const FW = 48, FH = 64; // fotograma del Eco
lib.setCanvas(112, 64);
const { OX } = lib.canvasSize();
const X0 = OX - 28; // recorte: de la daga atras hasta delante del puño

// pose de reposo del Caminante (la misma que su animacion idle), 4 instantes
const poses = [0, 0.25, 0.5, 0.75].map(t => {
  const b = Math.sin(t * 2 * Math.PI), s = Math.sin(t * 2 * Math.PI + 1);
  return pose({ hipx: 2.5 + 0.6 * s, hipy: -17.4 + 0.5 * b, lean: 24 + 1.5 * b, bend: 8 + 1.5 * b, head: -16 + s,
    nfx: 8, ffx: -7, fx: 2 + 0.6 * b, fy: 12 - 0.8 * b, gx: 8 + 0.6 * s, gy: 6 + 0.5 * b, blade: 180 + 3 * b,
    capeTx: -1, capeTy: 0.25, capeAmt: 0.45 + 0.08 * b, capeWave: 0.4, phase: t * 2 * Math.PI,
    scAmt: 0.6 + 0.1 * s, scTy: 0.1 + 0.1 * b, hoodTy: -0.5 });
});

// de los colores del Caminante a la rampa azul del recuerdo
const GHOST = { '1': 'e', '2': 'f', '3': 'g', '4': 'h', 'a': 'f', 'b': 'g', 'c': 'h', 'd': 'h', 'e': 'e', 'f': 'f', 'g': 'g', 'h': 'h' };
const hash = (a, b, c) => { const x = Math.sin(a * 127.1 + b * 311.7 + c * 74.7) * 43758.5453; return x - Math.floor(x); };

const frames = poses.map((p, fi) => {
  const r = lib.render(p);
  const g = Array.from({ length: FH }, () => Array(FW).fill('.'));
  for (let y = 0; y < FH; y++) for (let x = 0; x < FW; x++) {
    const src = r.g[y][X0 + x];
    if (src === '.') continue;
    g[y][x] = GHOST[src] || 'f';
  }
  // se deshace de la cintura para abajo: cada vez menos piel y mas jirones
  const y0 = 36;
  for (let y = y0; y < FH; y++) for (let x = 0; x < FW; x++) {
    if (g[y][x] === '.') continue;
    const t = (y - y0) / (FH - y0);
    if (hash(x, y, fi) < t * 0.95) g[y][x] = '.';
  }
  // jirones y chispas que suben
  for (let k = 0; k < 9; k++) {
    const x = 6 + Math.floor(hash(k, fi, 1) * 30), y = 48 + Math.floor(hash(k, fi, 2) * 15);
    if (g[y][x] === '.') g[y][x] = hash(k, fi, 3) < 0.5 ? 'f' : 'g';
  }
  const sx = 8 + ((fi * 11) % 28), sy = 54 - fi * 7;
  if (g[sy][sx] === '.') g[sy][sx] = 'h';
  return g;
});

let out = [
  '# El Eco: lo que queda de ti donde caíste. La silueta del Caminante, agazapado,',
  '# en azul frío y deshaciéndose de la cintura para abajo como un recuerdo que se',
  '# apaga. La genera tools/rig_eco.js a partir del esqueleto del Caminante',
  '# (tools/rig_lib.js); para cambiarlo se edita el script y se regenera.',
  '# Leyenda: ver art/palette.txt.', '',
  'sheet ' + FW + 'x' + FH, 'out res://game/echo/echo_sheet.png', ''].join(NL) + NL;
frames.forEach((g, i) => { out += 'part echo' + i + NL + g.map(r => r.join('')).join(NL) + NL + NL; });
out += 'anim float' + NL + frames.map((_, i) => 'frame echo' + i).join(NL) + NL;
require('fs').writeFileSync('art/source/echo.sprite', out);
console.log('eco: ' + frames.length + ' fotogramas de ' + FW + 'x' + FH);
