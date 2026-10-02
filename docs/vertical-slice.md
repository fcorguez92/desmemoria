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
- Reinicio de enemigos limitado a la zona (con cuatro salas pequeñas aún no hace falta).
- Que los objetos rompibles reaparezcan al reiniciar el mundo: no afectan a la
  partida, así que quedan rotos hasta recargar el nivel.

## Cómo está construida

- `game/levels/ultimo_umbral.map` — el terreno como texto. Leyenda: `T` suelo con
  musgo, `G` relleno de piedra, `B` ladrillo, `C` remate de muro, `S` tablón de
  madera; `P` inicio del jugador, `A` Ancla de Memoria, `E` cascarón (tajo), `1` lancero (estocada larga), `2` arrojador (esquirlas a distancia), `3` coloso (mazazo lento) y `4` acechador (embestida), `R` urna
  rompible, `I` inscripción legible, `d` / `j` / `w` recuerdo de dash / doble
  salto / salto de pared; `Q` caja rompible, `O` barril rompible (aguanta 2 golpes);
  `.` vacío. Marcadores de **decorado** sin función (sprites de `decor.sprite`, sin
  colisión): `Y` árbol muerto, `U` columna rota, `H` hierba (delante del jugador),
  `Z` zarza, `K` huesos y escombros (delante), `F` estandarte y `N` cadenas y `q`
  enredaderas (cuelgan del techo o de un tablón: el marcador va en la celda de
  debajo), `X` estatua, `V` mojón, `L` poste, `M` farol, `D` arco ciego de muro.
  La misma leyenda vale para todas las salas.
  Los tablones (`S`) son **plataformas de un solo sentido**: se atraviesan desde
  abajo y por los lados, y solo se pisan desde arriba (colisionan solo en una franja
  fina de 4 px en su borde superior; el resto es puro decorado). Por ejemplo, se
  puede pasar bajo el tejado de la cabaña o saltar a través de él para subirse.
  Con abajo + salto sobre un tablón se baja atravesándolo (`can_drop_through` del motor).
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
  (según su longitud); no afecta a la partida. Hoy solo hay una, con el texto
  fijado en la propia escena (ver la nota en `room.gd` sobre qué
  cambiaría si una zona necesitara varias con textos distintos).
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
