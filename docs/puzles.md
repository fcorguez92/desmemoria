# Puzles y mecánicas de mundo (documento vivo)

Estado: **diseño cerrado; construido: las fases W0, W1, W2, W3 y W4** (piezas de marcadores, pared lisa, simulador ampliado, verificador y retoque R7; marcas y coleccionables; compuerta, disparadores y muro frágil, salvo "Volver al Ancla", que es otro paquete; ciclo y plataforma sobre carril) y los puzles del dash (La Chimenea y La Pasarela) y los pinchos fijos y pulsantes. Unifica `docs/reunion/disenadores/02-puzles-de-movimiento.md` (el cuerpo del jugador: huecos, alturas, pozos) y `03-puzles-de-entorno-y-mecanicas.md` (las mecánicas de mundo: palancas, compuertas, piedras...), coordinados con el mapa (`mundo.md`, `01-mapa-macro.md`), el combate (`04`), la progresión (`05`) y los tilesets (`06`). Las decisiones al unificar y su porqué están en `docs/reunion/disenadores/DECISIONES-EDITOR-MUNDO.md`. La leyenda de caracteres del mapa de texto, en `vertical-slice.md`.

**Qué abrir para el detalle.** Cada puzle tiene su ficha completa (Cuenta, Pasos, Enseña, Pista, Sin atasco, Recompensa) en `03` §2 con su número `Pxx`; cada sala de movimiento con su dibujo `.map` y sus márgenes simulados en `02` §5 y §6. Este documento fija **qué se construye, con qué carácter, en qué orden y qué se guarda**; si algo choca con las propuestas, manda este.

## Principios (los que mandan sobre cualquier puzle)

1. **Un puzle es una frase del mundo.** Cuenta algo del canon con restos, no con texto. Si no cuenta nada, se quita.
2. **Cada mecánica se justifica por varios usos** (≥ 3 puzles, ≥ 2 regiones; Nombrar es la excepción, por ser habilidad del canon). Si solo sirve a un puzle, el puzle se reescribe con las que ya existen.
3. **Legible sin texto.** En este orden: se ve el efecto, se ve la causa (palanca con su testigo), se prueba sin riesgo (primera vez sin enemigos ni pinchos) y solo después se combina.
4. **Sin atasco.** Se sale siempre por donde se entró; ningún puzle cierra una reja sobre el jugador; morir o descansar reinicia lo temporal.
5. **Lo difícil es opcional.** El camino principal no pasa de dificultad 3. Los de 4 y 5 dan reliquias, atajos o lore.
6. **El camino principal solo usa mecánicas "de núcleo".** Todo puzle que dependa de una mecánica de ampliación o recortada tiene una **versión base** sin ella (plataformas fijas, palanca simple) o es opcional.
7. **Poco código.** Todo se coloca con marcadores del mapa de texto. Lo nuevo en `core/` es genérico (no sabe qué es un Nombre ni un Sello); lo específico del juego vive en `game/`.
8. **La dificultad sube por combinación y ritmo, no por precisión de píxel.**

## El cuerpo del jugador: medidas y gramática

### Medidas del motor

Baldosa 16 px; jugador 24×48 (1,5×3 baldosas). Velocidad 300 px/s; gravedad 2250 (×1,4 al caer). Salto 900 px/s (180 px = 11,25 baldosas) con recorte a la mitad al soltar. Doble salto 800 px/s, uno por tiempo en el aire (se recarga solo al pisar suelo). Dash 900 px/s durante 0,15 s (135 px = 8,4 baldosas), sin gravedad, uno por salto en el aire, enfriamiento 0,4 s. Salto de pared: caída de 120 px/s agarrado, salto con 850 px/s y empuje lateral 350 px/s durante 0,15 s; **el salto de pared no recarga el dash ni el doble salto** (decisión: se mantiene). Coyote 0,1 s, buffer de salto 0,12 s, corrección de esquina 8 px. Cámara 54×30 baldosas.

### Distancias medidas (en baldosas, con aterrizaje de 6)

| Maniobra | Hueco plano cómodo (margen ≥ 15) | Máximo jugable | Subida cómoda | Subida máxima |
|---|---|---|---|---|
| Salto | 12 | 14 (margen 12) | 10 | 11 |
| Doble salto | 21 | 24 (margen 10) | 15 | 19 (margen 14) |
| Dash en el salto | 21 | 22 (margen 15) | no sube | no sube |
| Doble salto + dash | 30 (margen ≥ 16) | 33 | subida 12 con hueco 22 (margen 14) | no medida |
| Pozo de dos paredes | ancho 5 a 14: margen 20; ancho 4: 16 | ancho 3: 11; ancho 2: 6 | sin límite | sin límite |

Lecturas: un hueco de 15 o más pide dash o doble salto; **el dash y el doble salto se parecen** (los dos cruzan 21), así que hasta 21 las llaves se diseñan como "dash o doble salto" y solo a partir de 25 (hasta 30) se exigen las dos a la vez. Las subidas de 12 a 15 son del doble salto; subir 20 con solo doble salto (margen 9) no es puzle, es precisión, y se evita. **Con el Agarre en cualquier pared, cualquier pared alta es una escalera**: por eso existe la pared lisa `%` (más abajo). El pozo de ancho 3 o menos es de maestría.

### Qué lleva el jugador en cada momento

Una sala de puerta debe ser **imposible con el inventario anterior y posible con el exacto**.

| Tramo | Inventario | Qué puede exigir una sala |
|---|---|---|
| Umbral y Terrazas hasta el foso | salto | hueco ≤ 12, altura ≤ 11 |
| Tras el Centinela Hueco | + dash | huecos de 15 a 21 |
| Tras la Torre de Riego | + doble salto | alturas de 12 a 15, huecos hasta 30 |
| Tras Jacinto (CIN-18) | + Agarre | pozos, paredes lisas, pinchos laterales |
| Archivo, Minas, Costa (orden libre) | + Agarre; **Excavar solo en las Minas tras Magda** | en el Archivo y la Costa **no se puede exigir Excavar**; la Costa ofrece camino largo (sin Excavar) y atajo con él |
| Herida y atajos | + Excavar | suelos hondos `$` |
| Acto IV (Umbral) | + Nombrar | Piedras de lectura (opcionales salvo la Sala de Aún) |

### Gramática por habilidad

Cinco peldaños: **introducir** (verlo antes de poder, usarlo sin riesgo), **desarrollar**, **retorcer** (una condición que lo hace pensar), **combinar** y **maestría** (opcional). Cifras en baldosas.

| Habilidad | Introducir | Desarrollar | Retorcer | Combinar | Maestría |
|---|---|---|---|---|---|
| **Dash** (la Carrera) | CIN-01 foso de 20 (hecha) | CIN-05, CIN-06: cruces de 16 y 17 (hechas) | HER-11 hilera de pulsantes de 24; HER-08 cruces de 22 | CIN-12 Acequia, COS-03 Cornisa de Sal: huecos de 26 a 30 | SEC-06 Establos: 3 huecos de 17 a 20 |
| **Doble salto** (Segundo Aliento) | CIN-07 Torre: cornisa de 13 | CIN-15 Bancales: subidas 13, 12, 13; hueco 15 | ARC-09 torres lisas de 14, huecos de 8 | CIN-12, HER-08 | SEC-08 Torreón: subidas 15-16, hueco 30 |
| **Agarre** (salto de pared) | CIN-25 Pozo de Piedra Seca: ancho 6, altos 22 y 17 | COS-02 Escalones del Tajo; ARC-01 Pozos Blancos | MIN-13 Zapadores (pinchos laterales); COS-04 Pilar (tramos lisos de 6) | HER-08 | SEC-09* parches de 3 entre lisas |
| **Excavar** (Golpe Hondo) | MIN-16 Hueco del Pico: pieza 3×3 y túnel de 6 | MIN-17 Veta, MIN-24 Latido | HER-07 suelo al revés: pieza correcta frente a ladrillo que no cede | SEC-07 con pared | SEC-11* |
| **Nombrar** | CIN-06 Mirador (hueco con Piedra) | HER-16 escalera de peldaños | HER-17* tablones de memoria | — | — |

(*) sala de reserva. Orden pedagógico de combinaciones: primero las dos habilidades recién conseguidas (dash + doble salto), luego cada una con la pared, y las de tres solo en maestría.

## Mecánicas de mundo: definitivas

Doce mecánicas más el terreno nuevo. **Núcleo** = obligatorias (el camino principal las usa). **Ampliación** = diseñadas y con marcador, se construyen si hay fuerza; nada del camino principal depende de ellas. **Recortada** = no se construye; el marcador queda reservado y cada sala que la usaba tiene una versión base. El carácter es el **definitivo** (el que pone el `.map`); la leyenda completa y sin conflictos está en `vertical-slice.md`.

| # | Mecánica | Marcador | Estado | Base en el código | Coste |
|---|---|---|---|---|---|
| M1 | Estado de mundo (marcas) | — | Núcleo | `core/save/flag_store.gd` | M |
| M2 | Grieta: muro o suelo **frágil** | `#` | Núcleo | `core/objects/breakable_wall.gd` | S |
| M2 | Grieta: muro o suelo **hondo** (Excavar) | `$` | Núcleo | ídem | M |
| M3 | Compuerta (reja, tablones, piedra, cal, puente, tinta) | `=` canal A, `+` canal B | Núcleo | `core/objects/gate.gd` (sale de `arena_gate.gd`) | S |
| M4 | Disparadores: palanca, placa, botón en alto | `z`, `_`, `*` | Núcleo | `core/objects/trigger.gd` | S |
| M5 | Receptor (ranura, nicho, altar) | `c` | Núcleo | `core/objects/receiver.gd` | S |
| M6 | Piedra de lectura (Nombrar) | `n` | Núcleo (3 piedras) | `game/environment/reading_stone.gd` | L |
| M7 | Plataforma sobre carril | `<` inicio, `>` fin | Núcleo | `core/objects/rail_platform.gd` | M |
| M8 | Corriente (viento y ascenso) | `)` `(` `u` | **Recortada** | `core/objects/air_current.gd` | M |
| M9 | Luz (lámparas y oscuridad) | `f` lámpara, `x` revelado | **Recortada** | `core/objects/lamp.gd` | M |
| M10 | Derribo (columna, estantería) | `k` | Ampliación | `core/objects/topple.gd` | M |
| M11 | Ciclo (ritmos y mareas) | `y` | Núcleo | `core/objects/cycle.gd` | S |
| M12 | Combinación (selector de símbolos) | `o` | Ampliación | `core/objects/dial.gd` | S |
| T1 | Pared lisa: sólida, no se agarra | `%` (baldosa) | Núcleo | dato en el `TileSet` + `PlatformerMotor` | S |
| T2 | Pinchos laterales | `{` `}` | Núcleo, fase tardía (antes de MIN-13) | `Hazard` con forma girada | S-M |
| T3 | Baldosas de región (06): desmemoriada, plataforma de piedra, muro trasero, muro con vano, agua | `g` `p` `m` `h` `a` (baldosas) | Núcleo para el arte (fase de arte) | `TextTileMap` autotiling + `TileSet` | M |

No se construyen (decisión): muro de cera `&` (02), pendientes `/` `\` (06). Sus caracteres quedan libres.

Convención de caracteres: **minúscula = mecánica o lógica; mayúscula = decorado, enemigo u objeto del mundo.** Hay pares que comparten letra con distinta caja (`c`/`C`, `f`/`F`, `k`/`K`, `n`/`N`, `o`/`O`, `u`/`U`, `x`/`X`, `y`/`Y`): se han mantenido por falta de otras letras; la prueba de caracteres válidos (C12) y el hábito de escribir las mecánicas solo en minúscula evitan los errores. La palanca es `z` y no `l` (la `l` se confunde con `1` e `I` en pantalla).

### Cómo se colocan (reglas comunes)

- Una **pieza** es un grupo de marcadores contiguos del mismo carácter (un muro de 2×6 es **una** pieza con 12 marcadores). Lo resuelve `TextTileMap.marker_groups(char)` (fase W0). Tamaños de pieza: de 1×1 a 4×10 baldosas.
- **Identificador de pieza:** `carácter@columna,fila` de su primera celda en orden de lectura (ej. `z@12,30`). Mover una pieza cambia su identificador, por eso lo **permanente** se declara a mano en la escena de la sala (campo `links`, un diccionario pieza → marca; para una compuerta o receptor el valor es la lista de marcas que lee —todas, "Y"—, para una palanca, placa, botón o grieta, la marca que escribe).
- Sin `links`, la marca por defecto de una palanca, placa, botón o muro es `t:sala.nombre_columna_fila` (**temporal** hasta que se le dé nombre a mano; p. ej. `t:cisterna.palanca_20_21`) y la de una compuerta es el canal de su sala (`t:sala.canal_a` para `=`, `t:sala.canal_b` para `+`). **Hecho en W2:** `room.gd` crea una entidad por pieza y lee `links` de la escena.
- `i` (inscripción): la k-ésima `i` del mapa, en orden de lectura, toma el k-ésimo texto del campo `notes` de la sala; si la sala solo tiene `note` (como hoy), todas lo usan.
- `!` (coleccionable) y `@` (personaje): el tipo y el id los declara la escena en `pickups` y `npcs`, en orden de lectura de los marcadores. Los enemigos nuevos `5`-`9` son **roles**; la escena (`enemy_set`) dice qué enemigo es cada uno en esa sala.
- Una `#` o `$` rota **no vuelve**; si el jugador la rompe, queda guardada (ver Estado).

### M1 · Estado de mundo (las marcas)

Diccionario de marcas con nombre (`p:torre_de_riego.rueda`). Las mecánicas no se hablan entre sí: una escribe una marca y otra la lee. API: `set_on(id, permanente)`, `is_on(id)`, `clear(id)`, señal `changed(id, valor)`. Permanente = se guarda; temporal = vive hasta el próximo reinicio (descansar o morir). Un `Node` del mundo en el grupo `flag_store`; los objetos de `core/` lo encuentran por grupo (no importan `game/`); `world.gd` lo vuelca en `save_game()` y lo recarga en `_apply_save()`. Ids desconocidos al cargar se ignoran.

### M2 · Grieta (frágil y hondo)

- **Frágil** (`#`): muro o suelo con **grietas blancas en zigzag** y polvo. Se rompe con el Filo, 3 golpes (cada uno agranda la grieta y suena hueco), sin habilidad alguna.
- **Hondo** (`$`): roca con **veta de rombos ámbar** (el color del recuerdo de Magda). Sin Excavar el Filo rebota con chispa y tañido, sin daño; con Excavar se rompe en 2 golpes. **Excavar = el tajo contra un muro hondo y el ataque hacia abajo (abajo + atacar, en el suelo o en el aire) contra un suelo hondo**, como fija `nucleo-jugable.md` (editor de sistemas). Sin Excavar, el ataque hacia abajo en el aire rebota (pogo) sobre `$` como sobre cualquier sólido; con Excavar lo rompe.
- Al romperse la pieza entera desaparece en 0,4 s con polvo, no vuelve y nunca daña. Una pieza hondo sobre un hueco nunca deja una sala sin salida: **todo túnel bajo una `$` tiene una salida que no exige Excavar** (MIN-16 lo cumple por simulación).
- Forma distinta además de color (para quien no distingue colores): zigzag frente a rombos.
- Guarda: permanente (`s:` secreto, `d:` atajo). Implementación: `StaticBody2D` golpeable como `BreakableProp`, con `hits`, `requires` (propiedad booleana del atacante; el jugador expone `can_dig`) y señal `broken`.

### M3 · Compuerta

Una pieza que cierra o abre un paso. Se abre cuando su marca (o todas las de su lista) está activa; animación de 0,45 s con `gate_open`; **nunca se cierra encima del jugador** (espera a que quede libre). Vestidos: **reja** (la Orden), **tablones** (Umbral, Cinturón), **piedra** (Minas), **cal** (Costa y Herida), **puente** (aparece en vez de desaparecer) y **tinta** (`fade_on_stand`: se borra 1,2 s después de pisarla y vuelve a los 6 s). Opciones: `inverted` y `one_way_side` (manilla solo en un lado: el patrón "se abre desde el otro lado"). Canal A = `=`, canal B = `+`. Es `arena_gate.gd` sacado de `game/boss/` a `core/objects/gate.gd`; `boss_room.gd` pasa a usar la versión de `core/` sin cambiar su comportamiento. Las rejas de arena (`[` `]`) siguen siendo las de `boss_room.gd`: no llevan testigo.

### M4 · Disparadores

- **Palanca** (`z`): Z o golpe; queda activada para siempre salvo `toggle` (alterna, temporal). Lleva un **testigo** (lamparilla) visible desde ambos lados.
- **Placa** (`_`): activa mientras haya alguien encima y `hold_time` segundos después (0 a 10; el testigo se apaga en cuenta atrás). Temporal.
- **Botón en alto** (`*`): disco de bronce a más de 4 baldosas, se golpea saltando; queda activado.
- Si el efecto cae fuera de pantalla: suena en su posición y sale "Algo se ha abierto, en alguna parte." con un punto en el mapa. Un único `trigger.gd` con `mode`.

### M5 · Receptor

Nicho (`c`) con la silueta de lo que espera. Mantener Z (`hold_time`): si todas las marcas de `requires` están activas, escribe su marca y reproduce su vestido; si no, `Readable` enseña la pista. No consume nada: los objetos no son inventario, son marcas. Hereda de él la Piedra de lectura.

### M6 · Piedra de lectura (Nombrar)

Piedra pulida con la **sombra grabada** de una cosa (`n`). Sin Nombrar: "Esta piedra pide un nombre." Con Nombrar: **mantener Z 0,6 s** abre la lista de Nombres sostenidos (ordenada por región); acierta o "La piedra no responde." (1,5 s de espera, sin castigo). Lista: solo los **sostenidos** (los callados con el Paño no aparecen), más **Linde** si se ha pronunciado (no cuenta entre los 30). Depende del diario de Nombres, que **aún no existe** (fase W7). **Solo hay tres piedras:**

| Id | Sala | Acepta | Efecto |
|---|---|---|---|
| `nudo` | El Patio de los Nombres (UMB-03) | Linde | Afloja el nudo (permanente) |
| `mirador` | El Mirador (CIN-06) | Oda Bellver | Invoca el Eco de Oda y empieza la carrera |
| `escalera` | La Sala de Aún (HER-16) | todos los sostenidos | Enciende peldaños |

Quedan **diferidas** (no se construyen; ver P21, P25, P33, P37, P40): `arco`, `voces`, `rellano`, `hojas`, `mesa_a`, `mesa_b`.

### M7 · Plataforma sobre carril

Plataforma de madera o hierro sobre un **carril dibujado** entre dos puntos (`<` y `>` más cercanos entre sí). De un solo sentido por arriba. Tres modos: **continua** (va y viene, espera 1,5 s en cada extremo), **a demanda** (se mueve al pisarla o al accionar su marca, vuelve a los 8 s) y **viaje** (Z en el embarcadero: sale, cruza y se queda). Velocidad 80 px/s por defecto (la barca, 160). **Nunca aplasta**: si algo la bloquea más de 0,3 s, se detiene y retrocede. Lleva al jugador con ella. `AnimatableBody2D` con `sync_to_physics`; el motor del jugador solo necesita no cancelar la velocidad que hereda del suelo (a comprobar con prueba). Usos del núcleo: la vagoneta de MIN-02, la barca del Cauce, y las ruedas y torres opcionales.

### M11 · Ciclo

Alterna una marca con `period`, `on_fraction`, `phase` y `warning_time`, exactamente como los pinchos de `hazard.gd` (2,4 s, 40 % activo, aviso 0,4 s). Ritmos: **tinta** 4 s / 3 s, **marea** 40 s (20 alta, 20 baja, aviso 3 s), **ventana** 6 s. Todo ciclo avisa al menos 0,4 s antes de cambiar, con el mismo gesto (la pieza alterna dos fotogramas a ~12 Hz). No guarda nada. Un `Node` de ~30 líneas.

### M10 · Derribo (ampliación)

Columna o estantería-torre con base cuarteada (`k`): un golpe la hace crujir 0,5 s y **cae en la dirección del golpe** girando 90° en 0,9 s hasta quedar como plataforma horizontal de un solo sentido. Solo cae si el hueco está libre. 1 de daño a lo que haya debajo. Si cae sobre una placa, la mantiene pulsada para siempre. Sin física de rígidos (`Tween`). Usos: P15, P28, P32.

### M12 · Combinación (ampliación)

3 a 5 discos grabados (`o`) con 4 símbolos que giran con el golpe o con Z; la solución nunca está en el selector. No hay intento fallido. Usos: P08, P16.

### M8 y M9 (recortadas)

M8 Corriente (viento ±180 px/s y ascenso) y M9 Luz (lámparas y plataformas reveladas) **no se construyen**: son las más caras en motor y arte y ningún camino principal las necesita. Las salas que las usaban tienen versión base: el Acantilado de Cortinas (COS-05) con plataformas fijas y el viento solo como partículas; la Cripta de las Lámparas (MIN-23) y la Mina Inundada (MIN-25) como plataformas de dash + doble salto; el Campo de los Ferrán (CIN-10) como combate con parche gris visual; el Faro (COS-18/19) con cal en las plataformas y sin luz. Si algún día se construyen, ya tienen carácter. Si se hiciera M8, `02` pide simular con la corriente dentro, y nunca ponerla en el cruce principal.

### T1 · Pared lisa `%`

Baldosa sólida que el Agarre no agarra (un dato `grip = false` en el `TileSet`, como el de "un solo sentido", y una comprobación en `PlatformerMotor`). Sin ella el Agarre se salta casi todo el diseño vertical. Convención de arte por región: **brillo sin grieta = no se agarra** (Archivo: blanco liso con juntas finas, agarres negros sobre blanco; Costa: sal blanca casi azul; Minas: roca pulida; Herida: brillo sin textura; el Cinturón no tiene lisas). Todo muro de una sala de orden libre (Archivo, Costa) alrededor de una puerta de doble salto o dash es `%`, no `B`. El autotiling de 06 la trata como terreno.

### T2 · Pinchos laterales `{` `}`

`{` es una tira pegada a una pared **izquierda** que apunta a la derecha; `}`, pegada a una pared **derecha** y apunta a la izquierda. Dañan 1 y devuelven al último suelo firme (como `^`). Cada tira mide 6 y siempre hay dos tiras vecinas de pared libre; el lado seguro es el cercano a la entrada. Fallback si no se construyen: tiras de `^` y `v` en repisas. Se necesitan para MIN-13 y SEC-07.

**Hecho en W4.** No hay pieza nueva en `core/`: son el mismo `Hazard` de los pinchos de suelo (`spikes.tscn`), girados 90° (`{`) o -90° (`}`) por `room.gd` (tabla `SPIKES`). Un `{` es una tira de 9×12 px pegada al lado izquierdo de su celda (el de la pared) y un `}` su espejo, así que el daño solo llega por el lado libre y coincide con la caja que usa `tools/sim_saltos.js` (`HAZBOX`). Dañan 1 y devuelven al último suelo firme igual que `^` (con 1 de vida matan, como `^`). Ejemplo: el pozo de la Torre de Riego (columnas 48-53, 6 de ancho), con 6 baldosas de `}` en la pared derecha (filas 8-13) y 6 de `{` en la cara del pilar (filas 16-21); se sube con Agarre en 2 saltos de pared (margen 14 en el simulador) y hay un `!` arriba. Sin Agarre se entra y se sale andando por debajo del pilar (6 baldosas libres). Arte: el sprite de pinchos girado; el dibujo definitivo queda pendiente.

## Estado y guardado

### Reglas

1. Un estado es **permanente (P)** si abre un camino, paga una recompensa o ya cuesta más de dos pasos. Todo lo demás es **temporal (T)**.
2. **T se reinicia al descansar o morir** (objetos del grupo `resettable` con `reset()`), no al cambiar de sala.
3. **Siempre se carga desde un Ancla**: T arranca de cero, no hace falta guardarlo.
4. Una cadena de más de dos pasos se registra paso a paso: el paso completado queda P.
5. Un id desconocido al cargar se ignora; una partida antigua sin las claves nuevas carga como si no hubiera marcas.

### Dónde y cómo

La partida (`SaveSlot`, `user://partida.json`) guarda `{ version = FORMAT_VERSION, data = {...} }` y **rechaza** una versión distinta. Por eso **no se sube `FORMAT_VERSION`** (la propuesta de `05` de pasar a `version: 2` descartaría todas las partidas): todo lo nuevo son **claves opcionales dentro de `data`**:

| Clave | Contenido | Lo guarda | Si falta |
|---|---|---|---|
| `flags` | Lista de marcas permanentes (puzles, secretos, atajos, Sellos, objetos de trama): ids con prefijo `p:` `s:` `d:` `i:` | M1 FlagStore | `[]` |
| `fragments` | Ids de fragmentos de vida y de frasco recogidos | pickups `!` (05) | `[]` |
| `bags` | Ids de Bolsas de Rastro recogidas | pickups `!` (05) | `[]` |
| `relics`, `names`, `forge`, `harvest`, `pins`, `plans`, `stats`, `cycle` | Como en `05` §8.3 | sistemas de `05` | valores iniciales |
| `bosses`, `rooms`, `seen`, `player` | Ya existen | `world.gd` | — |

Reparto: lo que es "una cosa hecha en el mundo" (palanca, grieta, piedra, Sello, Relevo) va en `flags`; lo que es "un objeto que se recoge y se cuenta" (fragmentos, bolsas, reliquias, Nombres) va en su clave, porque tiene contador o inventario. **El formato del id es el mismo** y la prueba de ids únicos mira los dos.

### Identificadores estables

**Hecho en W1.** `FlagStore` (`core/save/flag_store.gd`) guarda `flags` como diccionario `{ id: valor }` (no lista: `p:aun.final` necesita un valor de texto; una lista de ids antigua también se acepta). El mundo (`world.gd`) lo crea, lo mete en los grupos `flag_store` y `resettable` (las marcas `t:` se borran al descansar o morir) y lo guarda y carga junto al resto; `FORMAT_VERSION` sigue en 1 y una partida sin las claves carga sin marcas. **Coleccionables `!`:** `room.gd` pone una `game/pickups/collectible.tscn` en cada `!` con el id **`archivo_del_mapa.cCCfFF`** (columna y fila del marcador, p. ej. `cisterna.c37f05`): no hay lista que mantener y escala a cualquier número de salas; solo cambia si se mueve el `!` en el mapa. El tipo sale del campo `pickups` de la sala, atado a la posición: entradas `cCCfFF:tipo` (p. ej. `c37f05:bag`; tipos `fragment`, `bag`, `item`); sin entrada es `fragment`. Al cargar, los ids de `fragments` y `bags` que no existen entre los coleccionables del mundo se ignoran. Los fragmentos van a `fragments`, las bolsas a `bags` (listas de ids; los contadores salen de su tamaño, un id repetido no suma) y los objetos a `flags` con `i:`. Recoger un fragmento avisa "Fragmento de vida n/4". **Pendiente:** el +1 de vida cada 4 (K10, toca la estadística de vida), el Eco de las Bolsas (K11) y el dibujo definitivo (ahora un rombo provisional). `verifica_mundo.js` añade C13 (cada entrada de `pickups` apunta a un `!` existente y con tipo válido; ni dos salas del manifiesto con el mismo `.map`); los ids no pueden repetirse por construcción y la prueba de humo lo comprueba sobre el mundo real.

Formato `prefijo:sala.objeto`, minúsculas, sin acentos. Prefijos: `p:` puzle, `s:` secreto, `d:` puerta o atajo, `i:` objeto o sello conseguido, `n:` Nombre (lo gestiona el diario), `t:` temporal sin nombrar. **`sala` es el nombre del archivo del mapa sin extensión** (`torre_de_riego`, `antesala_de_apuntalamiento`, `segunda_torre_de_riego`), así no depende del título que se muestra. Lo permanente se nombra a mano en `links`. La prueba de humo comprueba que no hay duplicados y que todos los ids de este documento aparecen en alguna escena.

### Qué se guarda y qué se reinicia

| Elemento | Prefijo | Ejemplo | Se guarda | Reinicia al descansar o morir |
|---|---|---|---|---|
| Grieta rota (secreto) | `s:` | `s:cisterna.rosario` | Sí | No |
| Grieta rota (atajo) | `d:` | `d:silo_sin_grano.reja` | Sí | No |
| Palanca (permanente) | `d:` o `p:` | `p:torre_de_riego.rueda` | Sí | No |
| Palanca `toggle` | `t:` | desvío de la vagoneta | No | Sí |
| Placa de presión | `t:` | placas del Cruce del Pan | No | Sí (lo que abrió, si es P, se queda) |
| Compuerta | la de su marca | `d:ultimo_umbral.verja_patio` | La marca | Si depende de T, sí |
| Receptor (Sellos) | `p:` | `p:puerta_sin_muro.cera` | Sí | No |
| Sello conseguido | `i:` | `i:sello_cal` | Sí | No |
| Piedra de lectura | `p:` | `p:pasarela.ultima_carrera` | Sí | La de 4 s, no se guarda |
| Plataforma sobre carril | — | rueda, vagoneta | No (posición) | Sí |
| Derribo (puente o peso) | `p:` | `p:estanteria_nueve.puente` | Sí | No |
| Ciclo | — | marea, tinta | No | Reinicia fase |
| Combinación resuelta | `p:` | `p:sala_de_los_lacres.libro` | Sí | No |
| Final elegido | `p:` | `p:aun.final` (`sellar`, `soltar`, `compartir`) | Sí | No |

**Hecho en W2** (todo salvo la válvula "Volver al Ancla", que es otro paquete). **M3** `core/objects/gate.gd` (`Gate`, sacada de `arena_gate`; su escena es ahora `game/environment/reja.tscn`): una pieza de una o varias celdas (`cells`), con `requires` (lista de marcas: se abre con **todas**, "Y") e `inverted`; sin `requires` se maneja a mano con `set_closed()`, que es como la usan las rejas de `boss_room.gd` (la prueba del Aljibe no cambia). Al cerrarse espera si hay alguien de `blockers` (grupos `player` y `enemy`) dentro de una celda: nunca se cierra encima del jugador. Con marcas, el estado inicial (partida cargada) se pone sin animación. Sin hacer todavía: los vestidos tablones, piedra, cal, puente y tinta, `one_way_side` y el aviso "Algo se ha abierto, en alguna parte.". **M4** `core/objects/trigger.gd` (`Trigger`, un solo script con `mode`): palanca (Z o golpe; latch, o `toggle`), placa (`hold_time`, el testigo se apaga en cuenta atrás; una fila de `_` es una placa ancha) y botón (golpe, latch). Escriben su `flag_id`; que sea permanente o temporal lo dice el prefijo del id (`t:` se borra al descansar o morir y el disparador se apaga con ella). Escenas `palanca`, `placa` y `boton` en `game/environment/` (arte provisional con polígonos). **M2 frágil** `core/objects/breakable_wall.gd` (`BreakableWall`): sólido, 3 golpes (`hits`), grietas que crecen con cada uno, desaparece en 0,4 s y escribe su `flag_id`; al cargar una partida con la marca puesta no aparece. **Por sala, sin nada a mano:** `room.gd` agrupa los marcadores en piezas (`TextTileMap.marker_groups`) y crea una entidad por pieza; el campo `links` de la escena (`"z@20,21": "d:cisterna.nicho"`, `"=@7,11": ["d:cisterna.nicho"]`) nombra las marcas permanentes y C16 las comprueba. **Ejemplo jugable:** en La Cisterna, una reja de 11 celdas (`=`, columna 7) cierra el rincón izquierdo, fuera del camino, y una palanca (`z`, columna 20) la abre para siempre (`d:cisterna.nicho`). Pendiente de M2: el hondo (`$`) y Excavar son de W5.

**Hecho en W3** (sin el vestido "tinta" de la compuerta, que no lo necesitan los puzles que hay). **M11** `core/objects/cycle.gd` (`Cycle`): una pieza de `y` (`Node2D` con su propia colisión) que alterna presente/sólida y ausente con `period`, `on_fraction`, `phase` y `warning_time` (0,4 s). Es determinista: su reloj `time` solo avanza con la física del nodo y arranca en `phase * period`. Avisa antes de **cada** cambio con el mismo gesto (parpadeo entre dos fotogramas a 12 cambios por segundo): antes de desaparecer sigue sólida (`WARNING_OFF`); antes de aparecer aún no lo es (`WARNING_ON`). Nunca atrapa: si al tocarle ser sólida hay alguien dentro de una celda, espera fuera como fantasma; quien está encima no cuenta y cae sin que nadie lo empuje. `flag_id` (opcional) escribe una marca temporal mientras es sólida; no guarda nada. **M7** `core/objects/rail_platform.gd` (`RailPlatform`, `AnimatableBody2D` con `sync_to_physics` y una forma de un solo sentido): va del punto de partida a `end_offset`. `CONTINUOUS` (va y viene, espera `wait_time` en cada extremo), `ON_DEMAND` (la pisa alguien o está su `activation_flag`: va al final, espera mientras haya alguien o la marca y a los `return_delay` s vuelve) y `TRAVEL` (con alguien a bordo, Z la manda al otro extremo; con `activation_flag`, puesta va al final y borrada al inicio; se queda donde llega). Si arranca con la marca ya puesta (partida cargada) nace en el final; las temporales se borran al reiniciar y la plataforma vuelve. Nunca aplasta: se detiene si hay un sólido o un cuerpo en su camino, o un techo a menos de `rider_height` (48 px) sobre quien lleva, y tras `blocked_time` (0,3 s) retrocede. El jugador la acompaña sin tocar `player.gd` ni `PlatformerMotor`: `move_and_slide()` ya hereda la velocidad del suelo (probado, desfase de ~1 px). **En la sala**: `room.gd` pone un `Cycle` por pieza `y` y una `RailPlatform` por pareja `<` `>` (se emparejan por cercanía; el ancho de la plataforma es el de la pieza `<` y su borde de arriba el de su fila); `piece_params` (campo de la escena, clave = id de la pieza, para una plataforma el de su `<`) ajusta cualquier propiedad del nodo: `{"<@45,25": {"mode": 1}}`. El emparejado exige mismo ancho y misma columna o fila, y es determinista (más cercano primero; a igual distancia, orden de lectura); `piece_params` avisa de las propiedades que el nodo no tiene, convierte las marcas a `StringName` y admite `"mode": "on_demand"` además del número. En TRAVEL la interacción se recibe por `_unhandled_input` y consume el evento. Ni el puente de tinta ni la plataforma cuentan como "último suelo" del jugador (grupo `no_checkpoint`, que `player.gd` consulta sin conocer las clases): al caer de un puente sobre pinchos se vuelve a suelo firme. Comprobación **C17** del verificador: extremos compatibles y sin sólidos en medio, claves de `piece_params` existentes y sus propiedades conocidas. **Ejemplo jugable**: Galerías Bajas, un rincón opcional: una plataforma a demanda (cols. 45-46) sube a una repisa alta (fila 13) con un puente de tinta de 3 celdas (4 s, 75 % presente) hacia otra repisa; sin recompensa (es la prueba de las dos piezas, no un puzle del catálogo). **Límites conocidos**: `sim_saltos.js` no modela piezas móviles ni con ritmo (cuentan como aire); dos `y` pegadas por un lado forman **una sola pieza** y alternan juntas (para una ola hace falta al menos una celda de hueco entre tramos); el vestido "tinta" (`fade_on_stand`) de la compuerta no está hecho.

**Válvula "Volver al Ancla"** (opción de la pausa; igual que morir pero sin contar como muerte, con confirmación): **adoptada** por el editor de sistemas (`nucleo-jugable.md`, `DECISIONES-EDITOR-SISTEMAS.md`, coste S) y se construye con W2. Reinicia lo temporal. El diseño de los puzles no se apoya en ella.

## Catálogo de puzles de entorno (41)

Fichas completas en `03` §2 por número. **Estado:** **N** núcleo (camino principal o canon), **O** opcional con mecánicas de núcleo, **A** ampliación (necesita M10 o M12), **R** recortado o diferido (no se construye; la sala tiene versión base). Dificultad entre paréntesis.

### El Último Umbral

| P | Puzle | Sala | Mecánicas | Estado | Marcas | Nota de unificación |
|---|---|---|---|---|---|---|
| P01 | La Tabla Suelta (1) | UMB-01 cabaña | M2f | O | `s:ultimo_umbral.tabla` | Página de Corvel 1. El Nombre **Corvel se lee aquí** pero cuenta como del Archivo (ver Secretos). Retoque diferido R8 |
| P02 | La Verja del Patio (1) | UMB-02 / UMB-03 | M4 M3 | O | `d:ultimo_umbral.verja_patio` | Atajo; la verja nunca se cierra con el jugador dentro |
| P03 | El Cordel de Aldara (2) | UMB-03 | M6 M5 | N (canon) | `p:ultimo_umbral.nudo_flojo` | Acto IV; piedra `nudo` |
| P04 | La Puerta Tapiada (2) | UMB-01 / 07 / 08 | M2h | N (canon) | `d:puerta_tapiada.muro` | En el Sótano: FV (el 12.º), grabado de Aún, objeto de lore. La Medalla del Umbral está en UMB-05 (no aquí) |

### El Cinturón Yermo

| P | Puzle | Sala | Mecánicas | Estado | Marcas | Nota |
|---|---|---|---|---|---|---|
| P05 | Las Cuentas del Rosario (2) | CIN-02 | M2f | O | `s:cisterna.rosario` | La escalera real tiene **5 peldaños**, no 7: se rehace el texto (cuentas en el 2 y el 4, nicho al lado del 5). Reliquia Cuenta del Rosario aquí; en Terrazas solo el aviso. Retoque diferido R9 |
| P06 | La Rueda de Tomasa (3) | CIN-07 | M4 M7 | O | `p:torre_de_riego.rueda` | Atajo; el camino principal sigue siendo la cornisa (Doble) |
| P07 | Las Torres en Cadena (3) | CIN-13 | M7 M4 | O | `p:segunda_torre_de_riego.torre_1`, `.torre_2` | Versión base: plataformas fijas (puzle de Doble por saltos, sin rueda) |
| P08 | El Surco Ciego (3) | CIN-08 | M12 M2h | A | `p:surco_ciego.mojones`, `s:surco_ciego.hondo` | 60 Ecos y Semilla gris |
| P09 | El Cruce del Pan (3) | CIN-11 | M4 M3 | O | `p:cruce_del_pan.mesa` | Tres placas; Página de Corvel 2 |
| P10 | El Campo Gris (3) | CIN-10 | M9 | R | — | El Nombre Eulalia se lee en el mojón; el parche gris es visual |
| P11 | El Manantial (4) | CIN-20 / 12 / 07 | M2h M3 M7 | R | — | Dedal de la Torre queda en CIN-07 |
| P12 | El Mirador de Oda (3) | CIN-06 | M6 M11 M3 | N (canon, opcional) | `p:pasarela.ultima_carrera`, `i:insignia` | Eco a 330 px/s; puentes de luz de 2 s; piedra `mirador` |
| P13 | El Relevo de la Guardia (1) | CIN-04 | M5 | N (canon, epílogo) | `p:aljibe.relevo` | Pide `p:aun.compartido` e `i:insignia` |

### El Archivo

| P | Puzle | Sala | Mecánicas | Estado | Marcas | Nota |
|---|---|---|---|---|---|---|
| P14 | Pasillo Tres (3) | ARC-06 | M11 M3 | N | — (T) | 6 tramos de suelo de tinta, 4 s / 3 s, desfasados; camino principal |
| P15 | La Estantería-Puente (3) | ARC-05 | M10 | A | `p:estanteria_nueve.puente` | Es una **rama opcional** (Página de Corvel 3); no abre la Sala de los Lacres, que tiene su propia puerta |
| P16 | La Sala de los Lacres (3) | ARC-07 | M12 M3 | A | `p:sala_de_los_lacres.libro` | Pesa del Archivo (reliquia); **no** bloquea ARC-08. Cera ámbar oscura, no roja |
| P17 | El Pasaje de las Llaves (3) | ARC-14 / ARC-15 | M4 M3 | O | `d:pasaje_de_las_llaves.puerta` | "La Escalera de Caracol" de 03 es ARC-15 (La Escalera Taponada) |
| P18 | El Retrato Ausente (2) | ARC-12 | M2f | O | `s:retrato_ausente.reverso` | Nombre Ardena |
| P19 | La Tinta que Huye (4) | ARC-10 | M3 tinta | O | — | Integrada en Los Altos del Catálogo; **no** hay sala nueva |
| P20 | El Pozo Blanco (4) | — | M8 | R | — | ARC-01 hace su papel con `%` y agarres negros |
| P21 | El Arco del Silencio (2) | ARC-15 | M6 | R | — | Piedra extra diferida |

### Las Minas del Origen

| P | Puzle | Sala | Mecánicas | Estado | Marcas | Nota |
|---|---|---|---|---|---|---|
| P22 | La Vagoneta Quieta (3) | MIN-02 | M7 M4 | N | `s:vagoneta_quieta.nicho` (nicho); palanca `t:` | Hueco de 40 que ni el dash cubre; viaje de 14 s; el nicho (Diente de la Mina) es opcional |
| P23 | Galería de las Lámparas (2) | — | M9 | R | — | No es sala del macro |
| P24 | La Cuerda de Mil Nudos (4) | MIN-06 | M7 M4 M11 | O (reducido) | `d:cuerda_de_mil_nudos.ascensor` | MIN-06 es un **pozo de Agarre** con descansos (papeles); el montacargas es solo un ascensor opcional de vuelta. Nombre Dimas al fondo |
| P25 | Cámara de las Voces (2) | MIN-08 | M6 M9 | R | — | Piedra extra diferida |
| P26 | La Fila de Espera (2) | MIN-05 | M2h | R | — | Redundante: MIN-05 ya conecta con MIN-06 |
| P27 | La Red de Pasos Hondos (3) | MIN-16 / 17 / 18 / 19 / 24 + UMB-07 + CIN-02 | M2h | N | siete marcas `d:` (ver abajo) | Reinterpretada con las salas de `01`; no con las de `03` |
| P28 | El Contrapeso del Apuntalado (4) | MIN-14 | M4 M3 (+M10) | A; **base N** | `p:antesala_de_apuntalamiento.contrapeso` | Versión base: palanca tras un salto de Doble que abre la reja de piedra. Con Derribo: el puntal cae sobre la placa |

Las siete marcas de Excavar de P27: `d:hueco_del_pico.muro` (MIN-16), `d:veta_tapiada.paso` (MIN-17), `d:silo_sin_grano.reja` (CIN-02/SEC-01), `d:pozo_de_los_cantores.paso` (MIN-18), `d:pozo_del_latido.paso` (MIN-24), `d:galeria_de_la_marea.paso` (MIN-19) y `d:puerta_tapiada.muro` (UMB-01/07).

### La Costa Retenida

| P | Puzle | Sala | Mecánicas | Estado | Marcas | Nota |
|---|---|---|---|---|---|---|
| P29 | Acantilado de Cortinas (3) | COS-05 | M8 M11 | R | — | Sala base: plataformas fijas, cortinas como decorado |
| P30 | La Playa de Nombres (2) | COS-12 | M11 M3 | O | `i:zapato_de_telmo` | Marea de 40 s; las letras de piedra (Nombres Marta y Julián) se leen con cualquier marea |
| P31 | El Faro de las Velas (3) | COS-18 / 19 | M9 M4 M12 | R | — | Sin luz: escalera de cal; el Faro es solo la arena de Rufo |
| P32 | La Casa Atada (3) | COS-09 | M10 M2f | A | `s:casa_atada.cuerda` | Cortar la cuerda tiene coste humano; el Nombre Elvira tiene otra fuente |
| P33 | El Primer Olvido (1) | COS-20 | M6 | R | — | Piedra extra diferida |
| P34 | El Embarcadero (1) | COS-15 / 16, MIN-20 | M7 M4 | N | `d:barca_varada.viaje` | Barca en el Cauce, palanca en cada orilla; ~30 s de viaje (160 px/s); sin peaje; **sin "a nado"** |

### La Herida

| P | Puzle | Sala | Mecánicas | Estado | Marcas | Nota |
|---|---|---|---|---|---|---|
| P35 | La Puerta Sin Muro (3) | HER-02 | M5 ×3, M3 cal | N (canon) | `p:puerta_sin_muro.cera`, `.piedra`, `.cal`, `d:puerta_sin_muro.abierta`; `i:sello_cera`, `i:sello_piedra`, `i:sello_cal` | Diseño más abajo |
| P36 | El Círculo Colgado (4) | HER-04 | M7 M8 M11 | R | — | Sala base: cinco sillas fijas con su placa de Nombre; los cinco Nombres se leen al llegar a cada una |
| P37 | La Escalera de Hojas (4) | HER-03 | M3 M6 | R | — | Peldaños fijos; Página de Corvel 6 al pie, sin Nombrar |
| P38 | La Pared Raspada (2) | HER-05 | M2f | O | `s:pared_raspada.raya` | |
| P39 | El Eco Quieto (3) | HER-12 | M11 M3 | N | `d:eco_quieto.puerta` | **No exige Nombrar**; la puerta aparece 1,5 s cada 6 s y, cruzada, queda abierta |
| P40 | La Mesa de Dos (5) | HER-13 | M6 ×2 M11 | R | — | Piedras extra diferidas |
| P41 | Sala de Aún (2 / emocional 5) | HER-16 | M5 M6 M3 | N (canon) | `p:aun.escalera_comprometida`, `p:aun.final`, `p:aun.compartido` | Diseño más abajo |

Recuento: 11 de núcleo, 12 opcionales con mecánicas de núcleo, 5 de ampliación (P08, P15, P16, P32 y P28, que tiene versión base de núcleo) y 13 recortados o diferidos: 41.

## Los puzles del canon, con precisión

### La Puerta Sin Muro (HER-02)

- **Sala:** HER-02, 96×48 (no los 108×30 de `03`). Entrada por el norte desde HER-01; marco de piedra de 8×6 en el centro; salida al sur por una **niebla de cal** (compuerta cal) cerrada. Ancla A30 en HER-01.
- **Cruzar el marco no hace nada.** Los tres nichos (`c`) están en la jamba izquierda (disco partido: Cera), el dintel (guijarro con pico: Piedra) y la jamba derecha (círculo: Cal). Pista del canon en el nicho vacío: «Cera. Piedra. Cal. Todo lo que hicimos para que no hablase.»
- **Uso:** mantener Z 1 s ante un nicho cuyo Sello se tiene ("Romper el Sello": romper es **devolver**). Cada uno con su efecto (Cera: hojas que vuelan al oeste; Piedra: el suelo tiembla 1 s; Cal: polvo blanco que se disuelve). Orden libre.
- **Al tercero:** silencio de 2 s, un muro de ladrillo con tres huecos vacíos aparece 1,5 s y cae; la niebla se abre. Marca `d:puerta_sin_muro.abierta`.
- **Sin atasco:** se llega con 0 a 3 Sellos y se vuelve. La pausa muestra los Sellos (`IconRow`, 0 a 3) y su región (Cera: Archivo; Piedra: Minas; Cal: Costa).

### El nudo de Aldara, el Mirador y el Relevo

Como en `03` §3.2 a §3.4, con los ids de la tabla. El nudo (Patio, acto IV): se pronuncia Linde, el nudo queda **flojo, no deshecho** («No se deshace. Todavía no.»); solo se deshace en el final Compartir. El Mirador: piedra al pie de la linterna, Oda Bellver invoca un Eco que corre hacia el oeste dejando puentes de luz de 2 s en los tres huecos de 17; al tocar lo alto de La Chimenea se arrodilla y deja la Insignia de Mensajera. El Relevo: receptor en el pecho de la coraza arrodillada del Aljibe, mantener Z 1,5 s, solo con `p:aun.compartido` e `i:insignia`.

### La Sala de Aún

Sala de 54×30 a la que se llega por la última Ancla (A33). Tres salidas visibles: **El Asiento** (derecha, mantener Z 1,5 s), **El Margen** (izquierda, mantener Z 1,5 s) y **La Escalera de los Nombres** (centro, hacia arriba): 20 peldaños de 5×3 en zigzag, de un solo sentido y sólidos solo si están encendidos; mantener Z 3 s ante el pie con Nombrar pronuncia los Nombres sostenidos (0,15 s cada uno) y enciende un peldaño por Nombre, del color de su región. Si faltan: «Cada peldaño pide un nombre. Faltan {n}.» (se sube hasta el último encendido y se vuelve: no se compromete nada). Con 20 o más, el primer peldaño pisado activa `p:aun.escalera_comprometida`: el Asiento y el Margen se cubren de cal. En la cima, mantener Z 4 s dispara Compartir. Ancla justo antes; sin azar. El único punto sin retorno del juego es pisar el Asiento, el Margen o el primer escalón de la escalera final.

## Catálogo de salas de movimiento (33)

Dibujos `.map` y márgenes simulados en `02` §5 y §6. **C** camino principal · **O** opcional o atajo · **M** maestría · **R** reserva (fuera de las 136). Habilidades: D dash, J doble salto, W Agarre, E Excavar, N Nombrar.

| ID | Sala | Hab. | Tamaño | Dif. | Estado | Fallo | Camino principal / maestría |
|---|---|---|---|---|---|---|---|
| CIN-01 | Las Terrazas Secas (hecha) | D | 64×24 | 2 | C | cae a la Cisterna | foso de 20 |
| CIN-05 | La Chimenea (hecha) | D | 40×69 | 3 | C | escalón o pinchos | 3 cruces de 16 |
| CIN-06 | La Pasarela y El Mirador (hecha) | D (N) | 100×24 | 3 | C | pinchos | 3 huecos de 17; hueco de 40 con Nombrar |
| CIN-07 | La Torre de Riego (hecha) | J | 56×44 | 2 | C | escalón | escalera y cornisa de 13 |
| CIN-12 | La Acequia | D+J | 96×48 | 3 | O | pinchos | huecos 17, 27 y 21 |
| CIN-15 | Los Bancales Altos | J | 72×60 | 2 | O | escalón | 5 terrazas: 13, 15, 12, 13 |
| CIN-21 | El Descenso del Brocal | W | 64×96 | 2 | C | pinchos en repisas | dos pozos de 5 |
| CIN-24 | El Granero Sin Techo | J | 112×64 | 3 | O | escalón | vigas con huecos 14-19 |
| CIN-25 | El Pozo de Piedra Seca | W | 72×72 | 2 | O | pinchos al fondo | pozo ancho 6, altos 22 y 17 |
| COS-02 | Los Escalones del Tajo | W | 100×70 | 3 | C | cae al tramo anterior | 3 pozos de ancho 6, 5 y 4 |
| COS-03 | La Cornisa de Sal | D+J | 104×70 | 3 | C | sala inferior | 17, 19, 28 y subida 12 |
| COS-04 | El Pilar de Lacre | W | 80×160 | 3 | C | pinchos de cal | 4 tramos de 36 con lisas de 6 |
| COS-11 | Los Tendederos | D+J | 110×60 | 3 | O | sala inferior | huecos 12 a 26 |
| ARC-09 | La Biblioteca Intacta | J | 112×80 | 3 | O | tablón de rescate | 4 torres lisas de subida 14 |
| ARC-19 | El Archivo en Blanco | D+J | 144×70 | 4 | C | pinchos | plataformas de borde pálido: 16 a 26 |
| MIN-09 | La Sala de Estratos | J | 100×60 | 3 | C | escalón | subidas 12 a 15 |
| MIN-13 | Descenso de los Zapadores | W | 56×90 | 3 | C | tablón de rescate | pozo de ancho 7, 74 de alto, pinchos laterales |
| MIN-16 | El Hueco del Pico | E | 64×40 | 1 | C | ninguno | muro + túnel |
| MIN-17 | La Veta Tapiada | E | 64×200 | 2 | O (atajo) | ninguno | pieza `$` y 6 tramos de pozo |
| MIN-24 | El Pozo del Latido | E | 80×240 | 2 | O (atajo) | ninguno | 8 tramos de 30 |
| MIN-25 | La Mina Inundada | D+J | 112×60 | 3 | O | sala inferior | huecos 14 a 26 |
| HER-07 | La Cisterna Doblada | E | 96×31 | 3 | C | pinchos | suelo al revés, piezas de 3 a 5 |
| HER-08 | La Chimenea Vuelta | D+J+W | 40×69 | 4 | C | pinchos | pozo de 24 y 2 cruces de 22 |
| HER-09 | Las Terrazas de Ceniza | D | 64×24 | 3 | C | pinchos | foso de 20 y otro de 22 |
| HER-11 | Las Galerías Dobladas | D (E) | 84×34 | 4 | C | pinchos | hilera de pulsantes de 24 |
| SEC-02 | El Palomar | J+W | 40×60 | 4 | M | escalón | zigzag 13, 13, 12 |
| SEC-06 | Los Establos de los Mensajeros | D | 100×26 | 3 | O | pinchos | huecos 17, 19, 20 (el Doble también lo cruza, margen 17: aceptado) |
| SEC-07 | La Grieta de Rosendo | E+W | 56×40 | 4 | M | ninguno | pieza `$` sobre pozo de 20 |
| SEC-08 | Torreón de las Campanas Mudas | J+W | 40×100 | 5 | M | pinchos | maestría pura |
| HER-17* | La Sala Desmontada | D+J+W+N | 130×62 | 5 | R | pinchos | hueco de 40 con tablones |
| SEC-09* | La Pared de Sal | W (+J, D) | 40×72 | 5 | R | pinchos | parches de 3 cada 9 filas |
| SEC-10* | Los Peldaños del Ascenso | J+W | 48×80 | 4 | R | pinchos | |
| SEC-11* | La Sala Sin Suelo | E+D+J+W | 80×60 | 5 | R | pinchos | |

Las cuatro salas marcadas (*) son la reserva: IDs reservados, fuera de las 136. Las salas de movimiento sin dibujo (las de §6 de `02`) se dibujan al construirlas con las cotas de la tabla de distancias y se **simulan antes de darlas por buenas**.

## Secretos

### Tipos y reglas de colocación

| Tipo | Qué es | Cómo se anuncia |
|---|---|---|
| Muro frágil | Pieza `#` rompible con el Filo | Grietas blancas, polvo que cae, hueco sonoro |
| Suelo o muro hondo | Pieza `$`, solo con Excavar | Veta ámbar y tañido metálico; invita a volver |
| Camino oculto | Paso tapado por decorado sin colisión (`q`, `N`, `H`) | Una brizna de luz o un rastro de polvo |
| Atajo | Camino de ida que se abre desde el lado difícil (M3 + palanca) | La reja se ve desde el lado cerrado |
| Sala oculta | Una sala completa tras un secreto | Lo que la rodea se queda sin explicar |
| Nombre escondido | Un Nombre tras un secreto | Un susurro a menos de 6 baldosas |

1. **Máximo un secreto por cada tres salas** de media y nunca dos seguidos en la misma sala.
2. **Una pista visible en la misma pantalla**, siempre (si no se ve, no hay secreto). Idioma por región: Archivo, sombra o ausencia; Minas, polvo y veta; Costa, luz o cortina; Cinturón, un objeto fuera de lugar.
3. **Ningún secreto exige una habilidad desconocida** ni un dato que el juego no haya enseñado.
4. Recompensas: Ecos (40 a 100), objeto de lore, reliquia, Nombre, atajo. Ninguna da más poder que una reliquia.
5. **Nombres:** a lo sumo 4-5 de los 30 tras un secreto (dificultad ≤ 2); 28 alcanzables sin opcionales; Compartir (20) nunca depende de un secreto.
6. Reliquia **Llave sin puerta** (revela muros frágiles a 5 baldosas): **se vende** (Cano), no se encuentra.
7. El mapa marca con un punto discreto los secretos encontrados (sin decir dónde).
8. Cada secreto de maestría **se anuncia en una región anterior** (repisa con luz azul, mojón de Mensajero, veta ámbar) y se puede volver con todas las habilidades; no hay secretos "para siempre perdidos".

Totales propuestos (frágil / hondo / camino oculto / atajo / sala oculta / Nombre): Umbral 1/0/1/1/1/0, Cinturón 2/2/2/1/1/1, Archivo 2/0/1/1/1/2, Minas 1/3/1/1/2/0, Costa 1/1/2/1/0/1, Herida 1/1/0/1/0/0; total 37.

### El Nombre de Corvel

La primera Página de Corvel está en la cabaña del **Umbral** (P01), con su texto del canon y el Nombre Corvel. El Nombre cuenta, en las listas por región y en el color del peldaño, **como del Archivo** (así los cinco Nombres del Archivo del guion maestro siguen siendo cinco: Ilara, Corvel, Aurelio, Lucía, Ardena). No se reasigna ningún otro Nombre.

### Fragmentos de vida (12) y de frasco (3): colocación definitiva

`05` fija las cuotas por región y la cadencia (4.º fragmento a ~6:15, 8.º a ~9:00, 12.º a ~11:30, **nunca en las dos primeras horas**); `01` fija las salas. Para que cuadre, los tres fragmentos del Cinturón se ponen en salas del Cinturón alto (que se alcanzan con Doble, pasada la hora 3:30) y **ninguno en salas ya construidas**. Los que `01` repartía de más pasan a Bolsa de Rastro (Ecos).

| Región | FV (fragmentos de vida) | FF (de frasco) |
|---|---|---|
| Umbral (1) | UMB-08 Sótano de los Cantores (el 12.º) | — |
| Cinturón (3) | CIN-09 Casa Varga · CIN-30 Linde Gris · SEC-02 Palomar | — |
| Archivo (3) | ARC-12 Retrato Ausente · SEC-05 Depósito de lo Rechazado · ARC-01 Pozos Blancos (repisa lateral, Agarre) | ARC-24 Galería de los Atriles |
| Minas (3) | MIN-03 Nicho de las Ofrendas · MIN-06 Cuerda de Mil Nudos (fondo) · SEC-07 Grieta de Rosendo | MIN-11 Taller de Dola (favor del pico) |
| Costa (2) | COS-11 Tendederos · SEC-04 Cuarto de la Cama Hecha | COS-08 Altar de Sal (ofrenda) |
| Herida (0) | — | — |

Sustituciones respecto a `01`: UMB-06, SEC-03, CIN-25, HER-06 y SEC-01 pasan de FV (o "FF o FV") a Bolsa de Rastro o reliquia (SEC-01: Diente de la Mina); CIN-16, SEC-06, MIN-23, COS-14 y CIN-25 pasan de FF a Bolsa o reliquia. Fórmula (de `05`): `vida_max = 5 + nivel(Vitalidad) + floor(fragmentos_vida / 4) + (Trapo de Iria ? 1 : 0)`, tope 13; frascos 3 + 2 del árbol + 1 (3 fragmentos) = 6.

## Reglas de legibilidad y de márgenes

### Márgenes (las lecciones de este proyecto)

`decisiones.md` (2026-10-20): a 864×486, un salto de 180 px ocupa un 37 % del alto y 17 baldosas son más de la mitad del ancho; lo que sobre el papel era "margen de 10" era injugable con techos bajos, huecos de 4 baldosas y pinchos por todas partes. Por eso:

- **Márgenes amplios.** Camino principal: **≥ 12 fotogramas** en todos los parámetros y ± 18 px de posición inicial (ventana de 36); la mayoría sale de 15 a 20. Maestría: ≥ 8 fotogramas y ± 16 px, solo en el tramo "cumbre"; la sala de maestría sigue una curva de cinco tramos (calentamiento ≥ 15, núcleo ≥ 12, giro ≥ 10, cumbre ≥ 8, salida con descanso).
- **Sin techos bajos.** ≥ 6 baldosas libres sobre cualquier plataforma (lo vigila `_test_no_platform_has_a_cramped_ceiling`; hay que añadirle las salas nuevas y los caracteres `%`, `$`, `#`, `g`).
- **≥ 6 baldosas de hueco** en toda abertura entre salas y en todo paso (el mínimo ya construido es 4 y se ensancha: R7). La corrección de esquina (8 px) abre huecos de 1 baldosa bajo una esquina: no se usan como puerta.
- **Aterrizajes anchos:** ≥ 6 baldosas en el camino principal (≥ 5 solo en maestría, ≥ 4 en tablones de rescate), con una marca (mojón, lámpara o reja). **Pozos de pared:** ancho ≥ 4 en el principal; 3 solo en maestría.
- **Enemigos a ≥ 10 baldosas de cualquier puerta**, y en puzles de plataformas, ninguno (o muy lejos del salto). Sin tiempo ni enemigos en las salas de maestría.
- **Fallo barato:** 1 de daño y de vuelta al último suelo firme, o un tablón de rescate cada 21 de altura; repetir una sala no debe costar más de 20 s (la sala inferior de la Costa se aproxima a 25 s: tablón de rescate bajo los huecos de 28).
- **Suelo del fallo por región:** Cinturón, escalón o suelo de abajo; Archivo, pinchos de tinta; Minas, tablón de rescate o pinchos; Costa, la sala de abajo (playa); Herida, pinchos.
- **Una pantalla (54×30), o dos contiguas, bastan** para ver causa y consecuencia; los saltos largos (≥ 26) muestran el destino antes de despegar.

### Qué se puede pisar y cómo se señala el peligro

1. El borde superior de todo lo sólido lleva una línea clara de 1 píxel; el decorado nunca la lleva y es dos pasos más oscuro.
2. Los tablones tienen color propio (madera cálida) y soportes visibles; si se pueden atravesar, se ve luz por debajo.
3. Primer plano sin ambigüedad: lo que va delante del jugador (hierba, huesos) es bajo y estrecho y nunca tapa un salto.
4. Pinchos de hueso con silueta propia (rojo óseo), nunca camuflados; los pulsantes avisan 0,35-0,4 s antes. El abismo que lleva a otra sala se anuncia con niebla en el borde y una luz abajo (es "una caída", no "una trampa"). El suelo seguro de una repisa de pinchos es el lado cercano a la entrada.
5. **Regla del testigo (06):** toda causa y todo efecto remoto lleva una lamparilla; apagada = sin hacer, ámbar fijo = hecho para siempre, ámbar que mengua = temporal. **Nada en rojo** en testigos ni mecanismos (el rojo es peligro): el "testigo rojo" de P02 y el lacre rojo de P16 pasan a ámbar apagado y cera ámbar oscura.
6. **Forma antes que color** (grietas en zigzag frente a rombos; canales con símbolo grabado distinto).

### Enseñar cada habilidad sin texto

Mostrar (un objeto del dueño del recuerdo en el sitio imposible: la hoz en el primer pozo, una pluma en la cornisa, un pie alado en el foso, una veta ámbar en el muro) → probar sin riesgo (suelo debajo, sin enemigos) → torcer (una condición nueva en una segunda sala, nunca en la primera) → combinar solo cuando las dos piezas se han jugado por separado → "ver antes de poder" (la meta se ve al menos una sala antes; en salas más altas de una pantalla, un foco de luz o banderín arriba).

## Rupturas

Una ruptura es llegar a un sitio sin la habilidad prevista. **Hacia atrás se permite, hacia delante se impide.**

| Permitida a propósito | Margen | Veredicto |
|---|---|---|
| Cornisa de la Torre sin Doble, con Agarre y dash (tras La Era) | 15 con las dos; 3 solo con Agarre | Permitida; la de solo Agarre es de experto y no se corrige |
| Bancales Altos con Agarre y dash | 15 | Permitida |
| La Acequia con Agarre y dash | 8 | Permitida, ruta de experto |
| Chimenea Vuelta con Agarre y solo dash o solo doble salto | 12 y 15 | Permitida |
| Establos con doble salto en vez de dash | 17 | Permitida (el muro de cera está recortado) |
| La Pared de Sal con solo Agarre | 5 | Permitida (reserva) |

Impedidas, con regla y prueba: saltarse una puerta con una habilidad anterior (cada sala de puerta se simula con el inventario anterior y debe dar "meta no alcanzable"); paredes `B` alrededor de puertas de doble salto o dash en el Archivo y la Costa (son `%`); obligar a Excavar en el Archivo o la Costa; pixel-perfect obligatorio (la prueba falla por debajo de 12 fotogramas en el principal); callejones `$` sin salida. El dash al principio del salto anula la subida (no hay "dash para bajar"): las alturas de doble salto no se saltan con dash.

## Cómo validar

### El simulador de saltos

`tools/sim_saltos.js` (**ampliado en W0**; `node tools/sim_saltos.js sala.map DJW fila_inicio col_inicio [fila_meta] [--roto]`) conoce dash, doble salto, Agarre (salto de pared), `%`, `$` (sólida, o rota con `--roto`), compuertas cerradas y pinchos laterales: 60 fps, cápsula de 24×48, con los valores de `PlatformerMotor`, `DashComponent` y `player.gd`. La Chimenea real con dash da márgenes de 15 a 19 (cruce de 14 a 20 pedido). `node tools/test_sim_saltos.js` es su autoprueba. Los márgenes de `02` salieron de un prototipo temporal que no está en el repositorio; el simulador actual se reescribió desde sus especificaciones, con estas características (la lista original sigue como referencia):

- Parámetros de maniobra nuevos: fotograma del segundo salto, saltos de pared (número, fotogramas agarrado antes de saltar, dirección y duración del empuje). La pared solo se agarra si se pulsa hacia ella **y la baldosa no es `%`**.
- Sólidos: `T G B C % g $ #` y compuertas `=`/`+` cerradas; tablones `S p`; peligro `^ v ~ - { }` (los laterales con su caja girada). `$` se trata como sólido (pieza sin romper) o ausente (pieza rota).
- Margen por parámetro (altura del salto, momento del dash, momento del segundo salto, saltos de pared), como el original.
- Interfaz: `node tools/sim_saltos.js sala.map HABILIDADES fila_inicio col_inicio [fila_meta]`, con `HABILIDADES` una combinación de `D`, `J`, `W` (vacío = ninguna); `1`/`0` se acepta como alias de `D`/vacío para no romper `maniobras_puzle.js`.
- Comprobación cruzada obligatoria: La Chimenea real con dash debe dar márgenes de 14 a 20 (el original da 15 a 17).

### Procedimiento para un puzle de plataformas

1. Dibujar el `.map` con las cotas de la tabla de distancias.
2. Simular con el inventario exacto: margen ≥ 12 en todo el camino principal (≥ 8 en maestría).
3. Simular con el inventario anterior: la meta **no** debe alcanzarse (salvo las rupturas permitidas).
4. Guardar la maniobra: `node tools/maniobras_puzle.js` escribe `tests/puzzle_plans.json`. Hoy guarda parámetros de dash; para doble salto y pared se guardará la lista de entradas por fotograma que genera el simulador, y `_replay_plan` la repite en el motor.
5. La prueba de humo repite el plan en el motor y repite el primer plan clave **sin** la habilidad (`unlock_ability` falso) para comprobar que no llega (como `_test_dash_puzzle_needs_dash`).
6. **Jugarlo.** Los tests miden reglas, no sensaciones.

### Comprobaciones automáticas (lista del mundo)

Un script `tools/verifica_mundo.js` (**hecho en W0**: C1, C2, C3, C4, C8 y C12; `node tools/verifica_mundo.js`, la prueba de humo lo ejecuta si hay Node) más `tests/world_manifest.json` (una entrada por sala y por puerta, hecho a mano y versionado, empezando por las salas construidas y la región que se esté haciendo). Cada fallo imprime región, sala, borde y fila y sale con código ≠ 0.

| # | Comprobación | Dónde | Umbral | Fase |
|---|---|---|---|---|
| C1 | Salas sin solape | script | 0 solapes | W0 |
| C2 | Alineación de puertas: aberturas libres iguales en y absoluta, mismo nivel de suelo | script | ≥ 6 (4 en lo viejo hasta R7) | W0 |
| C3 | Aberturas huérfanas (no declaradas ni cielo) | script | 0 | W0 |
| C4 | Manifiesto ↔ `world.tscn` | script | 100 % | W0 |
| C12 | **Caracteres válidos** (todo carácter del `.map` está en la leyenda de `vertical-slice.md`) y anchura ≥ 54 | script | 0 | W0 |
| C5 | Accesibilidad por habilidades (superficies + simulador, cierre transitivo desde el Umbral) | script | cada sala se alcanza con exactamente su `requires` | tras ampliar el simulador |
| C6 | Sin bloqueos: desde cada superficie alcanzable hay camino a un Ancla | script | ninguna sala sin retorno | ídem |
| C7 | Anclas: distancia entre Anclas y al jefe | script | ≤ 8 en el principal; ≤ 1 al jefe | cuando haya Cinturón alto |
| C8 | Enemigos a ≥ 10 baldosas de puertas, techo ≥ 6 sobre tablones, sin pinchos bajo un spawn | script | 0 | W0 |
| C9 | Márgenes de puzle con `puzzle_plans.json` | script + humo | ≥ 12 | con el simulador ampliado |
| C10 | Coleccionables alcanzables con las habilidades de su sala; 30 Nombres (28 sin opcionales), 12 FV, 3 FF | script | exacto | por región |
| C11 | Caídas: la que mata no tiene sala debajo; la que cae a otra sala aterriza en suelo con retorno | script | 0 | ídem |
| C13 | Todo sentido único tiene camino de vuelta (C6) | script | 100 % | ídem |
| C14 | Con 0 Sellos no se llega a HER-02; con los 3, sí | script | exacto | Herida |
| C16 | **Enlaces de piezas**: cada clave de `links` es la primera celda de una pieza (`=`, `+`, `z`, `_`, `*`, `#`, `$`) del mapa y cada marca tiene la forma `prefijo:sala.objeto` (hecha en W2; el C13 de esta tabla sigue sin construir: el C13 del script son los coleccionables) | script | 0 | W2 |
| C18 | **Nombres en inscripciones**: el `note_name_id` de una sala y el `name_id` de `inscription.tscn` son ids de `game/names.gd`, no se repiten, y una sala con `note_name_id` tiene su `i` en el mapa | script | 0 | K22 |
| C15 | Presupuesto: salas por región y por función | script | ±2 respecto a `mundo.md` | continuo |

La prueba de humo conserva lo que necesita el motor: techos, reproducción de maniobras, ids únicos, guardado y carga de marcas, `%` no se agarra, pinchos laterales, salidas de `$`.

## Orden de implementación, costes y pruebas

Coste: **S** unas horas con su prueba; **M** una sesión larga; **L** varias. El orden **sigue el del mundo** (Cinturón alto → Agarre → Archivo/Minas/Costa → Herida → acto IV) y respeta las dependencias de las demás propuestas (`04`: ataque abajo, `telegraph_zone` y `status_effects` antes del Archivo; `05`: fases A-B antes de calibrar, registro de Nombres antes de Minas/Costa; `06`: autotiling y letras en su fase de arte). Después de cada fase hay que **jugar** el puzle (`CLAUDE.md`) y ejecutar la prueba de humo.

| Fase | Contenido | Coste | Depende de | Desbloquea | Pruebas | Hito del mundo |
|---|---|---|---|---|---|---|
| W0 | `TextTileMap.marker_groups(char)`; **pared lisa `%`** (TileSet + motor); **ampliar `sim_saltos.js`** (Doble, Agarre, `%`, `$`); `tools/verifica_mundo.js` con C1-C4, C8, C12; manifiesto de las 8 salas; **retoque R7** | S + S + M + S | — | Todo lo demás; las salas de Doble y Agarre | Un muro 2×3 de marcadores da 1 pieza; un cuerpo junto a `%` mantiene la caída; la Chimenea simulada da 14-20; el verificador sale 0 sobre las 8 salas | Antes del Cinturón alto |
| W1 (**hecha**: `FlagStore`, claves `flags`/`fragments`/`bags`, marcador `!`, un fragmento de ejemplo en la Cisterna; falta la fórmula de vida K10 y el efecto de las Bolsas) | **M1 FlagStore** + guardado (`flags`, sin subir `FORMAT_VERSION`); **coleccionables `!`** con id (fragmentos, bolsas, páginas, objetos; `fragments`, `bags`) | M + M | W0 | Todos los puzles; el ritmo de Ecos y el "+1 vida" | Poner, leer, guardar, cargar, ignorar id desconocido, ids únicos, partida antigua sin las claves; fragmentos 3 = vida base, 4 = +1, sin duplicados | Cinturón alto |
| W2 (**hecha** salvo "Volver al Ancla": `Gate`, `Trigger`, `BreakableWall`, `links` por sala, ejemplo en la Cisterna; ver "Hecho en W2") | **M3 Compuerta** (sacada de `arena_gate`) + **M4 Disparadores** + **M2 frágil** + **"Volver al Ancla"** en la pausa | S + S + S + S | W1 | P01, P02, P09, P17, P18, P38; retoque R4 (la reja) | La sala del Aljibe se comporta como antes; se abre con su marca, con "Y" de varias; no se cierra encima del jugador; palanca latch/toggle, placa con `hold_time`; 3 golpes rompen, 2 no; rota tras guardar y cargar | Cinturón alto, Era |
| W3 (**hecha** salvo el vestido tinta de M3: `Cycle`, `RailPlatform`, `piece_params` por sala, ejemplo en las Galerías Bajas; ver "Hecho en W3") | **M11 Ciclo** + **M7 Carril** (modos continua, a demanda, viaje) + vestido tinta de M3 | S + M | W2 | P14, P19, P22, P34 (barca), P06, P07, P12 | Periodo, fase y aviso respetados; la plataforma lleva al jugador, no aplasta y espera en los extremos | Archivo (Pasillo Tres), MIN-02, Cauce |
| W4 (**hecha**: marcadores `{` `}` en `room.gd`; ejemplo en el pozo de la Torre de Riego) | **Pinchos laterales `{ }`** | S-M | W0 | MIN-13, SEC-07 | Dañan 1 y devuelven al suelo firme (como `^`: solo matan si queda 1 de vida) | Antes de las Minas |
| W5 | **M2 hondo + Excavar** (Golpe Hondo: tajo contra muro, ataque hacia abajo contra suelo); **retoques R1 y R6** con UMB-07/08 y SEC-01 | M | W2, Excavar como habilidad, ataque abajo (`04`) | P04, P27, MIN-16/17/18/24, HER-07 | Rebota sin Excavar; con ella, 2 golpes; el ataque hacia abajo rompe suelo (en suelo y en el aire); tras romper, el jugador vuelve a su sala sin Excavar | Magda |
| W6 | **M5 Receptor** | S | W1 | P13, P35 (Sellos) | Con y sin marcas, `hold_time`, no consume; con 0 Sellos no se llega a HER-02 (C14) | Costa, Herida |
| W7 | **Registro de Nombres y diario** (`05` #9; claves `names`) | M | W1 | Piedras, Compartir, Hilos | Leídos y callados, 30 ids, sostenidos | Antes de Minas y Costa (`05` fase E) |
| W8 | **M6 Piedras de lectura (3)** y la mecánica de peldaños de HER-16 | L | W6, W7, Nombrar | P03, P12, P41 | Muda sin Nombrar; atenta con ella; acierta y falla; sin callados | Acto IV |
| W9 | Fase de arte (06): autotiling de 4 bits en `TextTileMap`, hojas de 256×144, `g p m h a` | M-L | W0 | Salas con la cara de su región | Máscaras, esquinas; el mismo `.map` con otro TileSet | Por región |
| WA | **Ampliaciones:** M10 Derribo, M12 Combinación | M + S | W2 | P15, P16, P08, P28 completo, P32 | Cae en la dirección del golpe, no cae sin hueco, mantiene una placa; giro cíclico, solución exacta | Opcional |
| WR | **Recortadas:** M8 Corriente, M9 Luz | M + M | motor | Versiones completas de P29, P10... | Empuja ±180 px/s; revelado según distancia | Solo si sobra tiempo |

**Orden de recorte** si hay que bajar alcance (primero lo primero): M8, M9, las ampliaciones M10 y M12, las salas opcionales de maestría, los secretos de camino oculto. **Lo que nunca se recorta:** M1 a M5, M7, M11, `%` y las tres piedras del canon.

**Pruebas globales.** (1) Ids únicos y presentes. (2) Guardado completo: resolver, guardar, cargar y comprobar. (3) Cada sala con puzle tiene una salida alcanzable desde cada estado intermedio. (4) Tras `reset()` lo T vuelve a su origen y lo P no se mueve. (5) Todos los puzles de movimiento: la suite de `puzzle_plans.json` sigue verde con todas las reliquias y el árbol equipados (ninguna mejora altera saltos ni dash, `05` T15).

## Preguntas abiertas

Las que siguen abiertas para el usuario están en `DECISIONES-EDITOR-MUNDO.md` (si el Agarre recarga el dash y el doble salto, enemigos nuevos por región, reparto de reliquias). Nada de este documento depende de ellas.
