# 05 · Progresión, economía y mejoras

Autor: diseñador de progresión y sistemas (sala de diseño). Estado: **propuesta para decidir**. Todas las cifras son de partida y se ajustan jugando; lo que no se discute es la estructura (qué da poder, cuánto cuesta, qué tope tiene).

Fuentes leídas: `CLAUDE.md`, `nucleo-jugable.md`, `guion-maestro.md`, `personajes.md`, `textos-del-juego.md`, `mundo.md`, `jefes.md`, `game/player/skills.gd`, `player.gd`, `core/components/skill_tree.gd` y `health_component.gd`.

---

## 0. Resumen ejecutivo y decisiones que necesito del usuario

1. **Cambio de fondo: el frasco deja de curar "del todo".** Hoy `use_heal_charge()` pone la vida al máximo al instante. Con 13 de vida y 6 frascos, eso son 78 vidas de colchón y ningún jefe es peligroso. Propongo que cure **3 vidas** (hasta 5 con el árbol), con un sorbo de 0,70 s que **se interrumpe si te golpean** (el frasco no se gasta si te interrumpen). Es la decisión más importante de este documento (ver §3.2 y riesgo R1).
2. **Vida máxima 13**: 5 base + 4 del árbol + 3 por 12 fragmentos (cada 4 = +1) + 1 del Trapo de Iria. **Frascos máximos 6**: 3 base + 2 del árbol + 1 por 3 fragmentos.
3. **Daño: tope 3 con el árbol**, 4 con la mejora única de Garrán (opcional, perdible), 5 como techo absoluto sumando reliquias. Ningún jefe está calculado contando con Garrán ni con reliquias.
4. **Árbol ampliado: 21 mejoras y 43 niveles** (hoy 9 y 22). Cuesta **2.180 Ecos** en total (hoy 310). Seis nodos se abren por historia (un jefe o una habilidad), no solo por Ecos.
5. **22 reliquias** y un sistema de **Hilos** (ranuras): 3 de base, +1 por cada 6 Nombres leídos (hasta 8), +1 con la Piedra menor de Linde. Total 9. Se cambian solo en un Ancla.
6. **Economía**: un máximo de **600 Ecos** llevables, "fatiga del Rastro" contra el grind (los enemigos que reaparecen sueltan 100 % / 50 % / 25 % / 0 %), 40 Bolsas de Rastro fijas en el mundo. Camino principal: ~2.550 Ecos brutos (≈ 88 % de todo lo comprable); al 100 %: ~3.300.
7. **Viaje rápido**: no hasta el acto IV. Antes, atajos físicos y la barca de Mirena. Con **Nombrar** (h 11:30) el Hito del Umbral se convierte en nodo de regreso ("Decir los nombres"), ida y vuelta, no entre cualquier par de Anclas.
8. **Modo asistido** por interruptores independientes, sin penalización narrativa; **Nuevo Ciclo** con 4 reliquias exclusivas (coste bajo, prioridad baja).
9. **Sin cartógrafa ni mapas de pago** (canon: `historia.md` §11 la elimina). Las "notas que revelan zonas" pasan a ser **6 planos pintados** hallados en el mundo, sin tienda.

---

## 1. Principios de la progresión

1. **Más poderoso, siempre vulnerable.** El jugador crece en *margen* (más vida, más cura, más ventana de parry), no en *inmunidad*. Regla de oro: **el enemigo común sigue pudiendo matarte en 5-6 golpes** en cualquier momento del juego. La vida sube de 5 a 13, pero el daño enemigo sube de 1 a 2-3.
2. **El movimiento no se compra.** Ninguna mejora, reliquia ni consumible cambia la altura del salto, la distancia del dash ni la velocidad de carrera. Motivo práctico: las distancias de La Chimenea y La Pasarela están validadas con maniobras exactas (`tests/puzzle_plans.json`) y cada sala futura se diseñará contra "salto + dash = 22 baldosas". El árbol solo toca *tiempos de espera* (dash), *tolerancias* (agarre) y *combate*.
3. **Cuatro fuentes de poder, cada una con su sabor.**

| Fuente | Qué da | Por qué así |
|---|---|---|
| **Exploración** | Fragmentos de vida y de frasco, Bolsas de Rastro, reliquias escondidas, planos | Recompensa mirar donde nadie te manda |
| **Jefes** | Habilidades de movimiento, Sellos, grandes bloques de Ecos, apertura de nodos del árbol | Cada jefe es un hito legible del arco |
| **PNJ** | Garrán (Filo Hondo), Cano (4 reliquias), Casilda, Gaspar, Iria, Sabela (reliquias), Mirena (barca) | Poder por relación, no por inventario |
| **Coleccionables y maestría** | Nombres (Hilos), Páginas (Pluma), Insignia (Oda), reliquias de parry | La maestría desbloquea cosas que el dinero no compra |

4. **Nada obligatorio depende de algo perdible ni opcional.** El kit "razonable" de cada jefe se calcula sin Garrán, sin reliquias opcionales y sin ningún jefe opcional (Casimar, Rufo, Oda).
5. **Las decisiones son de elección, no de acumulación.** En ningún momento del camino principal se puede comprar todo: a las 13 h falta ~12 % del árbol y ~25 % de las reliquias por equipar (por ranuras). El Paño es la tentación hecha mecánica: cierra esa brecha a cambio de un Nombre.
6. **Una sola moneda.** Los Ecos son lo único que se gasta. Nada de materiales, nada de segundas monedas. La excepción es el **hierro de Garrán** (un único objeto de misión, no una moneda).
7. **Los números se ven.** El menú del Ancla enseña siempre "antes → después" (ya lo hace `Skills.describe`) y el diario enseña "3/12" cuando falta algo, sin revelar dónde.
8. **El jefe no mira tu equipo.** Los nodos que dañan a enemigos comunes (Castigo, Peso) **no afectan a jefes**. Así la duración de cada jefe depende de pocas variables (daño, ritmo, alcance, Rompecorazas, Garrán) y es predecible.

---

## 2. La curva de poder, de 0 a 15 horas

### 2.1 Tabla maestra

"Personaje razonable": quien explora lo que se cruza, compra primero lo barato y útil, y no hace segundas rutas de farmeo. Cura = vidas por frasco. Hilos = ranuras de reliquia disponibles. Nombres = leídos. Ecos brutos = ganados en total desde el inicio; gastados = en el árbol, Garrán, Cano y barca. Dificultad percibida: 1 (relajada) a 10 (tensión máxima); no es el daño, es lo que siente el jugador medio.

| Hora | Hito | Vida | Frascos / cura | Daño | Movimiento | Hilos / reliquias a mano | Nombres | Ecos brutos / gastados | Dif. |
|---|---|---|---|---|---|---|---|---|---|
| 0:00 | Despertar en el Hito del Umbral | 5 | 3 / 3 | 1 | Mover, saltar, Filo, parry | 0 / 0 | 0 | 0 / 0 | 2 |
| 0:30 | Primer Ancla; se entiende la premisa | 5 | 3 / 3 | 1 | — | 0 / 0 | 2 | 15 / 0 | 3 |
| 1:00 | Foso de las Terrazas: se cae a La Cisterna | 5 | 3 / 3 | 2 | — | 3 / 1-3 (Cuenta; Cano: Medalla, Llave) | 5 | 40 / 30 | 4 |
| 2:00 | Antes del Aljibe (Ancla) | 7 | 3 / 3 | 2 | — | 3 / 3 | 5 | 110 / 95 | 5 |
| 2:15 | **Centinela Hueco** (jefe 1) | 7 | 3 / 3 | 2 | **Dash** | 3 / 3 | 5 | 150 / 95 | **7** |
| 2:45 | El Mirador: se ve la Herida; carta de Oda | 7 | 3 / 3 | 2 | Dash | 4 / 3 | 6 | 175 / 130 | 3 |
| 3:30 | La Torre de Riego (Tomasa) | 7 | 4 / 3 | 2 | **Doble salto** | 4 / 4 (Dedal) | 7 | 240 / 200 | 4 |
| 4:30 | **Jacinto** (jefe 2), La Era | 8 | 4 / 3 | 2 | **Salto de pared** | 4 / 5 (Hoz) | 10 | 395 / 350 | **7** |
| 5:30 | Entrada del Archivo | 8 | 4 / 3 | 2 | Pared | 4 / 6 (Aguja) | 11 | 480 / 430 | 5 |
| 6:15 | **Sor Ilara** (jefe 3) | 10 | 5 / 4 | 3 | Pared | 5 / 8 (Pesa, Lacre) | 12 | 650 / 590 | **7** |
| 7:30 | **Hesper** (jefe 4); **Sello de Cera** | 10 | 5 / 4 | 3 | Pared | 5 / 9 | 15 | 915 / 810 | **8** |
| 8:30 | Minas: Casimar (opcional) | 10 | 5 / 4 | 3 | Pared | 6 / 11 (Diente, Corona) | 17 | 1.100 / 960 | 7 |
| 9:15 | **Magda** (jefe 6); **Excavar**; **Sello de Piedra** | 11 | 5 / 5 | 3 | **Excavar** | 6 / 13 (Pizarra, Clavo) | 19 | 1.330 / 1.180 | **8** |
| 10:00 | Garrán forja el Filo Hondo (opcional) | 11 | 5 / 5 | 3-4 | Excavar | 6 / 14 | 20 | 1.500 / 1.330 | 6 |
| 10:50 | **Eudora** (jefe 8); **Sello de Cal**; el Paño | 12 | 6 / 5 | 3-4 | Excavar | 7 / 18 (Campanilla, Piedra blanca, Hebra, Trapo) | 24 | 2.020 / 1.800 | **8** |
| 11:30 | Vuelta al Umbral; **Nombrar**; Puerta Tapiada | 12 → 13 | 6 / 5 | 3-4 | **Nombrar** (5 habilidades) | 8 / 19 (+Piedra menor de Linde → 9 hilos) | 26 | 2.200 / 2.000 | 3 |
| 12:15 | La Herida: Puerta Sin Muro, Cano | 13 | 6 / 5 | 3-4 | Todas | 9 / 20 | 28 | 2.350 / 2.150 | 8 |
| 12:55 | **Maelis** (jefe 9) | 13 | 6 / 5 | 3-4 | Todas | 9 / 20 | 28 | 2.550 / 2.300 | **9** |
| 13:00 | Sala de Aún: elección de final | 13 | 6 / 5 | 3-4 | Todas | 9 / 20 | 28-30 | — | 4 |
| 14:00 | Oda, la Última Mensajera (jefe 10, secreto) | 13 | 6 / 5 | 4 | Todas | 9 / 21 | 30 | 3.050 / 2.600 | **10** |
| 15:00 | 100 %: Páginas, Pluma, Insignia | 13 | 6 / 5 | 4-5 | Todas | 9 / 22 | 30 | 3.310 / 2.600 + Paño | 2 |

Notas de lectura:

- **Vida 7 en el primer jefe**: 5 base más 2 niveles de Vitalidad (10 + 20 = 30 Ecos), que un jugador que haya limpiado el Cinturón bajo ya tiene. Si llega con 5 sigue pudiendo, pero entonces el jefe dura más (ver §6.5).
- **Daño 2 desde ~1:00**: Filo afilado I cuesta 30 Ecos; en La Cisterna se juntan ~40. El Centinela está pensado para daño 2 (21 golpes eficaces).
- **El Paño llega en la hora 10:50** y paga un Nombre por vez. Se explica en §3.7.
- **El momento más bajo de dificultad percibida (3) es la vuelta al Umbral**: calma y duelo. La curva sube en forma de dientes de sierra (patrón de 2,5 h por región, `guion-maestro.md` §7.1): subida, pico en el jefe, respiro con recompensa.

### 2.2 Cuánto del árbol y de las reliquias se tiene en cada hito

| Hora | % del árbol comprado | Compras hechas (de 43) | Reliquias equipadas típicas |
|---|---|---|---|
| 2:00 | 4 % | 6 | 1-2 |
| 4:30 | 15 % | 12 | 2-3 |
| 7:30 | 36 % | 20 | 3-4 |
| 9:15 | 54 % | 27 | 4 |
| 11:00 | 72 % | 33 | 4-5 |
| 13:00 | 88 % | 38 | 5 |
| 15:00 (100 %) | 100 % | 43 | 5-6 |

Los Ecos que "faltan" a las 13 h son la distancia entre 2.300 gastados y 2.600 totales comprables más lo que pesa elegir. Quien calla Nombres (hasta 400 Ecos) lo cierra del todo. Es la intención.

### 2.3 Qué se desbloquea por qué vía

| Vía | Ejemplos concretos | Hora típica |
|---|---|---|
| **Exploración** | Fragmentos de vida (12) y de frasco (3); 40 Bolsas de Rastro; Cuenta del Rosario; Hoz mellada; Moneda sin cara; 6 planos | todo el juego |
| **Jefes** | 4 habilidades, 3 Sellos, Llave de Tinta; apertura de Rompecorazas (J1), Castigo (J2), Desvío (J3), Brasa (J4), Peso (J6) | 2:15, 4:30, 6:15, 7:30, 9:15 |
| **PNJ** | Garrán (Filo Hondo), Cano (Medalla, Llave, Clavo, Moneda), Gaspar (Lacre), Casilda (Hebra), Iria (Trapo), Mirena (barca, Brújula), Brunel (Pizarra), Aldara (Nombrar, Piedra menor) | 1:00-11:30 |
| **Coleccionables** | Nombres → Hilos (+5), 20 Nombres → Compartir, Páginas (6) → Pluma | 2:45-13:30 |
| **Maestría** | Moneda sin cara (apuesta), Piedra blanca (parry), Clavo (parry), Insignia (Oda), reliquias de ritmo | 9:00-14:00 |

---

## 3. Todos los tipos de mejora

### 3.1 Fragmentos de vida (12)

Cada **4 fragmentos = +1 de vida máxima** (decisión del encargo). Hay 12: +3 en total. Se recogen del suelo, se notifica "Fragmento de vida 2/4" y el contador se muestra en el diario (no en el HUD).

| Región | Fragmentos | Método de obtención (regla, no ubicación fina) |
|---|---|---|
| El Último Umbral | 1 | Secreto: tras **La Puerta Tapiada**, se abre con Excavar y se vuelve a la hora 11:30. Es el cierre de la cuenta (12.º) |
| Cinturón Yermo | 3 | (1) nicho de La Cisterna, a la vista y sin habilidad; (2) plataforma lateral de La Chimenea que exige el dash exacto; (3) repisa alta de la Torre de Riego (doble salto) |
| El Archivo | 3 | (4) sala en blanco que solo cuaja si se pasa por ella en un orden; (5) tras pared falsa (Llave sin puerta ayuda); (6) pozo que pide salto de pared |
| Las Minas | 3 | (7) Veta Tapiada (Excavar); (8) fondo de la Cuerda de Mil Nudos (salto de pared encadenado); (9) tras un élite opcional |
| La Costa | 2 | (10) acantilado largo (el camino sin Excavar); (11) Playa de Nombres con la marea baja |
| La Herida | 0 | La última región no regala margen: el jugador llega con lo que juntó |

Reparto por *tipo de reto* (garantiza variedad): 4 de exploración visible, 4 de plataformas, 3 secretos (pared falsa / Excavar), 1 de combate opcional.

Cadencia de la cuenta: 4.º fragmento a ~6:15 (+1 vida: 8 → 9, sumando el árbol), 8.º a ~9:00 (+1), 12.º a ~11:30 (+1). Cada +1 llega en un hito emocional (antes de un jefe) y nunca en las dos primeras horas, para no inflar el arranque.

Fórmula de vida máxima (ver `Skills.stat`):

```
vida_max = 5 + nivel(Vitalidad) + floor(fragmentos_vida / 4) + (Trapo de Iria ? 1 : 0)   # tope absoluto 13
```

### 3.2 Frascos, cura y fragmentos de frasco

**Cambio de contrato (propuesto):** `HealthComponent.use_heal_charge()` pasa a curar `heal_amount` (no al máximo) y a tardar `heal_time`; `heal_amount` y `heal_time` son exports configurables del componente genérico (cabe en `core/`: no menciona conceptos del juego).

| Estadística | Base | Máximo | Cómo sube |
|---|---|---|---|
| Frascos (cargas) | 3 | 6 | Frascos I-II (árbol, +1 y +1) y 3 fragmentos de frasco (+1) |
| Cura por frasco | 3 vidas | 5 | Aliento I-II (árbol, +1 y +1) |
| Tiempo de sorbo | 0,70 s | 0,30 s (suelo) | Sorbo I-II (0,55 y 0,42) y Aguja del Escriba (−0,25) |
| Interrupción | Un golpe cancela el sorbo; **el frasco no se gasta** | — | — |
| Con vida llena | No se puede beber (ya es así) | — | — |

Los **fragmentos de frasco** son 3 (3 fragmentos = +1 frasco): uno en el Archivo (puzle de la Sala de los Relatores), uno en las Minas (Cámara del Taller de Dola, tras el favor del pico) y uno en la Costa (el Altar de Sal, a cambio de dejar una luz encendida). Uno por región de la tríada: es el *premio* de completar cada región en profundidad. Se llega a 6 frascos hacia la 10:30.

Por qué no más: con 13 de vida y 5 de cura, un frasco repone el 38 % de la barra. Seis frascos son 30 vidas de cura de campaña antes de volver a un Ancla, más del doble de la vida máxima. Más sería un colchón sin límite.

### 3.3 El árbol de habilidades ampliado

Se mantiene el diseño actual (ramas Cuerpo / Filo / Espíritu, `SkillTree` genérico) y **se conservan los 9 ids y los niveles actuales**: las partidas guardadas siguen siendo válidas (guardan niveles, no costes). Lo que cambia son los costes (más altos, tabla abajo) y se añaden **12 mejoras nuevas**. Las 9 originales mantienen sus efectos por nivel.

#### Rama Cuerpo (7 mejoras, 15 niveles, 715 Ecos)

| Mejora | Niveles | Efecto por nivel | Costes (Ecos) | Requiere | Puerta | Estado |
|---|---|---|---|---|---|---|
| Vitalidad | 4 | +1 vida máx (5 → 9) | 10 / 20 / 35 / 55 | — | — | existente |
| Frascos | 2 | +1 frasco (3 → 5) | 25 / 45 | Vitalidad | — | existente |
| Temple | 2 | Invulnerable tras golpe 0,6 → 0,8 → 1,0 s | 30 / 50 | Frascos | — | existente |
| Aliento | 2 | Cura por frasco +1 (3 → 4 → 5) | 40 / 70 | Frascos | — | **nuevo** |
| Sorbo | 2 | Tiempo de sorbo 0,70 → 0,55 → 0,42 s | 35 / 60 | Aliento | — | **nuevo** |
| Fortaleza | 2 | Retroceso recibido −25 % / −50 % (menos empujones a pinchos y fosos) | 45 / 75 | Temple | — | **nuevo** |
| Brasa | 1 | Una vez por descanso: si un golpe te mataría y tenías ≥ 3 de vida, quedas a 1 y 1,2 s de invulnerabilidad | 120 | Vitalidad **nivel 4** | **Hesper vencido** | **nuevo** |

Brasa no cuenta como inmortalidad: no vale contra caída mortal, pinchos ni el golpe de una Furia con varios impactos seguidos (la invulnerabilidad de 1,2 s lo evita, pero no se reactiva hasta el próximo Ancla).

#### Rama Filo (6 mejoras, 12 niveles, 670 Ecos)

| Mejora | Niveles | Efecto por nivel | Costes | Requiere | Puerta | Estado |
|---|---|---|---|---|---|---|
| Filo afilado | 2 | +1 daño por golpe (1 → 3) | 30 / 80 | — | — | existente |
| Ritmo | 3 | Espera entre golpes 0,30 → 0,26 → 0,22 → 0,18 s | 20 / 40 / 70 | Filo afilado | — | existente |
| Alcance | 2 | +6 px por nivel (20 → 32) | 25 / 45 | Ritmo | — | existente |
| Rompecorazas | 2 | +1 / +2 de daño solo contra **armadura** (Centinela, Colosos, Custodios blindados); no daña al núcleo | 50 / 90 | Filo afilado | **Centinela vencido** | **nuevo** |
| Castigo | 1 | +1 de daño al golpear a un enemigo común en su recuperación (tras fallar su ataque). **No afecta a jefes** | 100 | Ritmo **nivel 2** | **Jacinto vencido** | **nuevo** |
| Peso | 2 | Tus golpes aturden 0,15 / 0,30 s más a enemigos comunes y los empujan +25 % / +50 %. **No afecta a jefes** | 40 / 80 | Filo afilado **nivel 2** | **Magda vencida** | **nuevo** |

Por qué estas y no "más daño": el árbol de daño está capado a 3 (cada golpe vale más cuando los enemigos tienen 6-28 de vida). Las mejoras nuevas de Filo cambian *cómo* se pelea (castigar a destiempo, controlar posición, romper armaduras), no *cuánto*.

#### Rama Espíritu (8 mejoras, 16 niveles, 795 Ecos)

| Mejora | Niveles | Efecto por nivel | Costes | Requiere | Puerta | Estado |
|---|---|---|---|---|---|---|
| Guardia | 3 | Ventana de parry 0,20 → 0,25 → 0,30 → 0,35 s | 15 / 30 / 50 | — | — | existente |
| Impulso | 2 | Espera del dash 0,40 → 0,32 → 0,24 s | 20 / 40 | Guardia | — | existente |
| Contragolpe | 2 | Enemigo desviado aturdido +0,5 / +1,0 s (1,2 → 2,2 s) | 35 / 65 | Impulso | — | existente |
| Paso fantasma | 2 | El dash te hace invulnerable el 35 % / 60 % de su duración | 45 / 80 | Impulso | **tener Dash** | **nuevo** |
| Desvío | 1 | El parry también devuelve proyectiles de arrojadores (el daño reflejado es el del proyectil ×2) | 70 | Guardia **nivel 2** | **Ilara vencida** | **nuevo** |
| Latido | 2 | Espera tras pulsar el parry 0,70 → 0,55 → 0,40 s | 40 / 70 | Guardia | — | **nuevo** |
| Voz | 2 | **Nombrar** en combate: aturde 2 s a un vaciado (cascarón, lancero...) cercano, espera 25 s; nivel 2: aturde 3 s a todos los vaciados en pantalla, espera 18 s. No afecta a jefes | 60 / 100 | Contragolpe | **tener Nombrar** | **nuevo** |
| Asidero | 2 | Resbalas más despacio en la pared (−25 % / −50 %) y tienes 0,05 / 0,10 s de margen para saltar tras soltarte | 25 / 50 | Guardia | **tener Salto de pared** | **nuevo** |

Todas las tolerancias de Asidero y todo lo de Paso fantasma son **de ejecución, no de alcance**: no crean atajos en salas diseñadas con las cifras base.

#### Resumen de costes

| Rama | Mejoras | Niveles | Ecos |
|---|---|---|---|
| Cuerpo | 7 | 15 | 715 |
| Filo | 6 | 12 | 670 |
| Espíritu | 8 | 16 | 795 |
| **Total** | **21** | **43** | **2.180** |

Con el criterio del encargo ("~25-30 nodos"), cada **compra** es un nodo: 43 nodos de compra y 21 mejoras distintas. Es más legible en pantalla que 28 mejoras de un solo nivel, y encaja en el `SkillTree` actual (`costs` por nivel).

Cambios en la **vista del árbol**: pasa de 3×3 a 3 columnas × hasta 8 filas con desplazamiento vertical; las "puertas" muestran el texto de por qué están bloqueadas ("Aprendes del Segador cuando lo venzas") sin spoilers del recorrido.

#### Costes: por qué estos números

La regla de coste es: **el primer nivel de una mejora útil cuesta 10-35 Ecos (un par de enemigos de la región), el último de las caras cuesta 70-120**. Las mejoras que cambian estilo (Castigo, Brasa, Voz) cuestan entre 100 y 160, para que se compren a conciencia. Los costes que hoy ya existen se **multiplican por ~2,3**: pasan de 310 a 710 en las nueve originales.

### 3.4 Topes y límites (lo que no se puede romper)

| Estadística | Base | Máximo del árbol | Qué más suma | **Tope absoluto** |
|---|---|---|---|---|
| Vida máxima | 5 | 9 | +3 (fragmentos) +1 (Trapo) | **13** |
| Frascos | 3 | 5 | +1 (fragmentos) | **6** |
| Cura por frasco | 3 | 5 | — | **5** |
| Tiempo de sorbo | 0,70 s | 0,42 s | Aguja −0,25 s | suelo **0,30 s** |
| Daño por golpe | 1 | 3 | Garrán +1; Pesa +1 | **5** (sobre armadura, Rompecorazas aparte) |
| Espera entre golpes | 0,30 s | 0,18 s | Pesa +0,12 s; Hoz +0,03 s | suelo **0,16 s** |
| Alcance | 20 px | 32 px | Hoz +8 px | **40 px** |
| Invulnerabilidad tras golpe | 0,6 s | 1,0 s | — | **1,0 s** |
| Ventana de parry | 0,20 s | 0,35 s | — | **0,35 s** (el aviso del enemigo dura 0,40 s) |
| Espera del parry | 0,70 s | 0,40 s | — | 0,40 s |
| Espera del dash | 0,40 s | 0,24 s | Insignia −0,10 s | suelo **0,15 s** |
| Aturdimiento del parry | 1,2 s | 2,2 s | Corona +0,4 s | **2,6 s** |
| Hilos | 3 | — | +5 (Nombres) +1 (Piedra de Linde) | **9** |
| Ecos llevables | — | — | — | **600** |

Reglas de implementación: `Skills.stat(id, level)` sigue siendo la única fuente; las reliquias aplican modificaciones **después** y el resultado pasa por `clamp()` a su tope absoluto (tabla anterior). La prueba de humo verifica cada tope (ver §8.3).

### 3.5 Reliquias (22) y cómo se equipan

**Hilos.** Cada reliquia cuesta de 0 a 3 Hilos (ranuras). Se equipan en el **menú del Ancla**, nueva opción "Reliquias" (la segunda tras el árbol), y **solo se cambian descansando**; en el menú de pausa se ven pero no se editan. Los Hilos nunca disminuyen, así que no hay que prever reliquias que se suelten solas.

Cómo se ganan los Hilos: **3 de base**; **+1 por cada 6 Nombres leídos** (a 6, 12, 18, 24 y 30); **+1** con la Piedra menor de Linde, que Aldara entrega en el acto IV (la reliquia que cuesta 0 Hilos y da 1). Total 9. Leer (no sostener) es el contador: callar un Nombre con el Paño **no** quita Hilos. Es la lectura más fiel al canon ("callar... no modifica combate"). La variante dura (contar solo Nombres *sostenidos*, de modo que callar sí cuesta una ranura) queda como pregunta abierta (§9).

Lista de reliquias. "Hilos" es el coste de equipo. Las 15 primeras son las del canon (`textos-del-juego.md` §7), con efecto asignado; las 7 siguientes son nuevas y dan salida a PNJ que prometen "una reliquia" sin tenerla (Casilda, Jacinto, Mirena, Brunel, Cano, Aldara).

| # | Reliquia | Hilos | Efecto concreto | Dónde / cómo | Tipo |
|---|---|---|---|---|---|
| 1 | Aguja del Escriba | 1 | Sorbo del frasco −0,25 s (suelo 0,30 s) | Archivo, Scriptorium (h 5:30) | Supervivencia |
| 2 | Dedal de la Torre | 2 | Cada 25 s, un golpe de **1** de daño no te hiere (el relevo es automático). Queda inútil en cuanto el enemigo pega 2: es un amuleto de principio de viaje | Torre de Riego (h 3:30) | Supervivencia |
| 3 | Medalla del Umbral | 2 | Al morir **conservas el 25 %** de tus Ecos (se descuentan del Eco que dejas) | Cano, 50 Ecos | Economía |
| 4 | Trapo de Iria | 2 | **+1 vida máxima** (tope 13) | Iria, tras traerle el trompo y el zapato (h 10:50) | Supervivencia |
| 5 | Lacre de silencio | 1 | Los enemigos te detectan desde −30 % de distancia (220 → 154 px) | Gaspar, tras retirar tres sellos (h 6:30) | Sigilo |
| 6 | Diente de la Mina | 2 | +1 de daño contra criaturas **saturadas** de las Minas, Colosos y esqueletos de hueso/piedra | Minas (h 8:00) | Combate |
| 7 | Cuenta del Rosario | 1 | Una vez por descanso, si caes a un foso/pinchos mortales, vuelves al último suelo firme **sin morir** (−1 vida) | Foso de las Terrazas, escondida (h 1:00) | Supervivencia |
| 8 | Campanilla de la Costa | 1 | Aviso en el borde de la pantalla (flecha) de enemigos a menos de 18 baldosas aunque no los veas | Costa (h 10:00) | Exploración |
| 9 | Pesa del Archivo | 2 | **+1 daño por golpe y +0,12 s de espera** entre golpes (golpe lento, golpe fuerte; baja el DPS, sube el "un golpe menos") | Archivo (h 6:15) | Combate |
| 10 | Pluma sin tinta | 1 | Recoges tu Eco y las Bolsas de Rastro sin pulsar Z, a menos de 3 baldosas | Sabela, tras las 6 Páginas (post-juego) | Comodidad |
| 11 | Llave sin puerta | 1 | Los muros falsos y suelos frágiles **brillan** a menos de 6 baldosas | Cano, 60 Ecos | Exploración |
| 12 | Corona sin Reina | 2 | Enemigo desviado aturdido +0,4 s (tope 2,6 s) | Casimar (opcional, h 8:30) | Combate |
| 13 | Piedra blanca de la Costa | 3 | Parry exitoso cura **1 vida** (máx. 2 veces por descanso, mín. 8 s entre curaciones) | Muro Blanco (h 10:00) | Supervivencia/maestría |
| 14 | Vela del Faro | 1 | Las Anclas de salas ya visitadas aparecen en el mapa de la pausa aunque no hayas pasado cerca | Rufo (opcional, h 10:00) | Exploración |
| 15 | Insignia de Mensajera | 1 | Espera del dash −0,10 s (suelo 0,15 s). **Llave del Relevo** (no se puede quitar el logro, sí desequipar) | Oda (secreto, h 14:00) | Maestría |
| 16 | Hebra de Cal | 1 | Recuperar tu Eco te cura **2 vidas** | Casilda (h 10:30) | Supervivencia |
| 17 | Hoz mellada | 1 | Alcance +8 px (tope 40) y +0,03 s de espera | La Era, tras vencer a Jacinto (h 4:30) | Combate |
| 18 | Clavo de Cano | 2 | Un parry exitoso **reinicia el dash** | Cano, 90 Ecos (desde h 7:00) | Maestría |
| 19 | Piedra menor de Linde | **0** | **+1 Hilo** | Aldara, acto IV (h 11:30) | Capacidad |
| 20 | Brújula de Mirena | 1 | Una flecha tenue en el borde del mapa apunta a la **sala sin visitar más cercana** que tenga alguna salida | Mirena, tras tres viajes en barca (h 10:30) | Exploración |
| 21 | Pizarra de Brunel | 1 | En el mapa de la pausa, cada sala dice cuántos Nombres le quedan por leer (solo cifra, nunca dónde) | Brunel, tras escuchar su lista (h 9:00) | Exploración |
| 22 | Moneda sin cara | 2 | Los enemigos sueltan **×2 Ecos**, pero si mueres **el Eco se pierde para siempre** (no se puede recuperar) | Cano, 70 Ecos (desde h 9:00) | Riesgo |

Notas de equilibrio:

- **Ninguna reliquia es estrictamente mejor que otra.** Las más fuertes (Piedra blanca, Trapo) ocupan 3 y 2 de los 9 Hilos. Cada "combo" tiene un hueco: Pesa + Hoz pegan fuerte pero lento; Clavo + Insignia permiten dash-parry encadenado pero dejan sin Hilos para curación.
- **Tres reliquias son "de maestría" y piden jugar bien**: Piedra blanca (parry), Clavo de Cano (parry-dash), Insignia (dash corto). Son la recompensa de quien ya domina el parry.
- **Moneda sin cara** es la reliquia de riesgo. En la economía propuesta el Eco sobra al final, así que sirve para apostar al principio (acelerar el árbol) o para quien quiera que la muerte cueste de verdad.
- **Ninguna reliquia cierra ni abre caminos del camino principal.** Llave sin puerta ayuda a encontrar secretos, nada más.
- **Recuento:** 19 de 22 se consiguen sin jefes opcionales ni secretos; las otras tres son Corona (Casimar), Vela (Rufo) e Insignia (Oda). Pluma sin tinta queda para el final del juego (necesita la sexta Página, la de la Herida) y se cuenta entre las 19.

#### Curva de reliquias disponibles

| Hora | Disponibles (acumuladas) | Hilos | Reflexión |
|---|---|---|---|
| 1:00 | 1 + 2 en tienda | 3 | Primera decisión: Cuenta (1) + Dedal (2) o Medalla (2) |
| 4:30 | 5 | 4 | Hoz y Dedal compiten por Hilos |
| 6:30 | 8 | 5 | Pesa, Lacre, Aguja: el primer "build" |
| 9:15 | 13 | 6 | Clavo y Moneda en la tienda; hay que elegir |
| 10:50 | 18 | 7 | Piedra blanca (3 Hilos) obliga a descartar dos |
| 12:00 | 20 | 9 | Con la Piedra menor se puede probar de todo |
| 15:00 | 22 | 9 | El 100 %: nunca se lleva más del 30 % de lo que se tiene |

### 3.6 El Paño y los Nombres (beneficios mecánicos)

**Pronunciarlos (leerlos).** Es el 100 % del sistema "bueno":

| Efecto | Detalle |
|---|---|
| **Hilos** | +1 Hilo por cada 6 Nombres leídos (6, 12, 18, 24, 30). Se anuncia: "Los nombres te dan más hilo." |
| **Diario** | Pestaña "Nombres que sostienes" con contador por región ("Umbral 3/5"). Cada uno guarda su fuente leída |
| **Compartir** | 20 Nombres sostenidos + Nombrar abren la Escalera. Es el único bloqueo mecánico del sistema |
| **Voz** (árbol) | Nombrar se usa en combate. Gasta la acción, no un Nombre. Sin coste en recursos |
| **Descanso** | "Pronuncias los nombres. Nuevos: {lista}." (ya en `textos-del-juego.md` §1). Sin efecto de curación extra: descansar ya cura del todo |

No se da ninguna ventaja de combate directa por leer Nombres. Es una decisión consciente: el Nombre no es un mejorable, es una persona.

**Callarlos (el Paño).**

| Efecto | Detalle |
|---|---|
| **Qué da** | **40 Ecos** por Nombre silenciado. Es "un nivel medio del árbol" (los niveles medios cuestan 35-70) |
| **Qué cuesta** | El Nombre ya no cuenta como sostenido (la Escalera exige 20), su fuente se lee "en blanco" y no se recupera jamás. Aldara lo nota |
| **Qué no hace** | No quita Hilos (los Hilos cuentan Nombres leídos), no cambia combate ni mapa |
| **Límite natural** | Con 28 Nombres alcanzables sin opcionales y 20 necesarios para Compartir, se pueden callar **hasta 8 sin perder el final**; con 30, hasta 10. El máximo de Ecos es 320-400. No hace falta ningún tope artificial |
| **Confirmación** | Texto claro: "Es para siempre." Botón por defecto: "No" |
| **Cuándo** | Desde la hora 10:50. A esa hora al jugador le quedan ~12 % del árbol y las reliquias de la tienda por pagar: la tentación es real (un tercio de lo que le falta) |

Pago a medida (opcional, si el playtest dice que el Paño no pesa): 40 Ecos el primero y +5 por cada Nombre callado. El décimo pagaría 85. Se descarta de inicio por añadir una regla que explicar.

### 3.7 Mejoras del Filo por el forjador (Garrán)

Canon: Garrán da **una sola mejora**, a cambio del hierro de la Veta Tapiada. Se respeta.

| Detalle | Valor |
|---|---|
| Mejora | **Filo Hondo**: el tope de daño del árbol sube de 3 a **4** (el Filo pasa a hacer 4 en vez de 3 si ya tienes Filo afilado II) |
| Material | 1 **Hierro que suena** (objeto de misión, en la Veta Tapiada de las Minas, se pica con Excavar) |
| Coste | **150 Ecos** |
| Cuándo | Entre las 9:30 y las 10:30 (tras Excavar, antes de que "se hunda la fragua") |
| Si falta | El jugador pierde 1 de daño frente a lo que el diseño de Herida considera "ideal", **no** frente a lo que exige. Todos los jefes se pueden vencer sin Garrán |
| Si Garrán muere | Se pierde la mejora (perdible). Compensación: ninguna mecánica; el fogón apagado se lee como pérdida |
| Texto del menú | "Garrán te devuelve el Filo con un temple nuevo." |

Con Garrán, el daño efectivo contra un jefe baja su duración en un 20-25 %. Ninguna sala se diseña pensando en ello.

### 3.8 Consumibles y pociones: no entran

Justificación: el juego ya tiene un consumible (el frasco) y un contador (Ecos). Añadir pociones exigiría inventario, un menú de uso y balance de cantidades, y rompe el "un solo gesto" de curarse. Lo que otros juegos resuelven con consumibles se resuelve aquí con reliquias intercambiables en el Ancla. **Excepción a considerar si hace falta:** una "Bolsa de Rastro" ya es un consumible de un uso (te da Ecos). No se propone nada más.

### 3.9 Mejoras de dash y salto ("Impulso")

| Qué | Dónde | Efecto | Qué NO hace |
|---|---|---|---|
| Impulso I-II | Árbol | Espera del dash 0,40 → 0,24 s | No alarga el dash, no da un segundo dash en el aire |
| Paso fantasma I-II | Árbol | Invulnerable durante el 35 %/60 % del dash | No cruza paredes ni pinchos |
| Insignia de Mensajera | Reliquia | −0,10 s de espera | Mismo |
| Asidero I-II | Árbol | Menos resbalón en pared; margen de 0,05-0,10 s al soltar | No cambia la altura del salto de pared |
| Saltos, doble salto | — | **No mejoran** | La altura es contrato de diseño de nivel |

---

## 4. La economía de Ecos

### 4.1 Principios

1. **El Eco es memoria ajena.** Matar a un vaciado cosecha su Rastro (`personajes.md` §5). Lo que se gana pesa lo que fue esa persona: los élites sueltan más.
2. **El riesgo está en llevar, no en tener.** Los Ecos gastados son permanentes. Los Ecos *en la mano* son los únicos que se pierden. Eso empuja a gastar en cada Ancla.
3. **Regla de precio:** el coste de una compra es **entre 4 y 12 enemigos de la región actual**. Nunca más de 120 Ecos de una vez (salvo Garrán, 150).
4. **Ni grind ni inflación.** Los enemigos que reaparecen pagan cada vez menos; las Bolsas de Rastro y los jefes pagan una sola vez; el total comprable está cerrado (2.600 Ecos), y lo que sobra al 100 % no tiene dónde gastarse (a propósito: el cierre del arco económico).

### 4.2 Fuentes

| Fuente | Cantidad | Regla |
|---|---|---|
| Enemigos | ~0,5 Ecos por punto de vida del enemigo (0,67 en el Cinturón) | Ver tabla 4.3. Se aplica la fatiga del Rastro (4.5) |
| Jefes | Fijo, una vez (4.4) | Quedan guardados (`bosses` en la partida) |
| **Bolsas de Rastro** | 40 en el mundo, de 15 a 40 Ecos | Un montón de polvo gris que se pulsa; se guarda cuál se recogió. No reaparecen |
| El Paño | 40 por Nombre callado, hasta 400 | Una vez por Nombre |
| Tienda (Mirena) | No da Ecos | — |
| Venta de objetos | No existe | Evita la hoja de cálculo; los objetos con lore no se venden |

### 4.3 Enemigos por región: vida, daño y Ecos

Valores de partida para construir las regiones con consistencia. Cinturón respeta las cifras ya implementadas (`enemy_*.tscn`). "HTK" = golpes necesarios con el **daño esperado de la región** (2 en Cinturón, 3 después).

| Región | Enemigos con spawn (aprox.) | Común | Medio | Élite | Daño al jugador | Ecos (común / medio / élite) | HTK común / élite |
|---|---|---|---|---|---|---|---|
| Umbral | 5 | 3 vida | — | — | 1 | 2 | 2 / — |
| Cinturón | 50 | 3 (cascarón, acechador) | 4 (lancero), 2 (arrojador) | 10 (coloso) | 1 (coloso: 2) | 2 / 3 / 8 | 2 / 5 |
| Archivo | 45 | 6 | 8 | 18 | 1-2 | 3 / 4 / 10 | 2 / 6 |
| Minas | 55 | 8 | 10 | 22 | 2 | 4 / 5 / 12 | 3 / 8 |
| Costa | 36 | 9 | 12 | 24 | 2 | 5 / 6 / 13 | 3 / 8 |
| Herida | 30 | 12 | 15 | 28 | 2-3 | 6 / 8 / 15 | 4 / 10 |

Regla de diseño: **un enemigo común muere en 2-4 golpes, un élite en 6-10**. Si un enemigo supera eso, es mini-jefe (y entonces tiene aviso largo y Ancla cerca).

Daño al jugador en relación con la vida esperada de la región:

| Región | Vida esperada | Daño típico | Golpes para morir |
|---|---|---|---|
| Cinturón (h 0-4,5) | 5-8 | 1 | 5-8 |
| Archivo | 8-10 | 1-2 | 5-7 |
| Minas | 10-11 | 2 | 5 |
| Costa | 11-12 | 2 | 5-6 |
| Herida | 12-13 | 2-3 | 5 |

Se mantiene la sensación de "cinco golpes" con la que se juega ahora, pero con una barra más larga: el jugador *ve* su poder crecer y, al mismo tiempo, cada error sigue siendo un 20 % de su vida.

### 4.4 Jefes

| Jefe | Hora | Ecos | Tipo |
|---|---|---|---|
| 1 Centinela Hueco | 2:15 | 40 (ya implementado) | Obligatorio |
| 2 Jacinto | 4:30 | 60 | Obligatorio |
| 3 Sor Ilara | 6:15 | 80 | Obligatorio |
| 4 Hesper | 7:30 | 110 | Obligatorio |
| 5 Casimar | 8:30 | 90 | Opcional |
| 6 Magda Soler | 9:15 | 140 | Obligatorio |
| 7 Rufo | 10:00 | 90 | Opcional |
| 8 Eudora | 10:50 | 160 | Obligatorio |
| 9 Maelis | 12:55 | 200 | Obligatorio |
| 10 Oda | 14:00 | 150 | Secreto |
| **Obligatorios** | | **790** | |
| **Todos** | | **1.120** | |

### 4.5 Fatiga del Rastro (anti-grind)

Cada enemigo con punto de aparición fijo recuerda **cuántas veces ha sido cosechado**. Descansar o morir reinicia el mundo (como hoy), pero lo que sueltan es:

| Cosecha del mismo enemigo | Ecos |
|---|---|
| 1.ª | 100 % |
| 2.ª | 50 % |
| 3.ª | 25 % |
| 4.ª y siguientes | 0 (el Rastro está agotado; se ve un polvo más claro) |

- El contador se guarda **por sala y por posición** y no se reinicia nunca (ni al cambiar de sala). Nuevo Ciclo lo reinicia.
- Ejemplo del efecto: un jugador que farmea El Último Umbral hasta el hartazgo saca como máximo 1,75 veces lo que ya sacó.
- Los **jefes y Bolsas** no entran: pagan una vez.
- Mensaje: al primer enemigo con Rastro al 50 %, una línea: "Este Rastro está gastado." (no se repite).
- Es narrativamente coherente: el Rastro es memoria, y cada vez queda menos.

Por qué no "los enemigos no reaparecen": sin respawn la zona deja de ser peligrosa al volver y se pierde la tensión del Ancla que tanto cuida el diseño (`nucleo-jugable.md`).

### 4.6 Sumideros

| Sumidero | Total (Ecos) | Detalle |
|---|---|---|
| Árbol de habilidades | **2.180** | Cuerpo 715, Filo 670, Espíritu 795 |
| Garrán (Filo Hondo) | 150 | Una vez; opcional |
| Cano (4 reliquias) | 270 | Medalla 50, Llave sin puerta 60, Moneda sin cara 70, Clavo 90 |
| Barca de Mirena | ~8 viajes × 20 = 160 | Variable; el viaje del acto IV (regreso al Umbral) es **gratis** |
| **Total fijo comprable** | **2.600** | + hasta 160 en barca |
| Ciclo 2 (si se hace): 4 reliquias exclusivas | 150-300 cada una | Ver §7 |

### 4.7 Presupuesto por región

"Brutos" son los Ecos ganados en esa región con camino principal (≈ 70 % de las Bolsas, enemigos con ×1,2 por rondas de fatiga). "Al 100 %" suma todas las Bolsas, las secretas y los opcionales.

| Región (horas) | Enemigos 1.ª pasada | Con rondas (×1,2) | Jefes oblig. | Bolsas (camino) | **Brutos** | Acumulado | Gastos típicos al salir |
|---|---|---|---|---|---|---|---|
| Umbral + Cinturón (0-4:30) | 135 | 162 | 100 (J1+J2) | 133 | **395** | 395 | Vit 1-3, Filo I, Ritmo I-II, Guardia I-II, Frascos I; Cano |
| Archivo (4:30-7:30) | 158 | 190 | 190 (J3+J4) | 140 | **520** | 915 | Filo II, Aliento I, Alcance, Rompecorazas I, Temple I |
| Minas (7:30-9:45) | 248 | 298 | 140 (J6) | 140 | **578** | 1.493 | Ritmo III, Sorbo, Peso; Garrán; Clavo |
| Costa (9:45-11:00) | 198 | 238 | 160 (J8) | 126 | **524** | 2.017 | Fortaleza, Latido, Paso fantasma; Moneda |
| Umbral otra vez + Herida (11:00-13:00) | 210 | 252 | 200 (J9) | 84 | **536** | 2.553 | Brasa, Voz, Desvío; lo que quede |
| **Camino principal** | | | **790** | | **2.553** | | |
| Opcionales (J5, J7, J10) | | | 330 | | | | |
| Bolsas restantes + secretas | | | | 267 + 160 | | | |
| **Al 100 %** | | | **1.120** | **1.050** | **~3.310** | | |

Y sin contar el Paño (hasta 400 más). **Neto tras muertes** (se estima que el jugador medio pierde un 10 % por Ecos no recuperados): camino principal 2.300; al 100 %, 2.980. Frente a 2.600 de sumideros fijos, el jugador del camino principal compra el **88 %**; el del 100 %, todo y le sobran ~350.

### 4.8 Riesgo-recompensa de la muerte

Se mantiene el sistema actual (el Eco se queda donde pisaste suelo firme, se recupera con Z; morir antes de recogerlo lo pierde), con estos ajustes:

| Regla | Valor | Motivo |
|---|---|---|
| Pérdida al morir | 100 % de los Ecos en la mano | Hoy ya es así |
| Eco antiguo | Se pierde si mueres otra vez antes de recogerlo | Hoy ya es así |
| Reliquia Medalla | Conservas el 25 % | Opción para el prudente |
| Reliquia Moneda sin cara | ×2 de Ecos, sin Eco recuperable | Opción para el apostador |
| Reliquia Hebra de Cal | Recuperar el Eco cura 2 vidas | Suaviza el trayecto de vuelta |
| Reliquia Pluma sin tinta | Recogida automática | Evita el descuido |
| **Límite llevado** | **600** Ecos | Con precios de hasta 120 nadie necesita más; sobre 600 el Eco "rebosa" y no se recoge más (mensaje "Llevas todo lo que cabe en tu memoria") |

Valor esperado de un Eco típico: a las 4:30 un jugador lleva ~60 Ecos al morir (casi un Filo I y un Ritmo I); a las 12:00, ~150. Ambos son menos del 10 % del total comprable: duele, no arruina.

### 4.9 Evitar el grind y la inflación (lista de control)

1. Fatiga del Rastro (4.5).
2. Cap de 600 Ecos llevables (4.8).
3. Total comprable cerrado y público en el diario del árbol ("Llevas 1.340 de 2.180").
4. Paño con límite natural (28-30 Nombres, 20 necesarios).
5. Sumidero final: ninguno. El jugador completo no tiene en qué gastar, y no pasa nada: ya lo tiene todo.
6. Jefes y Bolsas, una vez. Los jefes opcionales rinden más por Ecos que cualquier farmeo.
7. Precios fijos: no suben con las compras de otro tipo.

---

## 5. Desbloqueo de niveles, viaje y registro del progreso

### 5.1 Llaves y cerraduras (desde el punto de vista del jugador)

Regla: **una cerradura se ve antes de tener su llave.** Toda puerta mecánica tiene una pista visual en la propia sala y un marcador automático en el mapa.

| Llave | Se consigue | Qué abre (en palabras del jugador) |
|---|---|---|
| **Dash** | Centinela (h 2:15) | Foso de las Terrazas (20 baldosas), La Chimenea, La Pasarela, El Mirador |
| **Doble salto** | Torre de Riego (h 3:30) | La cornisa del Ancla, el Cinturón alto, repisas del Archivo |
| **Salto de pared** | Jacinto (h 4:30) | Pozos del Archivo, acantilado de la Costa, pozo de las Minas |
| **Excavar** | Magda (h 9:15) | Atajos de las Minas, Puerta Tapiada del Umbral, Veta Tapiada, suelo de la Herida |
| **Nombrar** | Aldara (h 11:30) | Piedras de lectura (Mirador, Herida), la Escalera de los Nombres |
| **Llave de Tinta** | Ilara (h 6:15) | El Salón de Sellado (Hesper) |
| **Sello de Cera / de Piedra / de Cal** | Hesper / Magda / Eudora | Los tres huecos de la Puerta Sin Muro de la Herida |
| **Rastrillos** | Vencer al jefe de la sala | Las puertas de la arena (se abren al ganar) |
| **20 Nombres** | Leer | Subir la Escalera de los Nombres (Compartir) |
| **Insignia + Compartir** | Oda + 20 Nombres | Relevo: epílogo del Aljibe |
| **Hierro que suena** | Veta Tapiada (Excavar) | Mejora de Garrán |
| **Paño** | Quiteria / Eudora | La opción "Callar un nombre" |
| **Barca de Mirena** | Costa (h 10:30) | Viaje fijo Costa ↔ pie del Cinturón |

Lo que **no** es una llave: las reliquias (Llave sin puerta solo señala), el árbol (nunca bloquea una sala) y los Ecos.

### 5.2 Viaje rápido

Propuesta: **sin viaje rápido libre**; rápido, pero por pasos y con sentido.

| Etapa | Qué existe | Cómo se desbloquea |
|---|---|---|
| Acto I-III | **Atajos físicos**: puertas que se abren por un solo lado, ascensores de cuerda, escaleras largas, los rastrillos | Cada región trae 2-3; se cuentan en el diseño de sala (cada Ancla debe tener un retorno con ≤ 90 s de camino) |
| Acto III | **Barca de Mirena** (Costa ↔ pie del Cinturón, 20 Ecos; el último viaje es gratis) | Hablarle tras Eudora (o tras vencer a Rufo, lo que llegue antes) |
| Acto III | **Red de atajos de las Minas** | Excavar + Dola (los abre) |
| **Acto IV en adelante** | **"Decir los nombres"**: desde cualquier Ancla ya visitada se puede ir al **Hito del Umbral** y, desde él, volver a cualquier Ancla visitada | Se enciende al obtener **Nombrar**. Sin coste. Cuesta una breve animación (3 s) y fuerza una pantalla de carga corta |

Reglas: no se puede usar durante un jefe, con enemigos persiguiendo a menos de 8 baldosas, ni hacia las Anclas "sin nombre" de la Herida (que existen para ser conquistadas a pie). Es un viaje *a través del Hito*: encaja con la premisa (la memoria que conecta lugares) y con el momento narrativo del acto IV. Coste técnico: M (ver §8).

Por qué no antes: el diseño de 13 h con regiones de 20-30 salas pide explorar a pie; el atajo físico es la verdadera recompensa de abrir una puerta. Por qué sí después: 100 % (Puerta Tapiada, Pasarela de Oda, fragmentos) exige volver al Cinturón y al Umbral sin repetir 30 minutos de camino.

### 5.3 Mapa, marcadores, planos y brújula

| Sistema | Cómo funciona | Estado |
|---|---|---|
| **Descubrimiento por celdas** | Se pinta la baldosa a menos de 12 baldosas del jugador | Existe |
| **Marcadores automáticos** | Ancla (azul), Eco (violeta) | Existe |
| **Marcadores nuevos automáticos** | "Cerradura": icono de **candado** al ver una puerta/pared/foso que pide una habilidad que aún no tienes (se retira al tener la habilidad); "Brillo": objeto visible no recogido | Nuevo (M) |
| **Marcadores del jugador** | Hasta 8 alfileres de 4 tipos (interrogante, puerta, pared sospechosa, objeto) con la tecla de la pausa | Nuevo (S) |
| **Planos pintados (6)** | Un plano de pared/papel por región, hallado en una zona de calma (Mapa de la Era, Plano de Sabela, Carta de Mirena, Croquis de Dola, Tabla del Faro, Hoja arrancada de la Herida). Al leerlo, la **silueta** de las salas de la región aparece en gris (sin detalles ni secretos) | Nuevo (S). Sustituye a la cartógrafa del canon eliminada |
| **Hallazgos** | En la pausa, "Hallazgos": cuántas salas, Bolsas y secretos faltan en una región (**solo la cifra**, nunca el sitio). Se activa tras visitar el 70 % de la región | Nuevo (S) |
| **Brújula de Mirena** (reliquia) | Flecha hacia la sala visitable sin visitar más cercana | Nuevo (S) |

### 5.4 Pistas

Sin árbol de misiones y sin "diario de tareas". Pistas por los tres canales que ya existen:

1. **El Hito.** Tras ganar una habilidad, el primer descanso en cualquier Ancla añade **una línea** de pista (6-8 líneas en total, una por habilidad y por región): "Los fosos del Cinturón ya no son abismos." Se escribe en `textos-del-juego.md` en el mismo registro que los textos de Ancla.
2. **Las cerraduras.** El candado automático (5.3).
3. **Los PNJ.** Mirena, Cano y Dola señalan; ninguno obliga.

### 5.5 Registro del progreso

Dos porcentajes distintos para no confundir:

- **Camino principal %**: el que sale en la pausa y en el título ("Camino 62 %"). Mide lo que importa para ver la historia: jefes obligatorios y habilidades.
- **Completado %**: el 100 % de los coleccionables.

| Concepto | Peso en "Completado" |
|---|---|
| Salas descubiertas (136) | 20 |
| Jefes (10) | 15 |
| Nombres (30) | 15 |
| Habilidades (5) y Sellos (3) | 10 |
| Reliquias (22) | 10 |
| Árbol (43 niveles) | 10 |
| Fragmentos de vida (12) | 8 |
| Fragmentos de frasco (3) | 3 |
| Páginas de Corvel (6) | 3 |
| Planos (6) | 2 |
| Insignia y Relevo | 4 |
| **Total** | **100** |

**Camino principal** = (jefes obligatorios 7 × 8 % + habilidades 5 × 6 % + Sellos 3 × 4 % + llegada a la Herida 2 % + final 1 pt) normalizado a 100. La cifra exacta la fija quien implemente; lo que importa es que llegue a 100 en el final y no se mueva por coleccionables.

**Diario de la pausa**, pestañas: Estado (vida, frascos, cura, daño, Hilos), **Recuerdos** (habilidades), **Reliquias**, **Nombres que sostienes** (por región), Hallazgos, Estadísticas (tiempo, muertes, Ecos totales). Los Nombres se muestran sin pista de cómo conseguir los que faltan.

---

## 6. Dificultad

### 6.1 Curva objetiva

Resumen de lo que ya está en 4.3:

| Magnitud | Cinturón | Archivo | Minas | Costa | Herida |
|---|---|---|---|---|---|
| Vida del jugador | 5-8 | 8-10 | 10-11 | 11-12 | 12-13 |
| Daño del jugador | 1-2 | 2-3 | 3 | 3 | 3-4 |
| Vida enemigo común | 3 | 6 | 8 | 9 | 12 |
| Daño enemigo común | 1 | 1-2 | 2 | 2 | 2-3 |
| Golpes para matar (común) | 2 | 2 | 3 | 3 | 4 |
| Golpes para morir | 5-8 | 5-7 | 5 | 5-6 | 5 |
| Tiempo de aviso del enemigo (rápido / lento) | 0,40 s | 0,40 / 0,60 s | 0,35 / 0,55 s | 0,35 / 0,55 s | 0,30 / 0,50 s |

El aviso baja poco a poco (0,40 → 0,30 s); la ventana de parry máxima es 0,35 s. En la Herida un jugador con todo el árbol puede parar casi cualquier aviso corto, pero uno sin Guardia III no. Es el único lugar donde la curva exige un nivel de dominio.

### 6.2 El "personaje esperado" al llegar a cada jefe

Es el personaje que el diseño de ese jefe asume. Supone: árbol comprado en el orden "razonable", ninguna reliquia opcional, sin Garrán. La columna **Margen** muestra cuánto puede estar por debajo del esperado y aún ganar con paciencia (ver 6.4).

| Jefe | Hora | Vida | Frascos / cura | Daño | Espera golpe | Parry | Hilos / reliquias típicas | Margen (mínimo ganable) |
|---|---|---|---|---|---|---|---|---|
| 1 Centinela | 2:15 | 7 | 3 / 3 | 2 | 0,26 | 0,25 s | 3 / Cuenta, Medalla | Vida 5, daño 1 (más largo) |
| 2 Jacinto | 4:30 | 8 | 4 / 3 | 2 | 0,26 | 0,25 s | 4 / Dedal, Hoz | Vida 6, daño 2 |
| 3 Ilara | 6:15 | 10 | 5 / 4 | 3 | 0,22 | 0,30 s | 5 / Aguja, Pesa | Vida 8, daño 2 |
| 4 Hesper | 7:30 | 10 | 5 / 4 | 3 | 0,22 | 0,30 s | 5 / Aguja, Lacre | Vida 8, daño 3 |
| 5 Casimar (opc.) | 8:30 | 10 | 5 / 4 | 3 | 0,22 | 0,30 s | 6 / Diente | Vida 9 |
| 6 Magda | 9:15 | 11 | 5 / 5 | 3 | 0,18 | 0,35 s | 6 / Diente, Clavo | Vida 9, daño 3 |
| 7 Rufo (opc.) | 10:00 | 11 | 6 / 5 | 3 | 0,18 | 0,35 s | 6 / Campanilla | Vida 10 |
| 8 Eudora | 10:50 | 12 | 6 / 5 | 3 | 0,18 | 0,35 s | 7 / Piedra blanca | Vida 10 |
| 9 Maelis | 12:55 | 13 | 6 / 5 | 3 | 0,18 | 0,35 s | 9 / cualquiera | Vida 11 |
| 10 Oda (secreto) | 14:00 | 13 | 6 / 5 | 4 | 0,16 | 0,35 s | 9 / Insignia (de Oda) no necesaria | Vida 13 y Garrán |

### 6.3 Tiempos objetivo de pelea

"Pelea limpia" es el tiempo de un intento que acaba en victoria, entre que se cruza el umbral y cae el jefe, con el personaje esperado. Fórmula de partida: **golpes eficaces necesarios (N) × ~8 s por golpe eficaz**, porque entre golpe y golpe hay avisos, esquivas y ventanas.

| Jefe | Puntos de vida del jefe (armadura + núcleo) | N a daño esperado | Pelea limpia | Intentos (mediana / rango) | Muertes al jefe si se mantiene |
|---|---|---|---|---|---|
| 1 Centinela | 42 (existente: armadura 27 + núcleo 15) | 21 | 2:30 - 4:00 | 3 / 1-6 | 3 |
| 2 Jacinto | 52 | 26 | 3:00 - 4:30 | 3 / 1-7 | 3 |
| 3 Ilara | 72 | 24 | 3:00 - 5:00 | 4 / 2-8 | 4 |
| 4 Hesper | 90 | 30 | 4:00 - 6:00 | 5 / 2-9 | 5 |
| 5 Casimar (opc.) | 96 | 32 | 4:00 - 6:00 | 6 / 3-10 | 6 |
| 6 Magda | 102 | 34 | 4:30 - 6:30 | 5 / 2-9 | 5 |
| 7 Rufo (opc.) | 90 | 30 | 4:00 - 5:30 | 5 / 2-8 | 5 |
| 8 Eudora | 108 | 36 | 5:00 - 7:00 | 6 / 3-10 | 6 |
| 9 Maelis | 144 | 48 | 6:30 - 9:00 | 7 / 3-12 | 7 |
| 10 Oda (secreto) | 150 | 50 | 5:00 - 7:00 | 10 / 5-20 | 10 |

Los puntos de vida de los jefes 2-10 son una propuesta de presupuesto; el Centinela ya tiene su tabla en `jefes.md`. Con Garrán, N baja un 25 % y la pelea un 20 %. Con una reliquia ofensiva (Pesa), no cambia el tiempo (menos golpes, más lentos).

Duración total del juego con estos números: 7 jefes obligatorios × 5 intentos × ~4 min ≈ 2,3 h de combate de jefe, el 18 % del camino principal. Es una proporción sana.

### 6.4 Reglas para que ningún jefe sea imposible

Un jefe se da por válido en el taller cuando cumple **todo** lo siguiente:

1. **Ganable sin extras.** Alguien con el personaje esperado, **sin reliquias ni Garrán**, lo vence en ≤ 10 intentos (jefes opcionales y secretos: ≤ 15).
2. **Todo ataque avisa.** Aviso mínimo de 0,45 s para ataques de un golpe, 0,35 s para ataques rápidos que solo hacen 1 de daño. El aviso es una animación y un color, nunca solo sonido.
3. **Daño por golpe ≤ 25 % de la vida esperada** (el jefe necesita ≥ 4 golpes para matar; 2 de 10 = 20 %; 3 de 13 = 23 %). Ataques de 3 solo en jefes de la Herida y con 0,75 s de aviso.
4. **Al menos una ventana segura por ciclo**, de ≥ 1,2 s.
5. **Sin ataques inevitables.** Todo ataque se esquiva con dash, parry o posicionamiento; no existe daño por área que cubra la arena sin hueco.
6. **Sin dependencia de azar** para el daño (se puede hacer una furia con aleatoriedad en la posición de rocas, pero no en el aviso).
7. **Camino de vuelta ≤ 90 s** desde el Ancla hasta la puerta de la arena. El último Ancla antes del jefe está siempre a ≤ 60 s.
8. **Con Garrán o reliquias se hace más fácil, no necesario.** Ninguna reliquia rompe el combate: el tope absoluto es de 5 de daño, 0,16 s de espera.
9. **Validación con personaje mínimo:** el equipo prueba además con el "margen" de la tabla 6.2 y debe ser ganable en ≤ 15 intentos.
10. **Los ataques de un jefe nunca se acumulan con los enemigos comunes.** La arena está limpia al entrar.
11. **Jefes y respiración:** después de cada jefe, una sala sin enemigos con recompensa y Ancla.

### 6.5 Si el jugador llega con menos

| Situación | Efecto | Ayuda del diseño |
|---|---|---|
| Menos vida (5-6 en el jefe 1) | El jefe 1 dura ~6 min y exige 5-7 intentos | Cuenta del Rosario y Dedal (en la tienda) suavizan |
| Sin Aliento / sin frascos extra | Más difícil en jefes largos (Hesper, Magda) | El Ancla antes del jefe y una sala previa con Bolsas |
| Sin Guardia III | Parries a 0,25 s frente a un aviso de 0,40 s | Dash como alternativa; el aviso nunca exige parry |
| Sin Garrán | -1 de daño | Nada: diseñado para ello |
| Sobrearmado (todo el árbol, Piedra blanca) | Jefes entre un 25 % y un 40 % más cortos | No es un problema: es la recompensa de completar |

### 6.6 Modo asistido (opcional)

Un submenú "Ayuda" en Opciones, con **interruptores independientes** (no una barra de "fácil / difícil"). Se pueden cambiar en cualquier momento, también durante el juego, sin reiniciar. No hay aviso de culpa ni cambio de final.

| Opción | Valores | Efecto |
|---|---|---|
| Daño recibido | 100 % / 75 % / 50 % | Redondeo hacia arriba, mínimo 1 |
| Eco seguro | Sí / No | No se pierden los Ecos al morir |
| Margen del parry | Normal / +50 % | La ventana sube, con tope 0,50 s |
| Frascos | Normal / +1 cura y −30 % de tiempo | Mejora el frasco |
| Velocidad del juego | 100 / 90 / 80 % | Reduce la velocidad de todo el juego (hit stop aparte) |
| Vida de enemigos | 100 / 75 % | Redondeo hacia arriba |
| Aviso extra | No / Sí | Resalta 0,1 s antes de cada ataque |

Reglas: los logros siguen disponibles, con etiqueta "con ayuda" (sin bloquearlos); no se desactiva ningún final. **Oferta pasiva:** tras 6 muertes seguidas al mismo jefe, el menú de pausa muestra una línea "¿Quieres ajustar la ayuda?"; nunca un cuadro emergente. Nunca se activa sola. Coste: M.

---

## 7. Rejugabilidad y post-juego

Canon (`guion-maestro.md` §13): una sola partida debe poder verlo todo; no hay segundos mapas ni finales ocultos que exijan repetir. Todo lo siguiente es opcional y de bajo coste.

| Elemento | Qué es | Coste | Prioridad |
|---|---|---|---|
| **Sala de Aún → continuar** | Tras el final se vuelve al Umbral con la partida guardada justo antes de la Sala, para completar Nombres, Páginas, opcionales y el secreto de Oda (el 100 % de 15 h) | S (ya implícito) | Alta |
| **Contador de partida y tiempos** | Cronómetro en Estadísticas (tiempo de juego, muertes, Ecos totales) y **mejor tiempo por jefe** (pelea limpia). Sin tablas online | S | Alta |
| **Logros narrativos** | Ver lista abajo. Sin recompensa mecánica | S | Alta |
| **Memorias de jefe** | Tras vencer a un jefe, en el Ancla de su región, la opción "Recordar a {nombre}" repite la pelea en su arena (sin Ecos ni recompensas, con el mejor tiempo guardado) | M | Media |
| **Modo sin Ecos** | Los Ecos no se recuperan al morir (el Eco desaparece). Para quien quiera que la muerte duela. Marca "Camino del Olvido" en el título | S | Media |
| **Pruebas de la Pasarela** | Desafíos de plataformas con tiempo en La Chimenea y La Pasarela (cronómetro y medalla de bronce/plata/oro, sin recompensa) | M | Baja |
| **Nuevo Ciclo** | Ver siguiente subsección | M | Baja |

### 7.1 Logros

Sin recompensa mecánica. Se muestran en Estadísticas. Los marcados con (A) se desactivan con "Daño recibido < 100 %" o "Eco seguro".

| Logro | Condición |
|---|---|
| Despertar | Pronunciar los nombres del primer Ancla |
| Donde se sostiene | Leer los 5 Nombres de una región |
| Pronunciaste todos los nombres | Leer los 30 |
| Silencio | Callar un Nombre con el Paño (no es "malo": es un hecho) |
| Sin mirar atrás | Vencer a cualquier jefe obligatorio al primer intento (A) |
| La Carrera | Cruzar La Pasarela sin caer ni usar Ancla |
| Llegaste al Mirador sin morir | Alcanzar El Mirador sin morir desde el despertar (A) |
| Recuerdas | Recoger tu Eco 10 veces |
| Olvidar no ayuda | Recoger tu Eco sin haber perdido nunca más de uno seguido |
| Manos llenas | Tener 22 reliquias |
| Hilo completo | Alcanzar los 9 Hilos |
| Todo el árbol | Comprar el nivel 43 |
| Relevo | Completar el epílogo secreto |
| Una vida | Vencer a Maelis sin usar Brasa ni Cuenta del Rosario (A) |

### 7.2 Nuevo Ciclo (propuesta de mínimos)

Canon: conserva habilidades, árbol y Nombres; los PNJ no te reconocen; el mapa se conserva; enemigos algo más duros.

| Regla | Detalle |
|---|---|
| Se conserva | Habilidades, árbol, reliquias, Hilos, Nombres leídos, mapa, logros y mejor tiempo |
| Se reinicia | Jefes (reaparecen), fragmentos del mundo (se pueden volver a recoger **sin** sumar: ya están contados), Bolsas, fatiga del Rastro, Paño (se puede volver a callar... una vez por Nombre) |
| Dificultad | Enemigos y jefes ×1,5 de vida, +1 de daño (mínimo 2), aviso de ataque 10 % más corto |
| Ecos | Se mantienen y se cobran igual; el sumidero es la **tienda de Cano del Ciclo**: 4 reliquias exclusivas de 150-300 Ecos (Fragmento de Eco: +1 daño bajo 5 de vida; Pluma de Ceniza: parry cura 1 sin límite; Nudo apretado: +1 Hilo; Moneda de plata: Moneda sin cara sin penalización) |
| Textos | Pocas líneas cambian en PNJ ("No te conozco") |
| Fin | Un único final por ciclo; sin ciclo 3 |

Por qué es opcional: añade contenido sin mapas nuevos y solo vale la pena si el playtest dice que el juego "pide más". Si se recorta (el guion marca el orden: último en caer son los jefes opcionales), sale sin dolor.

---

## 8. Tabla de implementación

Estimación: **S** = ≤ 1 día; **M** = 2-4 días; **L** = 5+ días. Depende de lo que haya antes en la columna "Depende de".

### 8.1 Sistemas nuevos

| # | Sistema | Qué cambia | Dónde | Depende de | Coste |
|---|---|---|---|---|---|
| 1 | **Frasco rediseñado** (cura fija + sorbo interrumpible) | `use_heal_charge()` con `heal_amount`/`heal_time` exports; el sorbo se cancela con un golpe; el HUD enseña la cura | `core/components/health_component.gd`, `player.gd`, HUD | — | **M** |
| 2 | **Fórmulas de estadísticas con tope** | `Skills.stat()` + `StatSheet` (suma de árbol + reliquias + fragmentos, clamp al tope absoluto) | `game/player/skills.gd`, nuevo `game/player/stats.gd` | — | **S** |
| 3 | **Árbol ampliado (21 mejoras)** | +12 ids en `LIST`; `SkillTree.define()` admite `requires_level` y `gate`; nueva vista con desplazamiento | `skills.gd`, `core/components/skill_tree.gd`, `skill_tree_view.gd`, menú del Ancla | 2 | **L** |
| 4 | **Efectos nuevos del árbol** | Aliento, Sorbo, Fortaleza (retroceso), Brasa, Rompecorazas (armadura), Castigo, Peso, Paso fantasma (invulnerabilidad de dash), Desvío (proyectiles), Latido, Asidero, Voz | `player.gd`, `enemy.gd`, `projectile`, `centinela.gd` (armadura) | 1, 3 | **L** (cada uno S-M) |
| 5 | **Fragmentos de vida y de frasco** | Pickup genérico con id; contador; fórmula de vida máxima; texto "n/4" | `game/pickups/`, `player.gd`, guardado | 2 | **M** |
| 6 | **Bolsas de Rastro** | Pickup que da Ecos una vez, id guardado | `game/pickups/` | 5 | **S** |
| 7 | **Reliquias y Hilos** | Datos de las 22 (`game/player/relics.gd`), componente genérico `core/components/loadout.gd` (ranuras, equipar, capacidad), modificadores aplicados en `StatSheet`, 22 iconos | `core/`, `game/player/`, menú del Ancla | 2 | **L** |
| 8 | **Menú de reliquias en el Ancla** | Segunda opción del menú; lista con coste y descripción; barra de Hilos | `game/ui/anchor_menu.*` | 7 | **M** |
| 9 | **Registro de Nombres y diario** | Lista de 30 ids, leídos/callados, `Names` en `game/`; lectura de inscripciones notifica; pestaña "Nombres" y "Reliquias" | `game/`, `pause_menu.*`, `inscription` | — | **M** |
| 10 | **El Paño: "Callar un nombre"** | Opción de menú, confirmación, +40 Ecos, marca el Nombre | `anchor_menu`, `Names` | 9 | **S** |
| 11 | **Tienda de Cano** | Interacción con Cano, lista de 4 reliquias, compra | `game/npc/`, `relics.gd` | 7 | **M** |
| 12 | **Garrán (Filo Hondo)** | Hierro de misión, interacción, tope de daño +1 | `game/npc/`, `Stats` | 2 | **S** |
| 13 | **Economía: precios, caps y fatiga** | `ecos_reward` por región (datos), cap 600, contador de cosechas por enemigo, mensaje "Rastro gastado" | `enemy.gd`, `player.add_ecos`, guardado | — | **M** |
| 14 | **Marcadores y planos** | Candado automático, 8 alfileres, 6 planos, "Hallazgos" | `world.gd`, mapa de la pausa | — | **M** |
| 15 | **Viaje: barca y "Decir los nombres"** | Viaje fijo de la barca (S); viaje desde el Ancla al Hito del Umbral y vuelta (M) con carga corta | `world.gd`, `memory_anchor.gd`, menú del Ancla | 14 | **M** |
| 16 | **Progreso %** | Cálculo de "Camino" y "Completado" | `game/`, pausa | 5, 7, 9 | **S** |
| 17 | **Modo asistido** | 7 interruptores; guardado en `opciones.cfg` | Opciones, `player.gd`, `enemy.gd` | 1 | **M** |
| 18 | **Estadísticas y tiempos** | Cronómetro, mejor tiempo por jefe | `game/`, pausa | — | **S** |
| 19 | **Memorias de jefe, Pruebas** | Repetición de arena sin recompensa; cronómetro de sala | `boss_room.gd` | 18 | **M** |
| 20 | **Nuevo Ciclo** | Marcador de ciclo, multiplicadores, tienda del ciclo | `game/`, guardado | 7, 13 | **M** |

### 8.2 Orden recomendado

| Fase | Contenido | Por qué en este orden |
|---|---|---|
| **A. Base de estadísticas** | 2 (StatSheet con topes) y 1 (frasco rediseñado) | Todo lo demás depende de saber cuánto cura, cuánto daña y cuánto es el techo. Se puede jugar y sentir ya |
| **B. Economía legible** | 13 (precios, cap, fatiga), 6 (Bolsas), 5 (fragmentos) | Con estas piezas el Cinturón y el primer Archivo tienen su ritmo de Ecos y su "+1 de vida" |
| **C. Árbol mínimo ampliado** | 3 (con 6 de las 12 mejoras nuevas: Aliento, Sorbo, Latido, Rompecorazas, Brasa, Asidero) y las partes de 4 que exijan | Primero lo que no cambia reglas de combate |
| **D. Reliquias** | 7, 8, 11 | Mientras el Archivo se construye: los primeros 8 amuletos |
| **E. Nombres y Paño** | 9, 10 | Se necesita antes de las Minas/Costa; da Hilos |
| **F. Mapa, viaje y progreso** | 14, 15 (barca), 16, 18 | Cuando haya más de 40 salas |
| **G. Forja y resto del árbol** | 12, resto de 4 (Castigo, Peso, Fortaleza, Paso fantasma, Desvío, Voz) | Cuando existan Minas y los jefes correspondientes |
| **H. Ayuda y post-juego** | 17, 15 (Hito), 19, 20 | Cierre de calidad |

Las fases A-B son lo único que bloquea la "calibración" del juego; todo lo demás se enchufa sin romper nada. Cada fase es un PR (`docs/flujo-git.md`) con su rama.

### 8.3 Guardado de lo nuevo

Se añade `version: 2` al archivo `user://partida.json` y las claves nuevas, **todas opcionales** al cargar. Una partida sin ellas se lee con los valores iniciales (se comprueba con una partida vieja de verdad).

| Clave | Contenido | Valor por defecto si falta |
|---|---|---|
| `skills` | Niveles (ya existe). Los ids nuevos se ignoran si no existen en la versión | niveles 0 |
| `fragments` | Lista de ids de fragmentos de vida y de frasco recogidos | `[]` |
| `bags` | Lista de ids de Bolsas de Rastro recogidas | `[]` |
| `relics` | `{ owned: [...], equipped: [...] }` | `{ owned: [], equipped: [] }` |
| `names` | `{ read: [...], silenced: [...] }` | vacío |
| `forge` | `{ filo_hondo: bool, iron: bool }` | `false` |
| `harvest` | `{ "sala:pos": n }` (cosechas por enemigo) | `{}` |
| `bosses` | Ya existe | — |
| `pins` | Alfileres del jugador | `[]` |
| `plans` | Planos leídos | `[]` |
| `stats` | `{ time, deaths, best_boss_times }` | `0` |
| `cycle` | Número de ciclo | `1` |
| (opciones) `assist.*` | En `opciones.cfg` | todos "normal" |

La capacidad de Hilos no se guarda: se calcula (3 + Nombres/6 + Piedra de Linde).

### 8.4 Pruebas automáticas (en `tests/smoke_test.gd`)

| # | Prueba | Qué comprueba |
|---|---|---|
| T1 | Topes absolutos | Con **todo** comprado y **todas** las reliquias (simulado), vida ≤ 13, frascos ≤ 6, cura ≤ 5, daño ≤ 5, espera de golpe ≥ 0,16, parry ≤ 0,35, dash ≥ 0,15, invulnerabilidad ≤ 1,0, alcance ≤ 40 |
| T2 | Tabla de costes | La suma de `costs` del árbol es exactamente 2.180; todo coste > 0 y creciente en cada mejora |
| T3 | Grafo del árbol | Ninguna mejora tiene `requires` inexistente; no hay ciclos; las puertas (`gate`) referencian jefes o habilidades reales |
| T4 | Guardado completo | Ida y vuelta de `fragments`, `bags`, `relics`, `names`, `forge`, `harvest`, `pins`, `plans`, `stats`, `cycle` |
| T5 | Partida antigua | Cargar un JSON sin `version` ni claves nuevas: arranca con los valores iniciales y conserva Ecos, habilidades y árbol; niveles que superan el máximo se recortan |
| T6 | Ids desconocidos | Un id de reliquia/mejora desconocido en la partida se ignora sin romper |
| T7 | Fragmentos | 3 fragmentos de vida = vida base; 4 = +1; 12 = +3; no hay duplicados al recoger el mismo id dos veces |
| T8 | Hilos | 5 Nombres: 3 Hilos; 6: 4; 30: 8; con la Piedra: 9; equipar más reliquias que Hilos falla; equipar fuera de un Ancla falla |
| T9 | Reliquias | Cada una de las 22 tiene su efecto numérico y su coste; Trapo +1 vida (cap 13); Pesa +1 daño y +0,12 s; Medalla conserva 25 %; Moneda duplica y anula el Eco |
| T10 | Frasco | Cura exactamente `heal_amount`; un golpe durante el sorbo lo cancela y **no gasta carga**; con vida llena no se bebe |
| T11 | Fatiga del Rastro | La 1.ª cosecha paga el 100 %, la 2.ª 50 %, la 3.ª 25 %, la 4.ª 0; se guarda y se recupera tras cargar |
| T12 | Cap de Ecos | Con 600 llevados, un enemigo no suma; con 599 + 5 queda 600 |
| T13 | Paño | Callar un Nombre da 40, lo quita de "sostenidos", no de "leídos"; no se puede callar uno que no se leyó; el contador de Hilos no baja |
| T14 | Garrán | Sin hierro no se forja; con hierro y 150 Ecos, tope de daño 4; no se cobra dos veces |
| T15 | Movimiento intacto | La suite de planes de salto (`puzzle_plans.json`) sigue verde con todas las reliquias y el árbol completo equipados: ninguna mejora altera saltos ni dash |
| T16 | Jefes | Con el personaje esperado (datos de la tabla 6.2) la pelea del Centinela es ganable por un bot simple en ≤ 10 intentos (simulación); Castigo y Peso **no** cambian el daño a jefes |
| T17 | Brasa | Se activa una vez por descanso y solo con ≥ 3 de vida; no vale contra caída mortal |
| T18 | Progreso % | Con una partida sintética al 100 % da 100; ningún coleccionable mueve el "Camino" |
| T19 | Asistido | Cada interruptor modifica solo su magnitud; con "Daño 50 %" un golpe de 1 sigue siendo 1 |
| T20 | Presupuesto de Ecos | La suma de `ecos_reward` de los enemigos colocados + jefes + Bolsas se mantiene entre 2.400 y 2.700 (camino principal bruto) cuando el mundo esté completo: detecta inflación al añadir salas |

Y la comprobación humana, no automatizable: **jugarlo**. Cada fase termina con una sesión de 30-60 min con el cronómetro, apuntando muertes por jefe y Ecos en la mano al morir, para ajustar esta tabla.

---

## 9. Preguntas abiertas y riesgos

### 9.1 Preguntas para el usuario

1. **¿Aceptas que el frasco deje de curar del todo?** (cura 3-5, sorbo interrumpible). Si prefieres mantener el "cura del todo", hay que bajar el techo de frascos a 3 y eliminar los fragmentos de frasco, y la vida de 13 pierde sentido. Mi recomendación firme es cambiarlo.
2. **Hilos por Nombres leídos o por Nombres sostenidos.** Leídos (propuesto) respeta "callar no cambia el combate". Sostenidos hace que callar cueste una ranura de vez en cuando y le da peso real, pero va en contra del canon. ¿Cuál?
3. **¿Cuánto debe pagar el Paño?** 40 por Nombre (propuesto, hasta 400). Si en pruebas nadie calla, se sube a 60.
4. **Garrán: ¿sube el tope de daño a 4 o hace otra cosa?** (p. ej. "rompe armaduras de golpe"). Subir el daño da la mejora más clara; cambiar el comportamiento es más original.
5. **¿Viaje rápido desde el acto IV con "Decir los nombres"?** Es la opción de coste menor con sentido narrativo. Alternativa: ninguno; solo atajos físicos.
6. **¿Nuevo Ciclo?** Si hay fuerza para un solo extra post-juego, ¿prefieres Memorias de jefe, Modo sin Ecos o Ciclo 2?
7. **¿Topes de 13 de vida y 6 frascos?** Cualquiera de los dos se puede bajar sin tocar nada más.
8. **Idioma de nombres**: "Hilos" (ranuras), "Rastro" (drop) y "Rompecorazas", "Castigo", "Brasa"... ¿ok? Hay que pasar la comprobación de acepciones (`CLAUDE.md`). "Brasa" y "Castigo" no tienen acepción vulgar en español de España; "Peso", "Voz" y "Latido" tampoco.

### 9.2 Riesgos

| # | Riesgo | Probabilidad / impacto | Mitigación |
|---|---|---|---|
| R1 | Cambiar el frasco rompe la sensación actual y los tests existentes | Alta / Alta | Fase A aislada, un PR; mantener el export `heal_amount = max_health` para no romper los tests del componente |
| R2 | Demasiado árbol: 43 compras abruman a un jugador de nivel técnico básico | Media / Media | La vista agrupa y bloquea con texto; las mejoras nuevas se revelan por puertas, no todas a la vez |
| R3 | La economía cuadra en papel y se desvía en cuanto el mundo real tenga más o menos enemigos | Alta / Media | T20 (presupuesto de Ecos) y un registro en el diario de cuántos Ecos se llevan ganados; recalcular al terminar cada región |
| R4 | Fatiga del Rastro frustra a quien repite zonas por morir | Media / Baja | Las muertes "recuperando el Eco" no cuentan como cosecha; el mensaje lo explica una vez |
| R5 | Reliquias de maestría (Piedra blanca, Clavo) dominan a todos los jugadores hábiles | Media / Media | Hilos escasos (3 de 9) y un solo uso por descanso; se vigila con playtest |
| R6 | Los jefes 2-10 aún no existen: sus cifras (vida, tiempo) son un presupuesto, no una medición | Alta / Media | Cada jefe se valida con 6.4 al construirlo y ajusta su fila de 6.3 |
| R7 | La opción "Castigo/Peso no afectan a jefes" se siente incoherente al jugador | Baja / Baja | Texto del menú honesto: "Contra criaturas comunes" |
| R8 | Asistido se percibe como "culpa" | Media / Baja | Sin etiquetas morales, sin cambios de final, cambiable siempre |
| R9 | Garrán es perdible y el Filo Hondo es la única mejora de daño que lo es | Baja / Baja | Ya es opcional; ningún jefe lo exige |
| R10 | 22 reliquias exigen 22 iconos (arte) y 22 textos (escritores) | Alta / Media | Priorizar 10 para la primera versión: Cuenta, Dedal, Medalla, Hoz, Aguja, Pesa, Lacre, Diente, Clavo, Piedra blanca |
| R11 | Los Ecos sobran al final y el jugador se queda sin objetivo económico | Alta / Baja | Es el cierre del sistema; los desafíos (§7) cubren el post-juego |
| R12 | Las reliquias Lacre y Campanilla dependen de IA que no existe | Media / Baja | Se implementan al final; si no, se sustituyen por "+0,1 s de invulnerabilidad" (misma cifra de coste) |
| R13 | El tamaño del HUD con 13 vidas y 6 frascos | Media / Baja | Dos filas de iconos; hay 864×486 de pantalla, hay sitio |

### 9.3 Qué no he tocado (por canon)

No se añaden cartógrafa ni mapas de pago; no se cambia el árbol de ramas; no se añaden nuevos jefes ni PNJ; no se crean materiales ni segundas monedas. Cualquier cambio de cifras de combate de jefes ya implementados (Centinela) se hace en `jefes.md`, no aquí.
