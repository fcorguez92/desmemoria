// Autoprueba del simulador de saltos (tools/sim_saltos.js). Sale con código 1 si algo falla.
//   node tools/test_sim_saltos.js
const fs = require('fs');
const os = require('os');
const path = require('path');
const sim = require('./sim_saltos.js');

let fails = 0;
const check = (ok, what) => { console.log((ok ? '  ok    ' : '  FALLA ') + what); if (!ok) fails++; };

function load(text, opts = {}) {
  const f = path.join(os.tmpdir(), 'sim_test_' + process.pid + '.map');
  fs.writeFileSync(f, text);
  const m = sim.loadMap(f, opts);
  fs.unlinkSync(f);
  return m;
}
// Un pozo de ancho 6 (columnas 3-8) y 22 de alto; se sale por una repisa a la derecha (fila 8).
function shaft(wall) {
  const rows = [];
  for (let r = 0; r < 31; r++) {
    if (r < 8) rows.push('.'.repeat(21));
    else if (r === 8) rows.push('.'.repeat(9) + 'T'.repeat(12));
    else rows.push('..' + wall + '......' + wall + '.'.repeat(11));
  }
  rows.push('T'.repeat(21));
  return rows.join('\n') + '\n';
}
function reaches(m, skills, from, goalRow) {
  const r = sim.analyse(m, skills, from.row, from.col);
  return r.S.some((s) => s.row === goalRow && s.id in r.dist);
}
const start = { row: 31, col: 5 };

console.log('[Simulador de saltos]');
check(!reaches(load(shaft('B')), '', start, 8), 'sin habilidades no se sale del pozo');
check(!reaches(load(shaft('B')), 'DJ', start, 8), 'con dash y doble salto no se sale de un pozo de 22');
check(reaches(load(shaft('B')), 'W', start, 8), 'con Agarre se sale de un pozo de paredes normales');
check(!reaches(load(shaft('%')), 'W', start, 8), 'con Agarre no se sale si las paredes son lisas (%)');

// $ intacta es sólida; rota deja pasar. Un muro de $ cierra un pasillo.
const hall = 'BBBBBBBBBBBBBBBB\nB..............B\nB..............B\nB..............B\nB..............B\nB..............B\nBTTTTT$$$TTTTTTB\nBBBBBBBBBBBBBBBB\n';
check(load(hall).solid.has('$') && !load(hall, { broken: true }).solid.has('$'), '$ es sólida intacta y deja de serlo rota');

// Pinchos laterales: una tira { pegada a un muro izquierdo hace daño al rozarla.
const side = load('BBBBBBBBBBBB\nB{.........B\nB{.........B\nB{.........B\nBTTTTTTTTTTB\n');
const y = 3 * sim.CELL + sim.CELL - sim.P.hh; // de pie junto a la tira
const touch = sim.simulate(side, 2 * sim.CELL, y, { d1: -1, d2: -1, delay: 0, hold: 3, k: 10, dashAt: null }, { dash: false });
check(touch.hazard === true || touch.startHazard === true, 'los pinchos laterales { dañan al rozarlos');
const away = sim.simulate(side, 8 * sim.CELL, y, { d1: 1, d2: 1, delay: 0, hold: 3, k: 10, dashAt: null }, { dash: false });
check(away.hazard !== true, 'lejos de la tira no hay daño');

// El pozo con pinchos laterales de la Torre de Riego (W4): se sale con Agarre sin tocarlos,
// y hay maniobras que sí los tocan.
const torre = sim.loadMap(path.join(__dirname, '..', 'game', 'levels', 'torre_de_riego.map'));
const torreAnalysis = sim.analyse(torre, 'W', 28, 50);
const torreMeta = torreAnalysis.S.find((s) => s.row === 7 && s.c0 === 51);
check(torreMeta && torreMeta.id in torreAnalysis.dist, 'el pozo de la Torre de Riego se sale con Agarre sin tocar los pinchos laterales');
const torreOpts = { dash: false, dj: false, wall: true };
const torreY = 28 * sim.CELL - sim.P.hh;
check(sim.planGrid(torreOpts).some((plan) => sim.simulate(torre, 809, torreY, plan, torreOpts).hazard === true), 'y hay maniobras en ese pozo que sí los tocan');

process.exit(fails ? 1 : 0);
