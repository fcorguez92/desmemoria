// Compara dos .sprite del mismo personaje con distinto alto de lienzo y comprueba
// que cada fotograma nuevo es identico al antiguo desplazado hacia abajo
// (dy = alto nuevo - alto antiguo): las filas nuevas de arriba vacias y las
// demas iguales. Sirve para ampliar un lienzo sin tocar el dibujo (paquete H0-03).
// Uso: node tools/comparar_lienzo.js <antiguo.sprite> <nuevo.sprite>
const fs = require('fs');

function leer(file) {
  const t = fs.readFileSync(file, 'utf8').split(/\r?\n/);
  const sheet = /^sheet (\d+)x(\d+)/.exec(t.find(l => l.startsWith('sheet ')));
  const parts = {};
  for (let i = 0; i < t.length; i++) {
    if (!t[i].startsWith('part ')) continue;
    const rows = [];
    for (let j = i + 1; j < t.length && t[j] !== ''; j++) rows.push(t[j]);
    parts[t[i].slice(5)] = rows;
  }
  const order = t.filter(l => l.startsWith('frame ')).map(l => l.slice(6));
  return { w: +sheet[1], h: +sheet[2], parts, order };
}

const [a, b] = process.argv.slice(2).map(leer);
const dy = b.h - a.h;
let fallos = 0;
if (b.w !== a.w) { console.log('ancho distinto', a.w, b.w); fallos++; }
if (a.order.join() !== b.order.join()) { console.log('el orden de fotogramas difiere'); fallos++; }
for (const name of a.order) {
  const ra = a.parts[name], rb = b.parts[name];
  const vacia = ' '.repeat(0) + '.'.repeat(a.w);
  const esperado = [...Array(dy).fill(vacia), ...ra];
  if (!rb || rb.length !== esperado.length || rb.some((r, i) => r !== esperado[i])) { console.log('DIFIERE', name); fallos++; }
}
console.log(`${a.order.length} fotogramas, desplazamiento ${dy}px, fallos: ${fallos}`);
process.exit(fallos ? 1 : 0);
