# Vertical slice: El Último Umbral (documento vivo)

Un vertical slice es un trozo pequeño del juego terminado de principio a fin
(arte, mecánicas, ambiente) para comprobar que el conjunto funciona antes de
producir más contenido. Aquí es **El Último Umbral**, la primera región del mundo
(ver `mundo.md`): un asentamiento fronterizo de refugiados, pobre y remendado,
todavía sin señales de la Desmemoria.

## Objetivo de la zona

- Enseñar el juego sin texto: moverse, saltar el foso, combatir dos Cascarones y
  usar un Ancla de Memoria.
- Dar tono: un lugar abandonado a toda prisa, no un decorado de "aldea".
- Servir de banco de pruebas del **pipeline de niveles** (mapa de texto → baldosas).

## Recorrido (mapa de 80×28 baldosas de 16 px = 1280×448 px)

De izquierda a derecha:

1. **Puerta sellada** (columnas 0–1): un muro alto de ladrillo cierra la salida
   hacia atrás; el jugador empieza mirando hacia dentro. Cuenta, sin decirlo, que
   nadie vuelve.
2. **Cabaña en ruinas** (columnas 15–22): tejado de tablones sostenido por dos
   pilares. Junto a ella, el primer **Ancla de Memoria** (columna 11) para
   enseñar a descansar antes de que haya peligro.
3. **Foso** (columnas 32–41): primera prueba de plataformas; caer mata y devuelve
   al último Ancla (y deja un Eco si se llevaban Ecos).
4. **Dos Cascarones** (columnas 47 y 55): primer combate. Se pueden esquivar,
   devolver con parry (V) o simplemente atacar.
5. **Escalera de tablones** (columnas 62–77): sube hasta un segundo Ancla en lo
   alto (columna 74), una recompensa visible desde abajo.
6. **Salida al Cinturón Yermo** (columna 79): el camino sigue hacia Las Terrazas
   Secas, la siguiente sala del mundo (ver `mundo.md`).

## Ambiente

Un fondo con dos capas de parallax (colinas lejanas y ruinas a media distancia,
ambas siluetas de colores planos, sin arte final todavía) da profundidad al
cielo negro. Junto al camino hay urnas rompibles (se atraviesan, solo se rompen al golpearlas): no dan nada al romperlas, son
solo decoración, como los tarros de Hollow Knight o Dark Souls (ver "Cómo está
construida").

Narrativa ambiental, sin ningún diálogo ni texto explicativo salvo la
inscripción (que el jugador elige leer, no se le impone):

- **Junto a la entrada**, antes incluso del primer Ancla, una piedra con
  nombres grabados (Z para leerla): los supervivientes que se fueron dejaron
  constancia de a quién no querían olvidar.
- **Dentro de la cabaña en ruinas**, un carro volcado con una rueda suelta y un
  saco reventado: alguien se marchó deprisa, sin tiempo de recoger.
- **Junto al montón de escombros, antes del foso**, unas marcas de arrastre en
  el suelo que llevan hacia el borde: se puede deducir qué pasó ahí sin que
  nadie lo diga.

## Fuera del alcance de esta pasada (decidido a propósito)

- Personajes no jugadores y diálogo, jefe final, tienda o mejoras nuevas.
- Reinicio de enemigos limitado a la zona (con ocho salas, de momento no hace falta).
- Que los objetos rompibles reaparezcan al reiniciar el mundo: no afectan a la
  partida, así que quedan rotos hasta recargar el nivel.

## Leyenda del mapa de texto (única, para todas las salas)

Un `.map` es texto: una línea por fila, un carácter por baldosa. `.` y el espacio son vacío. Un carácter que está en la leyenda de la escena (`legend`) es una **baldosa** (con colisión); **cualquier otro carácter es un marcador**: no pone baldosa, anota su posición y `room.gd` (o el mundo) coloca ahí una entidad. Por eso **un carácter que no esté en esta tabla es un error** (se convertiría en un marcador sin avisar y dejaría un hueco): la comprobación C12 del verificador de mundo (ver `puzles.md`) lo detecta. La misma leyenda vale para todas las salas; el material de una baldosa lo decide el `TileSet` de la sala, no la letra.

Convenciones: **minúscula = mecánica o lógica; mayúscula = decorado, enemigo u objeto del mundo** (con las excepciones heredadas `A E R I P Q O`). Una **pieza** es un grupo de marcadores contiguos del mismo carácter (un muro de 2×6 es una sola pieza). Los pares que comparten letra con distinta caja (`c`/`C`, `f`/`F`, `k`/`K`, `n`/`N`, `o`/`O`, `u`/`U`, `x`/`X`, `y`/`Y`) no tienen relación entre sí.

**Estado:** ✔ existe en el código. Las fases (W0-W9, WA, WR) son las de `puzles.md`: **nuevo** = definitivo pero aún sin construir; **reservado** = carácter apartado para una mecánica recortada (no se usa en ningún mapa hasta que se construya).

### Baldosas (con colisión)

| Car. | Qué es | Estado |
|---|---|---|
| `T` | Suelo con piel (musgo en el Umbral) | ✔ |
| `G` | Relleno de roca o tierra | ✔ |
| `B` | Sillar o ladrillo labrado (arquitectura) | ✔ |
| `C` | Remate de muro | ✔ |
| `S` | Tablón de madera: plataforma **de un solo sentido** (se atraviesa desde abajo y por los lados; colisiona solo en una franja de 4 px en su borde superior; con abajo + salto se baja atravesándolo) | ✔ |
| `%` | Pared lisa: sólida, el salto de pared no se agarra | ✔ (W0; arte provisional: baldosa de piedra pálida; dato `smooth` en el `TileSet`) |
| `g` | Terreno desmemoriado: toda la familia de baldosas planas y sin textura (parches grises, Archivo en blanco, Herida) | nuevo (W9) |
| `p` | Plataforma de un solo sentido que no es de madera (repisa de piedra, reja, losa) | nuevo (W9) |

### Baldosas de fondo (sin colisión; capa de detrás del jugador)

| Car. | Qué es | Estado |
|---|---|---|
| `m` | Muro trasero liso | nuevo (W9) |
| `h` | Muro trasero con vano (arco, ventana, hornacina) | nuevo (W9) |
| `a` | Agua (superficie animada si tiene aire encima); decorativa, no ahoga | nuevo (W9) |

### Marcadores existentes

| Car. | Qué es | Estado |
|---|---|---|
| `P` | Inicio del jugador (lo lee el mundo, no la sala) | ✔ |
| `A` | Ancla de Memoria | ✔ |
| `E` | Enemigo: cascarón (tajo) | ✔ |
| `1` | Enemigo: lancero (estocada larga) | ✔ |
| `2` | Enemigo: arrojador (esquirlas a distancia) | ✔ |
| `3` | Enemigo: coloso (mazazo lento) | ✔ |
| `4` | Enemigo: acechador (embestida) | ✔ |
| `R` | Urna rompible (decoración; se atraviesa y se rompe al golpearla) | ✔ |
| `Q` | Caja rompible | ✔ |
| `O` | Barril rompible (aguanta 2 golpes) | ✔ |
| `I` | Inscripción de El Último Umbral (texto en su escena) | ✔ |
| `i` | Inscripción con el texto `note` de la sala (a partir de W1, la k-ésima `i` toma el k-ésimo texto de `notes`) | ✔ |
| `d` `j` `w` | Recuerdo de habilidad: dash, doble salto, salto de pared (se recuerda al tocarlo) | ✔ |
| `^` `v` | Pinchos fijos en el suelo / colgando del techo | ✔ |
| `~` `-` | Pinchos que salen y se retraen (periodo 2,4 s, 40 % activos, aviso 0,4 s); los dos grupos alternan | ✔ |
| `b` `t` `[` `]` `r` | Sala de jefe (`game/boss/boss_room.gd`): dónde duerme el jefe; línea que dispara la pelea (columna); celdas de la reja de entrada (se cierra al empezar); celdas de la reja de salida (cerrada hasta vencer); dónde aparece la recompensa | ✔ |

### Decorado (sin función ni colisión; `decor.sprite`, 48×64)

La letra es el **rol**; el dibujo concreto lo decide la región (propuesta de arte 06). Los que cuelgan (`F`, `N`, `q`) llevan el marcador en la celda de debajo.

| Car. | Rol | Estado |
|---|---|---|
| `Y` | Árbol muerto / alzado vertical grande | ✔ |
| `U` | Columna rota | ✔ |
| `H` | Hierba (delante del jugador) | ✔ |
| `Z` | Zarza seca | ✔ |
| `K` | Huesos y escombros (delante) | ✔ |
| `F` | Estandarte (cuelga) | ✔ |
| `N` | Cadenas (cuelgan) | ✔ |
| `X` | Estatua | ✔ |
| `V` | Mojón | ✔ |
| `L` | Poste de señal | ✔ |
| `M` | Farol | ✔ |
| `D` | **Arco ciego de muro** (decorado; **no** es el muro excavable: ese es `$`) | ✔ |
| `q` | Enredaderas (cuelgan) | ✔ |

Las piezas singulares (props únicos de cada región) no usan letra: se listan en un archivo `sala.props` (propuesta de arte 06 §5.1).

### Mecánicas de mundo (nuevos; ver `puzles.md`)

| Car. | Qué es | Estado |
|---|---|---|
| `#` | Muro o suelo **frágil** (se rompe a golpes, sin habilidad) | nuevo (W2) |
| `$` | Muro o suelo **hondo** (solo se rompe con Excavar) | nuevo (W5) |
| `=` | Compuerta, canal A (reja, tablones, piedra, cal, puente, tinta) | nuevo (W2) |
| `+` | Compuerta, canal B | nuevo (W2) |
| `z` | Palanca | nuevo (W2) |
| `_` | Placa de presión | nuevo (W2) |
| `*` | Botón en alto (se golpea saltando) | nuevo (W2) |
| `c` | Receptor: nicho, ranura, altar (Sellos de la Puerta Sin Muro, Relevo) | nuevo (W6) |
| `n` | Piedra de lectura (Nombrar) | nuevo (W8) |
| `<` `>` | Extremos de un carril de plataforma móvil, barca o vagoneta | nuevo (W3) |
| `y` | Ciclo (marea, tinta, ventana) | nuevo (W3) |
| `{` | Pinchos laterales pegados a una pared **izquierda** (apuntan a la derecha) | nuevo (W4) |
| `}` | Pinchos laterales pegados a una pared **derecha** (apuntan a la izquierda) | nuevo (W4) |
| `k` | Derribo: columna, estantería-torre, puntal | nuevo (WA, ampliación) |
| `o` | Combinación: selector de símbolos | nuevo (WA, ampliación) |
| `)` `(` | Corriente de viento hacia la derecha / hacia la izquierda | reservado (WR, recortada) |
| `u` | Corriente de ascenso | reservado (WR, recortada) |
| `f` | Lámpara de grasa | reservado (WR, recortada) |
| `x` | Plataforma o puente que solo existe con luz | reservado (WR, recortada) |

### Enemigos nuevos, objetos y personajes

| Car. | Qué es | Estado |
|---|---|---|
| `5` | Enemigo nuevo, rol **volador** (cuervo, polilla, murciélago, gaviota, vela...) | nuevo (04) |
| `6` | Enemigo nuevo, rol **guardia** (escudo o coraza que bloquea de frente, o emboscador durmiente) | nuevo (04) |
| `7` | Enemigo nuevo, rol **corredor** (carga, salto o rodadura, o rastrero) | nuevo (04) |
| `8` | Enemigo nuevo, rol **de zona o de apoyo** (crea una zona o un estado, o da escudo) | nuevo (04) |
| `9` | **Élite o minijefe** de la sala (uno por sala) | nuevo (04) |
| `!` | Coleccionable: fragmento de vida o de frasco, Bolsa de Rastro, Página de Corvel, reliquia, objeto de lore (tipo en el campo `pickups` de la escena como `c37f05:bag`, por posición, y `fragment` si falta; el id sale del mapa y la posición, `cisterna.c37f05`) | ✔ (W1) |
| `@` | Personaje no jugador (PNJ; cuál, en el campo `npcs` de la escena) | nuevo (fase de PNJ) |

Los enemigos `5`-`9` son **casilleros**: la escena de la sala (`enemy_set`) dice qué enemigo concreto es cada uno en esa sala (el catálogo está en la propuesta 04; el editor de combate fija cuáles entran). `1`-`4` y `E` conservan su significado en todas las salas.

### Libres

Letras `e s J W` y dígito `0`; símbolos `& / \ : ; ? " ' , | ` y el resto no usado. No se usan: `&` (muro de cera) y `/` `\` (pendientes) quedaron **recortados** y se dejan libres a propósito.


## Cómo está construida

- `game/levels/ultimo_umbral.map` — el terreno como texto. La leyenda de caracteres
  (baldosas, marcadores, decorado y mecánicas) es única para todas las salas y está
  en la sección anterior. En una **sala de jefe** (`game/boss/boss_room.gd`) se usan
  además `b` `t` `[` `]` `r`. El tablón `S` es una plataforma de un solo sentido: se
  puede pasar bajo el tejado de la cabaña o saltar a través de él para subirse.
- `game/levels/ultimo_umbral.tscn` — un `TextTileMap` (core) con el `TileSet`
  `tiles_umbral.tres` y su leyenda.
- `game/levels/room.gd` — el script de toda sala: coloca Anclas, enemigos, urnas,
  inscripciones y recuerdos en los marcadores. El jugador (`P`), la cámara y el
  mapa los lleva el mundo (`game/levels/world.gd`, ver `mundo.md`).
- `art/source/decor.sprite` — las 13 piezas de decorado (48×64). `room.gd` las coloca
  en los marcadores con la tabla `DECOR` (fotograma, si cuelga, z_index): lo que va
  detrás del jugador usa z -1/-2 y la hierba y los huesos z 1.
- `game/environment/breakable_crate.tscn` y `breakable_barrel.tscn` — caja (1 golpe)
  y barril (2 golpes), como la urna: se atraviesan y solo se rompen al golpearlos.
- `game/environment/breakable_urn.tscn` — una urna rompible (`core/objects/breakable_prop.gd`
  con un dibujo de polígonos). Se atraviesa y se rompe de un golpe;
  no suelta nada ni afecta a la partida.
- `game/environment/inscription.tscn` — una piedra con un texto (`core/objects/readable.gd`).
  Con Z al alcance, el jugador lo lee en el HUD el tiempo que tarde en leerse
  (según su longitud); no afecta a la partida. La de El Último Umbral (marcador
  `I`) lleva el texto en su escena; las demás salas usan el marcador `i`, que
  toma el texto del campo `note` de su sala.
- El carro volcado y el saco reventado de la cabaña, y las marcas de arrastre
  junto al foso, son polígonos fijos dentro de `ultimo_umbral.tscn` (nodo
  `SetDressing`): decorado propio de esta zona, sin colisión, no un objeto
  reutilizable como la urna o la inscripción.
- El fondo (`Background` en `world.tscn`, común a todo el mundo) es un
  `ParallaxBackground` con cinco capas (cielo fijo con estrellas y luna, colinas
  lejanas, niebla, ruinas con ventanas, arcos y torres, y árboles muertos cercanos) que se repiten en
  horizontal (`motion_mirroring`), para cubrir salas a cualquier distancia. Se
  oculta en las salas sin cielo (`has_sky = false`).
- `art/source/tiles_umbral.sprite` — las 5 baldosas (16×16), en el mismo formato
  de texto que los demás sprites.

Para **editar el nivel** basta con cambiar caracteres en el `.map` y ejecutar el
juego. Para **añadir una baldosa**: dibujarla como una `part` más en el `.sprite`,
regenerar el PNG, añadirla al `TileSet` (con su colisión) y a la leyenda.

`test_level.tscn` se mantiene como banco de pruebas de las mecánicas (lo usa la
prueba de humo); no es una zona del juego.

## Nota para exportar el juego

Los archivos `.map` no son recursos que Godot reconozca: al exportar hay que
añadir `*.map` a los filtros de "Recursos no gráficos" del preset de exportación,
o el nivel saldrá vacío.
