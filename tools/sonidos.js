// Generador de los efectos de sonido: los sintetiza por código (ruido filtrado,
// tonos, campanas, voces graves) y los escribe como .wav en game/audio/sfx/.
// Misma idea que el arte: nada de descargas, una sola fuente de verdad (este script).
// El tono buscado es el de Hollow Knight: sutil, grave, húmedo, con eco de caverna
// (el eco lo pone el bus "SFX" del juego, ver core/audio/sfx.gd).
//
// Uso: node tools/sonidos.js            (todos)
//      node tools/sonidos.js step ui    (solo los que empiecen por esos nombres)
// Cada sonido sale en varias variantes (nombre_1.wav, nombre_2.wav...) y el juego
// elige una al azar para que no suene a máquina.
const fs = require('fs');
const path = require('path');

const SR = 32000;
const OUT = path.join(__dirname, '..', 'game', 'audio', 'sfx');
const TAU = Math.PI * 2;

// ---------- utilidades ----------
function mulberry(seed) {
  let a = seed >>> 0;
  return () => { a = (a + 0x6D2B79F5) >>> 0; let t = Math.imul(a ^ (a >>> 15), 1 | a); t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t; return ((t ^ (t >>> 14)) >>> 0) / 4294967296; };
}
const hashStr = s => { let h = 2166136261; for (const c of s) h = Math.imul(h ^ c.charCodeAt(0), 16777619); return h >>> 0; };
const buf = sec => new Float32Array(Math.max(1, Math.ceil(sec * SR)));
const gen = (sec, fn) => { const b = buf(sec); for (let i = 0; i < b.length; i++) b[i] = fn(i / SR, i); return b; };
const noise = (sec, r) => gen(sec, () => r() * 2 - 1);
const val = (f, t) => typeof f === 'function' ? f(t) : f;

function tone(sec, freq, shape) {
  let ph = 0;
  return gen(sec, t => {
    ph += val(freq, t) / SR;
    if (shape === 'saw') return 2 * (ph % 1) - 1;
    if (shape === 'tri') return 4 * Math.abs((ph % 1) - 0.5) - 1;
    return Math.sin(TAU * ph);
  });
}
// envolvente: subida lineal `a` y caída exponencial con constante `d`
function env(b, a, d) {
  for (let i = 0; i < b.length; i++) { const t = i / SR; b[i] *= Math.min(t / Math.max(a, 1e-4), 1) * Math.exp(-t / d); }
  return b;
}
function mix(dst, src, gain = 1, at = 0) {
  const o = Math.round(at * SR);
  for (let i = 0; i < src.length && o + i < dst.length; i++) if (o + i >= 0) dst[o + i] += src[i] * gain;
  return dst;
}
const sat = (b, k = 2) => { const n = Math.tanh(k); for (let i = 0; i < b.length; i++) b[i] = Math.tanh(b[i] * k) / n; return b; };
const mul = (b, fn) => { for (let i = 0; i < b.length; i++) b[i] *= fn(i / SR); return b; };

// filtro biquad (RBJ). `f` puede ser una función del tiempo para barridos.
function biquad(x, type, f, q = 0.707) {
  const y = new Float32Array(x.length);
  let x1 = 0, x2 = 0, y1 = 0, y2 = 0;
  for (let i = 0; i < x.length; i++) {
    const fc = Math.min(Math.max(val(f, i / SR), 20), SR * 0.45);
    const w = TAU * fc / SR, c = Math.cos(w), al = Math.sin(w) / (2 * q);
    let b0, b1, b2;
    if (type === 'lp') { b0 = (1 - c) / 2; b1 = 1 - c; b2 = b0; }
    else if (type === 'hp') { b0 = (1 + c) / 2; b1 = -(1 + c); b2 = b0; }
    else { b0 = al; b1 = 0; b2 = -al; }
    const a0 = 1 + al, a1 = -2 * c, a2 = 1 - al;
    const o = (b0 * x[i] + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2) / a0;
    x2 = x1; x1 = x[i]; y2 = y1; y1 = o; y[i] = o;
  }
  return y;
}
const lp = (b, f, q) => biquad(b, 'lp', f, q);
const hp = (b, f, q) => biquad(b, 'hp', f, q);
const bp = (b, f, q) => biquad(b, 'bp', f, q);

// golpe de campana: parciales inarmónicos que se apagan a distinto ritmo
function bell(sec, f0, ratios, decays, gains, attack = 0.002) {
  const out = buf(sec);
  ratios.forEach((r, k) => mix(out, env(tone(sec, f0 * r), attack, decays[k]), gains[k]));
  return out;
}

// voz grave (gruñido, quejido): fuente de dientes de sierra con vibrato y
// temblor, pasada por formantes [frecuencia, ancho, ganancia], con aliento y
// modulación de amplitud ("rugosidad") para que raspe.
function voice(o, r) {
  const { f0a, f0b, dur, formants, rough = 0, depth = 0.6, breath = 0.3, attack = 0.04, release = 0.12, hump = 0 } = o;
  let ph = 0;
  const src = gen(dur, t => {
    const k = t / dur;
    let f = f0a + (f0b - f0a) * k + hump * Math.sin(Math.PI * k);
    f *= 1 + 0.025 * (r() - 0.5) + 0.012 * Math.sin(TAU * 5.3 * t);
    ph += f / SR;
    const s = 2 * (ph % 1) - 1;
    return s * Math.abs(s) * 0.8 + s * 0.2; // algo de pulso, menos áspero que la sierra pura
  });
  const out = buf(dur);
  for (const [f, bw, g] of formants) mix(out, bp(src, f, Math.max(0.6, f / bw)), g);
  if (breath > 0) mix(out, bp(noise(dur, r), formants[Math.min(1, formants.length - 1)][0] * 1.3, 0.9), breath);
  mul(out, t => {
    let a = Math.min(t / attack, 1) * Math.min(Math.max((dur - t) / release, 0), 1);
    if (rough > 0) a *= 1 - depth * 0.5 * (1 + Math.sin(TAU * rough * t));
    return a;
  });
  return out;
}

// chasquido de inicio: unos milisegundos de ruido medio que marcan el instante del
// impacto (los graves de un golpe tardan en notarse y en altavoces pequeños casi no se oyen)
function snap(b, r, gain, f = 1700) { return mix(b, env(bp(noise(0.03, r), f, 1.2), 0.0003, 0.004), gain); }

function finish(b, peak = 0.9) {
  const fin = Math.round(0.001 * SR), fout = Math.round(0.012 * SR);
  let m = 0;
  for (let i = 0; i < b.length; i++) { if (i < fin) b[i] *= i / fin; const j = b.length - 1 - i; if (j < fout) b[i] *= j / fout; m = Math.max(m, Math.abs(b[i])); }
  const k = m > 0 ? peak / m : 1;
  for (let i = 0; i < b.length; i++) b[i] *= k;
  return b;
}

function writeWav(file, b) {
  const data = Buffer.alloc(44 + b.length * 2);
  data.write('RIFF', 0); data.writeUInt32LE(36 + b.length * 2, 4); data.write('WAVEfmt ', 8);
  data.writeUInt32LE(16, 16); data.writeUInt16LE(1, 20); data.writeUInt16LE(1, 22);
  data.writeUInt32LE(SR, 24); data.writeUInt32LE(SR * 2, 28); data.writeUInt16LE(2, 32); data.writeUInt16LE(16, 34);
  data.write('data', 36); data.writeUInt32LE(b.length * 2, 40);
  for (let i = 0; i < b.length; i++) data.writeInt16LE(Math.round(Math.max(-1, Math.min(1, b[i])) * 32767), 44 + i * 2);
  fs.writeFileSync(file, data);
}

// ---------- catálogo ----------
const sounds = {};
const def = (name, variants, fn) => { sounds[name] = { variants, fn }; };

// --- pasos y movimiento del Caminante ---
// Pasos y aterrizajes según el material del suelo: piedra (seca y sorda), musgo
// (amortiguado) y madera (hueca, como un tablón).
const STEP = {
  stone: (i, r) => { const len = 0.16, f0 = 66 + i * 8, o = buf(len);
    mix(o, env(tone(len, t => f0 * Math.exp(-t * 20) + 40), 0.001, 0.04), 1.0);
    mix(o, env(bp(noise(len, r), 520 + i * 90, 1.0), 0.001, 0.03), 0.5);
    mix(o, env(hp(noise(len, r), 2600), 0.0005, 0.004), 0.07);
    return snap(lp(o, 2800), r, 0.3); },
  moss: (i, r) => { const len = 0.18, o = buf(len);
    mix(o, env(tone(len, t => 55 * Math.exp(-t * 16) + 36 + i * 4), 0.001, 0.045), 0.8);
    mix(o, env(lp(noise(len, r), 450 + i * 60), 0.001, 0.06), 0.8);
    return snap(lp(o, 1500), r, 0.14); },
  wood: (i, r) => { const len = 0.2, o = buf(len);
    mix(o, env(tone(len, t => 170 * Math.exp(-t * 22) + 105 + i * 8), 0.001, 0.05), 0.9);
    mix(o, env(bp(noise(len, r), 330 + i * 40, 3), 0.001, 0.07), 0.8);
    mix(o, env(bp(noise(len, r), 1150, 2), 0.0005, 0.008), 0.25);
    return snap(lp(o, 2600), r, 0.3); },
};
const LAND = {
  stone: (i, r) => { const len = 0.3, o = buf(len);
    mix(o, env(tone(len, t => 52 * Math.exp(-t * 15) + 30), 0.001, 0.09), 1.0);
    mix(o, env(tone(len, t => 120 * Math.exp(-t * 22) + 75), 0.001, 0.05), 0.55);
    mix(o, env(bp(noise(len, r), 420 + i * 60, 1.0), 0.001, 0.05), 0.4);
    mix(o, env(lp(noise(len, r), 700), 0.001, 0.09), 0.3);
    return snap(lp(o, 1800), r, 0.3); },
  moss: (i, r) => { const len = 0.3, o = buf(len);
    mix(o, env(tone(len, t => 46 * Math.exp(-t * 14) + 30), 0.001, 0.08), 0.9);
    mix(o, env(tone(len, t => 100 * Math.exp(-t * 22) + 65), 0.001, 0.05), 0.4);
    mix(o, env(lp(noise(len, r), 380), 0.001, 0.1), 0.7);
    return snap(lp(o, 1000), r, 0.14); },
  wood: (i, r) => { const len = 0.34, o = buf(len);
    mix(o, env(tone(len, t => 150 * Math.exp(-t * 18) + 85 + i * 6), 0.001, 0.07), 1.0);
    mix(o, env(bp(noise(len, r), 300 + i * 30, 3), 0.001, 0.1), 0.9);
    mix(o, env(bp(noise(len, r), 1000, 2), 0.0005, 0.01), 0.2);
    mix(o, env(bp(noise(len, r), 520, 5), 0.02, 0.08), 0.25, 0.03);
    return snap(lp(o, 2200), r, 0.3); },
};
for (const m of Object.keys(STEP)) { def('step_' + m, 4, STEP[m]); def('land_' + m, 3, LAND[m]); }
def('jump', 2, (i, r) => {
  const len = 0.2, o = buf(len);
  mix(o, env(bp(noise(len, r), t => 380 + 800 * t / len, 0.9), 0.03, 0.06), 0.8);
  mix(o, env(tone(len, 90 + i * 8), 0.002, 0.035), 0.5);
  return lp(o, 3500);
});
def('air_jump', 2, (i, r) => {
  const len = 0.3, o = buf(len);
  mix(o, env(bp(noise(len, r), t => 600 + 1400 * t / len, 1.6), 0.04, 0.08), 0.8);
  mix(o, env(tone(len, t => 520 + 260 * t / len, 'tri'), 0.04, 0.09), 0.12);
  return lp(o, 4500);
});
def('wall_jump', 2, (i, r) => {
  const len = 0.2, o = buf(len);
  const scrape = mul(bp(noise(len, r), 1400, 0.8), t => 0.6 + 0.4 * Math.sign(Math.sin(TAU * 62 * t)));
  mix(o, env(scrape, 0.005, 0.06), 0.8);
  mix(o, env(tone(len, 100), 0.002, 0.04), 0.6);
  return lp(o, 4000);
});
def('dash', 2, (i, r) => {
  const len = 0.38, o = buf(len);
  mix(o, env(bp(noise(len, r), t => 2200 * Math.exp(-t * 9) + 250, 0.8), 0.02, 0.11), 1.0);
  mix(o, sat(env(tone(len, t => 55 + 90 * Math.exp(-t * 12)), 0.005, 0.13), 1.5), 0.7);
  return lp(o, 5000);
});

// --- combate del Caminante ---
def('swing', 3, (i, r) => {
  const len = 0.26 + i * 0.02, o = buf(len);
  const s = 520 + i * 90;
  mix(o, env(bp(noise(len, r), t => s + 1900 * Math.sin(Math.PI * Math.min(t / len, 1)), 2.0), 0.035, 0.07), 1.0);
  mix(o, env(lp(noise(len, r), 700), 0.03, 0.08), 0.35);
  return lp(o, 5500);
});
def('hit_enemy', 3, (i, r) => {
  const len = 0.28, o = buf(len);
  mix(o, env(lp(noise(len, r), 3500), 0.001, 0.05), 1.0);
  mix(o, env(tone(len, t => 70 + 110 * Math.exp(-t * 30)), 0.001, 0.06), 0.9);
  mix(o, env(bp(noise(len, r), 320, 1.2), 0.004, 0.1), 0.5);
  mix(o, env(tone(len, 1700 + i * 200), 0.001, 0.02), 0.1);
  return lp(o, 5500);
});
def('parry', 2, (i, r) => {
  const len = 0.8, f = 430 + i * 40;
  const o = bell(len, f, [1, 2.32, 3.87, 5.4], [0.22, 0.14, 0.09, 0.05], [1, 0.7, 0.5, 0.3]);
  mix(o, env(hp(noise(len, r), 2000), 0.0005, 0.012), 0.8);
  mix(o, env(tone(len, 120), 0.001, 0.05), 0.5);
  mix(o, env(tone(len, t => 1800 + 600 * t / len), 0.05, 0.2), 0.08);
  return lp(o, 7000);
});
def('parry_raise', 1, (i, r) => {
  const len = 0.16, o = buf(len);
  mix(o, env(bp(noise(len, r), t => 900 + 900 * t / len, 2.5), 0.02, 0.05), 0.6);
  mix(o, env(tone(len, 300), 0.002, 0.03), 0.2);
  return lp(o, 4500);
});
def('player_hurt', 2, (i, r) => {
  const len = 0.5, o = buf(len);
  mix(o, env(tone(len, t => 40 + 60 * Math.exp(-t * 25)), 0.001, 0.09), 1.0);
  mix(o, env(lp(noise(len, r), 1800), 0.001, 0.06), 0.7);
  mix(o, voice({ f0a: 175 - i * 15, f0b: 105, dur: 0.3, formants: [[560, 120, 1], [1000, 160, 0.5]], breath: 0.25, attack: 0.01, release: 0.15 }, r), 0.55, 0.02);
  return lp(o, 4500);
});
def('player_die', 1, (i, r) => {
  const len = 2.2, o = buf(len);
  mix(o, env(sat(tone(len, t => 34 + 70 * Math.exp(-t * 1.6)), 1.6), 0.02, 0.8), 1.0);
  mix(o, env(lp(noise(len, r), 450), 0.3, 0.7), 0.4);
  mix(o, env(bp(noise(len, r), t => 900 * Math.exp(-t * 1.4) + 250, 1.0), 0.05, 0.4), 0.3, 0.1);
  mix(o, env(tone(len, 330), 0.7, 0.5), 0.1, 0.2);
  mix(o, env(tone(len, 495), 0.8, 0.5), 0.06, 0.25);
  return lp(o, 4000);
});
def('heal', 1, (i, r) => {
  const len = 1.0, o = buf(len);
  [0, 0.09, 0.18].forEach((at, k) => mix(o, env(tone(0.12, t => 170 + 150 * (t / 0.06) + k * 30), 0.003, 0.03), 0.8, at));
  mix(o, env(bp(noise(0.34, r), 1200, 1.4), 0.01, 0.1), 0.4);
  mul(o, t => t < 0.34 ? 1 - 0.4 * (0.5 + 0.5 * Math.sin(TAU * 26 * t)) : 1);
  mix(o, env(tone(0.8, 392), 0.15, 0.3), 0.18, 0.22);
  mix(o, env(tone(0.8, 588), 0.2, 0.3), 0.1, 0.24);
  return lp(o, 5000);
});

// --- mundo: cosas que se rompen, se recogen o se activan ---
def('break', 3, (i, r) => {
  const len = 0.5, o = buf(len);
  for (let k = 0; k < 7; k++) mix(o, env(bp(noise(0.06, r), 900 + r() * 2600, 3), 0.0005, 0.014), 0.6, r() * 0.1);
  mix(o, env(tone(len, t => 60 + 70 * Math.exp(-t * 25)), 0.001, 0.07), 0.9);
  mix(o, env(lp(noise(len, r), 2000), 0.002, 0.07), 0.6);
  for (let k = 0; k < 5; k++) mix(o, env(bp(noise(0.05, r), 1400 + r() * 2000, 4), 0.0005, 0.01), 0.22, 0.14 + r() * 0.3);
  return lp(o, 5500);
});
def('echo_collect', 1, (i, r) => {
  const len = 1.8, o = buf(len);
  [[294, 0], [440, 0.05], [588, 0.1]].forEach(([f, at]) => mix(o, bell(1.6, f, [1, 2.01, 3.0], [0.7, 0.45, 0.25], [1, 0.3, 0.12], 0.02), 0.5, at));
  mix(o, env(hp(noise(len, r), 5000), 0.1, 0.4), 0.05);
  mix(o, env(tone(len, t => 150 + 150 * t), 0.3, 0.5), 0.2);
  return lp(o, 6000);
});
def('ability_get', 1, (i, r) => {
  const len = 3.0, o = buf(len);
  const pad = buf(len);
  [0.995, 1, 1.006].forEach(d => mix(pad, tone(len, 147 * d, 'saw'), 0.3));
  mix(o, mul(lp(pad, t => 300 + 1800 * Math.min(t / 1.0, 1)), t => Math.min(t / 0.9, 1) * Math.exp(-Math.max(t - 1.0, 0) / 0.8)), 0.8);
  [[440, 0.9], [660, 0.98], [880, 1.06]].forEach(([f, at]) => mix(o, bell(1.9, f, [1, 2.76, 4.1], [1.0, 0.5, 0.2], [1, 0.25, 0.1]), 0.35, at));
  for (let k = 0; k < 12; k++) mix(o, env(hp(noise(0.08, r), 5500), 0.001, 0.03), 0.18, 1.0 + r() * 1.5);
  return lp(o, 6500);
});
def('anchor_rest', 1, (i, r) => {
  const len = 3.4, o = buf(len);
  mix(o, bell(len, 98, [1, 2, 2.76, 4.07, 5.4], [1.8, 1.2, 0.8, 0.5, 0.3], [1, 0.6, 0.4, 0.2, 0.1], 0.004), 0.9);
  mix(o, env(tone(len, 196), 0.5, 1.0), 0.18);
  mix(o, env(tone(len, 294), 0.7, 0.9), 0.1);
  mix(o, env(lp(noise(len, r), 500), 0.1, 0.7), 0.25);
  return lp(o, 4500);
});
def('skill_buy', 1, (i, r) => {
  const len = 1.2, o = buf(len);
  mix(o, bell(1.0, 330, [1, 2.4, 4.0], [0.5, 0.3, 0.15], [1, 0.3, 0.12]), 0.8);
  mix(o, bell(1.0, 495, [1, 2.4, 4.0], [0.5, 0.3, 0.15], [1, 0.3, 0.12]), 0.6, 0.11);
  for (let k = 0; k < 6; k++) mix(o, env(hp(noise(0.05, r), 4000), 0.0005, 0.01), 0.2, 0.05 + r() * 0.6);
  return lp(o, 6000);
});
def('ui_deny', 1, (i, r) => {
  const len = 0.22;
  return lp(env(sat(tone(len, 68, 'saw'), 2), 0.003, 0.06), 600);
});
def('shard_hit', 2, (i, r) => {
  const len = 0.16, o = buf(len);
  mix(o, env(bp(noise(len, r), 2500 + i * 400, 2), 0.0005, 0.02), 0.9);
  mix(o, env(tone(len, 900 - i * 100), 0.001, 0.03), 0.3);
  return lp(o, 6000);
});
def('shoot', 2, (i, r) => {
  const len = 0.26, o = buf(len);
  mix(o, env(bp(noise(len, r), t => 1400 + 2200 * t / len, 3), 0.01, 0.08), 0.9);
  mix(o, env(lp(noise(len, r), 800), 0.002, 0.03), 0.5);
  return lp(o, 6000);
});

// --- interfaz ---
def('ui_move', 2, (i, r) => {
  const len = 0.09, o = buf(len);
  mix(o, env(tone(len, 520 - i * 40), 0.001, 0.02), 0.6);
  mix(o, env(bp(noise(len, r), 2000, 1.5), 0.0005, 0.006), 0.15);
  return lp(o, 3500);
});
def('ui_accept', 1, (i, r) => {
  const len = 0.5, o = buf(len);
  mix(o, env(tone(len, 196), 0.004, 0.1), 0.8);
  mix(o, env(tone(len, 294), 0.004, 0.09), 0.5);
  mix(o, env(tone(len, 588), 0.004, 0.12), 0.12);
  mix(o, env(tone(len, 80), 0.002, 0.05), 0.6);
  return lp(o, 3500);
});
def('ui_back', 1, (i, r) => {
  const len = 0.24;
  return lp(env(tone(len, t => 262 - 85 * Math.min(t / 0.15, 1)), 0.004, 0.07), 1800);
});
def('ui_open', 1, (i, r) => {
  const len = 0.4, o = buf(len);
  mix(o, env(bp(noise(len, r), t => 300 + 700 * t / len, 1.0), 0.09, 0.1), 0.7);
  mix(o, env(tone(len, 110), 0.08, 0.1), 0.3);
  return lp(o, 3500);
});
def('ui_close', 1, (i, r) => {
  const len = 0.35, o = buf(len);
  mix(o, env(bp(noise(len, r), t => 900 - 600 * t / len, 1.0), 0.02, 0.08), 0.6);
  mix(o, env(tone(len, 90), 0.01, 0.07), 0.3);
  return lp(o, 3200);
});
def('begin', 1, (i, r) => {
  const len = 2.6, o = buf(len);
  mix(o, bell(len, 82, [1, 2, 2.76, 4.07], [1.5, 1.0, 0.6, 0.3], [1, 0.6, 0.35, 0.15]), 0.9);
  mix(o, env(bp(noise(len, r), t => 200 + 1500 * Math.min(t / 1.2, 1), 0.9), 0.5, 0.4), 0.5);
  mix(o, env(lp(noise(len, r), 400), 0.2, 0.9), 0.3);
  return lp(o, 4500);
});

// --- enemigos: armas ---
def('enemy_swing', 2, (i, r) => {
  const len = 0.34, o = buf(len);
  mix(o, env(bp(noise(len, r), t => 260 + 700 * Math.sin(Math.PI * Math.min(t / len, 1)), 1.3), 0.05, 0.09), 1.0);
  mix(o, env(lp(noise(len, r), 500), 0.05, 0.1), 0.4);
  return lp(o, 3500);
});
def('enemy_thrust', 2, (i, r) => {
  const len = 0.22, o = buf(len);
  mix(o, env(bp(noise(len, r), t => 700 + 2200 * Math.min(t / 0.1, 1), 1.8), 0.015, 0.05), 1.0);
  mix(o, env(tone(len, 150), 0.002, 0.03), 0.3);
  return lp(o, 5000);
});
def('enemy_slam', 2, (i, r) => {
  const len = 0.8, o = buf(len);
  mix(o, sat(env(tone(len, t => 30 + 50 * Math.exp(-t * 18)), 0.002, 0.2), 1.8), 1.0);
  mix(o, env(lp(noise(len, r), 1300), 0.002, 0.16), 0.8);
  for (let k = 0; k < 9; k++) mix(o, env(bp(noise(0.06, r), 700 + r() * 1800, 3), 0.0005, 0.015), 0.28, 0.03 + r() * 0.45);
  return snap(lp(o, 3500), r, 0.3, 1200);
});
def('enemy_lunge', 2, (i, r) => {
  const len = 0.32, o = buf(len);
  mix(o, env(bp(noise(len, r), t => 1300 * Math.exp(-t * 5) + 300, 1.0), 0.01, 0.1), 0.9);
  mix(o, env(mul(hp(noise(len, r), 2500), t => 0.5 + 0.5 * Math.sign(Math.sin(TAU * 95 * t))), 0.005, 0.08), 0.35);
  return lp(o, 5500);
});
def('enemy_step', 3, (i, r) => {
  const len = 0.14, o = buf(len);
  mix(o, env(tone(len, t => 55 * Math.exp(-t * 20) + 38 + i * 4), 0.002, 0.035), 1.0);
  mix(o, env(bp(noise(len, r), 500 + i * 100, 1.0), 0.001, 0.03), 0.6);
  return snap(lp(o, 2800), r, 0.25);
});
def('heavy_step', 3, (i, r) => {
  const len = 0.3, o = buf(len);
  mix(o, sat(env(tone(len, t => 48 * Math.exp(-t * 14) + 26 + i * 3), 0.002, 0.08), 1.4), 1.0);
  mix(o, env(lp(noise(len, r), 900), 0.002, 0.09), 0.6);
  return snap(lp(o, 2000), r, 0.25, 1200);
});

// --- enemigos: voces ---
const VOICES = {
  cascaron: { f0: 105, formants: [[480, 130, 1], [720, 180, 0.5], [150, 60, 0.6]], rough: 30, depth: 0.55, breath: 0.45, size: 1.0 },
  lancero: { f0: 135, formants: [[600, 130, 1], [1100, 190, 0.5]], rough: 22, depth: 0.4, breath: 0.3, size: 0.9 },
  arrojador: { f0: 200, formants: [[420, 110, 1], [1800, 260, 0.6]], rough: 38, depth: 0.5, breath: 0.7, size: 0.85 },
  coloso: { f0: 56, formants: [[280, 90, 1], [560, 140, 0.6]], rough: 16, depth: 0.7, breath: 0.35, size: 1.7 },
  acechador: { f0: 175, formants: [[700, 160, 1], [1500, 260, 0.6]], rough: 46, depth: 0.65, breath: 0.55, size: 0.8 },
};
const EVENTS = {
  alert: { variants: 1, make: (v, k) => ({ f0a: v.f0, f0b: v.f0 * 0.72, dur: 0.65 * v.size, hump: v.f0 * 0.1, attack: 0.1, release: 0.25 }) },
  attack: { variants: 2, make: (v, k) => ({ f0a: v.f0 * 0.95, f0b: v.f0 * (k ? 1.3 : 1.15), dur: 0.38 * v.size, attack: 0.03, release: 0.14, rough: v.rough * 1.3 }) },
  hurt: { variants: 2, make: (v, k) => ({ f0a: v.f0 * 1.35, f0b: v.f0 * 0.85, dur: 0.3 * v.size, attack: 0.008, release: 0.14 }) },
  die: { variants: 1, make: (v, k) => ({ f0a: v.f0 * 1.15, f0b: v.f0 * 0.45, dur: 1.0 * v.size, attack: 0.02, release: 0.5, breath: v.breath * 1.5 }) },
};
for (const [name, v] of Object.entries(VOICES)) {
  for (const [ev, e] of Object.entries(EVENTS)) {
    def(name + '_' + ev, e.variants, (i, r) => {
      const o = voice(Object.assign({ rough: v.rough, depth: v.depth, breath: v.breath, formants: v.formants }, e.make(v, i)), r);
      return lp(sat(o, 1.3), name === 'coloso' ? 1800 : 3200);
    });
  }
}

// ---------- ejecución ----------
const filters = process.argv.slice(2);
fs.mkdirSync(OUT, { recursive: true });
let files = 0, bytes = 0, worst = 0;
for (const [name, s] of Object.entries(sounds)) {
  if (filters.length && !filters.some(f => name.startsWith(f))) continue;
  for (let i = 0; i < s.variants; i++) {
    const r = mulberry(hashStr(name) + i * 7919);
    const b = finish(s.fn(i, r));
    for (const x of b) if (!Number.isFinite(x)) throw new Error('NaN en ' + name);
    const file = path.join(OUT, name + '_' + (i + 1) + '.wav');
    writeWav(file, b);
    files++; bytes += 44 + b.length * 2; worst = Math.max(worst, b.length / SR);
  }
}
console.log(files + ' sonidos, ' + (bytes / 1024 / 1024).toFixed(2) + ' MB, el más largo ' + worst.toFixed(1) + ' s');
