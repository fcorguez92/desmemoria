// Generador de los enemigos (ver tools/rig_lib.js): cinco cascarones distintos,
// cada uno con su estilo, su arma y sus animaciones de reposo, andar, aviso del
// ataque, golpe y golpe recibido. Todos comparten el mismo orden de filas en la
// hoja (idle, walk, windup, strike, hit) para que el juego los anime igual.
// Uso: node tools/rig_enemigos.js   (escribe art/source/<tipo>.sprite)
const lib = require('./rig_lib');
const { lerp, ease, pose, keyed, makeStyle, add, mul } = lib;

const frames = (n, fn) => Array.from({ length: n }, (_, i) => fn(i / n, i));
const seq = (keys, n, extra) => Array.from({ length: n }, (_, i) => pose(Object.assign(keyed(keys, n === 1 ? 0 : i / (n - 1)), extra || {}, { phase: i * 0.9 })));
function footCycle(s, A, L) { // s en [0,1): [x, y] de la suela
  if (s < 0.4) { const k = s / 0.4; return [lerp(-A, A * 1.2, ease(k)), -L * Math.sin(Math.PI * k)]; }
  const k = (s - 0.4) / 0.6; return [lerp(A * 1.2, -A, k), 0];
}
// carrera/andar generico a partir de un patron de pose base
function walk(n, A, L, base, fn) {
  return frames(n, (u, i) => {
    const nf = footCycle(u % 1, A, L), ff = footCycle((u + 0.5) % 1, A, L);
    const sw = Math.sin(2 * Math.PI * (u - 0.1)), down = Math.cos(4 * Math.PI * (u - 0.17));
    return pose(Object.assign({}, base, { nfx: nf[0], nfy: nf[1], ffx: ff[0], ffy: ff[1], nfa: nf[1] < -2 ? 30 : 0, ffa: ff[1] < -2 ? 30 : 0, phase: 4 * Math.PI * u }, fn(u, sw, down, i)));
  });
}
// golpe recibido generico: el cuerpo se echa atras y todo se sacude
function hitAnim(extra) {
  return [
    pose(Object.assign({ hipx: -2, hipy: -17, lean: -10, bend: -6, head: 12, nfx: 5, ffx: -6, fx: -3, fy: 8, gx: 6, gy: 4, capeTx: 0.6, capeTy: 0.3, capeAmt: 0.8 }, extra)),
    pose(Object.assign({ hipx: -4, hipy: -16.5, lean: -18, bend: -8, head: 16, nfx: 5, ffx: -8, fx: -6, fy: 4, gx: 8, gy: 0, capeTx: 0.8, capeTy: 0.4, capeAmt: 0.9 }, extra)),
    pose(Object.assign({ hipx: -3, hipy: -17, lean: -12, bend: -4, head: 10, nfx: 5, ffx: -7, fx: -2, fy: 8, gx: 6, gy: 6, capeTx: 0.2, capeTy: 0.7, capeAmt: 0.6 }, extra)),
    pose(Object.assign({ hipx: -1, hipy: -17.6, lean: -4, bend: 0, head: 3, nfx: 5, ffx: -5, fx: 3, fy: 12, gx: 0, gy: 12, capeTx: -0.4, capeTy: 0.6, capeAmt: 0.4 }, extra)),
  ];
}

const ENEMIES = {};

// ============ 1. Cascarón: tajo ============
{
  const S = makeStyle({
    head: 'bare', headR: 5.2, headDist: 4.6, eyeGlint: null,
    torsoR: [4.0, 4.4, 4.8, 2.4], armLen: 7.4, farArmLen: 7.2, armR: [2.6, 2.1, 1.9], farArmR: [2.4, 1.9, 1.7],
    nearLegR: [3.2, 2.7, 2.1, 1.6], farLegR: [3.2, 2.6, 2.1, 1.6],
    torsoCol: ['4', '3', '2'], nearLegCol: ['4', '3', '2'], farLegCol: ['3', '2', '1'], nearArmCol: ['4', '3', '2'], farArmCol: ['3', '2', '1'], handCol: ['4', '3'],
    cape: { on: true, base: 's', fold: 'r', edge: 't', segs: 4, seg: 5, w0: 2.6, wk: 0.8, rag: 4 },
    scarf: false, belt: false, pouch: false, noise: 0.16, wraps: ['s', 'r'], ribs: '2', eyeGlint: 'u', tunic: 6, waistBand: ['t', 's', 'r'], strap: 'r',
    weapon: 'knife', weaponLen: 16,
  });
  const idleBase = { hipx: 0, hipy: -17.6, lean: 14, bend: 12, head: -16, nfx: 5, ffx: -5, fx: 4, fy: 15, gx: -2, gy: 16, blade: 100, capeTx: -1, capeTy: 0.3, capeAmt: 0.35, capeWave: 0.5, hoodTy: -0.3 };
  ENEMIES.cascaron = {
    canvas: [96, 64], file: 'enemy', out: 'res://game/enemy/enemy_sheet.png', S,
    title: 'El cascarón', desc: 'figura pálida y sin rostro, encorvada, con trapos rojos y un cuchillo pesado y oxidado. Es lo que queda de quien la Desmemoria ha vaciado: sigue moviéndose por costumbre.',
    anims: {
      idle: { fps: 8, loop: true, frames: frames(8, (t) => { const b = Math.sin(t * 2 * Math.PI); return pose(Object.assign({}, idleBase, { hipy: -17.6 + 0.4 * b, lean: 14 + b, bend: 12 + 1.5 * b, fx: 4 + 0.6 * b, fy: 15 - 0.5 * b, gx: -2 - 0.5 * b, phase: t * 2 * Math.PI })); }) },
      walk: { fps: 24, loop: true, frames: walk(12, 7, 4, idleBase, (u, sw) => ({ hipx: 1, lean: 17, bend: 12, fx: 5 + 2 * sw, fy: 15, gx: -3 - 2 * sw, gy: 15, blade: 100 + 8 * sw, capeAmt: 0.55 })) },
      windup: { fps: 10, loop: false, frames: seq([
        { t: 0, ...idleBase },
        { t: 0.45, hipx: -1, hipy: -17.4, lean: 8, bend: 4, head: -6, nfx: 6, ffx: -6, fx: 6, fy: -4, gx: 2, gy: 8, blade: -40, capeTx: -0.4, capeTy: 0.4, capeAmt: 0.5, capeWave: 0.5, hoodTy: -0.3 },
        { t: 1, hipx: -3, hipy: -16.4, lean: -8, bend: -4, head: 2, nfx: 7, ffx: -7, fx: 3, fy: -15, gx: 8, gy: -9, blade: -88, capeTx: 0.2, capeTy: 0.5, capeAmt: 0.7, capeWave: 0.5, hoodTy: -0.3 },
      ], 6) },
      strike: { fps: 30, loop: false, frames: seq([
        { t: 0, hipx: -3, hipy: -16.4, lean: -8, bend: -4, head: 2, nfx: 7, ffx: -7, fx: 3, fy: -15, gx: 8, gy: -9, blade: -88, capeTx: 0.2, capeTy: 0.5, capeAmt: 0.7, capeWave: 0.5, hoodTy: -0.3 },
        { t: 0.3, hipx: 3, hipy: -16, lean: 22, bend: 8, head: -12, nfx: 11, ffx: -9, fx: 12, fy: -6, gx: -2, gy: 6, blade: -35, capeTx: -1, capeTy: 0.1, capeAmt: 0.9, capeWave: 0.5, hoodTy: -0.3 },
        { t: 0.6, hipx: 7, hipy: -15.4, lean: 36, bend: 12, head: -20, nfx: 14, ffx: -11, fx: 20, fy: 9, gx: -6, gy: 10, blade: 50, capeTx: -1, capeTy: -0.1, capeAmt: 1, capeWave: 0.5, hoodTy: -0.3 },
        { t: 1, hipx: 7, hipy: -15.6, lean: 38, bend: 12, head: -22, nfx: 14, ffx: -11, fx: 18, fy: 16, gx: -6, gy: 12, blade: 98, capeTx: -1, capeTy: 0.1, capeAmt: 0.9, capeWave: 0.5, hoodTy: -0.3 },
      ], 6) },
      hit: { fps: 16, loop: false, frames: hitAnim({ blade: 130 }) },
    },
  };
}

// ============ 2. Lancero: estocada de largo alcance ============
{
  const S = makeStyle({
    head: 'helm', headR: 5.4, headDist: 4.7,
    torsoR: [4.4, 4.8, 5.2, 2.6], armLen: 7.0, farArmLen: 7.0,
    torsoCol: ['4', '3', '2'], nearLegCol: ['4', '3', '2'], farLegCol: ['3', '2', '1'], nearArmCol: ['4', '3', '2'], farArmCol: ['3', '2', '1'], handCol: ['4', '3'],
    cape: { on: true, base: 'r', fold: '1', edge: 's', segs: 3, seg: 5, w0: 2.8, wk: 0.9, rag: 3 },
    scarf: false, belt: false, pouch: false, noise: 0.16, wraps: ['s', 'r'], ribs: '2', eyeGlint: 'u', tunic: 6, strap: 'b', waistBand: ['b', 'a', 'a'], shoulderPad: 3.6,
    weapon: 'spear', weaponLen: 36,
  });
  const idle = { hipx: 0, hipy: -18.6, lean: 7, bend: 4, head: -6, nfx: 7, ffx: -7, fx: 8, fy: 2, gx: 13, gy: -2, blade: -34, capeTx: -1, capeTy: 0.3, capeAmt: 0.3, capeWave: 0.5 };
  ENEMIES.lancero = {
    canvas: [144, 64], file: 'lancero', out: 'res://game/enemy/lancero_sheet.png', S,
    title: 'El lancero', desc: 'cascarón con yelmo oxidado y una lanza larga: castiga a distancia con una estocada que llega más lejos que cualquier tajo.',
    anims: {
      idle: { fps: 8, loop: true, frames: frames(8, (t) => { const b = Math.sin(t * 2 * Math.PI); return pose(Object.assign({}, idle, { hipy: -18.6 + 0.4 * b, lean: 7 + 0.8 * b, fx: 8 + 0.5 * b, fy: 2 - 0.4 * b, blade: -34 + 1.5 * b, phase: t * 2 * Math.PI })); }) },
      walk: { fps: 24, loop: true, frames: walk(12, 8, 4, idle, (u, sw, down) => ({ hipx: 1, hipy: -18.6 + 0.8 * down, lean: 9, fx: 8, fy: 2 - 0.8 * Math.abs(sw), gx: 13, gy: -2, blade: -34 + 3 * sw, capeAmt: 0.6 })) },
      windup: { fps: 10, loop: false, frames: seq([
        { t: 0, ...idle },
        { t: 0.5, hipx: -2, hipy: -18, lean: 0, bend: 0, head: 0, nfx: 8, ffx: -8, fx: 4, fy: 5, gx: 10, gy: 2, blade: -16, capeTx: -0.2, capeTy: 0.4, capeAmt: 0.5, capeWave: 0.5 },
        { t: 1, hipx: -4, hipy: -17.4, lean: -9, bend: -4, head: 6, nfx: 9, ffx: -9, fx: -3, fy: 6, gx: 5, gy: 5, blade: -4, capeTx: 0.4, capeTy: 0.4, capeAmt: 0.6, capeWave: 0.5 },
      ], 6) },
      strike: { fps: 30, loop: false, frames: seq([
        { t: 0, hipx: -4, hipy: -17.4, lean: -9, bend: -4, head: 6, nfx: 9, ffx: -9, fx: -3, fy: 6, gx: 5, gy: 5, blade: -4, capeTx: 0.4, capeTy: 0.4, capeAmt: 0.6, capeWave: 0.5 },
        { t: 0.25, hipx: 2, hipy: -17.4, lean: 10, bend: 4, head: -4, nfx: 12, ffx: -10, fx: 8, fy: 5, gx: 14, gy: 4, blade: -3, capeTx: -1, capeTy: 0.2, capeAmt: 0.8, capeWave: 0.5 },
        { t: 0.55, hipx: 8, hipy: -16.4, lean: 30, bend: 10, head: -18, nfx: 17, ffx: -13, fx: 16, fy: 3, gx: 21, gy: 2, blade: -2, capeTx: -1, capeTy: -0.1, capeAmt: 1, capeWave: 0.5 },
        { t: 1, hipx: 9, hipy: -16.4, lean: 32, bend: 10, head: -20, nfx: 18, ffx: -14, fx: 17, fy: 3, gx: 22, gy: 2, blade: -2, capeTx: -1, capeTy: -0.1, capeAmt: 1, capeWave: 0.5 },
      ], 6) },
      hit: { fps: 16, loop: false, frames: hitAnim({ blade: -30 }) },
    },
  };
}

// ============ 3. Arrojador: proyectil a distancia ============
{
  const S = makeStyle({
    head: 'hood', headR: 5.2, headDist: 4.7,
    hood: { main: 's', hi: 't', face: '1', mask: null, eye: ['u', 't'], trim: null },
    legLen: 10.2, torsoR: [3.4, 3.8, 4.2, 2.2], armLen: 7.6, farArmLen: 7.4, armR: [2.3, 1.9, 1.7], farArmR: [2.2, 1.8, 1.6],
    nearLegR: [3.0, 2.4, 1.9, 1.5], farLegR: [3.0, 2.4, 1.9, 1.5],
    torsoCol: ['3', '2', '2'], nearLegCol: ['3', '2', '1'], farLegCol: ['2', '1', '1'], nearArmCol: ['4', '3', '2'], farArmCol: ['3', '2', '1'], handCol: ['4', '3'],
    cape: { on: true, base: 's', fold: 'r', edge: 't', segs: 4, seg: 6, w0: 2.8, wk: 1.0, rag: 5 },
    scarf: false, belt: false, pouch: false, noise: 0.16, wraps: ['s', 'r'], ribs: '2', eyeGlint: 'u', tunic: 6, strap: 'r',
    weapon: 'shard', weaponLen: 9,
  });
  const idle = { hipx: 1, hipy: -19, lean: 20, bend: 14, head: -14, nfx: 6, ffx: -6, fx: 6, fy: 10, gx: -2, gy: 13, blade: 60, capeTx: -1, capeTy: 0.3, capeAmt: 0.4, capeWave: 0.6, hoodTy: -0.5 };
  ENEMIES.arrojador = {
    canvas: [96, 64], file: 'arrojador', out: 'res://game/enemy/arrojador_sheet.png', S,
    title: 'El arrojador', desc: 'cascarón encapuchado de rojo que no se acerca: arroja esquirlas de hueso desde lejos. Hay que cruzar la distancia a saltos o desviar el tiro.',
    anims: {
      idle: { fps: 8, loop: true, frames: frames(8, (t) => { const b = Math.sin(t * 2 * Math.PI); return pose(Object.assign({}, idle, { hipy: -19 + 0.4 * b, lean: 20 + b, bend: 14 + 1.5 * b, fx: 6 + 0.5 * b, fy: 10 - 0.5 * b, phase: t * 2 * Math.PI })); }) },
      walk: { fps: 24, loop: true, frames: walk(12, 8, 4.5, idle, (u, sw, down) => ({ hipx: 2, hipy: -19 + 0.7 * down, lean: 24, bend: 14, fx: 7 + 1.5 * sw, fy: 10, gx: -4 - 2 * sw, gy: 13, blade: 60 + 6 * sw, capeAmt: 0.7 })) },
      windup: { fps: 10, loop: false, frames: seq([
        { t: 0, ...idle },
        { t: 0.5, hipx: -1, hipy: -18.6, lean: 8, bend: 4, head: -4, nfx: 7, ffx: -7, fx: -2, fy: 0, gx: 6, gy: 4, blade: -20, capeTx: -0.3, capeTy: 0.4, capeAmt: 0.5, capeWave: 0.6, hoodTy: -0.5 },
        { t: 1, hipx: -3, hipy: -18.2, lean: -6, bend: -6, head: 4, nfx: 8, ffx: -8, fx: -6, fy: -13, gx: 10, gy: -2, blade: 5, capeTx: 0.3, capeTy: 0.5, capeAmt: 0.7, capeWave: 0.6, hoodTy: -0.5 },
      ], 6) },
      strike: { fps: 30, loop: false, frames: [
        ...seq([
          { t: 0, hipx: -3, hipy: -18.2, lean: -6, bend: -6, head: 4, nfx: 8, ffx: -8, fx: -6, fy: -13, gx: 10, gy: -2, blade: 5, capeTx: 0.3, capeTy: 0.5, capeAmt: 0.7, capeWave: 0.6, hoodTy: -0.5 },
          { t: 0.5, hipx: 3, hipy: -17.6, lean: 20, bend: 8, head: -12, nfx: 10, ffx: -9, fx: 10, fy: -10, gx: -2, gy: 5, blade: 0, capeTx: -1, capeTy: 0.1, capeAmt: 0.9, capeWave: 0.6, hoodTy: -0.5 },
        ], 3),
        ...seq([
          { t: 0, hipx: 6, hipy: -17, lean: 30, bend: 10, head: -20, nfx: 12, ffx: -10, fx: 19, fy: -3, gx: -6, gy: 8, blade: 5, capeTx: -1, capeTy: 0, capeAmt: 1, capeWave: 0.6, hoodTy: -0.5, noWeapon: true },
          { t: 1, hipx: 7, hipy: -17, lean: 32, bend: 10, head: -22, nfx: 12, ffx: -10, fx: 20, fy: 0, gx: -7, gy: 9, blade: 15, capeTx: -1, capeTy: 0, capeAmt: 1, capeWave: 0.6, hoodTy: -0.5, noWeapon: true },
        ], 3),
      ] },
      hit: { fps: 16, loop: false, frames: hitAnim({ blade: 100 }) },
    },
  };
}

// ============ 4. Coloso: mazazo lento y devastador ============
{
  const S = makeStyle({
    head: 'bare', headR: 4.6, headDist: 5.6, legLen: 11.6, waistLen: 8.6, chestLen: 8.6,
    torsoR: [6.6, 7.4, 8.4, 3.6], armLen: 9.2, farArmLen: 9.0, armR: [4.4, 3.8, 3.4], farArmR: [4.0, 3.4, 3.0],
    nearLegR: [5.2, 4.4, 3.6, 2.6], farLegR: [5.0, 4.2, 3.4, 2.5],
    torsoCol: ['4', '3', '2'], nearLegCol: ['4', '3', '2'], farLegCol: ['3', '2', '1'], nearArmCol: ['4', '3', '2'], farArmCol: ['3', '2', '1'], handCol: ['4', '3'],
    cape: { on: true, base: 's', fold: 'r', edge: 't', segs: 4, seg: 7, w0: 4.6, wk: 1.1, rag: 5 },
    scarf: false, belt: false, pouch: false, noise: 0.16, wraps: ['s', 'r'], ribs: '2', eyeGlint: 'u', tunic: 6, strap: 'b', waistBand: ['t', 's', 'r'], shoulderPad: 5.4,
    weapon: 'maul', weaponLen: 26,
  });
  const idle = { hipx: 0, hipy: -23, lean: 10, bend: 6, head: 0, nfx: 9, ffx: -9, fx: 9, fy: 6, gx: 2, gy: 12, blade: -112, capeTx: -1, capeTy: 0.3, capeAmt: 0.25, capeWave: 0.4 };
  const slamDust = (grow) => (out, f) => {
    // escombros y polvo donde cae la cabeza del mazo
    const gx = Math.floor(f.tip[0]), gy = 95;
    const pts = [[-9, 0, '3'], [-6, -2, '4'], [-3, -1, '3'], [4, -2, '4'], [7, -1, '3'], [10, 0, '3'], [-12, -4, '2'], [13, -3, '2'], [0, -4, '4'], [-5, -6, '3'], [6, -5, '3'], [-2, -8, '2'], [3, -9, '2']];
    for (const [dx, dy, c] of pts) if (Math.abs(dx) <= grow) out.set(gx + dx, gy + dy - Math.floor(grow / 4), c);
    for (let k = -grow; k <= grow; k += 2) out.set(gx + k, gy, '2');
  };
  ENEMIES.coloso = {
    canvas: [144, 96], file: 'coloso', out: 'res://game/enemy/coloso_sheet.png', S,
    title: 'El coloso', desc: 'cascarón enorme que arrastra un mazo de piedra. Avanza despacio y avisa mucho su golpe, pero un solo mazazo hace mucho daño: hay que apartarse a tiempo.',
    anims: {
      idle: { fps: 6, loop: true, frames: frames(8, (t) => { const b = Math.sin(t * 2 * Math.PI); return pose(Object.assign({}, idle, { hipy: -23 + 0.6 * b, lean: 10 + 0.8 * b, bend: 6 + 1.2 * b, fx: 9 + 0.4 * b, fy: 6 - 0.4 * b, phase: t * 2 * Math.PI })); }) },
      walk: { fps: 18, loop: true, frames: walk(12, 8, 5, idle, (u, sw, down) => ({ hipx: 1, hipy: -23 + 1.3 * down, lean: 12, bend: 6, fx: 9 + 0.5 * sw, fy: 6, gx: 3 - 1.5 * sw, gy: 12, blade: -112 + 4 * sw, capeAmt: 0.5 })) },
      windup: { fps: 8, loop: false, frames: seq([
        { t: 0, ...idle },
        { t: 0.5, hipx: -1, hipy: -22, lean: 0, bend: -4, head: 6, nfx: 10, ffx: -10, fx: 8, fy: -8, gx: 8, gy: -4, blade: -96, capeTx: -0.3, capeTy: 0.4, capeAmt: 0.5, capeWave: 0.4 },
        { t: 1, hipx: -3, hipy: -21, lean: -16, bend: -8, head: 10, nfx: 11, ffx: -11, fx: 6, fy: -22, gx: 10, gy: -18, blade: -92, capeTx: 0.3, capeTy: 0.5, capeAmt: 0.7, capeWave: 0.4 },
      ], 6) },
      strike: { fps: 24, loop: false, frames: seq([
        { t: 0, hipx: -3, hipy: -21, lean: -16, bend: -8, head: 10, nfx: 11, ffx: -11, fx: 6, fy: -22, gx: 10, gy: -18, blade: -92, capeTx: 0.3, capeTy: 0.5, capeAmt: 0.7, capeWave: 0.4 },
        { t: 0.3, hipx: 4, hipy: -20, lean: 14, bend: 6, head: -6, nfx: 13, ffx: -11, fx: 12, fy: -14, gx: 12, gy: -8, blade: -50, capeTx: -1, capeTy: 0, capeAmt: 0.9, capeWave: 0.4 },
        { t: 0.6, hipx: 10, hipy: -17.5, lean: 42, bend: 12, head: -22, nfx: 17, ffx: -12, fx: 22, fy: -6, gx: 18, gy: -2, blade: 56, capeTx: -1, capeTy: -0.2, capeAmt: 1, capeWave: 0.4 },
        { t: 1, hipx: 11, hipy: -17, lean: 46, bend: 12, head: -24, nfx: 17, ffx: -12, fx: 24, fy: -2, gx: 19, gy: 4, blade: 66, capeTx: -1, capeTy: -0.1, capeAmt: 1, capeWave: 0.4 },
      ], 6).map((p, i) => (i >= 4 ? Object.assign(p, { post: slamDust(i === 4 ? 9 : 13) }) : p)) },
      hit: { fps: 14, loop: false, frames: hitAnim({ hipy: -22, blade: -100, nfx: 9, ffx: -9 }) },
    },
  };
}

// ============ 5. Acechador: embestida con garras ============
{
  const S = makeStyle({
    head: 'bare', headR: 4.6, headDist: 4.4, legLen: 10.4, eyeGlint: 'u',
    torsoR: [3.2, 3.6, 3.8, 2.0], armLen: 8.4, farArmLen: 8.2, armR: [2.1, 1.7, 1.5], farArmR: [2.0, 1.6, 1.4],
    nearLegR: [3.0, 2.3, 1.8, 1.5], farLegR: [3.0, 2.2, 1.8, 1.4],
    torsoCol: ['4', '3', '2'], nearLegCol: ['4', '3', '2'], farLegCol: ['3', '2', '1'], nearArmCol: ['4', '3', '2'], farArmCol: ['3', '2', '1'], handCol: ['4', '3'],
    cape: { on: true, base: 's', fold: 'r', edge: 't', segs: 3, seg: 5, w0: 2.4, wk: 0.8, rag: 4 },
    scarf: false, belt: false, pouch: false, noise: 0.16, wraps: ['s', 'r'], ribs: '2', eyeGlint: 'u', tunic: 6, waistBand: ['t', 's', 'r'],
    weapon: 'claws', weaponLen: 7, farHand: 'claws',
  });
  const idle = { hipx: 3, hipy: -14.4, lean: 50, bend: 20, head: -42, nfx: 9, ffx: -5, fx: 8, fy: 11, gx: 6, gy: 13, blade: 70, gAng: 70, capeTx: -1, capeTy: 0.1, capeAmt: 0.6, capeWave: 0.6 };
  ENEMIES.acechador = {
    canvas: [112, 64], file: 'acechador', out: 'res://game/enemy/acechador_sheet.png', S,
    title: 'El acechador', desc: 'cascarón flaco y rápido que va casi a cuatro patas. Se agazapa un instante y se lanza en línea recta con las garras por delante: hay que esquivarlo por arriba o hacia atrás.',
    anims: {
      idle: { fps: 9, loop: true, frames: frames(8, (t) => { const b = Math.sin(t * 2 * Math.PI); return pose(Object.assign({}, idle, { hipy: -14.4 + 0.5 * b, lean: 50 + 1.5 * b, bend: 20 + 2 * b, fx: 8 + 0.8 * b, gx: 6 - 0.8 * b, phase: t * 2 * Math.PI })); }) },
      walk: { fps: 30, loop: true, frames: walk(12, 11, 6, idle, (u, sw, down) => ({ hipx: 4, hipy: -14.4 + 1.2 * down, lean: 54, bend: 22, head: -46, fx: 10 + 4 * sw, fy: 10, gx: 8 - 4 * sw, gy: 12, blade: 70 + 10 * sw, gAng: 60 - 10 * sw, capeAmt: 0.9 })) },
      windup: { fps: 12, loop: false, frames: seq([
        { t: 0, ...idle },
        { t: 0.5, hipx: 1, hipy: -11.6, lean: 62, bend: 26, head: -54, nfx: 11, ffx: -3, fx: 2, fy: 10, gx: 0, gy: 12, blade: 110, gAng: 110, capeTx: -0.8, capeTy: 0.2, capeAmt: 0.7, capeWave: 0.6 },
        { t: 1, hipx: -1, hipy: -9.8, lean: 68, bend: 28, head: -60, nfx: 12, ffx: -2, fx: -5, fy: 9, gx: -6, gy: 11, blade: 140, gAng: 140, capeTx: -0.6, capeTy: 0.3, capeAmt: 0.6, capeWave: 0.6 },
      ], 6) },
      strike: { fps: 24, loop: false, frames: seq([
        { t: 0, hipx: -1, hipy: -9.8, lean: 68, bend: 28, head: -60, nfx: 12, ffx: -2, fx: -5, fy: 9, gx: -6, gy: 11, blade: 140, gAng: 140, capeTx: -0.6, capeTy: 0.3, capeAmt: 0.6, capeWave: 0.6 },
        { t: 0.3, hipx: 4, hipy: -17, lean: 84, bend: 8, head: -72, nfx: -4, nfy: -6, ffx: -12, ffy: -9, nfa: 40, ffa: 50, fx: 15, fy: 2, gx: 13, gy: 5, blade: 5, gAng: 10, capeTx: -1, capeTy: 0, capeAmt: 1, capeWave: 0.3 },
        { t: 1, hipx: 6, hipy: -17.4, lean: 88, bend: 6, head: -76, nfx: -7, nfy: -7, ffx: -14, ffy: -10, nfa: 40, ffa: 50, fx: 17, fy: 1, gx: 15, gy: 4, blade: 0, gAng: 0, capeTx: -1, capeTy: -0.05, capeAmt: 1, capeWave: 0.25 },
      ], 6) },
      hit: { fps: 16, loop: false, frames: hitAnim({ hipy: -14.4, lean: 20, bend: 20, head: -20, nfx: 8, ffx: -4, blade: 100, gAng: 100 }) },
    },
  };
}

// ---------- salida ----------
const order = ['idle', 'walk', 'windup', 'strike', 'hit'];
const only = process.argv[2];
for (const [name, E] of Object.entries(ENEMIES)) {
  if (only && only !== name) continue;
  lib.setCanvas(E.canvas[0], E.canvas[1]);
  const header = [
    '# ' + E.title + ': ' + E.desc,
    '# Cada fotograma es un lienzo completo de ' + E.canvas[0] + 'x' + E.canvas[1] + ' con los pies en la fila de abajo.',
    '# Lo genera el esqueleto de tools/rig_enemigos.js (ver tools/rig_lib.js); para cambiar',
    '# el movimiento se edita el esqueleto y se regenera, no estos fotogramas a mano.',
    '# Leyenda: ver art/palette.txt. El punto (.) es transparente.'];
  const info = lib.writeSprite('art/source/' + E.file + '.sprite', header, E.out, order, E.anims, E.S);
  // donde sale el proyectil / la punta del arma en el golpe (respecto a los pies)
  const strike = E.anims.strike.frames[E.anims.strike.frames.length - 1];
  const r = lib.render(strike, E.S);
  const cs = lib.canvasSize();
  console.log(name, JSON.stringify(info), 'tip-strike=(' + (r.tip[0] - cs.OX).toFixed(1) + ',' + (r.tip[1] - cs.OY).toFixed(1) + ')');
}
