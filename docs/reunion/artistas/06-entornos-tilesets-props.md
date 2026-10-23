# Entornos, tilesets, fondos y props (propuesta del artista de entornos)

Autor: artista de entornos, tilesets, fondos y props (sala de artistas). Estado: propuesta para la reunión; nada de esto está aprobado hasta que lo decida el usuario. No modifica ningún otro archivo ni el código.

Se apoya en la biblia visual (`01-direccion-de-arte.md`: pilares, paleta ampliada de 31 colores, fichas de región, desaturación por sala, luz y partículas), en el pipeline (`02-pipeline-y-herramientas.md`: generador de tilesets, de fondos y de props), en los efectos ambientales (`03-interfaz-efectos-animacion.md`), en el mapa macro de diseño (`01-mapa-macro.md`) y en las doce mecánicas de mundo (`03-puzles-de-entorno-y-mecanicas.md`). Respeta las restricciones del proyecto: pixel art, 864×486 con escalado entero, rejilla de 16×16, un único autor sin dibujar a mano salvo lo imprescindible, máximo 32 colores, un componente por cosa, nada "por si acaso".

Nomenclatura: "región" es una de las seis (Último Umbral, Cinturón Yermo, Archivo, Minas del Origen, Costa Retenida, Herida). Los códigos de una letra o dígito entre comillas invertidas son los de `art/palette.txt` (en `.sprite`) o los de la leyenda del mapa de texto (en `.map`), y hay que distinguirlos con cuidado: **son dos espacios de nombres distintos**. En un `.sprite`, `4` es Piedra 4; en un `.map`, `4` es el acechador.

---

## 0. Resumen ejecutivo y decisiones propuestas

1. **Las letras del mapa describen el rol de la baldosa; el `TileSet` de la sala decide su material.** `T`, `G`, `B`, `C`, `S` significan "suelo con piel", "roca", "sillar", "remate" y "tablón" en todas las regiones. El mismo `.map` pintado con el tileset del Cinturón o con el del Archivo cambia de aspecto sin tocar una sola letra. Es la decisión que hace barato el resto.
2. **Autotiling por código, no por letras.** En vez de añadir letras para esquinas, bordes y techos, `TextTileMap` calcula la forma de cada baldosa según sus cuatro vecinas (máscara de 4 bits, 16 formas) y una pequeña tabla de esquinas interiores. Cada baldosa del mapa sigue siendo una sola letra. Se añaden solo **siete letras nuevas** (`g`, `p`, `m`, `h`, `a`, `/`, `\`) para cosas que no se pueden deducir de la vecindad.
3. **Una hoja de 256×144 px (16 columnas × 9 filas = 144 baldosas) por región**, con el mismo orden de índices en las seis. Las cinco baldosas actuales conservan sus posiciones (0 a 4) para que el nivel construido siga funcionando durante la migración.
4. **La Desmemoria tiene dos representaciones y cada una resuelve un problema.** La *desaturación gradual* (sombreador global de la biblia, niveles 0-3) cubre el degradado entre salas. La *baldosa desmemoriada* (`g`) es otra forma, plana y sin textura, con paleta neutra horneada: sirve para los parches grises del Cinturón, los pasillos en blanco del Archivo y toda la Herida **sin sombreador alguno**. Los dos mecanismos no se pisan.
5. **Un fondo por región, hecho de tiras PNG periódicas generadas por código**, y un conjunto pequeño de "siluetas de interior" reutilizables para las salas sin cielo, que cambian de rampa según la región. Cinco capas máximo, 864 px de ancho, unos 2-3 MB de VRAM por región, solo una región cargada a la vez.
6. **Unos 100 props**, de los que casi la mitad son reutilizables entre regiones mediante rampa de paleta, y menos de 25 piezas "singulares" que merecen dibujo a mano (Hito de Nombres, Piedras de lectura, Anclas por región, estatuas, el árbol grande, el arco sin juntas).
7. **La luz sigue siendo sprites aditivos con bandas** (ya decidido en la biblia), con un único juego de halos en blanco que se tiñe con `modulate`. La oscuridad total de las Minas necesita un prototipo de un día antes de comprometerse (sección 7.4).
8. **Orden de producción distinto al de la biblia en un punto:** primero el generador y una *primera pasada automática* de las seis regiones (media jornada por región), y solo después se mejora región a región. Así el juego completo se puede recorrer con seis caras distintas mucho antes de que ninguna esté terminada.
9. **Dos incoherencias detectadas en lo ya hecho, que conviene corregir en la fase A:** el estandarte (`F`) y el poste de señal (`L`) usan rojo saturado en el decorado, contra la regla "rojo = peligro"; y el marcador `D` está ocupado por el arco ciego de decorado, mientras el mapa macro lo reserva para el muro excavable (sección 2.2).

Esfuerzo total estimado: **unos 110 puntos** (1 punto ≈ una sesión corta de trabajo; misma escala que la biblia), de los que 23 son herramientas y 87 contenido. El vertical slice ampliado (Umbral y Cinturón bajo, 8 salas) se cierra con unos 45.

---

## 1. Estado actual y lo que hay que cambiar

Inventario verificado leyendo `art/source/tiles_umbral.sprite`, `art/source/decor.sprite`, `game/levels/tiles_umbral.tres`, `game/levels/room.gd` y el `ParallaxBackground` de `game/levels/world.tscn`:

| Elemento | Hoy | Problema | Consecuencia para esta propuesta |
|---|---|---|---|
| Baldosas | 5 en una fila (16×16): `moss` (0), `stone` relleno (1), `stone` ladrillo (2), `stone` remate (3), `wood` tablón (4). Colisión cuadrada completa; el tablón, una franja de 4 px de un solo sentido. Capa de datos `material` con textos (`moss`, `stone`, `wood`) | Sin esquinas, bordes laterales, techos ni pendientes: toda forma es un rectángulo con las caras repetidas. El relleno (1) es "sopa de píxeles" (alterna 2 y 3 sin estructura). Una sola región | Se necesita autotiling y un juego de formas completo |
| Decorado | 13 piezas de 48×64 en una hoja (`decor.sprite`): árbol, columna, hierba, zarza, huesos, estandarte, cadenas, estatua, mojón, poste, farol, arco, enredaderas. `room.gd` las coloca con la tabla `DECOR` (fotograma, cuelga, `z_index`) | Lienzo único de 48×64 aunque la pieza sea de 16×24; sin variantes; estandarte con rojo `t`/`u` y poste con trapos rojos | Hace falta una hoja por tamaño o un manifiesto de tamaños (sección 5.1) |
| Fondo | Un solo `ParallaxBackground` global con cinco capas dibujadas con polígonos en la propia escena (cielo fijo, colinas lejanas 0,15, niebla 0,28, ruinas 0,4, árboles 0,7); se oculta con `has_sky = false` | Es el fondo del Umbral aplicado a todo el mundo; no hay fondo de interior; se edita a mano en el `.tscn` | Un fondo por región, intercambiable por `world.gd`, generado a PNG |
| Props de sala | Caja, barril, urna rompibles y piedra con inscripción como escenas; carro volcado y saco como polígonos en `SetDressing` de una sola sala | Cada prop singular es código o polígonos a medida | Se unifica en una tabla de props (5.1) |
| Luz | Halo aditivo del Ancla; nada más | Sin faroles, sin reliquias, sin oscuridad | Sección 7 |
| Leyenda del mapa | `T G B C S`, jugador `P`, Ancla `A`, enemigos `E 1 2 3 4`, urna `R`, caja `Q`, barril `O`, inscripciones `I i`, recuerdos `d j w`, pinchos `^ v ~ -`, jefe `b t [ ] r`, decorado `Y U H Z K F N X V L M D q` | Quedan libres solo `a e g h m p s z J W` y símbolos como `/ \ : ; ! ? @ % &` | Elegir con cuidado las siete letras nuevas |

Lo que está bien y se conserva: la rejilla de 16×16, el tablón de una sola dirección con franja fina, el remate de muro con su línea clara (`4`), el musgo como "piel" del suelo, la tabla de marcadores de decorado en `room.gd` y la idea de que "una letra, un marcador" también sirve para el decorado.

Lectura crítica del tileset actual frente a la biblia: el suelo con musgo (0) no tiene "labio de luz" continuo (la fila superior mezcla `n` y `p`, y solo unos puntos llegan al tono claro), así que a distancia la superficie pisable no se distingue de la hierba decorativa que hay encima. La biblia exige una línea clara de 1 px en el tono 4 de la rampa; lo propongo como corrección de la baldosa 0 y de todas las nuevas (sección 2.5).

---

## 2. El sistema de baldosas

### 2.1 Principio: letra = rol, tileset = material

El mapa de texto seguirá teniendo una letra por baldosa. Lo que cambia es **qué significa la letra**:

| Letra | Rol | Colisión | Nota |
|---|---|---|---|
| `T` | Suelo con piel | Sólida | Si tiene aire encima, dibuja la "piel" de la región (musgo, tierra con paja, losa, polvo, sal). Si no, se comporta como `G` |
| `G` | Roca / tierra de relleno | Sólida | Si queda a la vista por algún lado, dibuja su borde de roca desnuda |
| `B` | Sillar labrado (arquitectura) | Sólida | Muros, bóvedas, cimientos: lo que alguien construyó |
| `C` | Remate | Sólida | Coronación de muro, cornisa, viga transversal |
| `S` | Tablón / pasarela | Una dirección (franja de 4 px) | Madera atada en el Cinturón, estante en el Archivo, andamio en las Minas |

Un mapa pintado así se puede reutilizar en otra región cambiando solo el `TileSet` de la escena: la **misma forma de sala** con otra cara. Esto es especialmente útil para las salas reconstruidas de la Herida (`HER-07 La Cisterna Doblada`, `HER-08 La Chimenea Vuelta`, etc.), que son versiones desmemoriadas de salas ya existentes: se reutiliza el `.map` de la sala original, se cambian las letras de relleno a `g` y se añaden los marcadores torcidos.

### 2.2 Letras nuevas (propuesta cerrada)

Criterio: sólo letras que no se pueden deducir de la vecindad ni de la sala. Comprobadas contra la leyenda actual (`A E R I i d j w ^ v ~ - Y U H Z K F N X V L M D q Q O b t [ ] r P 1-4`, baldosas `T G B C S`) y contra los marcadores propuestos por el diseñador de puzles (`# $ = + l _ * c n < > ) ( u f x k y o`).

| Letra | Rol | Colisión | Por qué no se deduce |
|---|---|---|---|
| `g` | **Terreno desmemoriado**: toda la familia de baldosas planas sin textura (suelo, relleno, bordes, esquinas, techo). Sustituye a `T`, `G` y `B` donde la Desmemoria lo ha borrado | Sólida | Es una decisión de diseño de nivel: dónde empieza el borrado |
| `p` | **Plataforma de una dirección no de madera**: repisa de piedra, reja de hierro, losa suspendida | Una dirección | Igual que `S` pero otro material; sin ella, el Archivo y las Minas no tendrían plataformas de piedra ni de metal |
| `m` | **Muro trasero liso**: baldosa de fondo sin colisión, capa de detrás del jugador | Ninguna | Los interiores necesitan una pared detrás; hoy es el color plano del cielo |
| `h` | **Muro trasero con vano**: arco, ventana, hornacina o reja de fondo | Ninguna | Rompe la monotonía del muro liso; el vano concreto lo decide el tileset |
| `a` | **Agua** (superficie animada si tiene aire encima, relleno si tiene agua encima) | Ninguna (decorativa hasta decidir si daña o nada) | Para Cisterna, Mina Inundada, Salina, Gruta y Cauce |
| `/` | **Pendiente ascendente a la derecha** (45°) | Sólida inclinada | Solo si el motor del jugador la soporta; ver pregunta 3 |
| `\` | **Pendiente descendente a la derecha** (45°) | Sólida inclinada | Ídem |

Letras que se quedan libres tras esta propuesta: `e s z J W` y los símbolos `: ; ! ? @ % &`. Es margen suficiente para lo que añadan las mecánicas.

**Dos conflictos que hay que resolver antes de implementar:**

- **`D`.** El mapa macro (intervenciones I1 e I6) pide un "tile nuevo `D`" para el muro excavable y la reja con grano; pero `D` ya es el arco ciego de decorado en `room.gd`, y está en uso en 10 sitios de los mapas actuales. El diseñador de puzles propone `#` (frágil) y `$` (hondo). **Recomendación: adoptar `#` y `$` y dejar `D` como decorado.** Es lo que ya asume esta propuesta.
- **`N`.** En la leyenda documentada `N` son las cadenas colgantes, y en `chimenea.map` aparece en las dos filas bajo una plataforma, con la lógica de "el marcador va en la celda de debajo". Está bien, pero hay que recordar que `N` no tiene relación con "Nombrar" (marcador `n`): minúscula y mayúscula coexisten.

### 2.3 Autotiling: la máscara de cuatro bits

`TextTileMap` (core) recorre las celdas de terreno y, para cada una, calcula una máscara con sus cuatro vecinas ortogonales. Se consideran "terreno" las letras `T G B C g # $` (y los marcadores que sean sólidos). Los tablones `S` y las plataformas `p` **no** conectan con nada: son siempre su propio juego de piezas.

Bit de cada vecina (si es terreno): norte = 1, este = 2, sur = 4, oeste = 8. El índice de columna dentro de la fila del terreno es la suma.

| Máscara | Vecinas sólidas | Pieza | Uso típico |
|---|---|---|---|
| 0 | ninguna | Bloque aislado, con contorno en los cuatro lados | Piedra suelta, escombro grande |
| 1 | N | Extremo inferior de un pilar | Estalactita sólida, pilar colgante |
| 2 | E | Extremo izquierdo de una viga horizontal | Losa en voladizo |
| 3 | N+E | Esquina inferior izquierda (exterior) | Fondo de un pozo, rincón |
| 4 | S | Extremo superior de un pilar | Pilar, mojón alto |
| 5 | N+S | Pilar vertical | Tabique de una baldosa de ancho |
| 6 | E+S | Esquina superior izquierda (exterior) | Borde izquierdo de una plataforma |
| 7 | N+E+S | Pared izquierda (oeste libre) | Pared de un pozo, lado derecho de una sala |
| 8 | W | Extremo derecho de una viga | Losa en voladizo |
| 9 | N+W | Esquina inferior derecha (exterior) | Fondo de un pozo |
| 10 | E+W | Losa horizontal fina | Puente de piedra de una baldosa |
| 11 | N+E+W | Techo (sur libre) | Techo de sala, bóveda plana |
| 12 | S+W | Esquina superior derecha (exterior) | Borde derecho de una plataforma |
| 13 | N+S+W | Pared derecha (este libre) | Pared de un pozo, lado izquierdo de una sala |
| 14 | E+S+W | **Suelo** (norte libre) | Superficie pisable: la que lleva el labio de luz |
| 15 | todas | Relleno | Interior de masas |

Para la máscara 15 se consultan además las cuatro diagonales: si alguna está libre se usa una **esquina interior** (4 piezas, una por diagonal; si hay dos diagonales libres, se elige la de mayor prioridad noroeste, noreste, sureste, suroeste; las demás combinaciones raras se resuelven con el relleno).

**Variantes.** Para romper la repetición, las máscaras 14 (suelo), 15 (relleno), 7 y 13 (paredes) tienen hasta cuatro variantes. La elección es determinista: `hash2(x, y, semilla_de_sala) % n`, con una única regla antivecino (no repetir la variante de la baldosa de la izquierda ni la de arriba). Sin aleatoriedad en ejecución: la misma sala se ve siempre igual y se puede comparar en capturas.

**Coste de código:** unas 40-60 líneas en `TextTileMap` más una tabla `terrain_sets` en la leyenda de la escena. Es trabajo de programación, no de arte, pero condiciona el orden de la hoja, por eso lo fijo aquí. Alternativa: terrenos nativos de Godot 4. Los descarto porque obligan a pintar `TileSet` por terreno a mano (señalar esquinas en el editor, que el usuario no domina) y el cálculo de 4 bits es más fácil de revisar en texto y de probar con la prueba de humo.

### 2.4 La hoja de la región: 256×144 y mapa de índices

Cada región tiene un PNG de 256×144 px: 16 columnas × 9 filas de 16×16. El índice de una baldosa es `fila × 16 + columna`. El `TileSet` mantiene `texture_region_size = 16×16` y las coordenadas de atlas `(columna, fila)`; deja de ser "una fila de baldosas" como describe `docs/arte.md`, y ese documento se actualizará al integrar.

| Fila | Contenido (columna: pieza) |
|---|---|
| **0 · Sueltas** | 0 `T` clásica (compat.), 1 `G` clásica, 2 `B` clásica, 3 `C` clásica, 4 `S` clásica (**posiciones de hoy, intactas**); 5 `p` centro; 6 `#` frágil (base); 7 `$` hondo (base); 8 y 9 `a` superficie, dos fotogramas; 10 `a` relleno; 11 y 12 `m` liso (dos variantes); 13 y 14 `h` con vano (arco, ventana); 15 reserva |
| **1 · `G` roca** | 0 a 15: las 16 máscaras de roca/tierra desnuda |
| **2 · `T` piel** | 0 a 7: las ocho máscaras con el norte libre (0, 2, 4, 6, 8, 10, 12 y 14, en ese orden: la columna es la máscara dividida entre 2); 8 a 11: cuatro variantes del suelo plano (máscara 14); 12 y 13: piel que se desborda por el borde izquierdo y derecho (1 px que cuelga); 14 y 15: piel con detalle singular (flor, hongo, cuenta) |
| **3 · `B` sillar** | 0 a 15: las 16 máscaras de sillar labrado |
| **4 · Remates y plataformas** | 0 `C` extremo izquierdo; 1 a 4 `C` centro (cuatro variantes); 5 `C` extremo derecho; 6 y 7 `C` esquina interior izquierda y derecha; 8 `S` extremo izquierdo; 9 y 10 `S` centro (dos variantes); 11 `S` extremo derecho; 12 `S` con puntal visible debajo; 13 `p` izquierda; 14 `p` centro; 15 `p` derecha |
| **5 · Interiores y variantes** | 0 a 3: esquinas interiores de `G` (NO, NE, SE, SO); 4 a 7: esquinas interiores de `B`; 8 a 11: cuatro variantes del relleno de `G`; 12 a 15: cuatro variantes del relleno de `B` |
| **6 · `g` desmemoriado** | 0 a 15: las 16 máscaras del terreno plano (la máscara 14 lleva el labio de luz en `w` o `y`) |
| **7 · Pendientes y fronteras** | 0 a 3: pendiente `/` (superficie, relleno bajo la superficie, unión superior, unión inferior); 4 a 7: pendiente `\` (ídem); 8 a 11: frontera `g` hacia `G`/`B` por el norte, este, sur y oeste (corte recto con 1 px de `w`); 12 a 15: el mismo corte visto desde el lado de la roca recordada |
| **8 · Daño y decales** | 0 a 2: grietas sobre `G` en tres etapas (golpe 1, 2 y 3); 3 a 5: grietas sobre `B`; 6 a 9: muro tapiado (ladrillo irregular con veta ámbar de "hondo" en dos de ellos); 10 y 11: goteo (dos variantes); 12: chorreón de humedad; 13: musgo o liquen de pared; 14: escarcha de sal; 15: mancha de tinta |

Total: 144 baldosas. De ellas, **la mayoría no se dibujan: se derivan** (sección 2.6): las 16 máscaras de cada terreno salen de cuatro piezas maestras (relleno, borde, esquina exterior, esquina interior) recortadas y giradas por el generador, y las variantes salen del ruido determinista con rampa.

Dos observaciones prácticas:

- **Colisión.** Las pendientes (fila 7) llevan polígonos diagonales; las plataformas `S` y `p`, la franja fina de 4 px del tablón actual; todo lo demás, el cuadrado completo. La capa de datos `material` se amplía (sección 2.7).
- **Si el programador prefiere una sola fila**, la hoja se puede serializar como una fila de 144 fotogramas (2304×16, con índice `fila × 16 + columna` igual). El orden no cambia; solo cambia la geometría del PNG.

### 2.5 Lenguaje común de la baldosa (las reglas que no se negocian)

Estas reglas salen de los pilares de la biblia y valen para todos los tilesets; se comprueban con la prueba de escala de grises.

| Regla | Detalle |
|---|---|
| **Labio de luz** | Toda superficie pisable (máscaras con el norte libre, `S`, `p`, `C` superior) lleva 1 px de tono 4 de la rampa de la región en su fila superior, con salpicaduras de tono 3 hacia la fila 2. Es lo único de la capa de juego con tono 4 fuera de enemigos y reliquias |
| **Cara frontal** | Debajo del labio, 2-3 filas de tono 2 (cara en sombra) antes de la textura del relleno. Da lectura de volumen sin contorno negro |
| **Contorno** | Solo `1` o `0`, y solo donde la baldosa limita con aire: un contorno de 1 px por los lados libres. Una baldosa sin lados libres (máscara 15) no tiene contorno |
| **Techos** | Las máscaras con el sur libre (11, 1, 9, 3) llevan una fila de tono 1 pegada al borde inferior y algún colgante de 1-2 px: se leen como "sombra bajo la que se puede pasar" |
| **Paredes escalables** | Muescas verticales: 1 px de tono 3 cada 3-4 filas en las máscaras 7 y 13. Las paredes lisas (sin muescas) son las del muro tapiado y de las salas de Agarre que se quieren prohibir; si el motor no distingue entre paredes escalables y no escalables (pregunta 4), solo se dibujan las muescas |
| **Ruido** | El ruido determinista **solo salta entre tonos adyacentes de la rampa** (nunca del 1 al 4). Con tres tonos bien distribuidos se evita la "sopa de píxeles" del relleno actual: bandas horizontales de estratos para roca, bloques de 2-4 px para tierra, juntas de 1 px para sillar |
| **Densidad** | Máximo 25-30 % de píxeles distintos al tono base de la baldosa. El detalle (grietas, musgo, gotas) se concentra en bordes y se deja la mitad central tranquila: el jugador pisa y salta sobre ella y no debe distraer |
| **Costuras** | El generador comprueba cada baldosa repetida 8×8 y cada pareja de vecinas posibles (la cara derecha de A con la cara izquierda de B). Las filas y columnas del borde de un tipo se conservan idénticas entre variantes |
| **Paleta** | Máximo tres rampas principales por región más las señales activas en pequeñas dosis. Nunca `t` ni `u` en terreno (reservados al daño) |
| **Rojo** | Ninguno en el terreno ni en el decorado, con una excepción propuesta: `r` y `s` (rojos oscuros apagados) para tela remendada del Umbral y del Cinturón, nunca `t`/`u` (pregunta 5) |

### 2.6 Qué genera el código y qué se dibuja

La hoja se produce con el generador `tools/arte_tiles.js` del plan de pipeline, con una **definición de región** (rampas, semillas, densidades) y las piezas maestras. Lo que se dibuja a mano son las **piezas maestras**, pocas y muy bien hechas:

| Pieza maestra | Se dibuja a mano | Se genera |
|---|---|---|
| Relleno de `G` | Una muestra de 16×16 por región como referencia de textura (el ojo manda) | Las cuatro variantes con ruido sobre esa muestra |
| Suelo `T` con piel (norte libre) | Una de 16×16 por región | Variantes, extremos, desbordes |
| Sillar `B` | Una de 16×16 (dos hiladas de 16×8, o una de 16×16 en el Archivo) | Las 16 máscaras por recorte |
| Remate `C` | Tres piezas (izquierda, centro, derecha) | Variantes |
| Tablón `S` y repisa `p` | Dos piezas | Extremos y puntales |
| `g` desmemoriado | Ninguna: se genera por completo (plano + labio) | Todo, incluidas las fronteras |
| Grietas | Un conjunto de 3 etapas por región (reutilizable, solo cambia de rampa) | Aplicadas sobre `G`/`B` |
| Muro tapiado y decales | Las 4 de la fila 8 | Rampas por región |

El número de píxeles que se dibujan a mano por región baja a unos 12 bloques de 16×16, o **cerca de dos horas de trabajo** por región una vez calibrado el generador. La paleta alternativa por región es la regla A de la biblia; la variación con ruido, la regla B; el dibujo manual, solo para remates singulares.

### 2.7 Material y sonido (capa de datos del `TileSet`)

El `TileSet` actual ya tiene una capa de datos `material` (texto: `moss`, `stone`, `wood`). Se amplía sin tocar la jugabilidad: sirve para que los pasos y aterrizajes suenen distinto. Valores propuestos por región:

| Región | Materiales de `material` |
|---|---|
| Umbral | `moss`, `stone`, `wood` (ya existen) |
| Cinturón | `earth` (tierra seca, la mayoría), `stone`, `wood` (tablones atados), `straw` (paja del Almiar) |
| Archivo | `flag` (losa de piedra pulida), `stone`, `wood` (estante), `paper` (pasillos en blanco: pisadas amortiguadas) |
| Minas | `rock`, `wood` (andamio), `metal` (raíles y repisas), `water` (charcos) |
| Costa | `sand` (arena de la playa), `salt`, `stone`, `wood` |
| Herida | `void` (todo `g`: sin sonido de paso, el silencio como firma) |

El conjunto de materiales es de **ocho** sonidos de pisada distintos a lo sumo, que es lo que entra en `docs/sonido.md` sin ampliar el sintetizador de forma significativa. Decisión del programador de sonido, no del artista.

### 2.8 Ejemplos de baldosa (formato `.sprite`, 16×16)

Dos ejemplos para fijar el listón de estilo. Códigos de `art/palette.txt` ampliada (`5 6 7` tierra y paja, `x y w` neutros).

**Cinturón, `T` con piel, suelo plano (máscara 14).** Labio claro de paja (`7`) con destellos de `4`; tierra seca (`6` y `5`) con alguna piedra (`3`) y briznas; las filas bajas se funden con el relleno:

```
7777747777777477
6776767667677676
6566656566656566
5655565555655655
5555355555553555
5535555355555355
5555565555565555
5655555535555655
```

(Las ocho filas restantes siguen el relleno de tierra del Cinturón: bandas de `5` con puntos de `6` y alguna `3`, sin tocar los tonos 7 ni 4.)

**Desmemoriado, `g`, suelo plano (máscara 14).** Una sola superficie, sin textura y con borde recto: es la baldosa que dice "aquí no hay nada que recordar". El labio es `y` (neutro medio) y el cuerpo, `x`:

```
yyyyyyyyyyyyyyyy
xxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxx
```

(Las doce filas restantes son `x` lisas; la frontera con una baldosa recordada añade una columna de `w` de 1 px, ver fila 7 de la hoja.) En la Herida, en las salas más profundas, esta misma baldosa se genera con píxeles de 2×2 o de 4×4 (sección 3.6).

---

## 3. Tileset de cada región

Convención de cada ficha: la tabla da, por letra, el material, la rampa y el detalle que lo distingue; después, lo singular de la región, cómo se rompe la repetición, qué cambia entre la versión "recordada" y la "desmemoriada" de la misma baldosa, y en qué sala se prueba primero. Todas las baldosas se pintan a color pleno (nivel 0); el sombreador de desaturación hace el resto (biblia, 3.3). Los códigos son de la paleta ampliada.

### 3.1 El Último Umbral (nivel 0: el estándar de "memoria viva")

Rampas: Piedra (`1 2 3 4`), Tierra (`5 6 7`), Musgo (`m n o p`). Ámbar solo en puntos de luz.

| Letra | Material y aspecto | Rampa | Detalle que lo distingue |
|---|---|---|---|
| `T` | Tierra pisada con hierba amarillenta y musgo en los bordes. Es la baldosa 0 actual, corregida | Labio `p` (musgo 4) alternado con `7` (paja); cuerpo `5 6`; musgo `n o` en el borde frontal | Línea continua de labio (hoy la fila superior es irregular); brotes de 1-2 px cada 4-6 baldosas; alguna mota ámbar (`b`) de ceniza |
| `G` | Roca bruta y tierra con piedras | `2 3`, juntas con `1`, algún `5` | Bandas horizontales cortas de estrato, no moteado uniforme; una veta de musgo muy rara |
| `B` | Muro de piedra bruta con parches de madera (el aspecto "pobre y reparado" de la biblia) | `3` en el sillar, `2` en las juntas, `1` de contorno; parches de `5 6` (una de cada seis piezas) con dos clavos `4` | Hiladas irregulares de dos alturas (16×16 y 16×8), una pieza remendada con tabla; así el muro cuenta que alguien lo arregló |
| `C` | Remate de muro con lajas y tejadillo de tablas | Labio `4`, cara `3`, tablas `6` | El remate actual (3) mantiene su línea clara; se añaden dos variantes con una laja ladeada y una con un travesaño de madera |
| `S` | Tablón de madera clavado | `6` cara, `5` sombra, `4` clavo, labio `b` (ámbar 2) | **Labio ámbar** como pide la biblia para plataformas de una dirección (hoy el tablón tiene un labio `d`, el ámbar más claro, que compite con las luces; con `b` se lee como suelo y no como lámpara). Clavos visibles, un nudo cada 3-4 baldosas |
| `p` | Repisa de piedra o losa suspendida | `3`, labio `4`, soporte `2` | Se usa muy poco; para las ruinas del Rellano |
| `g` | Apenas se usa; en el Umbral nada está desmemoriado. Reservado para la Puerta Tapiada: el interior de las marcas de uñas | `x y` | Solo una sala |
| `m`, `h` | Muro trasero de tablas remendadas (`m`), con ventana ámbar encendida (`h`) en las chabolas | `2 3`, ventana `c d` | La ventana ámbar es "el cuadro más cálido del juego": ventana pequeña, 4×6 px, sin halo propio (el halo lo pone un nodo aparte) |

**Singular:** muro tapiado (fila 8, columnas 6 a 9) para la Puerta Tapiada: ladrillo irregular con una veta de rombos ámbar apenas insinuada (la "veta de Golpe Hondo" de M2). Tiene que estar visible desde la primera pantalla del juego, porque el diseño lo plantea como "mira, pero no toques".

**Variación:** cuatro variantes de relleno; la piel (`T`) alterna tres longitudes de hierba amarilla para que no se lea como un patrón.

**Recordada frente a desmemoriada:** el Umbral es el patrón de lo recordado. No hay versión desmemoriada salvo el hueco de las uñas.

**Primera sala de prueba:** `ultimo_umbral` (la sala 0 construida; se puede comparar contra la captura actual).

### 3.2 El Cinturón Yermo (nivel 1 con parches de nivel 3)

Rampas: Piedra, Tierra/Paja (`5 6 7`), Musgo; ámbar en faroles. Tinte ocre seco (por sombreador, no por rampas).

| Letra | Material y aspecto | Rampa | Detalle que lo distingue |
|---|---|---|---|
| `T` | Tierra seca de bancal con briznas de paja | Labio `7` con puntos de `4`; cuerpo `6 5`; piedrecillas `3` | Ver ejemplo de la sección 2.8. Sin musgo, salvo rastro `n` junto a las acequias |
| `G` | Tierra compactada con piedra suelta | `5 6` dominante, `3` en piedras de 2-3 px, `1` solo en grietas | Surcos horizontales largos de 1 px (el campo arado), más regulares que en el Umbral |
| `B` | Piedra seca: muros de bancal sin argamasa | `3` piedra, `1` hueco entre piedras, `2` sombra | **Sin juntas rectas**: las piedras encajan en forma de lajas irregulares. Distingue el Cinturón del Archivo (juntas rectas) de un vistazo |
| `C` | Coronación del muro de bancal: una hilada de lajas planas | Labio `4`, cara `3` | Dos variantes: una con hierba seca asomando (`7`) y otra con una piedra grande |
| `S` | Andamio de tablas atadas con cuerda | Tabla `6`, sombra `5`, cuerda `7` | Los extremos llevan **una vuelta de cuerda** (1-2 px de `7` sobre la tabla) y de la cara inferior sale el puntal de la variante 12 de la fila 4. Es la plataforma de una dirección de las torres de riego |
| `p` | Losa saliente de un muro de bancal | `3` con labio `4` | Para las terrazas altas donde un tablón sería raro |
| `a` | Acequia llena, solo tras el Manantial (P11); la acequia seca es decorado | `f`, `e` | Opcional |
| `g` | **Parche gris** del Campo de los Ferrán y de las terrazas con mancha: tierra sin textura de bordes rectos | `x y`, labio `y` | Ver abajo |
| `m`, `h` | Muro trasero de adobe y entramado (graneros), vano de puerta sin puerta | `5 6`, vano `1` | Granero sin Techo |

**Singular:**

- **El parche gris.** Un terreno `g` con borde recto, sin la menor irregularidad, junto a tierra normal: el contraste entre la tierra irregular y un plano exacto es lo que cuenta la historia. La frontera (fila 7) añade una línea `w` de 1 px que hace de "corte con tijera" (el texto del campo dice "con el borde limpio, como cortado con tijera"). Es la primera vez que el jugador ve la Desmemoria como forma, no como niebla (ficha 5.2 de la biblia).
- **Tablones que se borran** (Linde Gris, CIN-30): `S` con la variante `fade` (sección 6.3), el mismo tablón con la mitad inferior ya transparente.
- **Parches de nivel 3 en salas de nivel 1.** Como el nivel de desaturación es *por sala*, el parche gris no se hace con sombreador: se hace con `g`. Es lo que permite "una mancha gris en una terraza" sin una máscara de pantalla.

**Variación:** cuatro variantes de suelo y relleno; una variante "pisada" del suelo (huellas de 3 px) que el nivel coloca cerca de los caminos para sugerir tránsito pasado (el prop de huellas de P10 la complementa).

**Primera sala de prueba:** `terrazas_secas`, `torre_de_riego`.

### 3.3 Transición húmeda: Cisterna, Galerías y Aljibe (variante del Cinturón, no región nueva)

Las salas ya construidas `cisterna`, `galerias_bajas` y `aljibe` (y la futura Cisterna Doblada de la Herida) comparten una paleta húmeda. **No hace falta un tileset aparte**: es el tileset del Cinturón con otra rampa de piedra y decales de humedad.

| Aspecto | Cómo |
|---|---|
| Rampa | Piedra más oscura (se desplaza un tono: `1 2 3` donde el Cinturón usa `2 3 4`), musgo `m n o` en lugar de paja, un hilo `e f` en la base del muro |
| Decales (fila 8) | Goteo (10, 11), chorreón de humedad (12), musgo de pared (13) |
| Labio de luz | Se mantiene en `4`, pero con 1 px menos de salpicadura: la humedad "come" el brillo |
| Agua `a` | Cisterna: el fondo con agua baja `f` y superficie `g`, con dos fotogramas que cambian de posición los destellos `h` de 1 px |
| Tinte | De ocre a azul verdoso a mitad de la caída: el tinte global se interpola por sala, no por baldosa |

El Aljibe, sala de jefe, usa el mismo juego con `B` más alto, y la reja de arena (sección 6.9) con herrajes de hierro oxidado.

### 3.4 El Archivo (nivel 1 en salas intactas, 2 en las erosionadas, 3 en los pasillos en blanco)

Rampas: Piedra, Hueso/Pergamino (`8`), Ámbar (velas), Azul (sellos). Tinte cálido casi neutro. **El Archivo es el tileset más regular**: simetría, juntas rectas, orden.

| Letra | Material y aspecto | Rampa | Detalle que lo distingue |
|---|---|---|---|
| `T` | Losa grande de suelo pulido: baldosa de 16×16 con una cruz ligera de junta | Labio `4`, cuerpo `3`, junta `2`, desgaste `8` en el centro | Es el suelo más "limpio": poco ruido, desgaste central en parches de 2×2 donde se ha caminado. Sin piel vegetal |
| `G` | Sillar fino de cimiento | `2 3`, juntas `1` | Dos hiladas de 16×8, regulares |
| `B` | **Muro de sillería con juntas de cal** | `3` sillar, `8` junta (1 px), `2` sombra | La junta clara de `8` es lo que lo distingue de cualquier otra región. Una de cada ocho hiladas lleva una placa con 2-3 puntos grabados (nombres) |
| `C` | Cornisa moldurada: tres líneas (bocel, filete, cuarto bocel) | `4`, `3`, `2` | Es lo más ornamentado del juego; se reserva para el borde alto de las salas |
| `S` | **Estante de madera** como plataforma: tabla con lomos de libro visibles debajo | Tabla `6`, sombra `5`; lomos `a b c` cada 2 px | Labio ámbar (`b`). Los libros son 4-6 columnas de 1-2 px de colores de la rampa de ámbar y azul apagado: su orden regular es lo que contará la Desmemoria cuando se rompa |
| `p` | Repisa de piedra moldurada o balcón de arco | `3`, labio `4`, ménsula `2` | Plataforma de un solo sentido para los Altos del Catálogo |
| `g` | **Pasillo en blanco**: losas planas `w`/`y` sin junta ni textura | `w` suelo, `y` labio inverso, `x` cuerpo | Ver abajo |
| `m` | Pared de la sala: sillar liso casi negro (la pared es más oscura que el suelo, para dar profundidad) | `1 2` | Fondo de toda la nave |
| `h` | Pared con **arco apuntado ciego** y hornacina con estantes | `2 3`, relleno `1` | El arco ciego es el motivo transversal de la biblia (apartado 6) |
| `a` | Pozas de tinta (Cripta de los Registros Quemados) | `e`, `0` | Sin brillo |

**Singulares:**

- **Pasillo en blanco.** Una sala `g` entera: suelo `w` con labio de 1 px hacia arriba, cuerpo `x`, pared `y`. Es la única sala con el suelo *más claro que la pared*. La inversión de contraste es lo que se siente "mal" (una sala en blanco es un hueco de luz). Los pasillos en blanco alternan, en la misma sala, con tramos `T` recordados: la frontera `g` a `T` (fila 7) es el elemento visual clave.
- **Estantería-torre** como terreno: columna de `B` cuyas caras tienen hileras de lomos. No es una baldosa nueva: es decorado de 48×48 apilable (5.4) con colisión de terreno detrás.
- **Estantes en blanco:** los mismos lomos en `w`/`y` sin título (decorado).

**Variación:** el Archivo tiene muy poca, a propósito. Dos variantes de suelo (una con el desgaste) y dos de sillar. La tentación de añadir ruido contradice el tema. La variación que cuenta es el nivel de desaturación de la sala, que baja el contraste de la cal.

**Primera sala de prueba:** la Nave Raspada (ARC-04): es larga, sin plataformas, y obliga a comprobar la repetición.

### 3.5 Las Minas del Origen (nivel 2; mineral y hongos a color)

Rampas: Piedra muy oscura (tonos 1 y 2 casi todo), Azul (mineral), Musgo (hongos), Ámbar (farolillos), Tierra (vigas). Tinte verde azulado frío.

| Letra | Material y aspecto | Rampa | Detalle que lo distingue |
|---|---|---|---|
| `T` | Roca con polvo y charcos | Labio `3` (no `4`: en la oscuridad el tono 4 sería un faro), cuerpo `2`, polvo `x` | El labio de luz baja un tono (**excepción documentada** a la regla de la biblia: en las Minas el tono 4 queda reservado a las luces; ver pregunta 6) y se compensa con un contorno `0` más marcado |
| `G` | Roca con **estratos** visibles: bandas horizontales de 3-5 px | `1 2`, estrato claro `3` | El ruido está correlacionado por filas (la roca se ve en capas) |
| `B` | Mampostería de la Orden (arcos enterrados) y muro de apeo | `2 3`, vigas `5 6` | Mitad de las piezas `B` son bloque de piedra y mitad, vigas verticales con un travesaño |
| `C` | Viga travesaño y dintel de madera | `6`, clavos `3`, sombra `5` | Se pone sobre las bocas de galería |
| `S` | Tablones de andamio minero | `6 5`, clavos `3` | Labio ámbar tenue (`a`, el tono 1 de ámbar, para que se lea en casi negro) |
| `p` | **Raíl / repisa de hierro**: plataforma metálica con remaches | `2 3`, remaches `4`, óxido `b` | Los carriles de M7 usan estas piezas en forma de raíl (sección 6.7) |
| `g` | Solo el arco del Archivo enterrado (la parte desmemoriada) | `x y` | Anecdótico |
| `m` | Roca trasera, muy oscura, con **vetas luminosas** | `0 1`, vetas `f g` (emisivas) | Las vetas no se desaturan; laten cuando el Eco está cerca (sección 6.10) |
| `h` | Boca de galería lejana o ventana al abismo | `0` con borde `1` | Da profundidad |
| `a` | Agua de la Mina Inundada y de los charcos del Cauce | `e f`, brillo `g` | Reflejos |

**Singular:** vetas luminosas (`f g`) sobre `G` y sobre `m` como **decal emisivo**: píxeles que no pasan por el sombreador de desaturación ni por la oscuridad de sala (sección 7.4). Se dibujan en una capa separada de la baldosa (en esta región, las columnas 10 a 15 de la fila 8 son decales emisivos en lugar de goteo) para poder activarlas aparte.

**Variación:** los estratos y la densidad de vetas varían por sala (parámetro `veta`, de 0 a 3). Las salas de pozo vertical usan estratos inclinados (se rotan las muestras de las variantes 8 a 11 de la fila 5).

**Regla de seguridad (biblia 4.1):** pinchos y abismos siempre con un tono ámbar tenue propio o un reflejo azul. El generador incluye una variante de `T` con "borde de peligro" (1 px de `a` en el labio) para los suelos que dan a un abismo en sala oscura; se activa con una opción de la sala, no con una baldosa nueva.

**Primera sala de prueba:** el Andén de los Picos (MIN-01).

### 3.6 La Costa Retenida (nivel 0 con matiz frío)

Rampas: Piedra clara (`3 4`), Cal/Sal (`8 9 v`), Azul, Ámbar (faroles), un poco de Tierra. Tinte cian fresco.

| Letra | Material y aspecto | Rampa | Detalle que lo distingue |
|---|---|---|---|
| `T` | Roca de acantilado con **líquenes** fríos y sal | Labio `9` (sal) con `4`; cuerpo `3`; liquen `v` y `n` | La sal blanca en el borde hace de labio de luz y hace brillar toda la costa. Los líquenes son verdes fríos (`n`, `v`), no el musgo cálido del Umbral |
| `G` | Roca calcárea | `3 4`, grietas `2`, sal `9` | Colores más claros que cualquier otra región: lo más claro del terreno antes de la Herida |
| `B` | **Muro encalado** | `8` cal en la cara, `3` sombra, `2` junta, `1` contorno | Blanco cálido y luminoso. Una de cada cuatro hiladas con desconchón que deja ver la piedra (`3`) |
| `C` | Remate de **pizarra** oscura | `2`, labio `4`, desborde `1` | Contraste fuerte con el encalado: dibuja la silueta de los tejados |
| `S` | Tablón de puente blanqueado por el salitre | `6`, sal `9` en las vetas, cuerda `7` | Puente colgante: los extremos con nudos de cuerda |
| `p` | Muelle: pilote con tablas | `5 6`, algas `v` | Para el Embarcadero |
| `a` | Mar | `v` superficie, `f` fondo, espuma `9` | Cuatro fotogramas de ola (la hoja admite dos en la fila 0; los otros dos van en un decal) |
| `g` | Solo el Rellano de Cal (el círculo de cal) | `w y` | Una sola sala |
| `m`, `h` | Muro trasero encalado, ventana de arco rebajado con persiana | `8`/`3` | Interiores del pueblo |

**Singular:** la **arena** de la Playa de Nombres: una piel alternativa de `T` (`piel = arena`, con dos filas de píxeles de sal y huellas), seleccionada por sala. El círculo de cal del Rellano es un decal de 64×8 (prop).

**Variación:** cuatro variantes de roca; el muro encalado tiene "mancha" (humedad), "limpio" y una tercera con la silueta de un símbolo tachado de la Orden (esta última es decorado, no baldosa).

**Primera sala de prueba:** el Muro Blanco (COS-07).

### 3.7 La Herida (nivel 3; todo `g`)

Rampa: solo Neutros (`0 x y w`) y Piedra. Acento opcional `z` lavanda (reservado; pregunta 8).

| Letra | Material y aspecto | Rampa | Detalle que lo distingue |
|---|---|---|---|
| `g` | **Todo el terreno**: plano, sin textura. Se acaba la distinción entre `T`, `G`, `B`: en la Herida las cuatro letras `T G B C` se dibujan con la misma familia plana | `x` cuerpo, `y` labio, `w` filo, `0` contorno solo donde falta suelo | Sin ruido |
| `S`, `p` | Plataformas como bloques lisos con un solo tono `y` | `y`, labio `w` | Siguen siendo plataformas de una dirección; su forma plana las hace parecer "el recuerdo de una repisa" |
| `m` | Pared trasera blanca (`w` degradando a `y`) | `w y` | La Herida no tiene fondo oscuro |

**La resolución degradada.** La biblia propone que el pixelado crezca a bloques de 2×2 y 4×4 a medida que se avanza. El generador lo hace sin dibujar nada: toma la hoja `g` a resolución 1 y la cuantiza por bloques con vecino más cercano. Resultado: **tres hojas** (R1, R2, R4) del mismo tileset, con idénticos índices. Cada sala de la Herida declara su hoja (`resolucion: 1 | 2 | 4`):

| Resolución | Salas | Aspecto |
|---|---|---|
| R1 (1 px) | Páramo Gris, Puerta Sin Muro | Plano pero a escala normal; la pérdida de textura es lo único que cambia |
| R2 (2×2) | Escalera de Hojas, Círculo Colgado, Pared Raspada y las reconstrucciones | Todo es ligeramente más grueso que el personaje: una nota de extrañeza |
| R4 (4×4) | Antesala del Asiento, Sala del Asiento, Sala de Aún | El mundo es "el recuerdo de un mundo"; el Caminante, a 1 px, parece más real que todo lo demás |

Matiz técnico: las baldosas de R2 y R4 siguen siendo de 16×16 en el atlas (los bloques de 2 y 4 px caben exactos), y los **sprites del jugador, los enemigos y el Eco no cambian de resolución**: el contraste de resolución es parte del mensaje. La colisión no cambia.

**Primera sala de prueba:** la Pared Raspada (HER-05).

### 3.8 Transiciones entre regiones y salas reconstruidas

Las regiones no se unen con "tiles de transición": se unen con **parámetros por sala** (rampa, tinte, nivel de desaturación, hoja de baldosa) que cambian de forma gradual a lo largo de varias salas.

| Transición | Salas | Qué cambia | Cómo |
|---|---|---|---|
| Umbral a Cinturón | Umbral, Terrazas Secas, Torre | La tierra pasa de hierba y musgo a paja seca; el ámbar cede al ocre | Las Terrazas usan `T` del Cinturón con una mezcla de piel de las dos regiones en las primeras columnas (parámetro `piel_mezcla`) |
| Terrazas a Cisterna | Terrazas, Cisterna, Galerías | Humedad, azul verdoso | Sección 3.3 |
| Cinturón a Archivo | Era, Pozos Blancos, Puerta del Archivo | La tierra desaparece; entran el sillar y la losa; paredes blancas con arañazos | Pozos Blancos: `B` del Archivo con las paredes lisas de la Era; las muescas de Agarre se dibujan como arañazos (decales) en la roca |
| Minas a Archivo enterrado | Arcos del Archivo enterrado en las Minas | Un arco de piedra clara incrustado en roca oscura | `B` de las Minas con una zona de `B` del Archivo en la parte incrustada, dentro de una misma sala (dos hojas en dos capas de `TileMap`) |
| Cinturón a Costa | Cuesta del Segador, Paso del Pastor | Tierra a roca con liquen y sal; el cielo se abre | Dos o tres salas con `T` de la Costa pero tierra del Cinturón en el relleno |
| Costa a Herida | Pilar de Lacre, Páramo Gris | De la roca encalada al plano | El Pilar de Lacre empieza con la cal normal y llega a `g` en los últimos tramos de bajada |
| Herida: salas reconstruidas | Cisterna Doblada, Chimenea Vuelta, Terrazas de Ceniza, Scriptorium Sin Tinta, Galerías Dobladas | La versión "mal recordada" de una sala conocida | Mismo `.map` de la sala original con `T G B` sustituidas por `g`, resolución R2, y los marcadores de la sala original mal colocados (torcidos o espejados) |

En una transición el mismo carácter del `.map` se pinta con una **mezcla de dos hojas**: el generador produce una hoja intermedia por interpolación de rampa (por ejemplo, 50 % Cinturón y 50 % Archivo), de modo que no hay que dibujar nada nuevo. Se declara en la escena como `hoja_mezcla`. Dos salas de transición por frontera son suficientes.

---

## 4. Fondos de parallax

### 4.1 Formato y técnica

Decisión de la biblia y del pipeline: tiras PNG periódicas generadas por código (`tools/arte_fondo.js`), una por capa, con una **definición de región** (silueta, densidad, rampa, altura de horizonte). Detalle que añado:

| Aspecto | Propuesta |
|---|---|
| Ancho de tira | **864 px** (una pantalla) para todas las capas. La repetición horizontal es por `Parallax2D` con `repeat_size.x = 864` (o `motion_mirroring` en el `ParallaxBackground` actual si no se migra). El ruido que dibuja la silueta es periódico con módulo 864, así que no hay costura |
| Alto de tira | Distinto por capa, lo mínimo que cubre la zona útil (ver tablas). Las capas lejanas son bajas; las cercanas, más altas. Ninguna repite en vertical |
| Parallax vertical | Factor y entre 0,1 y 0,2: la capa sube un poco cuando la cámara sube, pero el horizonte no se despega. La altura del horizonte se fija por región con un desplazamiento base (`scroll_offset.y`) |
| Capas | **Cuatro de escena más una de primer plano** por región, y una de efecto (niebla) cuando procede. Menos que la biblia lo permite (5), porque cada capa extra cuesta producción y legibilidad |
| Rango de valor | El de la biblia 1.3: fondo lejano tono 1-2, medio 1-2, cercano 1-3. **Ninguna capa de fondo con tono 4** (el tono 4 es la capa de juego), salvo el cielo y las luces que forman parte de la escena (luna, ventanas ámbar, claraboyas) |
| Sin contorno | Las capas lejanas y medias no llevan contorno oscuro; la cercana, solo siluetas (como pide la biblia) |
| Rojo | Prohibido en fondos. Es una regla de la biblia que se comprueba en la validación del generador |
| Animación | Tres mecanismos baratos, ninguno por fotograma completo: (1) **autodesplazamiento** (`Parallax2D.autoscroll`) para nubes, niebla y calima; (2) **pequeños sprites animados** de 2-4 fotogramas colocados sobre la capa para humo, banderines, estrellas o velas; (3) **cambio de paleta cíclico** (parpadeo de un único color de la capa, cada pocos segundos) para vetas y estrellas |
| Peso | Cada región pesa 2-3 MB de VRAM (864 × alto total × 4 bytes). Solo hay una región cargada a la vez (se reemplaza en el cruce de sala). En disco los PNG son muy pequeños (bandas planas) |
| Desaturación | Las capas de fondo reciben el material de desaturación de la sala igual que el terreno (biblia 3.3). Las luces del fondo (luna, ventanas, claraboyas) no |
| Cambio de región | `world.gd` mantiene un `Backdrop` activo por región. Al cruzar de región o de modo (exterior/interior) hace un fundido de 0,6 s (misma duración que la desaturación) entre el actual y el nuevo. No se cargan dos a la vez: el fundido usa el nuevo a alpha 0 hasta que está listo, y el antiguo se libera al terminar |

Hoy existe **un solo** `ParallaxBackground` con cinco capas dibujadas con polígonos (cielo, colinas, niebla, ruinas, árboles). Sale tal cual como fondo del Umbral (es decir, se convierte a PNG por el generador y se compara con la captura), y las otras cinco regiones reciben el suyo.

### 4.2 Fondos por región

Convención: factor de desplazamiento `(x, y)` respecto de la cámara (0 = fijo; 1 = igual que el juego). Los colores usan los códigos de la paleta ampliada.

#### El Último Umbral (exterior, crepúsculo)

| Capa | Factor | Tamaño | Qué dibuja | Colores | Animación |
|---|---|---|---|---|---|
| 1 Cielo | (0, 0) fijo | 864×192 | Crepúsculo en cuatro bandas planas (`1` arriba, luego `a`, `b`, `c` en el horizonte); luna incompleta; una docena de estrellas | `1 a b c` + luna `8`, estrellas `4` | Tres estrellas parpadean (2 fotogramas cada 2 s) |
| 2 Colinas y muralla | (0,15; 0,10) | 864×128 | Colinas lejanas y la silueta de la muralla con almenas rotas | `1 2`, calima `a` en el borde alto | Ninguna |
| 3 Tejados y humo | (0,35; 0,12) | 864×176 | Tejados de chabolas, chimeneas, una atalaya | `1 2`, ventanitas `b` (pequeñas, 2×3 px) | Humo de tres chimeneas: sprite de 4 fotogramas, 8 px/s |
| 4 Postes y árboles muertos | (0,60; 0,20) | 864×224 | Postes con banderines, dos árboles muertos, una carreta volcada lejana | `1 2 3`, contorno `1` | Banderines: 2 fotogramas, balanceo lento |
| Efecto: niebla baja | (0,28; 0,12) | 864×64 | Tres bandas semitransparentes | `a` al 15 % de opacidad | `autoscroll` 6 px/s |
| Primer plano | (1,3; 1,0) | 864×64 | Hierba alta y vigas en silueta casi negra, semitransparentes donde tapan | `0 m` | Hierba: balanceo de 1 px |

El diseño cumple el pilar "silueta contra luz": las siluetas oscuras se recortan contra la franja `c` del horizonte. Es el cuadro más cálido del juego (ficha 5.1 de la biblia). **Equivale a las cinco capas actuales**: cielo con estrellas y luna, colinas, niebla, ruinas con ventanas y árboles.

#### El Cinturón Yermo (exterior, mediodía lavado)

| Capa | Factor | Tamaño | Qué dibuja | Colores | Animación |
|---|---|---|---|---|---|
| 1 Cielo | (0, 0) | 864×192 | Cielo blanquecino sin sol, con nubes planas y largas | Bandas `3 4 8`, nubes `8` | Nubes lentas (`autoscroll` 3 px/s) |
| 2 Colinas en terraza | (0,15; 0,10) | 864×128 | Cadena de colinas escalonadas en bancales | `2 3`, calima `7` | Banda de calima que deriva (`autoscroll` 4 px/s) |
| 3 Torres de riego y molinos | (0,35; 0,12) | 864×192 | Torres de riego, acueductos secos, molinos sin aspas | `1 2` | Una aspa rota que cuelga y se balancea (2 fotogramas) |
| 4 Cercas, espigas y andamios | (0,60; 0,20) | 864×160 | Cercas, espigas muertas, algún andamio suelto, un espantapájaros lejano | `1 2 3`, espigas `7` | Espigas: ondulación de 1 px en ráfagas (viento) |
| Primer plano | (1,3; 1,0) | 864×64 | Tallos secos | `0 5` | Se inclinan con las ráfagas |

El viento es el protagonista: las tres animaciones comparten el mismo reloj de ráfaga (una señal global `gust` cada 6-9 s), de modo que cielo, espigas y primer plano se mueven a la vez.

#### El Archivo (interior monumental)

| Capa | Factor | Tamaño | Qué dibuja | Colores | Animación |
|---|---|---|---|---|---|
| 1 Pared de la nave | (0,05; 0,05) | 864×288 | Pared con ventanales altos y arcos ciegos | `1 2`, ventanales `3` | Haces de luz de los ventanales (cuñas aditivas, sección 7) |
| 2 Estanterías en perspectiva | (0,20; 0,10) | 864×256 | Filas de estanterías-torre en siluetas muy oscuras | `0 1` | Ninguna |
| 3 Arcos y columnas con velas | (0,45; 0,15) | 864×288 | Arcos, columnas, candelabros altos | `1 2`, velas `b c` | Velas: 2 fotogramas, parpadeo irregular |
| 4 Escaleras y pasarelas | (0,70; 0,20) | 864×224 | Escaleras de caracol, pasarelas, un balcón | `1 2 3` | Ninguna (poco movimiento a propósito) |
| Primer plano | (1,4; 1,0) | 864×96 | Cortinajes y lámparas colgantes cortados por el borde | `0 1`, lámpara `a` | Lámpara: balanceo de 2 px, 4 s |

Silencio visual: solo se mueven velas, motas y haces. El contraste con el Cinturón ventoso es lo que se busca (ficha 5.3 de la biblia).

#### Las Minas del Origen (interior oscuro)

| Capa | Factor | Tamaño | Qué dibuja | Colores | Animación |
|---|---|---|---|---|---|
| 1 Negro con puntos | (0,10; 0,05) | 864×200 | Fondo casi negro con puntos de mineral lejano | `0`, puntos `f g` | Centelleo lento: cada punto cambia de tono cada 4-8 s (cambio de paleta cíclico) |
| 2 Pared de roca con vetas | (0,30; 0,10) | 864×288 | Roca estratificada con vetas luminosas | `0 1 2`, vetas `f g` | Las vetas laten con 3 fotogramas (0,3 Hz); más rápido junto a un Eco (sección 6.10) |
| 3 Vigas y raíles | (0,60; 0,15) | 864×224 | Puntales de madera, raíles en perspectiva, una vagoneta lejana | `1 2 5` | Ninguna |
| Primer plano | (1,3; 1,0) | 864×96 | Estalactitas y cadenas en silueta | `0` | Cadenas: balanceo de 1 px |

Solo tres capas de escena: el poco parallax es una decisión de la biblia (la oscuridad esconde el resto) y ahorra producción.

#### La Costa Retenida (exterior, cielo tormentoso)

| Capa | Factor | Tamaño | Qué dibuja | Colores | Animación |
|---|---|---|---|---|---|
| 1 Cielo con nubes | (0,05; 0,05) | 864×192 | Cielo en bandas con nubes rápidas y una rendija de luz fría | `2 3 4`, rendija `9 h` | Dos bandas de nubes con `autoscroll` a 10 y 16 px/s |
| 2 Mar y horizonte | (0,15; 0,08) | 864×96 | Mar con horizonte y rocas lejanas | `e f v`, espuma `9` | Olas: 2 fotogramas, un destello de espuma que cambia de sitio |
| 3 Acantilados con asentamientos | (0,35; 0,12) | 864×224 | Acantilados lejanos con casas encaladas y un faro apagado | `1 2`, casas `8`, ventanitas `b` | Gaviotas (silueta de 2 fotogramas) que cruzan cada 20-30 s |
| 4 Mástiles, redes y velas | (0,60; 0,20) | 864×200 | Mástiles, redes, velas rasgadas, anclas | `1 2 3` | Velas rasgadas: ondulación de 2 fotogramas |
| Primer plano | (1,3; 1,0) | 864×64 | Cuerdas y espuma | `0 9` (espuma al 50 %) | Espuma: desplazamiento rápido horizontal |

#### La Herida (exterior sin origen)

| Capa | Factor | Tamaño | Qué dibuja | Colores | Animación |
|---|---|---|---|---|---|
| 1 Blanco | (0,05; 0,05) | 864×192 | Blanco que degrada a gris | `w`, `y` (bandas planas) | Ninguna |
| 2 Edificios mal recordados | (0,20; 0,08) | 864×224 | Siluetas planas de edificios de las otras regiones: una torre de riego sin detalle, una estantería-torre, un arco, un mástil | `y` un solo tono | Ninguna; se solapan con transparencia |
| 3 Bloques flotantes | (0,50; 0,15) | 864×224 | Bloques planos suspendidos | `x y` | Flotan: desplazamiento vertical de 1 píxel cada 3-5 s |
| Primer plano | Ninguno | | El primer plano sería "algo" | | |

La resolución de la capa 2 y 3 baja con la sala (R1, R2, R4, sección 3.7): se generan las tres versiones. En las salas de R4 las siluetas se reducen a bloques de 4×4.

### 4.3 Interiores sin cielo

Las salas sin cielo (Cisterna, Galerías, Aljibe, Chimenea, Granero, todas las del Archivo, las Minas, las casas de la Costa) no usan el fondo exterior. Hoy `has_sky = false` oculta el fondo y se queda un color plano. Propuesta: tres elementos apilados.

| Elemento | Qué es | Cómo se hace |
|---|---|---|
| **Pared trasera** | Capa de baldosas `m` y `h` detrás del jugador (sin colisión), del tileset de la región. Da forma y escala a la sala | Una segunda capa de `TextTileMap`; la letra `m` rellena y `h` salpica vanos. El generador de salas puede rellenar automáticamente la pared trasera de las celdas vacías interiores (opción `pared_trasera: true`), en vez de pintarla a mano |
| **Siluetas de interior** | Dos capas de parallax (factor 0,2 y 0,45) con la arquitectura lejana de la sala | Seis siluetas reutilizables (tabla siguiente) que cambian de rampa con la región |
| **Degradado base** | Bandas verticales de 16 px bajo todo | Una textura de 1×486 estirada, una banda por tono de la rampa |

Las seis siluetas (864×256 cada una, dos capas por silueta):

| Silueta | Contenido | Se usa en |
|---|---|---|
| I1 Bóveda de cañón | Arcos de medio punto repetidos cada 96 px, con nervaduras | Cisterna, Galerías, Aljibe, naves del Archivo |
| I2 Arcadas con pilares | Pilares gruesos y arcos rebajados | Archivo (sala de lectura), Costa (pueblo interior) |
| I3 Vigas y puntales | Armazón de madera: vigas, cruces de San Andrés, pajar | Granero, Almiar, Minas con apeos, Casa de las Redes |
| I4 Roca y raíles | Estratos de roca y raíles en perspectiva | Minas |
| I5 Muro con ventanas altas | Pared con ventanas y haces | Chimenea, Archivo, Rellano de la Vela |
| I6 Blanco con huecos | Bloques planos blancos con huecos negros | Herida |

**Mezcla en las zonas de transición.** Una sala de frontera se compone con la capa lejana de una silueta de la región A y la capa media de la región B (por ejemplo, Pozos Blancos: I1 del Archivo lejos y I3 de granero cerca, en rampa del Archivo). La biblia pide que las regiones se conecten geográficamente; aquí el fondo lo hace sin dibujar nada nuevo.

**Salas interiores con ventana al exterior** (el Rellano de la Vela del Umbral, que da vista al mar; la Cornisa de Sal): usan un fondo exterior parcial. Se declara `backdrop = "umbral"` más `ventana = rect`, y el fondo exterior se recorta con una máscara (un `Rect2` en la escena) detrás de la pared trasera. Es el único caso que necesita máscara; si no compensa, se resuelve con una pared trasera que tiene un hueco con el cielo dibujado en la propia hoja (solución estática, más barata).

### 4.4 Presupuesto

| Concepto | Cantidad | VRAM por región |
|---|---|---|
| Umbral, Cinturón, Costa | 4 capas + efecto + primer plano | 2,7 a 3,0 MB |
| Archivo | 4 capas + primer plano | 3,4 MB |
| Minas | 3 capas + primer plano | 2,6 MB |
| Herida | 3 capas (x3 resoluciones, pero se carga una) | 2,0 MB |
| Interiores (6 siluetas) | 6 × 2 capas | 1,8 MB cada una (una activa por sala) |

La suma de lo cargado a la vez no pasa de 6 MB. Es una cuarta parte de lo que supondría la estimación de la tira de dos pantallas del pipeline (13 MB por región), y se consigue con tiras de una pantalla y alturas ajustadas por capa.

---

## 5. Props y decorado

### 5.1 Formato, manifiesto y colocación

Hoy el decorado son 13 piezas en un lienzo único de 48×64, colocadas con un marcador de una letra y una tabla `DECOR` (fotograma, cuelga, `z_index`). Propongo conservar la idea y ampliarla en tres cosas.

**1. Las 13 letras actuales pasan a ser roles, como el terreno.** Son justo los motivos transversales de la biblia (apartado 6): cadenas, estandartes, arco ciego, marcas, y los demás. La letra dice el rol y la región decide el dibujo.

| Letra | Rol | Umbral | Cinturón | Archivo | Minas | Costa | Herida |
|---|---|---|---|---|---|---|---|
| `Y` | Árbol / alzado vertical grande | Árbol muerto | Espantapájaros alto o álamo seco | Estantería-torre (apilable) | Puntal doble | Mástil | Árbol de un solo tono |
| `U` | Columna | Columna rota | Poste de acueducto | Columna con vela | Columna de apeo | Contrafuerte | Columna sin capitel |
| `H` | Vegetación baja (delante) | Hierba amarilla | Espigas secas | Pila de papeles | Hongos | Hierba rasa y algas | Ninguna (sustituida por nada) |
| `Z` | Matorral | Zarza | Zarza seca | Cesto de papeles | Cristal pequeño | Liquen | Ninguno |
| `K` | Restos (delante) | Huesos y escombros | Paja y astillas | Libros caídos | Escombro de roca | Algas y conchas | Fragmentos planos |
| `F` | Estandarte / colgante de tela | Estandarte remendado | Espantapájaros colgado | Cortinaje | Tarjeta de turno | Vela rasgada | Rectángulo plano |
| `N` | Cadenas colgantes | Cadena de pozo | Cadena de arado | Cadena de archivo | Cadena de ascensor | Cadena de ancla | Cuerda sin eslabones |
| `X` | Estatua | Estatua decapitada | Mojón con rostro | Busto sin nombre | Cantero de piedra | Figura de proa | Estatua plana |
| `V` | Mojón | Mojón de piedras | Mojón de los caminos | Hito de lectura | Hito de la mina | Baliza | Mojón plano |
| `L` | Poste | Poste de señal | Poste con huellas | Atril | Poste con farolillo | Poste de red | Poste plano |
| `M` | Farol | Farol | Farol de camino | Lámpara de aceite | Farolillo de la Orden | Farol de Descreído | Farol sin llama |
| `D` | Arco ciego | Arco de muro | Acueducto | Bóveda | Boca de mina | Puerta de muralla | Arco sin nada |
| `q` | Enredadera / colgante vegetal | Enredadera | Hiedra seca | Papel colgado | Raíces | Algas colgantes | Nada |

**2. Piezas específicas por lista de props.** Para las piezas únicas de cada región no hay letras. Se añade un archivo de texto por sala, `sala.props`, con una línea por pieza: `id x_baldosa y_baldosa [espejo] [z]`. Ejemplo: `chabola_a 12 19` o `huellas_botas 44 20 espejo`. Es texto legible, versionable y revisable, y no agota el alfabeto de la leyenda. `room.gd` lo lee con una función de 20 líneas y busca `id` en el manifiesto.

**3. Manifiesto y hojas.** Una hoja por región (`decor_<región>.sprite`) con **celda de 64×64** (anclaje en la base, centrado, múltiplos de 8, como el resto) y una hoja `decor_grande` compartida con **celda de 128×128** para piezas mayores (chabolas, árboles grandes, molinos, faros). El manifiesto es un cuadro de texto `art/source/props.txt` con una línea por pieza: `id hoja fotograma ancho alto z cuelga rompible golpes`. El generador lo valida contra la hoja (tamaño que cabe, anclaje correcto) y emite la tabla que consume `room.gd`.

| Convención | Valor |
|---|---|
| Capa `F2` | `z_index = -2`: fondo cercano (arcos, molinos, graneros, claraboyas) |
| Capa `F1` | `z_index = -1`: detrás del jugador (la mayoría) |
| Capa `D1` | `z_index = 1`: delante del jugador (hierba, huesos, cortinajes cortos) |
| Colisión | Ninguna en el decorado. Las excepciones (plataformas, muros que se rompen) no son decorado, son mecánicas (sección 6) |
| Rompible | Se coloca como `BreakableProp` (caja, barril, urna ya existen); no suelta nada salvo que el diseño lo marque; el sprite cambia a "roto" 0,2 s y se desvanece |
| Animación | Hasta 4 fotogramas por pieza, en columnas contiguas de la misma fila |
| Variante | Cada pieza puede tener 2-3 variantes (se elige por `hash2(x, y)`); cuentan como una pieza |

### 5.2 Reglas de estilo para props

| Regla | Detalle |
|---|---|
| Valor | Rango 1-3 de la rampa, con tono 4 solo en un borde o una luz. Los props nunca compiten con el labio de luz del terreno |
| Silueta | La silueta debe leerse en gris. Se comprueba con la prueba de escala de grises |
| Rojo | Ningún `t` ni `u`. Para tela remendada o de espantapájaros se permite `r` y `s` (ver pregunta 5). **Hoy el estandarte `F` y el poste `L` incumplen esta regla** y se corrigen en la fase A |
| Ámbar | Solo donde hay calor humano (luz, ventana, ascua) |
| Azul | Solo en lo que es recuerdo o habilidad: sellos del Archivo, mineral, agua. Nunca en un prop de peligro |
| Rotura | Los rompibles tienen una grieta visible o están claramente "al borde" de romperse (caja con tablas sueltas, barril con aro flojo) |
| Rastro humano | Todo prop de una región habitada lleva un indicio de uso: huellas, cuerda, parche, marca de tiza |
| Contenido | Un prop que cuenta algo del canon lleva la pista en el dibujo (el delantal de Eulalia, el peine de Elvira), no en un cartel |

### 5.3 Tablas por región

Columnas: `Marcador` (letra del rol o `.props`), `Tamaño` en píxeles, `Capa` (`F2`, `F1`, `D1`), `Rompible`, `Qué cuenta` y `Reutilizable` (con qué rampa y en qué región se repite).

#### El Último Umbral (17 piezas)

| Prop | Marcador | Tamaño | Capa | Rompible | Qué cuenta | Reutilizable |
|---|---|---|---|---|---|---|
| Chabola de tablas (fachada) | `.props` | 96×64 | F1 | No | Diez familias remendaron su tejado con lo que tenían | Cinturón (barracas de peón), con rampa de paja |
| Toldo de lona remendada | `.props` | 64×24 | F1 | No | La lona es una vela vieja del Rellano: alguien la ató con cuerda | Costa (tendederos), con rampa fría |
| Hoguera de refugiados | `.props` | 32×24 | F1 | No | Quien la cuida aún recuerda; es el único fuego del Umbral que nadie apaga | Costa (braseros), Minas (hogar de la Colonia) |
| Banderines remendados | `F` | 48×40 | F1 | No | Cada banderín es un paño de una casa distinta | Costa (velas rasgadas), Archivo (cortinajes) |
| Pozo con cadena | `.props` | 32×40 | F1 | No | Cadena de pozo, motivo transversal | Cinturón (brocal), Costa (aljibe) |
| Muro de nombres de tiza | `.props` | 48×48 | F1 | No | Los nombres de los desaparecidos; tiene dos fotogramas: el segundo, con más nombres, aparece en el acto IV | Cinturón (grabados en postes), Archivo (lomos), Herida (líneas borradas) |
| Carro volcado | `.props` | 64×32 | F1 | No | La barricada de carros que no sirvió. Sustituye al polígono actual de `SetDressing` | Cinturón, Costa |
| Saco reventado | `.props` | 24×16 | D1 | 1 golpe | Grano que se pudre; no suelta nada | Cinturón (almiar), Minas (saco de mineral) |
| Mesa de doce cuencos | `.props` | 48×24 | F1 | No | Doce cuencos para una mesa que fue de más; hay uno de menos en un lado | Costa (Altar de Sal) |
| Cordel de Aldara con nudos | `.props` | 64×32 | F1 | No | Un nudo por Nombre no sostenido; un nudo oscuro extra. Dos fotogramas (apretado, flojo) | Único |
| Fragua y yunque | `.props` | 56×40 | F1 | No | La fragua de Garrán; brasas encendidas | Minas (Taller de Dola), con rampa fría |
| Cuervo posado | `.props` | 12×12 | F1 | No | El único animal vivo: silueta, 2 fotogramas | Cinturón, Costa (gaviota) |
| Árbol muerto grande | `Y` | 96×96 | F2 | No | El árbol del primer pantallazo; ramas en cruz | Cinturón (álamo seco) |
| Vela votiva del Rellano | `.props` | 8×16 | F1 | No | Una vela encendida por cada Nombre; texto de la vela | Archivo (velas), Costa (balizas) |
| Cartel de salida | `L` | 32×48 | F1 | No | "Cuenta los peldaños para volver" | Cinturón (poste de aviso) |
| Barricada de carros | `.props` | 80×48 | F1 | No | La muralla de los refugiados | Cinturón, Costa (empalizada) |
| Jirón de la Orden | `F` | 32×48 | F1 | No | Detrás del Estandarte: el último trapo de quien mandaba | Archivo (cortinaje) |

#### El Cinturón Yermo (17 piezas)

| Prop | Marcador | Tamaño | Capa | Rompible | Qué cuenta | Reutilizable |
|---|---|---|---|---|---|---|
| Espantapájaros | `Y` | 32×56 | F1 | No | Sigue en pie y mira el campo vacío. Delantal de rojo apagado `s`, nunca `t` | Umbral (muñeco de las barricadas) |
| Espantapájaros con el delantal de Eulalia | `.props` | 32×56 | F1 | No | El Nombre Eulalia Ferrán; el delantal azulado de tela cuidada es la única pieza con color vivo del campo gris | Único |
| Espiga muerta | `H` | 16×24 | D1 | No | El cultivo que nadie recuerda | Costa (hierba rasa) |
| Cerca de estacas | `.props` | 64×24 | F1 | No | Marca de lo que alguien quiso guardar | Umbral, Costa |
| Molino sin aspas | `.props` | 96×96 | F2 | No | "Aspas rotas": dos aspas sueltas que cuelgan | Costa (faro apagado), con rampa |
| Cubo de la rueda | `.props` | 24×24 | F1 | No | Lo que sube y baja en la Torre de Riego; es el objeto de la mecánica M7 | Minas (cangilón) |
| Acequia seca | `.props` | 64×16 | F1 | No | El cauce con el fondo agrietado; con el Manantial se rellena | Cisterna (canal) |
| Almiar | `.props` | 48×32 | F1 | No | El almiar donde se pelea; la paja amarillenta `7` | Umbral (granero) |
| Carreta de heno rota | `.props` | 72×40 | F1 | No | La carga de la última cosecha | Umbral |
| Granero a medio caer | `.props` | 112×80 | F2 | No | Granero Sin Techo; las vigas al aire | Costa (casa de redes) |
| Andamio (puntal + cuerda) | `.props` | 16×64 | F1 | No | Soporte de un tablón `S`; cuerda con nudo | Minas (puntales) |
| Cuerda con polea | `N` | 16×48 | F1 | No | La cuerda de la Rampa de Servicio (cuelga) | Costa (ancla) |
| Mojón de los caminos | `V` | 16×24 | F1 | No | "Camino de los Mojones": nombres grabados en el mojón | Costa, Archivo |
| Cruz de la Ermita | `.props` | 40×64 | F1 | No | La capilla del Cruce; Gaspar | Costa (cruz de marea) |
| Huellas de botas | `.props` | 48×4 | F1 | No | Las huellas de Eulalia que guían el Campo Gris (P10) | Único |
| Mesa del Cruce del Pan | `.props` | 56×24 | F1 | No | Tres sitios, tres rayas de tiza que se borran | Costa (mesa de redes) |
| Parche gris (borde) | `.props` | 32×16 | F1 | No | Decal de borde recto en la hierba junto al parche; remata el contraste | Archivo (borde del pasillo en blanco) |

#### Cisterna, Galerías y Aljibe (transición húmeda, 7 piezas adicionales)

| Prop | Marcador | Tamaño | Capa | Rompible | Qué cuenta | Reutilizable |
|---|---|---|---|---|---|---|
| Columna con musgo | `U` | 24×64 | F1 | No | Bóveda que se sostiene sola | Archivo (columna), Minas (apeo) |
| Goteo desde el techo | `.props` | 8×24 | F1 | No | Animado (4 fotogramas); el sonido de la sala | Minas |
| Rejilla de desagüe | `.props` | 32×16 | F1 | No | Sala de agua que ya no se vacía | Costa |
| Barril de la Orden | `O` | 24×32 | F1 | 2 golpes | Del Aljibe; marca de la Orden tachada | Minas |
| Caja de provisiones | `Q` | 24×24 | F1 | 1 golpe | Provisión que no llegó a los guardias | Todas |
| Cadena del rastrillo | `N` | 8×48 | F1 | No | Los rastrillos del Aljibe; coincide con la reja de arena (6.9) | Costa |
| Esqueleto apoyado | `K` | 32×24 | D1 | No | Alguien esperó aquí un relevo | Minas (Fila de Espera), Archivo (Pasaje de las Llaves) |

#### El Archivo (18 piezas)

| Prop | Marcador | Tamaño | Capa | Rompible | Qué cuenta | Reutilizable |
|---|---|---|---|---|---|---|
| Estantería-torre (módulo) | `Y` apilable | 48×48 | F1 | No (es de M10 si se marca `k`) | Cuatro a seis módulos forman la torre; los lomos ordenados por colores son el orden que la Desmemoria borra | Herida (módulo plano) |
| Estantería baja | `.props` | 48×32 | F1 | No | Sección de Linajes: contenido dado por perdido | Minas (estante de herramientas) |
| Pupitre de escriba | `.props` | 40×32 | F1 | No | El pupitre de Gaspar; tintero y pluma | Herida (pupitre de ceniza) |
| Atril | `L` | 24×40 | F1 | No | Libro abierto con renglones que se pierden | Costa (atril de ofrendas) |
| Candelabro de pie | `M` | 16×48 | F1 | No | Vela con halo ámbar pequeño | Umbral, Costa |
| Lámpara de aceite colgante | `.props` | 16×32 | D1 | No | Luz estable y pequeña | Minas, Costa |
| Libros apilados | `K` | 24×16 | D1 | 1 golpe (se desparraman) | Lo que alguien dejó sin devolver | Todas |
| Libro que respira | `.props` | 16×12 | F1 | No | Animado de 2 fotogramas: el único ser vivo del Archivo | Único |
| Paloma disecada | `.props` | 12×12 | F1 | No | La fauna del Archivo | Costa (gaviota) |
| Sello de cera gigante | `.props` | 64×64 | F2 | No | El sello del Claustro de la Tinta; en azul cuando el sello está activo | Herida (sello sin color) |
| Runa de sello | `.props` | 24×24 | F1 | No | Azul emisivo; sala de sellado | Minas (mineral) |
| Cadena de archivo con candado | `N` | 8×64 | F1 | No | Libros encadenados | Costa (ancla) |
| Marco sin retrato | `.props` | 40×56 | F1 | No | El Retrato Ausente: marco, clavo y sombra | Herida |
| Cortinaje | `F` | 32×96 | D1 | No | Cae en primer plano; semitransparente | Costa (vela), Herida |
| Haz de claraboya | `.props` | 48×192 | F2 | No | Cuña de luz aditiva, con polvo | Umbral (rayo por tejado) |
| Silla de extracción | `.props` | 40×56 | F1 | No | La sala del crimen; cadenas en los reposabrazos | Herida |
| Escalera de caracol (decorado) | `D` | 48×96 | F1 | No | El decorado sobre la plataforma real (S/p) | Minas (escalera de pozo) |
| Estantes en blanco | `.props` | 48×48 | F1 | No | Los lomos sin título: el borrado hecho forma | Herida |

#### Las Minas del Origen (17 piezas)

| Prop | Marcador | Tamaño | Capa | Rompible | Qué cuenta | Reutilizable |
|---|---|---|---|---|---|---|
| Puntal doble | `Y` | 64×48 | F1 | No (M10 si es `k`) | El apeo que sostiene lo que se cavó | Cinturón (andamio), Costa (pilote) |
| Raíles (tramo) | `.props` | 64×8 | F1 | No | "Los raíles bajan siempre": dos pendientes en las bajadas | Costa (muelle) |
| Vagoneta | `.props` | 48×32 | F1 | No | Carga que no se pudo mover. La versión móvil es de M7 | Costa (carretilla) |
| Pico clavado | `.props` | 16×24 | F1 | No | La marca de quien dejó de cavar | Cinturón (azada) |
| Farolillo de la Orden | `M` | 12×20 | F1 | No | Ámbar tenue; halo pequeño | Archivo, Costa |
| Cristal grande | `.props` | 24×40 | F1 | No | Mineral luminoso (emisivo `f g`); halo azul de 48 px | Archivo (sello), Herida (cristal plano) |
| Racimo pequeño de cristal | `Z` | 16×16 | F1 | No | Los dedos de la vena | Todas con rampa azul |
| Hongo luminoso | `H` | 16×24 | D1 | No | Vida lenta: `o n` más un destello `g` | Cisterna |
| Estalactita | `.props` | 16×48 | D1 | No | Primer plano; silueta casi negra | Todas las cuevas |
| Cadena de ascensor | `N` | 8×128 | F1 | No | La Cuerda de Mil Nudos | Costa (ancla) |
| Esqueleto sentado | `K` | 32×40 | F1 | No | La Fila de Espera: tres variantes mirando el mismo muro | Archivo, Cisterna |
| Tarjeta de turno | `F` | 24×16 | F1 | No | "Estoy bien" escrito en cada nudo; tarjetas que cuelgan | Herida |
| Tallas en la viga | `.props` | 32×8 | F1 | No | Nombres tallados en las vigas | Cinturón (postes), Costa |
| Arco del Archivo enterrado | `D` | 64×80 | F2 | No | El nexo con la superficie: un arco de piedra clara en la roca | Único |
| Trono hundido | `.props` | 64×64 | F1 | No | Casimar y sus aplausos | Herida (trono plano) |
| Charco reflectante | `.props` | 48×8 | F1 | No | Animado (2 fotogramas); refleja el cristal | Cisterna, Costa |
| Murciélago | `.props` | 12×8 | F1 | No | Silueta de 2 fotogramas que cruza | Cisterna |

#### La Costa Retenida (18 piezas)

| Prop | Marcador | Tamaño | Capa | Rompible | Qué cuenta | Reutilizable |
|---|---|---|---|---|---|---|
| Mástil con vela rasgada | `Y` | 24×96 | F1 | No | La vela se rompió donde dejaron de acordarse del viento | Umbral (poste con trapo) |
| Red colgada | `.props` | 64×48 | F1 | No | Redes tejidas por Mirena | Umbral (red de cuerdas) |
| Ancla de barco | `X` | 32×40 | F1 | No | Ancla y cadena; ancla vieja de la Orden | Minas |
| Faro apagado (fondo) | `.props` | 48×96 | F2 | No | El faro de las Velas visto desde lejos | Cinturón (torre de riego) |
| Farol de Descreído | `M` | 12×20 | F1 | No | Ámbar; quien lo enciende no cree en el archivo | Todas |
| Barca varada | `.props` | 96×32 | F1 | No | La barca de Mirena | Minas (barca del Cauce) |
| Remo | `.props` | 8×40 | F1 | No | Adorno junto a la barca | Único |
| Cortina de lino | `F` | 24×64 | F1 | No | Cortinas del Acantilado; se hinchan con el viento (4 fotogramas) | Archivo (cortinaje) |
| Tendedero con pañuelos | `.props` | 96×24 | F1 | No | El Sendero de los Pañuelos; animado | Umbral (banderines) |
| Letra de piedra de la playa | `.props` | 8×8 | F1 | No | Las letras de los nombres de la Playa | Archivo |
| Zapato pequeño | `.props` | 8×6 | F1 | Recogible | El zapato de Telmo (P30) | Único |
| Empalizada | `.props` | 64×48 | F1 | No | Defensa hacia el interior | Umbral, Cinturón |
| Ballesta montada | `.props` | 32×24 | F1 | No | Los Descreídos defienden lo que eligen olvidar | Umbral (atalaya) |
| Símbolo tachado de la Orden | `.props` | 24×24 | F1 | No | Lo opuesto a las marcas del Archivo | Único |
| Contrafuerte | `U` | 32×80 | F2 | No | Muro encalado a la altura del acantilado | Archivo |
| Cangrejo | `.props` | 8×6 | F1 | No | Animado de 2 fotogramas | Único |
| Cesto de pescado seco | `.props` | 16×16 | F1 | 1 golpe | Provisión | Todas |
| Círculo de cal | `.props` | 64×8 | F1 | No | El Rellano de Cal: círculo en el suelo (M6) | Herida (círculo plano) |

#### La Herida (16 piezas)

| Prop | Marcador | Tamaño | Capa | Rompible | Qué cuenta | Reutilizable |
|---|---|---|---|---|---|---|
| Arco sin juntas | `D` | 64×80 | F2 | No | "Un arco sin nada": el arco ciego sin textura | Único |
| Estantería en bloque | `Y` | 48×96 | F1 | No | La estantería de la Herida, sin lomos | Archivo (versión con lomos) |
| Árbol de un solo tono | `Y` | 64×96 | F2 | No | Árbol recordado mal: un tronco y una mancha | Umbral, Cinturón |
| Bloque flotante 2×2 | `.props` | 32×32 | F2 | No | Fragmentos de un edificio; animados con 1 px de vaivén | Único |
| Bloque flotante 4×4 | `.props` | 64×64 | F2 | No | Ídem, en R4 | Único |
| Hoja que se desprende | `.props` | 16×20 | D1 | No | Página que se separa del muro y se disuelve (4 fotogramas) | Archivo (páginas) |
| Línea de texto raspada | `.props` | 64×8 | F1 | No | Texto que se borra: los renglones que desaparecen | Archivo |
| Lomos sin título | `.props` | 48×32 | F1 | No | Estante sin escribir | Archivo |
| Silla colgada con máscara azul | `.props` | 24×40 | F1 | No | Las cinco sillas del Círculo; la máscara azul `g` es el único color | Único |
| Pupitre de ceniza | `.props` | 40×32 | F1 | No | El Scriptorium Sin Tinta | Archivo |
| Taza llena y taza volcada | `.props` | 12×12 | F1 | No | Los dos que dijeron "volveré mañana"; tonos ámbar (la única cosa cálida) | Único |
| Puerta que no existe (marco) | `.props` | 48×64 | F1 | No | El Eco Quieto abre una puerta que no hay | Único |
| Mesa de dos | `.props` | 56×24 | F1 | No | La Mesa de Dos | Único |
| Raya de nombre | `.props` | 32×8 | F1 | No | Cientos de nombres con una raya diagonal; tres variantes | Cinturón, Archivo |
| Farol sin llama | `M` | 12×20 | F1 | No | La lámpara sin llama (P38) | Archivo |
| Columna sin capitel | `U` | 24×64 | F1 | No | Arquitectura "recuerdo de una arquitectura" | Cisterna |

Total: **17 + 17 + 7 + 18 + 17 + 18 + 16 = 110 piezas**, de ellas 13 por rol y 97 con identidad propia. Si se descuentan las piezas ya hechas (13 de `decor.sprite`, caja, barril, urna y la inscripción), quedan unas **95 por dibujar o generar**. Coincide con la cifra pedida (unas 90).

### 5.4 Piezas apilables y de gran tamaño

| Pieza | Cómo se resuelve |
|---|---|
| Estantería-torre del Archivo (hasta 192 px) | Módulo de 48×48 que `room.gd` apila cuantas veces haya marcadores `Y` consecutivos hacia arriba (base, centro, remate: tres fotogramas). Evita una sprite de 192 px, y se puede variar la altura por sala |
| Chabola, granero, molino, faro (hasta 112×96) | Hoja `decor_grande` de 128×128 por celda. Son siempre `F2` o `F1`, sin colisión |
| Haces de claraboya | Cuñas de luz de 48×192 como sprites aditivos; no son decorado sino luz (sección 7.1) |
| Árbol del Ancla de una región, Piedras de lectura | Piezas singulares que se dibujan a mano (sección 6.10) |

### 5.5 Piezas reutilizables entre regiones con otra rampa

La reutilización se hace en el generador de props, no en el motor: un prop se define una vez con **rampas simbólicas** (`piedra`, `madera`, `tela`, `luz`, `vegetal`) y cada región da una paleta que las traduce. Los primeros candidatos:

| Familia | Piezas | Se reutilizan con rampa en |
|---|---|---|
| Contenedores | Caja, barril, urna, saco, cesto | Todas (la forma no cambia; cambian las marcas de la Orden: tachadas en la Costa, sin marcas en la Herida) |
| Luz portátil | Farol, farolillo, candelabro, lámpara | Todas menos la Herida (solo "farol sin llama") |
| Colgantes | Cadena, estandarte/cortinaje/vela, enredadera | Todas (tabla de roles, 5.1) |
| Piedra | Columna, estatua, mojón, arco | Todas |
| Madera | Poste, puntal, andamio, carro, barca | Umbral, Cinturón, Minas, Costa |
| Vida pequeña | Cuervo/gaviota, paloma, murciélago, cangrejo | Misma silueta con otra forma de ala |
| Restos humanos | Esqueleto sentado, huesos | Cisterna, Minas, Archivo |
| Escritura | Marcas de tiza, líneas raspadas, tarjetas | Umbral, Cinturón, Archivo, Minas, Herida |

Con esto el número de dibujos nuevos baja de 95 a unos **55 diseños únicos**, el resto son recolorados y variaciones de tamaño. El generador de props marca las piezas con `reutiliza: <id>` para no regenerarlas dos veces.

### 5.6 Qué se dibuja a mano (25 piezas singulares)

La biblia propone dibujar a mano solo lo singular. Mi lista, por orden de importancia narrativa:

1. Hito de Nombres del Umbral (grande, con los nombres de tiza).
2. Muro de nombres del Patio.
3. Árbol muerto grande del primer pantallazo.
4. Espantapájaros con el delantal de Eulalia.
5. Cordel de Aldara con nudos.
6. Ancla de cada región, seis variantes (6.10).
7. Piedra de lectura, seis variantes por región (6.5).
8. Marco sin retrato del Archivo.
9. Sello de cera gigante.
10. Arco del Archivo enterrado.
11. Trono hundido.
12. Barca de Mirena.
13. Faro apagado.
14. Símbolo tachado de la Orden.
15. Círculo de cal.
16. Sillas con máscara azul (cinco variantes del mismo diseño).
17. Puerta que no existe.
18. Taza llena y taza volcada.
19. Arco sin juntas.
20. Pared Raspada: tres variantes de raya.
21. Zapato pequeño de Telmo.
22. Libro que respira.
23. Puerta de región (6.9), seis variantes de un mismo diseño.
24. Muro tapiado (fila 8 del tileset del Umbral).
25. Escalera de los Nombres apagada (Sala de Aún).

Las demás son familias generadas por código con una forma maestra por familia.

---

## 6. Aspecto de las mecánicas de mundo y de los elementos jugables

### 6.1 Principios visuales de la interacción

Las doce mecánicas del diseñador de puzles se enseñan "sin texto": se ve el efecto, se ve la causa, se prueba sin riesgo. Eso es un problema de arte antes que de diseño. Propongo cinco reglas comunes, para que el jugador aprenda **una gramática** y no doce.

| Regla | Descripción |
|---|---|
| **R1. El testigo** | Toda causa y todo efecto remoto llevan una lamparilla pequeña de 6×6 px, el *testigo*. Apagado (gris `2`, sin halo): sin hacer. **Ámbar fijo** (`c` con una chispa `d` y halo de 16 px): hecho para siempre (marca permanente). **Ámbar que mengua en 3 pasos**: temporal, con cuenta atrás. El ámbar es "alguien lo recuerda" (pilar P1), así que el significado cuadra con la biblia |
| **R2. Forma antes que color** | Lo que se distingue por color se distingue también por forma, para quien no vea los colores. Las grietas frágiles son zigzags; las hondas, rombos; los canales llevan un símbolo grabado distinto (círculo, triángulo, rombo, cuadrado) |
| **R3. Lo interactuable lleva una marca de uso** | Una palanca con la empuñadura brillante por el roce, un botón abollado, una piedra con las hendiduras de la mano pulidas. Se lee como "alguien lo tocó muchas veces" |
| **R4. Aviso previo uniforme** | Todo ciclo y toda caída avisa con el mismo gesto: la pieza alterna dos fotogramas (el normal y el de un tono más claro) a ~12 Hz durante `warning_time` (mínimo 0,4 s) |
| **R5. Nada en rojo** | Ningún testigo, mecanismo ni pista en `t`/`u`. El rojo es peligro. **El diseñador propone "lamparilla roja" en el testigo de P02 y lacres de cera en P16: se sustituyen por ámbar apagado y cera ámbar oscura (`a b`)**, o se aprueba una excepción (pregunta 5) |

### 6.2 M2 · Grieta (muro frágil y suelo hondo)

| Estado | Frágil | Hondo |
|---|---|---|
| Quieto | Muro o suelo con **grietas en zigzag** claras (`8`, 1 px) y una "boca" negra (`0`) en el cruce de dos grietas. Cada 2-3 s cae polvo (1-2 partículas de `3`) | Roca con una **veta de rombos ámbar** (rombos de 3 px en `b`, con el centro `c`; unos 4 por baldosa, repartidos en diagonal). Sin polvo |
| Golpeado | Cada golpe pasa a la etapa siguiente de grietas (fila 8, columnas 0 a 5 del tileset) y suena hueco; chispa de polvo en el punto de impacto | Rebote con chispa `d` de 3 fotogramas; la veta parpadea. Sin cambio de etapa |
| Roto | La pieza entera se desintegra en 0,4 s: trozos de 3-4 px del tono de la baldosa que caen con gravedad, y desaparece | Con Excavar, igual; la veta se apaga en el último golpe |

Tamaño: múltiplos de 16, piezas rectangulares de 1×1 a 4×8 baldosas (una pieza es "un grupo de marcadores contiguos del mismo carácter", como define la mecánica). El generador forma la pieza con la baldosa `G` o `B` de la región (según el material de la pared) más el overlay de grietas: no hay un dibujo por región, hay uno por etapa que se compone encima.

El **suelo hondo** lleva la veta **en el labio de luz**: es lo único que cambia respecto del suelo normal, y se ve desde arriba. En pared, la veta recorre dos filas de la baldosa. En el muro tapiado inicial del Umbral (`ultimo_umbral`) la veta debe poder verse desde la primera pantalla.

### 6.3 M3 · Compuerta (reja, tablones, piedra, cal, puente)

Todas las compuertas llevan **su testigo y su símbolo de canal** grabados en el dintel (o en un lateral si es suelo). Tamaño: ancho 16 o 32 px, alto de 3 a 8 baldosas. Animación de 0,45 s en tres fotogramas (cerrada, a medias, abierta).

| Vestido | Cerrada | Abierta | Región |
|---|---|---|---|
| Reja | Barrotes verticales de 2 px en `3` cada 4 px, travesaño `2`, herrajes oxidados `b`, cadena que cae a un lado | Se recoge hacia arriba y deja dos baldosas de remate con barrotes cortos (como el rastrillo del Aljibe) | Todas; es la de la Orden |
| Tablones | Tres o cuatro tablas clavadas en cruz (`6 5`, clavos `4`), alguna rota | Las tablas caen a un lado y quedan como restos (`K`) | Umbral, Cinturón |
| Piedra | Losa `3 2` con el grabado de la Orden tachado; sin testigo propio (la activa un disparador lejano) | Se hunde en el suelo | Minas |
| Cal | Niebla blanca `8`/`9` casi sólida, con borde que vibra (2 fotogramas) | Se disipa en bandas horizontales | Costa, Herida |
| Puente | **Ausente**: solo el hueco, con el borde de los dos lados limpio | Aparece tablón a tablón (de un lado al otro, 0,45 s) | Cinturón, Archivo |
| Tablón de tinta (`fade_on_stand`) | `S` con una **mancha de tinta** `0 1` que lo cubre (6 px de grosor) | Al pisarlo, la mitad inferior se vuelve transparente con una trama 2×2 (0,6 s) y desaparece (1,2 s); vuelve a los 6 s con un parpadeo | Archivo, Herida |
| Un solo sentido (`one_way_side`) | Del lado que se abre: manilla y cerrojo visibles. Del otro: lisa, sin manilla, con el testigo visible | Igual | Todas |

Dos detalles de legibilidad: la compuerta cerrada nunca se confunde con un muro (lleva siempre el testigo y el símbolo, y su hueco tiene un dintel); y la **compuerta que se abre desde fuera de pantalla** muestra su testigo como lo único ámbar de la zona, de modo que se ve incluso de lejos.

### 6.4 M4 · Disparadores (palanca, placa, botón)

| Pieza | Tamaño | Aspecto | Estados |
|---|---|---|---|
| Palanca | 16×24 | Mango de hierro (`2 3`) en un zócalo de piedra (`3 2`); el pomo brilla `4` por el roce. Testigo de 6×6 sobre el zócalo | Arriba (sin accionar); abajo (accionada), 0,2 s de animación; el testigo pasa a ámbar fijo (permanente) o menguante (`toggle`) |
| Placa de presión | 32×4 (a ras de suelo) | Losa `3` con borde `1`, rebajada 1 px; sobre ella, en la pared, el testigo con cuenta atrás | Libre; pisada (baja 2 px y se enciende el testigo); tras soltarla, el testigo mengua en `hold_time` pasos |
| Botón en alto | 12×12 | Disco de bronce (`b c`, brillo `d` de 1 px) hundido en un marco `2`; **cuatro muescas en cruz** y una abolladura en el centro: es golpeable | Normal; hundido 2 px y testigo ámbar |

El diseñador pide que si el efecto cae fuera de pantalla, suene "su efecto en su posición" y salga un aviso. En arte: el **testigo parpadea una vez más grande** (ancho de halo de 16 a 32 px durante 0,5 s) cuando se acciona algo lejano, para que el ojo vaya al lado correcto.

### 6.5 M5 y M6 · Receptor y Piedra de lectura

**Receptor (nicho).** Hueco en la pared de 24×32 con la **silueta en relieve** (tono 1 sobre 2) de lo que espera: disco partido, guijarro con pico, círculo de cal, llave. La silueta es el único código; sin texto. Cumplido: el objeto aparece dentro, a tono ámbar apagado (`b`) y el testigo se enciende. En la **Puerta Sin Muro** (HER-02) los tres huecos (Cera, Piedra, Cal) se ven vacíos desde el Pilar de Lacre, como pide el mapa macro.

**Piedra de lectura.** Es una pieza singular (se dibuja a mano; 32×48): una piedra pulida (`3 4`) con la **sombra grabada** de una cosa (un pie alado, un cordel, una silla: la que cada piedra pide) en tono 1 y dos hendiduras de mano. Seis variantes de cuerpo, una por región, con la misma sombra:

| Región | Cuerpo de la piedra |
|---|---|
| Umbral | Piedra de cantero con un cordel anudado alrededor |
| Cinturón | Mojón de campo con una espiga grabada en la base |
| Archivo | Atril de piedra con un libro de piedra |
| Minas | Bloque de roca con una veta apagada |
| Costa | Piedra blanqueada de sal |
| Herida | Bloque plano sin juntas |

Estados, con una señal azul (el azul es habilidad, `g`):

| Estado | Imagen |
|---|---|
| Muda (sin Nombrar) | Opaca, sin brillo; las hendiduras oscuras |
| Atenta (con Nombrar) | Un píxel de `g` en cada hendidura, con un latido lento (0,5 Hz) |
| Eligiendo | Las hendiduras brillan fijas (`g`); el juego se pausa |
| Dicha | La sombra grabada se ilumina en `h`, 1,2 s |
| Resuelta | Azul fijo en las hendiduras y la sombra "llena" (relleno `f`) |
| Callada | Un parpadeo gris de un fotograma; luego, igual que Atenta |

La piedra es la **cerradura visible antes que la llave**: el jugador la ve en el Umbral y en el Mirador desde la primera visita, y debe leerse como "esto pide algo". Las hendiduras y la sombra lo hacen sin texto.

### 6.6 M1, M11 y M12 · Estado, ciclo y combinación

**M1 (marcas)** no se ve, pero su **consecuencia sí**: los objetos con marca permanente cambian de aspecto para siempre (el testigo ámbar fijo, la palanca abajo, la reja abierta con una película de polvo). Eso es "el mundo recuerda" hecho imagen.

**M11 (ciclo).** Todo lo que late usa el aviso uniforme de R4. Casos concretos:

| Ciclo | Imagen | Aviso |
|---|---|---|
| Tinta (4 s encendida / 3 s apagada) | Tablón de tinta que se apaga | La mancha de tinta se desvanece 0,5 s antes y sube el crujido de página |
| Soplo (5 s) | Cortinas y polvo del lado de donde viene el viento | Las cortinas se hinchan 1 s antes del cambio |
| Marea (40 s) | Agua alta y baja con espuma en el borde | Espuma y rumor 3 s antes |
| Ventana (6 s) | Puerta o ventana que aparece | La pieza alterna los dos fotogramas a 12 Hz durante 0,4 s |
| Pinchos que salen | Ya existen (`~` y `-`, periodo 2,4 s, 40 % activos) | Asoman 2 px, 0,4 s antes de salir |

**M12 (selector).** De 3 a 5 discos de 24×24 de piedra (`3`, borde `2`) con cuatro símbolos grabados de 12×12 en dos tonos (`3` sobre `2`); al girar, un tic de 1 fotograma (el símbolo se desplaza media baldosa). Los símbolos de cada puzle de observación son:

| Puzle | Símbolos |
|---|---|
| Surco Ciego (Cinturón) | espiga, hoz, pan, ojo |
| Sala de los Lacres (Archivo) | sello de rango, de copia, de borrado, vacío: **cera ámbar oscura (`a b`), no roja** |
| Faro de las Velas (Costa) | cuenco, cinta, peine (las ofrendas del altar) |

### 6.7 M7 · Plataforma sobre carril

| Variante | Tamaño | Aspecto | Región |
|---|---|---|---|
| Cangilón de la Torre de Riego | 24×24 | Balde de madera `6 5` con aros de hierro y una cuerda `7` al eje de la rueda; plataforma de una dirección en su borde superior (labio `b`) | Cinturón |
| Plataforma continua | 48×8 o 96×8 | Tablas `6 5` con travesaños y herrajes `3`, labio ámbar; **carril dibujado**: línea de clavos `3` cada 8 px y topes de 8×8 en los extremos | Cinturón, Costa |
| Ascensor de cadena | 64×8 + barandilla de 64×16 | Plataforma con barandilla baja y una cadena de 8×128 que sube; el montacargas lleva el testigo | Minas |
| Vagoneta | 48×32 | Cuerpo de madera y hierro, ruedas, carga de roca; viaja sobre raíles `p` | Minas |
| Barca | 96×32 | Casco de madera y una vela rasgada; el remo y Mirena a bordo | Costa |
| Silla colgada | 24×40 | Silla de madera sin pintar colgada de un cable, con una máscara azul `g` en el respaldo | Herida |

Reglas visuales: **nunca aplasta** (bordes redondeados, sin pinchos, sin puntas); el carril se ve siempre (el jugador debe saber hasta dónde va y cuándo vuelve); una plataforma "a demanda" muestra el testigo en el embarcadero. Las plataformas móviles se distinguen de las fijas por llevar **herrajes visibles y un travesaño inferior**.

### 6.8 M8, M9 y M10 · Corriente, luz y derribo

**M8 · Corriente.**

| Variante | Imagen |
|---|---|
| Lateral (Costa) | Cortinas de lino que se tienden hacia el lado del viento, y 8-12 partículas de 1×3 px en `4`/`9` que cruzan la zona |
| Lateral (Archivo, Herida) | Páginas sueltas de 3×4 px que cruzan; en la Herida, fragmentos planos `w y` |
| Ascenso | Páginas o polvo que suben, con 4 fotogramas de giro. En la Costa, el aire frío del acantilado: hilos de `9` |

Se anuncian con las mismas partículas **dos baldosas antes** de la zona, más separadas. Nunca en ámbar ni en rojo.

**M9 · Luz.**

| Pieza | Aspecto |
|---|---|
| Lámpara de grasa | 12×16; cuenco de hierro `2 3`, mecha. Apagada: cuenco oscuro, mecha negra. Encendida: llama ámbar de tres tamaños según lo que queda de los 60 s (grande, media, pequeña): la mecha se ve menguar. Halo con radio de 7 baldosas (112 px), según la mecánica |
| Plataforma revelada (`x`) | Con luz: baldosa normal. **Sin luz: un contorno punteado de 1 px en `1`** (la "sombra" de la plataforma, que el diseño pide ver desde el principio para que el jugador sepa que existe) |
| Aviso de apagado | Antes de apagarse una plataforma con el jugador encima: parpadeo del contorno 2 s y sonido de mecha |

**M10 · Derribo.**

| Etapa | Imagen |
|---|---|
| Quieto | Columna, estantería o puntal alto y estrecho con la **base cuarteada** (decal de grietas de la fila 8 en las dos baldosas inferiores) y una **sombra pintada en el suelo** inclinada hacia el lado en que caería: un decal de 48×8 en tono 1 |
| Crujido (0,5 s) | La pieza tiembla 1 px; polvo en la base; sonido |
| Caída (0,9 s) | Gira 90° sobre su base. Para no rotar por subpíxel, el generador precalcula **7 fotogramas** de rotación (0°, 15°, 30°, 45°, 60°, 75°, 90°) con el algoritmo de rotación de pixel art y se reproducen a 8 fps; así no hay deformaciones de pixel |
| Caído | Plataforma horizontal de una dirección con labio de luz; tiene el mismo sillar de la estantería por el canto |

### 6.9 Rejas de arena, puertas de región, puentes y ascensores

**Rejas de arena (sala de jefe).** Hoy `[` y `]` cierran la sala del jefe con un rastrillo. Propongo que se distingan de las compuertas de puzle por una sola cosa: **no llevan testigo**. Son más pesadas (barrotes de 3 px, herrajes de hierro oxidado, una cadena colgando) y se cierran con un destello breve `d` (un fotograma). Se enseña por contraste: una reja con testigo se abre con una palanca; una sin testigo no se abre más que venciendo.

**Puertas de región.** Los bordes entre regiones se señalan con un **arco ciego monumental** (64×96, capa F2) con un **glifo en la clave** de 12×12 que identifica a la región de delante:

| Región | Glifo en la clave del arco |
|---|---|
| Umbral | Círculo cortado (sol poniente) |
| Cinturón | Espiga |
| Archivo | Pluma |
| Minas | Pico |
| Costa | Ancla |
| Herida | Rectángulo vacío |

Dentro del arco se ve **una franja de 1 baldosa de ancho con el cielo o la luz de la región siguiente** (una pincelada del color de lo que viene). Es la única "puerta" que anuncia el cambio sin cartel. El nivel declara el glifo y el generador monta el arco; el tinte global empieza a interpolar 8 baldosas antes del borde.

**Puentes.** Tres familias, ninguna exclusiva de una región:

| Puente | Imagen |
|---|---|
| Pasarela de tablones | `S` continuas con barandillas decoradas (F1) de postes `5` y cuerda `7`. Pasarela de los Mensajeros, Cuesta del Segador |
| Puente de cuerda (Costa) | Tablones `S` colgados de dos cuerdas con nudos; se balancea 1 px a ráfagas |
| Puente de Cera (Archivo) | Plataforma `p` de piedra blanca con barandilla de hierro y velas votivas; es el pasaje largo hacia la Costa |

**Ascensores.** Los de las Minas (Cuerda de Mil Nudos) llevan la cadena de 128 px que sube, un testigo en cada descanso y barandillas bajas. Un ascensor "parado" tiene el testigo apagado; "en tránsito", ámbar fijo; "esperando", ámbar menguante (cuenta atrás de los 6 s del ciclo).

### 6.10 Anclas, Hitos, Piedras y peligros de región

**Ancla de Memoria.** Hoy hay una (`anchor_sheet.png`, 64×80, 8 fotogramas): monumento de piedra con tres runas ámbar, un cristal azul y llama ámbar, con musgo. Hay **34 Anclas** en el mundo; para que no se lean como "la misma estatua", se mantiene la silueta y el código de color (cristal azul + llama ámbar: la excepción deliberada de la biblia) y se cambian la **materia, el desgaste y el entorno**. No se redibuja: el generador (`tools/arte_ancla.js`, que ya existe) recibe una variante por región.

| Región | Variante | Qué cambia |
|---|---|---|
| Umbral | La actual | Musgo, runas vivas |
| Cinturón | Ancla de polvo | Pedestal con paja y arena acumuladas, grietas, runas con parte borrada; el cristal sigue vivo |
| Archivo | **Ancla "de tinta"** | Pergaminos enrollados alrededor del pie; las tres runas son lomos de libro; una pluma de hierro apoyada en la base |
| Minas | Ancla de roca | Hecha de la propia pared, bruta; cristal más grande, con vetas azules que lo conectan al muro |
| Costa | Ancla de sal | Piedra blanqueada, cadena de ancla enrollada, algas en la base; el cristal, con un reflejo cian |
| Herida | **Ancla sin nombre** | Piedra en neutros (`x y w`), sin musgo, sin runas; **el cristal y la llama conservan su color**, la excepción total: es el único objeto cromático de la sala |

Estados, para cada variante: apagada, encendida (los 8 fotogramas actuales) y "descansando" (el destello). El halo de 96 px y el charco de luz en el suelo (biblia 4.1) son comunes. Dentro del halo el sombreador **devuelve ~30 % del color** al terreno (pregunta 7 de la biblia).

**Hito de Nombres (Umbral).** Piedra grande del Patio de los Nombres (128×128 en `decor_grande`) con los 30 huecos para Nombres grabados (cada Nombre sostenido se enciende en ámbar `c`) y la inscripción de Linde. Tiene dos estados: apagado (inicio) y con los nombres que se hayan sostenido. Es una pieza dibujada a mano.

**Veta que late con el Eco.** En las Minas las vetas `f g` laten cada 3 s a tres fotogramas; junto a un Eco (a menos de 8 baldosas) laten al doble de rápido. Es la única reacción ambiental al Eco y refuerza que el azul es "memoria que te acompaña".

**Pinchos por región.** Hoy hay uno de hierro oxidado en 3 fotogramas de 16×16 (extendido, a medias, retraído). Se mantienen la punta clara roja (`u`) y la cadencia, pero el **cuerpo cambia por región** (la punta nunca: regla de la biblia 1.3):

| Región | Cuerpo del pincho | Nota |
|---|---|---|
| Umbral | Clavos de hierro oxidado sobre tablón (el actual) | Es el estándar |
| Cinturón | Estacas de madera y puntas de hoz | Madera `6 5` con la punta de hierro `u` |
| Archivo | **Plumas de hierro** y abrecartas en vertical | Elegante, forjado; cuerpo `2 3`, punta `u` |
| Minas | Púas de roca con un reflejo ámbar tenue en el cuerpo | En oscuridad, un tono `a` propio (regla de seguridad 4.1) |
| Costa | Anclas y garfios clavados; anzuelos | Hierro `2 3`, óxido `b` |
| Herida | **Triángulos planos** sin textura, `x` con la punta `u` | El único rojo de la sala; son los pinchos que "recuerdan" ser pinchos |

**Brasas.** Se tratan como luz y partícula, no como peligro: la hoguera del Umbral, la fragua de Garrán, el brasero de la Costa. Sprite de 4 fotogramas (`a b c d`) con halo ámbar de 32-48 px, parpadeo irregular y brasas que suben (partículas del Umbral, sección 7.5). Si el diseño necesitara **brasas dañinas** (suelo de carbones), se dibujarían con `s t u` como peligro (esta sí es una excepción legítima al "rojo solo en peligro") con aviso de 0,4 s (pregunta 11).

---

## 7. Iluminación y atmósfera

### 7.1 Técnica: sin iluminación dinámica pesada

La biblia (4.1) ya lo decide: **toda la luz es sprites aditivos precalculados con degradado en bandas**, no iluminación dinámica. Concreto:

| Elemento | Cómo |
|---|---|
| **Halo** | Un sprite circular con **cuatro bandas** de opacidad (aprox. 45 %, 30 %, 18 %, 8 % de dentro a fuera), `blend_mode = add`. El generador `tools/arte_halos.js` produce **un solo juego en blanco** (cinco tamaños: 48, 64, 96, 128 y 192 px de diámetro) y se tiñe con `modulate` (ámbar, azul, blanco cálido). No hace falta un PNG por color |
| **Charco de luz** | Elipse aplastada de 2 bandas bajo la fuente, sobre el suelo (capa `F1`); da anclaje a la luz. Solo en Ancla, hogueras y fragua |
| **Cuña de luz** (claraboya, ventana) | Trapecio vertical de 48×192 con dos bandas, aditivo, opacidad baja, con 6-8 motas de polvo dentro (partículas). Es lo que hace "monumental" al Archivo |
| **Parpadeo** | Cambio de escala (±1 px de radio) y de opacidad en pasos, con periodo irregular. Se programa con un `Tween` o con un reloj ruidoso determinista; sin sombreador |
| **Pulso** | Reliquias y Ancla: seno lento a 0,5 Hz en la opacidad, en pasos de 4 niveles para que no parezca un degradado suave |
| **`Light2D` de Godot** | Se puede usar `PointLight2D` solo con **sombras desactivadas** y textura de bandas propia, si hace falta la oscuridad (7.4). En el resto de salas, no |

Una norma de legibilidad: **ningún halo baja el valor de lo que ilumina**. Un halo solo suma. El jugador debe verse con y sin luz.

### 7.2 Luces por región

| Región | Fuente | Tamaño del halo | Color | Comportamiento |
|---|---|---|---|---|
| Umbral | Ancla; hoguera; fragua; faroles; ventanas de las chabolas | Ancla 192; hoguera 96; fragua 96; farol 64; ventana 32 | Ámbar; azul solo en el cristal del Ancla | Parpadeo suave; el Ancla pulsa. Crepúsculo: el cielo ya es la luz principal |
| Cinturón | Ancla; faroles escasos; hogueras raras | Ancla 192; farol 64 | Ámbar | Poco ámbar a propósito: el cielo lavado hace de luz |
| Archivo | Cuñas de claraboya; velas; lámparas de aceite; runas azules | Cuña 48×192; vela 48; lámpara 64; runa 48 | Blanco cálido, ámbar, azul tenue | Muy estables: sin parpadeo, salvo las velas. Silencio visual |
| Minas | Minerales; hongos; farolillos; resplandor del Caminante | Cristal 48 a 96; hongo 48; farolillo 64; Caminante 80 | Azul, verde azulado, ámbar | Latido lento; el resplandor del Caminante nunca se apaga (el diseño fija 2,5 baldosas de radio, 80 px de diámetro; la biblia proponía 64 de radio; ver pregunta 6) |
| Costa | Faroles de Descreídos; reflejos de mar; rendija de luz fría del cielo | Farol 64; rendija: cuña de 64×192 | Ámbar; blanco azulado | Los faroles parpadean con el viento (más rápido que en el Umbral) |
| Herida | Ninguna | | | **Sin halos**, salvo el Ancla y el Caminante. Luz blanca sin origen |

Relación entre luz y desaturación: **toda luz pequeña conserva su color en cualquier nivel** (una vela en una sala de nivel 2 sigue siendo ámbar). Lo que se desatura es lo iluminado. Es la misma lógica de la biblia 3.1: lo que alguien recuerda conserva el color.

### 7.3 Niebla y partículas por región

La niebla es una banda semitransparente que se desplaza por `autoscroll`, en dos posiciones posibles: **baja** (en el suelo, capa D1) o **de fondo** (entre capas de parallax). Las partículas siguen las reglas de la biblia (4.2): máximo 30 simultáneas por pantalla, 1-2 px, tonos de la rampa de la región, sin texturas propias (texturas de 1×1, 2×2, 3×3 y 4×4).

| Región | Niebla | Partículas (cuántas simultáneas) | Textura | Notas |
|---|---|---|---|---|
| Umbral | Baja, `a` al 15 %, 6 px/s | Brasas (8), ceniza (6), polvo en haces (4) | 1×1, 2×2 | Las brasas nacen de las hogueras, no del aire. Ascienden despacio |
| Cinturón | Calima de fondo (`7` al 12 %) | Polvo (8), briznas de paja (6), hojas secas (4) | 1×1, 2×1, 3×2 | Horizontales con ráfagas (el reloj `gust` compartido) |
| Archivo | Ninguna | Motas en haces (10), hojas de pergamino (4), polillas (3) | 1×1, 4×3 | Movimiento lento; el reposo es la firma |
| Minas | Vapor tenue bajo (`3` al 10 %) | Esporas (8), goteo (3), polvo de roca (6) | 1×1, 2×2 | Las esporas flotan cerca de los hongos; el goteo cae en cada charco |
| Costa | Espuma baja (`9` al 20 %, rápida) | Espuma y sal (12), nubes de lluvia ocasional (8 gotas) | 1×1, 2×1 | El viento es fuerte: horizontal |
| Herida | **Ninguna** (la niebla sería "algo") | Fragmentos de página (6): no caen ni suben, se disuelven | 4×5 | Sin gravedad; giro lento |
| Todas | | Chispas del golpe, polvo del salto, hojas del aterrizaje | Del suelo | Se hornean en el color del suelo que se pisa (la capa de datos `material`) |

Presupuesto: ninguna región pasa de 18 partículas ambientales fijas, quedando 12 para los eventos del jugador y los enemigos (límite global de 30).

### 7.4 Oscuridad: Minas, el Faro y las salas oscuras

La oscuridad total es lo más delicado del plan. La mecánica M9 (luz y revelado) y la ficha de las Minas la necesitan. Dos enfoques, con riesgos.

| Opción | Cómo | Ventajas | Riesgos |
|---|---|---|---|
| **A. `CanvasModulate` + `PointLight2D`** (la propone el diseñador) | Un `CanvasModulate` casi negro en la sala; luces `PointLight2D` con textura de bandas, sin sombras | Nativo de Godot; los objetos "revelados" aparecen en cuanto la luz los toca | `CanvasModulate` oscurece **todo** lo que se dibuja en su capa, incluidas las vetas luminosas y los minerales (que deben seguir brillantes) y el Ancla; hay que sacar los emisivos a una `CanvasLayer` superior |
| **B. Capa de oscuridad propia** | Un sprite negro que cubre la pantalla, con "agujeros" por halos (sustractivos) | Control total; los emisivos nunca se oscurecen porque se dibujan por encima | Más código propio (blend sustractivo); un recorte duro del halo |

**Recomendación:** no comprometerse todavía. Un **prototipo de un día** con la opción A y los emisivos en una `CanvasLayer` superior (con `follow_viewport_enabled`) decide. Si no funciona bien, la opción B o el **plan de reserva** del arte, que no necesita nada especial: **no hay oscuridad total, sino una sala de valor bajo** (todo en tonos 1-2, con los halos como únicas luces claras), que es lo que la rampa ya permite. Con el resplandor propio del Caminante el jugador nunca queda ciego y la biblia (4.1) se cumple.

**Reglas de seguridad** (de la biblia, y sin negociación):

1. Los peligros siempre tienen un tono ámbar tenue propio o un reflejo azul (los pinchos de las Minas llevan `a` en el cuerpo; sección 6.10).
2. La primera sala oscura que ve el jugador tiene una fuente de luz visible desde la entrada (el Andén de los Picos, con farolillos).
3. Las plataformas "reveladas" tienen su contorno punteado visible desde el principio (6.8).

### 7.5 Integración con la desaturación por sala

El mecanismo es el de la biblia (3.3): un sombreador `canvas_item` global con dos uniforms, `desaturacion` (0 a 1) y `tinte` (vec3). Se interpola 0,6 s al cruzar de sala. Mi aportación es la **tabla de qué entra y qué no**, y el uso de `g` para lo que no debe depender del sombreador.

| Categoría | Pasa por el sombreador | Razón |
|---|---|---|
| Terreno (`TextTileMap`) | Sí | Es lo que se desatura |
| Fondos de parallax | Sí | Idem |
| Props y decorado | Sí | Idem |
| Enemigos | Sí, excepto el rojo de aviso (se mantiene al 100 %) | Legibilidad del peligro |
| Jugador, Eco | **No** | El Caminante no puede olvidar |
| Ancla, reliquias, Hito, Piedras de lectura (azul), testigos ámbar | **No** | Lo que alguien recuerda conserva el color |
| Halos y luces | **No** | Son memoria o calor |
| Emisivos (vetas, minerales, hongos) | **No** | Idem |
| UI | **No** | |
| Baldosas `g` (desmemoriadas) | Sí, aunque ya son neutras | No cambian; el sombreador no las afecta porque no tienen croma |

Valores propuestos, como punto de partida para ajustar jugando (el nivel es por sala y el tinte, por región):

| Región | Nivel de sala | `desaturacion` | `tinte` (rojo, verde, azul) | Observaciones |
|---|---|---|---|---|
| Umbral | 0 | 0,00 | (1,05; 0,97; 0,88), cálido | Referencia de color vivo |
| Cinturón (normal) | 1 | 0,30 | (1,04; 1,00; 0,88), ocre | Parches grises con `g`, no con sombreador |
| Cisterna, Galerías | 1 | 0,30 | (0,88; 1,00; 1,02), azul verdoso | El tinte se interpola a lo largo de la caída |
| Archivo, sala intacta | 1 | 0,30 | (1,02; 1,00; 0,95) | |
| Archivo, sala erosionada | 2 | 0,65 | (1,02; 1,00; 0,95) | Sube ligeramente el tono 1 |
| Archivo, pasillo en blanco | 3 | 0,95 | (1,00; 1,00; 1,00) | Con baldosas `g` además del sombreador |
| Minas | 2 | 0,65 | (0,85; 1,00; 1,00) | Mineral y hongos a color por ser emisivos |
| Costa | 0 | 0,00 | (0,92; 1,00; 1,06), cian | Tinte frío |
| Herida | 3 | 0,95 | (1,00; 1,00; 1,00) | Todo el terreno es `g`; el sombreador solo desatura fondos y props |

**Dos usos de la baldosa `g` que evitan trabajo:**

1. **Parche gris del Cinturón y pasillos en blanco del Archivo** no necesitan zonas de sombreador ni máscaras de pantalla: una mancha de `g` dentro de una sala de nivel 1 ya está desmemoriada. El nivel de sala sigue siendo una sola cifra.
2. **Frontera visible entre memoria y olvido.** La fila 7 del tileset añade la línea `w` de 1 px entre `g` y la roca recordada. En las salas de transición la frontera es un elemento de diseño de nivel, no un efecto.

**Ancla que devuelve color.** Con la opción de la biblia (uniform de posición y radio, ~30 % de color recuperado dentro del halo), la sala de nivel 2 o 3 muestra un círculo de terreno más vivo alrededor del Ancla. Coste: una línea más en el sombreador. Recomiendo hacerlo: es la señal más clara de "isla segura".

---

## 8. Plan de producción

### 8.1 Criterio de orden

Lo que más urge es **poder recorrer el juego completo con aspecto distinto en cada región** cuanto antes, para tomar decisiones de ritmo, color y legibilidad con el juego real y no con regiones aisladas. Eso aconseja cambiar el orden de la biblia (que hace cada región entera antes de empezar la siguiente) por dos pasadas:

1. **Una primera pasada automática de las seis regiones** (tileset, fondo y un puñado de props) en cuanto exista el generador. Calidad "aceptable": no la definitiva, pero con identidad por rampa, forma y fondo.
2. **Una segunda pasada región a región** que mejora lo que más se ve y lo que más cuenta, por orden de aparición en el camino principal.

Lo que no se toca nunca por orden es la prueba de escala de grises: cada hito se aprueba con ella.

### 8.2 Fases, esfuerzo y método

Esfuerzo en puntos (1 punto ≈ una sesión corta; S = 1-2, M = 3-5, L = 6-10, como la biblia). "Método": **C** = generado por código, **M** = dibujado a mano, **C+M** = código con pieza maestra a mano.

**Fase 0 · Herramientas (23 puntos)**

| # | Tarea | Puntos | Método | Dependencias |
|---|---|---|---|---|
| E0.1 | Ampliar `art/palette.txt` a 31 colores y comprobar conflictos (pregunta 1 de la biblia) | 1 | C | Ninguna |
| E0.2 | Autotiling de 4 bits en `TextTileMap`, letras nuevas en la leyenda, pruebas en `smoke_test.gd` | 3 | Código (programación) | Aprobar letras (2.2) |
| E0.3 | `tools/arte_tiles.js`: hoja de 256×144 por región, variantes, `g`, fronteras, grietas, validación de costuras | 5 | C+M | E0.1 |
| E0.4 | Sombreador de desaturación y uniforms por sala (A2 de la biblia) | 2 | Código | E0.1 |
| E0.5 | Manifiesto de props, lectura de `sala.props`, celdas de 64×64 y 128×128, generador de familias | 3 | C+M | E0.1 |
| E0.6 | `tools/arte_fondo.js` y `Backdrop` por región en `world.gd` (fundido de 0,6 s) | 5 | C+código | E0.1 |
| E0.7 | `tools/arte_halos.js`: cinco halos en blanco y cuñas de luz | 1 | C | |
| E0.8 | Validador: escala de grises, rojo prohibido, costuras, ancho de tiras | 3 | Código | E0.3, E0.6 |

**Fase 1 · Las ocho salas construidas: Umbral y Cinturón bajo (22 puntos)**

Es el primer hito de verdad: lo ya jugable con su aspecto casi final.

| # | Tarea | Puntos | Método |
|---|---|---|---|
| E1.1 | Tileset del Umbral: corregir el labio de luz, `S` con labio `b`, autotiling, muro tapiado | 2 | C+M |
| E1.2 | Tileset del Cinturón (suelo, terraza, andamio, parche gris) | 3 | C+M |
| E1.3 | Tileset húmedo (Cisterna, Galerías, Aljibe) como variante | 2 | C |
| E1.4 | Fondo del Umbral: convertir las cinco capas actuales a tiras | 2 | C |
| E1.5 | Fondo del Cinturón (4 capas, viento) | 3 | C |
| E1.6 | Props del Umbral (17, de ellos 8 reutilizados) | 4 | C+M |
| E1.7 | Props del Cinturón y húmeda (24, 10 reutilizados) | 4 | C+M |
| E1.8 | Migración de los 8 mapas a la nueva hoja y corrección del rojo del estandarte y del poste | 2 | Código y M |

**Fase 2 · Primera pasada automática de las cuatro regiones restantes (10 puntos)**

| # | Tarea | Puntos | Método |
|---|---|---|---|
| E2.1 | Tilesets del Archivo, Minas, Costa y Herida generados con la definición de región (sin retoques) | 4 | C |
| E2.2 | Fondos de las cuatro regiones y las seis siluetas de interior (sin animación) | 4 | C |
| E2.3 | Seis props mínimos por región con recolorado de familias | 2 | C |

Hito 2: **el juego completo (136 salas) se puede recorrer con seis aspectos distintos**, aún sin pulir.

**Fase 3 · Segunda pasada, región a región (35 puntos)**

El orden recomendado es el de **aparición en el camino principal**, con la Costa antes que las Minas porque da el color de contraste (biblia 7):

| Región | Tileset | Fondo | Props | Extras | Puntos |
|---|---|---|---|---|---|
| Archivo | 2 (juntas, losas, estantes, `g`) | 3 (4 capas + animaciones de velas) | 4 (estantería apilable, sello, marco) | 1 (pasillos en blanco con fronteras) | 10 |
| Costa | 3 (muro encalado, arena, mar `a`) | 3 (cielo, mar, acantilado) | 4 (mástil, red, barca, faro) | 0 | 10 |
| Minas | 2 (estratos, vetas emisivas) | 2 (tres capas) | 4 (puntales, cristal, hongos, esqueletos) | 1 (prototipo de oscuridad, 7.4) | 9 |
| Herida | 2 (tres resoluciones) | 2 (blanco, siluetas, bloques) | 2 (arco sin juntas, sillas, taza) | 0 | 6 |

**Fase 4 · Mecánicas y elementos jugables (14 puntos)**

| # | Tarea | Puntos | Método |
|---|---|---|---|
| E4.1 | Grieta frágil y honda, compuertas (reja, tablones, piedra, cal), disparadores (palanca, placa, botón): las cuatro mecánicas más baratas del diseño (M2, M3, M4 y M11) | 4 | C+M |
| E4.2 | Piedras de lectura (6 variantes), receptor y símbolos de combinación | 2 | M |
| E4.3 | Plataforma sobre carril (6 variantes), corriente, luz, derribo con 7 fotogramas de caída | 4 | C+M |
| E4.4 | Seis Anclas por región con el generador existente | 1 | C |
| E4.5 | Puertas de región con glifos (seis), puentes | 1 | C+M |
| E4.6 | Pinchos por región (seis cuerpos), brasas | 1 | C |
| E4.7 | Rejas de arena nuevas (sin testigo) y ascensores | 1 | C |

Las mecánicas deben seguir el orden de implementación del diseñador (M1, M2, M3, M4 y M11 primero). Su arte llega con ellas, no antes.

**Fase 5 · Atmósfera y cierre (6 puntos)**

| # | Tarea | Puntos | Método |
|---|---|---|---|
| E5.1 | Partículas por región y niebla (tabla 7.3) | 2 | C |
| E5.2 | Luces: halos por fuente, cuñas, parpadeos (7.2) | 2 | C |
| E5.3 | Ancla que devuelve color en el sombreador | 1 | Código |
| E5.4 | Revisión global en escala de grises y de legibilidad | 1 | M |

**Total: 110 puntos** (23 de herramientas y 87 de contenido). El vertical slice ampliado (fases 0 y 1) cuesta unos 45. Hasta el hito 2 (juego completo con seis caras) son unos 55.

### 8.3 Qué se genera por código y qué se dibuja

| Cosa | Por código | A mano |
|---|---|---|
| Baldosas: las 16 máscaras, variantes, `g`, fronteras, grietas, resoluciones R2/R4 | Todo | Una pieza maestra de 16×16 por letra y región (unas 12 por región) |
| Rampas de región, tintes, transiciones | Todo | Nada |
| Fondos: siluetas periódicas, bandas, degradados | Todo | Nada (se ajustan parámetros) |
| Siluetas de interior (6) | Todo | Nada |
| Halos y cuñas de luz | Todo | Nada |
| Props: familias (contenedores, madera, piedra, colgantes) | Una forma maestra por familia y variantes por ruido | Forma maestra de cada familia |
| Props singulares (25, ver 5.6) | Nada | Todo |
| Anclas por región | Todo (generador existente con parámetro de región) | Nada |
| Piedras de lectura | | Cuerpo de 6 variantes; sombra grabada de cada una |
| Puertas de región | Arco y marco | Seis glifos de 12×12 |
| Pinchos | Cuerpo por rampa | Seis siluetas |
| Mecánicas: etapas de grietas, compuertas, plataformas | Composición con baldosas de la región | Overlays de grietas, testigo, símbolos |

### 8.4 Riesgos

| Riesgo | Mitigación |
|---|---|
| Que el generador produzca "sopa de píxeles" | Ruido solo entre tonos adyacentes; 25-30 % de píxeles distintos como máximo; revisión con tablero 8×8 y en gris |
| Que el autotiling no cubra una forma rara (techos en diagonal, columnas de un solo tile) | Máscara 0 a 15 más esquinas interiores cubre todas las formas ortogonales; las formas raras se resuelven con `p` o un prop. Pendientes solo si se aprueban |
| Que las seis regiones se vean "el mismo juego con otro filtro" | Cada región tiene una forma propia de `B` (juntas), de `S` (soporte) y de `T` (piel), no solo rampa; los fondos y las siluetas cambian la masa del conjunto |
| Que el fondo compita con la capa de juego | Reglas de valor, sin tono 4, sin contorno en capas lejanas y revisión en gris |
| Que el prototipo de oscuridad falle | Plan de reserva: "oscuro pero legible" por valor (7.4) |
| Exceso de piezas singulares (25) | Orden por importancia narrativa; las últimas de la lista 5.6 son prescindibles sin tocar el juego |

---

## 9. Preguntas abiertas

1. **Autotiling por código o terrenos de Godot.** Recomiendo código (máscara de 4 bits más esquinas interiores). ¿Se acepta, o prefiere el equipo de programación los terrenos nativos con el editor?
2. **Letras nuevas.** ¿Se aprueban `g p m h a / \`? ¿Y la regla de que el muro excavable sea `#` y `$` (diseño de puzles), manteniendo `D` como arco ciego de decorado? Esto afecta al mapa macro (intervenciones I1 e I6).
3. **Pendientes.** ¿Las soporta el motor del jugador (suelos inclinados) y el diseño las quiere? Si no, se quita la fila 7 parcial y se ahorran 8 baldosas por región.
4. **Paredes escalables y no escalables.** ¿Distingue el motor entre ambas? La biblia pide muescas en las escalables y paredes lisas en las otras; si no se distinguen, solo se dibujan las muescas y toda pared se puede escalar.
5. **Rojo apagado en el decorado y en los testigos.** El estandarte `F` y el poste `L` actuales usan rojo saturado. Propongo permitir `r` y `s` (nunca `t` ni `u`) para tela del Umbral y del Cinturón, y sustituir "lamparilla roja" por ámbar apagado y el lacre de cera rojo por cera ámbar oscura. ¿Se acepta, o se quiere una prohibición absoluta?
6. **Minas: labio de luz en tono 3 y resplandor del Caminante.** La biblia pide labio 4; propongo bajar a 3 en las Minas porque el 4 sería un faro en la oscuridad. Y el resplandor propio del Caminante: la biblia da 64 de radio, el diseño de puzles 2,5 baldosas (40 de radio). ¿Cuál?
7. **Props con archivo `.props` por sala.** Alternativa: ampliar letras con símbolos poco usados. Recomiendo el archivo, porque ~100 piezas no caben en un alfabeto de ~12 letras libres. ¿Aprobado?
8. **Acento `z` de la Herida.** ¿Se reserva el último color libre para la lavanda de "lo que no existe", o se deja libre? De momento mi propuesta no lo usa (la Herida funciona con neutros, y el Ancla sin nombre conserva el azul y el ámbar existentes).
9. **Resolución degradada en la Herida.** Las tres hojas R1, R2 y R4 rompen "un píxel de arte = un píxel de pantalla" solo en terreno y fondos, no en el personaje. ¿Se acepta? (Pregunta 8 de la biblia, ya con solución técnica barata.)
10. **Oscuridad total.** ¿Se aprueba un prototipo de un día antes de comprometerse? ¿Se acepta el plan de reserva de "oscuro pero legible" si el prototipo falla?
11. **Agua y brasas dañinas.** En esta propuesta `a` (agua) y las brasas son decorativas. Si el diseño quiere agua que ahoga o carbones que queman, su aspecto cambia (azul tono 3 con espuma; rojo `t` `u` con aviso) y entran en la lista de peligros con su regla de legibilidad.
12. **`Parallax2D` o `ParallaxBackground`.** Si el proyecto está en Godot 4.3 o posterior, `Parallax2D` da `autoscroll` y repetición sin código; si se prefiere no migrar, el `ParallaxBackground` actual sirve con `motion_mirroring` y las animaciones lentas se hacen con `Tween`.
13. **Hoja 2D o en una fila.** Propongo 256×144 con índice `fila × 16 + columna`. ¿El generador del `TileSet` (hoy a mano en `tiles_umbral.tres`) se genera también por script, o se mantiene a mano? Un `TileSet` de 144 baldosas con colisiones a mano es inviable; recomiendo generarlo.
14. **Sonido de pisadas por material.** La capa de datos `material` permite un sonido por baldosa. ¿Se quiere? Son ocho materiales, y la Herida en silencio.
15. **Primer plano sobre el jugador.** Heredo la pregunta 12 de la biblia: ¿se acepta hierba y cortinajes semitransparentes delante del jugador? En plataformas finas pueden molestar. Propongo desactivarlos en las salas de plataformas de precisión.
16. **Primera pasada automática antes del pulido.** ¿Se aprueba el cambio de orden de la sección 8.1 frente al de la biblia?
