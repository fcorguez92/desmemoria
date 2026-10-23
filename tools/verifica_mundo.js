// Verificador del mundo: comprobaciones estáticas sobre los .map y el manifiesto
// (tests/world_manifest.json) de docs/puzles.md ("Comprobaciones automáticas").
// Hechas hoy: C1 sin solapes, C2 alineación y anchura de las puertas, C3 aberturas
// huérfanas, C4 manifiesto frente a world.tscn, C8 enemigos y tablones, C12
// caracteres válidos y anchura, C13 coleccionables, C16 enlaces de las piezas,
// C17 extremos de carril en pares y ajustes de piezas (piece_params).
// Sale con código 1 si algún fallo; cada fallo dice
// comprobación, sala, borde y fila/columna.
//
//   node tools/verifica_mundo.js [--manifiesto ruta.json]
//
// Las salas nuevas se añaden al manifiesto (a mano) y el script las comprueba solo.
// "excepciones" del manifiesto: lista de textos exactos de fallos conocidos que se
// aceptan (cada uno con su motivo); se imprimen como avisos para no olvidarlos.
const fs = require('fs');
const path = require('path');
const ROOT = path.join(__dirname, '..');
const LEVELS = path.join(ROOT, 'game/levels');

const SOLID = new Set('TGBCg%$#=+');  // lo que cierra el paso en un borde (compuertas y piezas cerradas)
const PLANKS = new Set('Sp');
const CEILING = new Set('TGBC%g');
const SPIKES = new Set('^v~-{}');
const ENEMIES = new Set('E123456789');
const MIN_DOOR = 6, MIN_ENEMY_DOOR = 10, MIN_CEILING = 6, MIN_WIDTH = 54;

const failures = [], warnings = [];
let accepted = new Set();
const fail = (code, room, where, msg) => {
  const text = `${code} ${room}${where ? ' ' + where : ''}: ${msg}`;
  (accepted.has(text) ? warnings : failures).push(text);
};

function loadRoom(entry) {
  const file = path.join(LEVELS, entry.id + '.map');
  if (!fs.existsSync(file)) { fail('C4', entry.id, '', `no existe ${path.relative(ROOT, file)}`); return null; }
  const rows = fs.readFileSync(file, 'utf8').split('\n').map((l) => l.replace(/\r$/, '')).filter((l, i, a) => !(i === a.length - 1 && l === ''));
  return { ...entry, rows, w: Math.max(...rows.map((r) => r.length)), h: rows.length };
}
const ch = (room, c, r) => (r < 0 || r >= room.h || c < 0 || c >= room.w ? 'B' : (room.rows[r][c] || '.'));
const roomAt = (rooms, x, y) => rooms.find((o) => x >= o.x && x < o.x + o.w && y >= o.y && y < o.y + o.h);

// Celdas del borde de una sala: para cada índice a lo largo del borde, la celda
// interior y la celda absoluta que queda al otro lado.
function edgeCells(room, side) {
  const n = side === 'L' || side === 'R' ? room.h : room.w;
  const out = [];
  for (let i = 0; i < n; i++) {
    const inner = { L: [0, i], R: [room.w - 1, i], T: [i, 0], B: [i, room.h - 1] }[side];
    const beyond = { L: [room.x - 1, room.y + i], R: [room.x + room.w, room.y + i], T: [room.x + i, room.y - 1], B: [room.x + i, room.y + room.h] }[side];
    out.push({ i, inner, beyond });
  }
  return out;
}
const rangeText = (a, b) => (a === b ? `${a}` : `${a}-${b}`);

// Piezas de marcadores de las mecánicas (= + z _ * # $): grupos conexos por lados, con
// el id carácter@columna,fila de su primera celda en orden de lectura (como room.gd).
function piecesOf(room) {
  const out = new Set();
  const seen = new Set();
  room.rows.forEach((row, r) => [...row].forEach((c, col) => {
    if (!'=+z_*#$<>y'.includes(c) || seen.has(`${col},${r}`)) return;
    out.add(`${c}@${col},${r}`);
    const queue = [[col, r]];
    seen.add(`${col},${r}`);
    while (queue.length) {
      const [x, y] = queue.pop();
      for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) {
        const nx = x + dx, ny = y + dy;
        if (!seen.has(`${nx},${ny}`) && ny >= 0 && ny < room.h && room.rows[ny][nx] === c) { seen.add(`${nx},${ny}`); queue.push([nx, ny]); }
      }
    }
  }));
  return out;
}

// Piezas de un carácter: grupos conexos por lados, con id, y centro en celdas.
function groupsOf(room, c) {
  const out = [];
  const seen = new Set();
  room.rows.forEach((row, r) => [...row].forEach((ch2, col) => {
    if (ch2 !== c || seen.has(`${col},${r}`)) return;
    const cells = [];
    const queue = [[col, r]];
    seen.add(`${col},${r}`);
    while (queue.length) {
      const [x, y] = queue.pop();
      cells.push([x, y]);
      for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) {
        const nx = x + dx, ny = y + dy;
        if (!seen.has(`${nx},${ny}`) && ny >= 0 && ny < room.h && room.rows[ny][nx] === c) { seen.add(`${nx},${ny}`); queue.push([nx, ny]); }
      }
    }
    out.push({ x0: Math.min(...cells.map((p) => p[0])), x1: Math.max(...cells.map((p) => p[0])), y0: Math.min(...cells.map((p) => p[1])), y1: Math.max(...cells.map((p) => p[1])), id: `${c}@${col},${r}`, cx: cells.reduce((a, p) => a + p[0], 0) / cells.length, cy: cells.reduce((a, p) => a + p[1], 0) / cells.length });
  }));
  return out;
}

// C12: caracteres de la leyenda de docs/vertical-slice.md.
function legendChars() {
  const text = fs.readFileSync(path.join(ROOT, 'docs/vertical-slice.md'), 'utf8');
  const start = text.indexOf('## Leyenda del mapa de texto');
  const end = text.indexOf('### Libres', start);
  const set = new Set('. ');
  for (const line of text.slice(start, end).split('\n')) {
    if (!line.startsWith('| `')) continue;
    const firstCell = line.split('|')[1];
    for (const m of firstCell.matchAll(/`([^`])`/g)) set.add(m[1]);
  }
  return set;
}

// C4: salas y posiciones de world.tscn.
function worldRooms() {
  const text = fs.readFileSync(path.join(LEVELS, 'world.tscn'), 'utf8');
  const res = {};
  for (const m of text.matchAll(/\[ext_resource type="PackedScene" path="res:\/\/game\/levels\/([^"]+)\.tscn" id="([^"]+)"\]/g)) res[m[2]] = m[1];
  const found = [];
  const re = /\[node name="([^"]+)" parent="Rooms" instance=ExtResource\("([^"]+)"\)\]\n(position = Vector2\(([-\d.]+), ([-\d.]+)\)\n)?/g;
  for (const m of text.matchAll(re)) found.push({ node: m[1], scene: res[m[2]], x: m[4] ? +m[4] / 16 : 0, y: m[5] ? +m[5] / 16 : 0 });
  return found;
}
function sceneMap(scene) {
  const t = fs.readFileSync(path.join(LEVELS, scene + '.tscn'), 'utf8');
  const m = t.match(/map_file = "res:\/\/game\/levels\/([^"]+)\.map"/);
  return m ? m[1] : null;
}

function main() {
  const manifestPath = process.argv.includes('--manifiesto') ? process.argv[process.argv.indexOf('--manifiesto') + 1] : path.join(ROOT, 'tests/world_manifest.json');
  const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
  accepted = new Set(manifest.excepciones || []);
  const rooms = manifest.salas.map(loadRoom).filter(Boolean);
  const valid = legendChars();

  // C12: caracteres válidos y anchura.
  for (const room of rooms) {
    const seen = new Map();
    room.rows.forEach((row, r) => [...row].forEach((c, col) => { if (!valid.has(c) && !seen.has(c)) seen.set(c, `fila ${r} columna ${col}`); }));
    for (const [c, where] of seen) fail('C12', room.id, where, `carácter "${c}" que no está en la leyenda de vertical-slice.md`);
    if (room.w < MIN_WIDTH && !room.estrecha) fail('C12', room.id, '', `anchura ${room.w} < ${MIN_WIDTH} (marca "estrecha" en el manifiesto si es a propósito)`);
  }

  // C13: coleccionables "!". Su id sale de sala+columna+fila (room.gd) y por tanto es
  // único; aquí se comprueba que el "pickups" de la escena no declare más tipos que
  // marcadores y que cada tipo sea válido.
  for (const room of rooms) {
    const count = room.rows.reduce((n, row) => n + [...row].filter((c) => c === "!").length, 0);
    const scene = worldRooms().find((w) => sceneMap(w.scene) === room.id);
    const m = scene && fs.readFileSync(path.join(LEVELS, scene.scene + ".tscn"), "utf8").match(/^pickups = PackedStringArray((.*))$/m);
    const entries = m ? [...m[1].matchAll(/"([^"]*)"/g)].map((k) => k[1]) : [];
    const keys = new Set();
    room.rows.forEach((row, r) => [...row].forEach((c, col) => { if (c === "!") keys.add(`c${String(col).padStart(2, "0")}f${String(r).padStart(2, "0")}`); }));
    for (const e of entries) {
      const [key, kind] = e.split(":");
      if (!keys.has(key)) fail("C13", room.id, "", `"pickups" tiene "${e}" y no hay un "!" en esa posición`);
      if (!["fragment", "bag", "item"].includes(kind)) fail("C13", room.id, "", `tipo de coleccionable desconocido en "${e}"`);
    }
  }

  // C13 también: dos salas del manifiesto no pueden compartir archivo .map (los ids de coleccionables saldrían repetidos).
  const mapsSeen = new Set();
  for (const room of rooms) {
    if (mapsSeen.has(room.id)) fail("C13", room.id, "", "dos salas del manifiesto con el mismo archivo .map");
    mapsSeen.add(room.id);
  }

  // C16: enlaces ("links" de la escena) de las piezas de mecánica. Cada clave debe
  // ser el id de una pieza que existe en el mapa (carácter@columna,fila de su primera
  // celda en orden de lectura, ver room.gd) y cada marca, tener la forma prefijo:sala.objeto.
  for (const room of rooms) {
    const scene = worldRooms().find((w) => sceneMap(w.scene) === room.id);
    const text = scene ? fs.readFileSync(path.join(LEVELS, scene.scene + '.tscn'), 'utf8') : '';
    const m = text.match(/^links = (\{[\s\S]*?\})\s*$/m);
    if (!m) continue;
    const pieces = piecesOf(room);
    for (const k of m[1].matchAll(/"([^"]+)"\s*:/g)) {
      if (!pieces.has(k[1])) fail('C16', room.id, '', `el enlace "${k[1]}" no es la primera celda de ninguna pieza del mapa`);
    }
    for (const v of m[1].matchAll(/"([^"]+)"/g)) {
      if (v[1].includes('@')) continue;  // es una clave
      if (!/^[pdsitn]:[a-z0-9_]+\.[a-z0-9_]+$/.test(v[1])) fail('C16', room.id, '', `la marca "${v[1]}" no tiene la forma prefijo:sala.objeto (minúsculas, sin acentos)`);
    }
  }

  // C17: extremos de carril. Cada < debe tener su > (se emparejan por cercanía, como en
  // room.gd: primero los pares más próximos) y los dos extremos de un par no pueden
  // estar en la misma celda. Las claves de piece_params (ajustes de ciclos y plataformas)
  // deben ser el id de una pieza < o y que exista en el mapa.
  // Propiedades de los nodos (mantener en sincronía con core/objects/cycle.gd y rail_platform.gd).
  const KNOWN = {
    y: ["period", "on_fraction", "phase", "warning_time", "blink_rate", "cells", "cell_size", "blockers", "flag_id", "body_color", "edge_color"],
    "<": ["mode", "end_offset", "size", "speed", "wait_time", "return_delay", "blocked_time", "rider_height", "activation_flag", "action_interact", "rider_groups", "blocker_groups", "body_color", "edge_color", "rail_color"],
  };
  for (const room of rooms) {
    const groups = (c) => groupsOf(room, c);
    const starts = groups("<"), ends = groups(">");
    // Compatibles: mismo ancho y misma columna o fila. Desempate por orden de lectura (como room.gd).
    const cand = [];
    starts.forEach((a, i) => ends.forEach((b, j) => {
      if (a.x1 - a.x0 === b.x1 - b.x0 && (a.x0 === b.x0 || a.y0 === b.y0)) cand.push([Math.hypot(a.cx - b.cx, a.cy - b.cy), i, j]);
    }));
    cand.sort((p, q) => (Math.abs(p[0] - q[0]) > 1e-9 ? p[0] - q[0] : p[1] - q[1] || p[2] - q[2]));
    const usedS = new Set(), usedE = new Set();
    for (const [d, i, j] of cand) {
      if (usedS.has(i) || usedE.has(j)) continue;
      usedS.add(i); usedE.add(j);
      const a = starts[i], b = ends[j];
      if (d < 1) fail("C17", room.id, a.id, "el inicio y el fin del carril están en la misma celda");
      const x0 = Math.min(a.x0, b.x0), x1 = Math.max(a.x1, b.x1), y0 = Math.min(a.y0, b.y0), y1 = Math.max(a.y1, b.y1);
      outer: for (let y = y0; y <= y1; y++) for (let x = x0; x <= x1; x++) {
        if (SOLID.has(ch(room, x, y))) { fail("C17", room.id, a.id, `hay un sólido ("${ch(room, x, y)}") en fila ${y} columna ${x} en el tramo del carril`); break outer; }
      }
    }
    starts.forEach((a, i) => { if (!usedS.has(i)) fail("C17", room.id, a.id, "el extremo < no tiene un > del mismo ancho y alineado (misma columna o fila)"); });
    ends.forEach((b, j) => { if (!usedE.has(j)) fail("C17", room.id, b.id, "el extremo > no tiene un < del mismo ancho y alineado"); });
    const scene = worldRooms().find((w) => sceneMap(w.scene) === room.id);
    const text = scene ? fs.readFileSync(path.join(LEVELS, scene.scene + ".tscn"), "utf8") : "";
    const m = text.match(/^piece_params = (\{[\s\S]*?\n\})\s*$/m);
    if (!m) continue;
    const ids = new Set([...starts, ...groups("y")].map((g) => g.id));
    let current = null;
    for (const line of m[1].split("\n")) {
      const k = line.match(/^"([^"]+)"\s*:\s*(.*)$/);
      if (!k) continue;
      if (k[1].includes("@")) {
        current = k[1];
        if (!ids.has(current)) fail("C17", room.id, "", `el ajuste "${current}" no es la primera celda de un < ni de una y del mapa`);
      } else if (current && ids.has(current) && !KNOWN[current[0]].includes(k[1])) {
        fail("C17", room.id, current, `la propiedad "${k[1]}" no existe; conocidas: ${KNOWN[current[0]].join(", ")}`);
      }
    }
  }

  // C1: sin solapes.
  for (let a = 0; a < rooms.length; a++) for (let b = a + 1; b < rooms.length; b++) {
    const A = rooms[a], B = rooms[b];
    if (A.x < B.x + B.w && B.x < A.x + A.w && A.y < B.y + B.h && B.y < A.y + A.h) fail('C1', A.id, '', `solapa con ${B.id}`);
  }

  // C2 y C3: aberturas de cada borde.
  for (const room of rooms) {
    const declared = [];  // {side, from, to, kind, a}
    for (const p of room.puertas || []) declared.push({ ...p, kind: 'puerta' });
    for (const o of room.abiertas || []) declared.push({ ...o, kind: 'abierta' });
    for (const side of ['L', 'R', 'T', 'B']) {
      // Pasos reales del mapa: celdas libres del borde, agrupadas por lo que hay al otro lado.
      const runs = [];
      let cur = null;
      const flush = () => { if (cur) runs.push(cur); cur = null; };
      for (const cell of edgeCells(room, side)) {
        if (SOLID.has(ch(room, cell.inner[0], cell.inner[1]))) { flush(); continue; }
        const other = roomAt(rooms, cell.beyond[0], cell.beyond[1]);
        let kind = 'abierta', a = null;
        if (other) {
          if (SOLID.has(ch(other, cell.beyond[0] - other.x, cell.beyond[1] - other.y))) { flush(); continue; }  // libre contra pared: no es paso
          kind = 'puerta'; a = other.id;
        }
        if (cur && cur.kind === kind && cur.a === a && cur.to === cell.i - 1) cur.to = cell.i; else { flush(); cur = { side, from: cell.i, to: cell.i, kind, a }; }
      }
      flush();
      const decl = declared.filter((d) => d.lado === side);
      for (const run of runs) {
        const match = decl.find((d) => d.desde === run.from && d.hasta === run.to && d.kind === run.kind && (run.kind === 'abierta' || d.a === run.a));
        const where = `borde ${side} ${side === 'L' || side === 'R' ? 'filas' : 'columnas'} ${rangeText(run.from, run.to)}`;
        if (!match) {
          const near = decl.find((d) => d.kind === run.kind && !(d.hasta < run.from || d.desde > run.to));
          if (run.kind === 'abierta') fail('C3', room.id, where, near ? `abertura huérfana que no coincide con la declarada ${rangeText(near.desde, near.hasta)}` : 'abertura huérfana: da a nada y no está declarada (cielo o abismo)');
          else fail(near ? 'C2' : 'C3', room.id, where, near ? `el paso hacia ${run.a} mide ${rangeText(run.from, run.to)} y el manifiesto dice ${rangeText(near.desde, near.hasta)} (¿mal alineado?)` : `paso hacia ${run.a} no declarado en el manifiesto`);
          continue;
        }
        if (run.kind === 'puerta') {
          const width = run.to - run.from + 1;
          if (width < MIN_DOOR) fail('C2', room.id, where, `el paso hacia ${run.a} mide ${width} < ${MIN_DOOR}`);
          // Mismo nivel de suelo: bajo el paso (L/R), sólido a ambos lados.
          if (side === 'L' || side === 'R') {
            const other = rooms.find((o) => o.id === run.a);
            const below = run.to + 1;
            if (below < room.h) {
              const mine = ch(room, side === 'L' ? 0 : room.w - 1, below);
              const oy = room.y + below - other.y, ox = side === 'L' ? other.w - 1 : 0;
              if (!SOLID.has(mine) && !PLANKS.has(mine)) fail('C2', room.id, where, `bajo el paso no hay suelo (${JSON.stringify(mine)}) en esta sala`);
              else if (oy >= 0 && oy < other.h && !SOLID.has(ch(other, ox, oy)) && !PLANKS.has(ch(other, ox, oy))) fail('C2', room.id, where, `bajo el paso no hay suelo en ${other.id}: el nivel de suelo no coincide`);
            }
          }
        }
      }
      for (const d of decl) {
        if (!runs.some((r) => r.from === d.desde && r.to === d.hasta && r.kind === d.kind)) fail('C3', room.id, `borde ${side} ${rangeText(d.desde, d.hasta)}`, `el manifiesto declara una ${d.kind} que el mapa no tiene`);
      }
    }
    // Declaraciones con lado que el mapa no usa se ven arriba; las de otra sala, en su turno.
    void declared;
  }

  // C4: manifiesto frente a world.tscn.
  const world = worldRooms();
  for (const room of rooms) {
    const w = world.find((n) => n.scene === room.id);
    if (!w) { fail('C4', room.id, '', 'no está en world.tscn'); continue; }
    if (w.x !== room.x || w.y !== room.y) fail('C4', room.id, '', `posición del manifiesto (${room.x}, ${room.y}) distinta de world.tscn (${w.x}, ${w.y})`);
    const mapName = sceneMap(room.id);
    if (mapName !== room.id) fail('C4', room.id, '', `la escena usa el mapa "${mapName}", no "${room.id}"`);
  }
  for (const w of world) if (!rooms.some((r) => r.id === w.scene)) fail('C4', w.scene, '', 'está en world.tscn y falta en el manifiesto');

  // C8: enemigos lejos de las puertas, tablones con techo y sin pinchos bajo un enemigo.
  for (const room of rooms) {
    const doorCells = [];
    for (const p of room.puertas || []) {
      for (let i = p.desde; i <= p.hasta; i++) doorCells.push({ L: [0, i], R: [room.w - 1, i], T: [i, 0], B: [i, room.h - 1] }[p.lado]);
    }
    room.rows.forEach((row, r) => [...row].forEach((c, col) => {
      if (ENEMIES.has(c)) {
        const d = Math.min(Infinity, ...doorCells.map(([x, y]) => Math.hypot(x - col, y - r)));
        if (d < MIN_ENEMY_DOOR) fail('C8', room.id, `fila ${r} columna ${col}`, `enemigo "${c}" a ${d.toFixed(1)} baldosas de una puerta (mínimo ${MIN_ENEMY_DOOR})`);
        let y = r + 1;
        while (y < room.h && ch(room, col, y) === '.') y++;
        if (y < room.h && SPIKES.has(ch(room, col, y))) fail('C8', room.id, `fila ${r} columna ${col}`, `pinchos bajo el enemigo "${c}"`);
      }
      if (PLANKS.has(c) && col > 1 && col < room.w - 2) {
        let free = 0, y = r - 1;
        while (y >= 0 && !CEILING.has(ch(room, col, y))) { free++; y--; }
        if (y >= 0 && free < MIN_CEILING) fail('C8', room.id, `fila ${r} columna ${col}`, `tablón con solo ${free} baldosas libres hasta el techo (mínimo ${MIN_CEILING})`);
      }
    }));
  }

  for (const w of warnings) console.log('  aviso (excepción conocida): ' + w);
  for (const f of failures) console.log('  FALLA ' + f);
  console.log(`\nMundo: ${rooms.length} salas; ${failures.length ? 'HAY FALLOS (' + failures.length + ')' : 'TODO OK'}${warnings.length ? ', ' + warnings.length + ' avisos' : ''}`);
  return failures.length ? 1 : 0;
}
process.exit(main());
