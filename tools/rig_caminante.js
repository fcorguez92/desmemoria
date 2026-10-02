// Generador del Caminante (ver tools/rig_lib.js): define sus poses y animaciones.
// Uso: node tools/rig_caminante.js   (escribe art/source/player.sprite)
const lib = require("./rig_lib");
const { rad, add, lerp, ease, clamp, pose, figure, keyed } = lib;
lib.setCanvas(112, 64);
const S = lib.HERO;

// ---------- animaciones ----------
// Referencia: asesino agazapado, muy inclinado hacia delante, con el puño de la
// espada junto al pecho y la hoja curva colgando por debajo y hacia delante; el
// otro brazo echado atras para equilibrar.
function footCycle(s, A, L) { // s en [0,1): devuelve [x, y] de la suela
  if (s < 0.38) { const k = s / 0.38; return [lerp(-A, A * 1.25, ease(k)), -L * Math.sin(Math.PI * k) * (k < 0.5 ? 1.15 : 1)]; }
  const k = (s - 0.38) / 0.62; return [lerp(A * 1.25, -A, k), 0];
}

const anims = {};

// reposo: agazapado y alerta; respira, el peso se mece y la capa ondea
anims.idle = { fps: 10, loop: true, frames: Array.from({ length: 10 }, (_, i) => {
  const t = i / 10, b = Math.sin(t * 2 * Math.PI), s = Math.sin(t * 2 * Math.PI + 1);
  return pose({ hipx: 2.5 + 0.6 * s, hipy: -17.4 + 0.5 * b, lean: 24 + 1.5 * b, bend: 8 + 1.5 * b, head: -16 + 1 * s,
    nfx: 8, ffx: -7, fx: 2 + 0.6 * b, fy: 12 - 0.8 * b, gx: 8 + 0.6 * s, gy: 6 + 0.5 * b, blade: 180 + 3 * b,
    capeTx: -1, capeTy: 0.25, capeAmt: 0.45 + 0.08 * b, capeWave: 0.4, phase: t * 2 * Math.PI,
    scAmt: 0.6 + 0.1 * s, scTy: 0.1 + 0.1 * b, hoodTy: -0.5 });
}) };

// carrera: muy curvado, casi a ras de suelo, brazo libre atras y la daga al pecho
anims.run = { fps: 40, loop: true, frames: Array.from({ length: 14 }, (_, i) => {
  const u = i / 14;
  const nf = footCycle(u % 1, 11.5, 9), ff = footCycle((u + 0.5) % 1, 11.5, 9);
  const down = Math.cos(4 * Math.PI * (u - 0.17));
  const sw = Math.sin(2 * Math.PI * (u - 0.1));
  return pose({ hipx: 4, hipy: -16.6 + 1.5 * down, lean: 52, bend: 17, head: -38 + 1.5 * down,
    nfx: nf[0], nfy: nf[1], ffx: ff[0], ffy: ff[1], nfa: nf[1] < -3 ? 38 : 0, ffa: ff[1] < -3 ? 38 : 0,
    fx: -3 + 1.5 * sw, fy: 12 - 1.4 * Math.abs(sw), gx: 9 + 3 * sw, gy: 4 - 1.5 * Math.abs(sw), blade: 184 + 4 * sw,
    capeTx: -1, capeTy: -0.32 + 0.1 * down, capeAmt: 1, capeWave: 0.5, phase: 4 * Math.PI * u,
    scTx: -1, scTy: -0.15, scAmt: 1, hoodTy: -0.7, lines: 3 });
}) };

// salto: impulso y piernas recogidas, con la daga siempre junto al pecho
anims.jump = { fps: 24, loop: false, frames: [
  pose({ hipy: -16.5, lean: 28, bend: 10, head: -18, hipx: 2, nfx: 6, nfy: 0, ffx: -6, ffy: 0, fx: -2, fy: 11, gx: 8, gy: 6, blade: 182, capeTy: 0.9, capeTx: -0.4, capeAmt: 0.5, scTy: 0.9, scTx: -0.5, scAmt: 0.6 }),
  pose({ hipy: -19.5, lean: 26, bend: 8, head: -16, hipx: 2, nfx: 7, nfy: -5, ffx: -6, ffy: -7, nfa: 20, ffa: 40, fx: -3, fy: 10, gx: 9, gy: 0, blade: 184, capeTy: 1, capeTx: -0.5, capeAmt: 0.75, scTy: 1, scTx: -0.45, scAmt: 0.8 }),
  pose({ hipy: -20, lean: 22, bend: 8, head: -14, hipx: 2, nfx: 8, nfy: -8, ffx: -6, ffy: -10, nfa: 25, ffa: 45, fx: -3, fy: 10, gx: 9, gy: -1, blade: 184, capeTy: 1, capeTx: -0.6, capeAmt: 0.85, scTy: 1, scTx: -0.55, scAmt: 0.85 }),
  pose({ hipy: -20, lean: 20, bend: 6, head: -12, hipx: 2, nfx: 8, nfy: -9, ffx: -5, ffy: -11, nfa: 30, ffa: 50, fx: -3, fy: 10, gx: 8, gy: 0, blade: 184, capeTy: 0.8, capeTx: -0.8, capeAmt: 0.8, scTy: 0.7, scTx: -0.9, scAmt: 0.8 }),
] };

// caida: cuerpo recogido, capa hacia arriba, daga lista al frente
anims.fall = { fps: 16, loop: true, frames: Array.from({ length: 4 }, (_, i) => {
  const t = i / 4, s = Math.sin(t * 2 * Math.PI);
  return pose({ hipy: -20, lean: 14, bend: 6, head: -8, hipx: 1, nfx: 6, nfy: -2 + s, ffx: -5, ffy: -4 - s, nfa: 15, ffa: 25,
    fx: -2, fy: 9 + s, gx: 10, gy: -3 - s, blade: 184 + 3 * s, capeTy: -1, capeTx: -0.35, capeAmt: 1, capeWave: 0.6, phase: t * 2 * Math.PI,
    scTy: -1, scTx: -0.4, scAmt: 1, hoodTy: -1 });
}) };

// ataque: tajo con la daga del reves. El puño sale del pecho, la muñeca hace girar
// la hoja curva y el golpe sube en arco; todo el cuerpo se lanza y gira.
const ATT = [
  // preparado: la daga atras, junto a la cadera
  { t: 0.00, hipx: 2, hipy: -17.4, lean: 24, bend: 8, head: -16, nfx: 8, ffx: -7, nfy: 0, ffy: 0, fx: 2, fy: 12, gx: 8, gy: 6, blade: 180, capeTx: -1, capeTy: 0.3, capeAmt: 0.5, scTx: -1, scAmt: 0.6 },
  // carga: el cuerpo se tuerce hacia atras y el puño va aun mas atras, hoja hacia detras
  { t: 0.07, hipx: -2, hipy: -16.6, lean: 12, bend: -4, head: -4, nfx: 9, ffx: -9, nfy: 0, ffy: 0, fx: -9, fy: 9, gx: 12, gy: 2, blade: 196, capeTx: 0.3, capeTy: 0.4, capeAmt: 0.7, scTx: 0.3, scAmt: 0.7 },
  // arranca: la cadera empuja y el puño cruza junto a la cintura, la hoja baja
  { t: 0.14, hipx: 5, hipy: -15.8, lean: 34, bend: 12, head: -22, nfx: 13, ffx: -11, nfy: 0, ffy: 0, fx: 4, fy: 13, gx: -9, gy: 6, blade: 125, capeTx: -1, capeTy: 0.1, capeAmt: 0.9, scTx: -1, scAmt: 0.9 },
  // golpe: brazo extendido al frente y la hoja corta hacia delante
  { t: 0.22, hipx: 9, hipy: -15, lean: 46, bend: 14, head: -30, nfx: 16, ffx: -13, nfy: 0, ffy: 0, fx: 19, fy: 3, gx: -12, gy: 5, blade: 25, capeTx: -1, capeTy: -0.2, capeAmt: 1, scTx: -1, scAmt: 1 },
  // sigue: el arco asciende al frente
  { t: 0.34, hipx: 11, hipy: -15.4, lean: 52, bend: 12, head: -34, nfx: 17, ffx: -14, nfy: 0, ffy: 0, fx: 20, fy: -6, gx: -11, gy: 6, blade: -22, capeTx: -1, capeTy: -0.4, capeAmt: 1, scTx: -1, scTy: -0.3, scAmt: 1 },
  // recupera: el puño vuelve atras
  { t: 0.50, hipx: 8, hipy: -16.4, lean: 40, bend: 12, head: -26, nfx: 15, ffx: -12, nfy: 0, ffy: 0, fx: 12, fy: 4, gx: -2, gy: 7, blade: 70, capeTx: -1, capeTy: 0, capeAmt: 0.9, scTx: -1, scAmt: 0.9 },
  { t: 0.72, hipx: 5, hipy: -17, lean: 30, bend: 10, head: -20, nfx: 11, ffx: -8, nfy: 0, ffy: 0, fx: 3, fy: 11, gx: 5, gy: 7, blade: 150, capeTx: -1, capeTy: 0.2, capeAmt: 0.7, scTx: -1, scAmt: 0.8 },
  { t: 1.00, hipx: 2, hipy: -17.4, lean: 24, bend: 8, head: -16, nfx: 8, ffx: -7, nfy: 0, ffy: 0, fx: 2, fy: 12, gx: 8, gy: 6, blade: 180, capeTx: -1, capeTy: 0.3, capeAmt: 0.5, scTx: -1, scAmt: 0.6 },
];
const attFrames = Array.from({ length: 12 }, (_, i) => pose(Object.assign(keyed(ATT, i / 11), { phase: i * 0.8 })));
{
  const tipAt = t => figure(pose(keyed(ATT, clamp(t, 0, 1)))).tip;
  for (let i = 0; i < attFrames.length; i++) {
    const t = i / 11;
    if (i >= 2 && i <= 8) {
      const pts = [];
      for (let k = 0; k <= 12; k++) pts.push(tipAt(t - 0.15 + 0.15 * k / 12));
      attFrames[i].trailFrom = pts;
    }
  }
}
anims.attack = { fps: 40, loop: false, frames: attFrames };

// guardia: puño alto delante del pecho con la hoja curva cubriendo el cuerpo
anims.parry = { fps: 20, loop: false, frames: [
  pose({ hipx: 1, hipy: -17.4, lean: 18, bend: 4, head: -10, nfx: 8, ffx: -8, fx: 6, fy: 2, gx: -4, gy: 8, blade: 100 }),
  pose({ hipx: 0, hipy: -17, lean: 12, bend: 2, head: -6, nfx: 9, ffx: -9, fx: 12, fy: -7, gx: -3, gy: 6, blade: 96 }),
  pose({ hipx: -0.5, hipy: -17, lean: 10, bend: 1, head: -4, nfx: 9, ffx: -9, fx: 14, fy: -9, gx: -2, gy: 5, blade: 94 }),
  pose({ hipx: -0.5, hipy: -17, lean: 10, bend: 1, head: -4, nfx: 9, ffx: -9, fx: 14, fy: -9, gx: -2, gy: 5, blade: 94, capeAmt: 0.35 }),
] };

// golpe recibido: el cuerpo se dobla hacia atras y todo se sacude
anims.hit = { fps: 16, loop: false, frames: [
  pose({ hipx: -3, hipy: -18, lean: -14, bend: -10, head: 12, nfx: 6, ffx: -8, fx: -5, fy: -8, gx: 8, gy: -4, blade: 140, capeTx: 1, capeTy: 0.3, capeAmt: 0.9, scTx: 1, scTy: 0.2, scAmt: 0.9 }),
  pose({ hipx: -5, hipy: -17, lean: -22, bend: -12, head: 14, nfx: 5, ffx: -10, fx: -8, fy: -4, gx: 9, gy: -1, blade: 150, capeTx: 0.8, capeTy: 0.5, capeAmt: 0.9, scTx: 0.8, scAmt: 0.9 }),
  pose({ hipx: -4, hipy: -17.5, lean: -10, bend: -6, head: 8, nfx: 5, ffx: -9, fx: -2, fy: 3, gx: 7, gy: 4, blade: 125, capeTx: 0.2, capeTy: 0.8, capeAmt: 0.6 }),
  pose({ hipx: -1, hipy: -18, lean: 8, bend: 0, head: -4, nfx: 6, ffx: -7, fx: 6, fy: 8, gx: -2, gy: 9, blade: 100, capeTx: -0.4, capeTy: 0.6, capeAmt: 0.4 }),
] };

// dash: casi a ras de suelo, hoja hacia atras, imagenes residuales y lineas
anims.dash = { fps: 40, loop: false, frames: [
  pose({ hipx: -1, hipy: -15.5, lean: 30, bend: 12, head: -18, nfx: 9, ffx: -10, fx: -5, fy: 6, gx: 8, gy: 8, blade: 185, capeTx: -1, capeTy: 0.1, capeAmt: 0.8, scAmt: 0.9 }),
  pose({ hipx: 5, hipy: -13, lean: 64, bend: 14, head: -42, nfx: 15, nfy: -2, nfa: 12, ffx: -18, ffy: -6, ffa: 25, fx: -3, fy: 8, gx: 10, gy: 12, blade: 190, capeTx: -1, capeTy: -0.05, capeAmt: 1, capeWave: 0.25, scAmt: 1, scTy: -0.05, ghost: 1, lines: 4, hoodTy: -0.25 }),
  pose({ hipx: 6, hipy: -12.5, lean: 70, bend: 12, head: -48, nfx: 18, nfy: -3, nfa: 12, ffx: -20, ffy: -7, ffa: 25, fx: -5, fy: 9, gx: 12, gy: 13, blade: 192, capeTx: -1, capeTy: -0.02, capeAmt: 1, capeWave: 0.2, scAmt: 1, scTy: -0.02, ghost: 2, lines: 6, phase: 1, hoodTy: -0.2 }),
  pose({ hipx: 6, hipy: -12.5, lean: 70, bend: 12, head: -48, nfx: 19, nfy: -3, nfa: 12, ffx: -21, ffy: -6, ffa: 25, fx: -6, fy: 9, gx: 12, gy: 13, blade: 192, capeTx: -1, capeTy: 0, capeAmt: 1, capeWave: 0.2, scAmt: 1, scTy: 0, ghost: 2, lines: 6, phase: 2, hoodTy: -0.2 }),
  pose({ hipx: 5, hipy: -13.5, lean: 58, bend: 12, head: -38, nfx: 15, nfy: -2, ffx: -17, ffy: -4, ffa: 20, fx: -1, fy: 8, gx: 9, gy: 11, blade: 188, capeTx: -1, capeTy: 0.1, capeAmt: 1, scAmt: 1, ghost: 1, lines: 3, phase: 3 }),
  pose({ hipx: 3, hipy: -17, lean: 32, bend: 10, head: -20, nfx: 10, ffx: -8, fx: 7, fy: 9, gx: -4, gy: 9, blade: 183, capeTx: -1, capeTy: 0.3, capeAmt: 0.8, scAmt: 0.8 }),
] };

// ---------- salida ----------
const order = ["idle", "run", "jump", "fall", "attack", "parry", "hit", "dash"];
const header = [
  "# El caminante, un asesino de la memoria: capucha, mascara y bufanda de luz azul",
  "# y una daga curva que empuña del reves. Cada fotograma es un lienzo completo de",
  "# 112x64 con los pies en la fila de abajo.",
  "# Lo genera el esqueleto de tools/rig_caminante.js (columna curvada, piernas y",
  "# brazos con cinematica inversa, capa y bufanda con inercia); para cambiar el",
  "# movimiento se edita el esqueleto y se regenera, no estos fotogramas a mano.",
  "# Leyenda: ver art/palette.txt. El punto (.) es transparente."];
const info = lib.writeSprite(process.argv[2] || "art/source/player.sprite", header, "res://game/player/player_sheet.png", order, anims, S);
console.log(JSON.stringify(info));
