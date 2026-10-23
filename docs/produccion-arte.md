# Producción de arte: hoja de ruta por hitos jugables (documento vivo)

Complementa a `docs/arte.md` (las reglas) y unifica las seis propuestas de `docs/reunion/artistas/`. Las decisiones que justifican este plan están en `docs/reunion/artistas/DECISIONES-EDITOR-ARTE.md`. Estado: propuesta del editor de arte, pendiente de aprobación del usuario.

## 1. Cómo leer este documento

- **Un hito es algo que se puede jugar**: termina con una región (o un tramo) que se recorre con su aspecto, no con una lista de ficheros. Todo hito se cierra **jugándolo** (regla de `CLAUDE.md`: los tests miden reglas, no sensaciones) y con la prueba de escala de grises.
- Dentro de cada hito los paquetes siguen el orden **herramientas, baldosas, fondos, enemigos, jefes, PNJ, interfaz y efectos**: así lo primero que se puede probar es el espacio, y lo último, el adorno.
- Un **paquete** tiene el tamaño de un pull request (un tema, una rama, la prueba de humo en verde). Cada uno lleva id, objetivo, entradas, salidas, dependencias, criterio de aceptación verificable y esfuerzo.
- Esfuerzo: **S** = 1-2 puntos, **M** = 3-5, **L** = 6-10 (1 punto ≈ una sesión corta de trabajo, la misma escala de las propuestas). Los puntos entre paréntesis son los que se suman en los totales.
- Salidas "código (core)" o "código (game)" son trabajo de programación que el paquete de arte necesita; se anotan para que no se olviden, pero no se cuentan como arte salvo que se indique.
- Todos los comandos de verificación son los de siempre: `node tools/…` para regenerar, `godot --headless --path . --script res://tools/build_sprites.gd`, `godot --headless --path . --import` y `godot --headless --path . --script res://tests/smoke_test.gd` (código de salida 0).

## 2. Presupuesto y líneas de corte

Lo que suman las propuestas, sin deduplicar: pipeline ~35-45 días (≈ 40 puntos), interfaz y efectos ≈ 83, personajes y PNJ 65-98, criaturas y jefes 196 (140 con los recortes de su propio documento), entornos 110 y la lista de producción de la biblia (95-190, que se solapa con las demás). Total bruto ≈ 500; deduplicado, ≈ 420.

El plan de este documento (con los recortes ya aplicados) cuesta **≈ 365 puntos** si se hacen las seis regiones y unos **45 más** de opcionales. Para una sola persona eso son muchos meses; por eso hay tres líneas de corte, y el proyecto se puede dar por terminado en cualquiera de ellas:

| Línea | Hasta | Puntos acumulados | Qué se puede jugar |
|---|---|---|---|
| **A. Núcleo comprometido** | H0-H4 | **168** | Último Umbral y Cinturón Yermo completos, con su jefe (Jacinto), el Centinela, PNJ del Umbral y las pantallas de interfaz esenciales. Las otras cuatro regiones se recorren con la primera pasada automática (H2) |
| **B. Mitad del mundo** | H5 | 237 | Añade el Archivo con sus dos jefes |
| **C. Mundo completo** | H6-H8 | 365 | Costa, Minas y Herida |
| Opcionales | H9 | +45 | Casimar, Rufo, Oda, retratos, Reliquias… |

Recomendación: **comprometerse con la línea A**, jugarla y decidir con datos reales (cuánto cuesta un punto de verdad) si se sigue. Si el diseño mantiene 136 salas en seis regiones, el coste de arte de las tres últimas regiones (≈ 130 puntos) se debería comparar con el de reducir el alcance en el diseño; es una conversación con el usuario, no una decisión de arte (ver choque C-10 en `DECISIONES-EDITOR-ARTE.md`).

## 3. Hitos y paquetes

### H0. Base verificable (≈ 17 puntos) — sin cambio visible

Objetivo: que todo lo que se produzca después nazca verificado y que el problema de los 49,5 MB del jefe no se multiplique por diez.

| Id | Objetivo | Entradas | Salidas | Depende de | Criterio de aceptación | Esf. |
|---|---|---|---|---|---|---|
| H0-01 | Paleta de 31 colores | `art/palette.txt`, tabla de `arte.md` §2 | 11 líneas nuevas en la paleta; `z` sin definir | — | `build_sprites.gd` sale con 0 y `git status` no muestra cambios en ningún PNG; un `.sprite` de prueba con `z` falla con el mensaje "carácter sin color" | S (1) |
| H0-02 | Extraer las primitivas del rig | `tools/rig_lib.js` | `tools/lib/raster.js` (Canvas, `shape`, contorno, sombreado por cadena, ruido, `trailChain`, `writeSprite`); `rig_lib.js` pasa a importarlo | — | Tras regenerar todos los rigs (`rig_caminante`, `rig_enemigos`, `rig_eco`, `rig_centinela`), `git diff --stat` de `art/source/` está vacío (byte a byte) | S (1) |
| H0-03 | Lienzo del Caminante a 112×96 | `rig_caminante.js` (`setCanvas`), `game/player/player.tscn` | `player.sprite` regenerado; `vframes` y `offset` ajustados; prueba de humo actualizada | H0-02 | Script de comparación: cada fotograma nuevo es idéntico al antiguo desplazado 32 px hacia abajo; el offset del `Sprite2D` pasa de (0, -8) a (0, -24) y los pies coinciden en el juego (captura antes/después); smoke en verde; se juega un minuto | S (2) |
| H0-04 | Manifiesto `.anim.json` y validador de hojas | `build_sprites.gd`, generadores | Un `.anim.json` por hoja (celda, anclaje, animaciones con fps/bucle/impacto, puntos); comprobaciones 1-9 de `arte.md` §15; salida 1 con mensaje en español (fichero, animación, fotograma) | H0-01 | Con hojas de prueba defectuosas (celda vacía, color fuera de paleta, par de fotogramas idéntico, píxel en el borde, pies desalineados) el validador falla en cada caso y con el mensaje esperado; con las hojas actuales sale 0 (las listas `hold` documentan las excepciones) | M (4) |
| H0-05 | Prueba de humo del arte | manifiestos | Prueba "El arte cumple las reglas" en `tests/smoke_test.gd` (existe la hoja, el tamaño coincide con el manifiesto, las animaciones de cada escena existen, presupuesto) que sustituye a las dos comprobaciones sueltas | H0-04 | Smoke en verde sin regenerar nada; si se cambia un fotograma del manifiesto sin tocar la escena, la prueba falla | S (1) |
| H0-06 | Atlas recortado del Centinela | `rig_centinela.js`/`build_sprites.gd`, `core/components/sheet_animator.gd` | Atlas con solo los fotogramas existentes y recortados; `SheetAnimator` con región y desplazamiento para hojas de atlas (código (core), con su prueba); `centinela.tscn` y `centinela.gd` actualizados | H0-04 | La hoja del jefe baja de 49,5 MB a **≤ 16 MB** (medido por el validador); la pelea se juega entera sin diferencias visibles (captura de cada animación antes/después); smoke en verde | M (4) |
| H0-07 | Generación incremental y `.sprite` generados fuera de Git (si el usuario lo aprueba, D-12) | `build_sprites.gd`, `.gitignore` | Caché de hashes `art/.cache/` (fuera de Git); `.sprite` de rigs en `.gitignore` y `git rm --cached`; nota en `arte.md` y `CLAUDE.md` | H0-04 | Segunda ejecución sin cambios tarda < 3 s; un clon limpio con los PNG versionados arranca el juego sin ejecutar Node | S (1) |
| H0-08 | Validador de legibilidad | PNG de hojas, tiras y baldosas | `tools/validar_arte.gd`: vista previa en escala de grises en `art/preview/`; error si hay `t`/`u` en una hoja marcada como terreno, fondo o decorado; error si una tira de fondo no es periódica | H0-04 | Una hoja de prueba con `t` en terreno falla; con las hojas actuales de baldosas y decorado, **falla en el estandarte y el poste** (confirma el hallazgo que corrige H1-06) | M (3) |

Hito H0 cerrado cuando: los ocho paquetes están en `main`, el jefe cabe en ≤ 16 MB y el juego se juega igual que antes.

### H1. Slice ampliado: Umbral y Cinturón bajo con cara de región (≈ 59 puntos)

Objetivo: las ocho salas actuales con su aspecto casi final, el Caminante con las poses que el juego ya necesita y la interfaz esencial.

**Herramientas**

| Id | Objetivo | Entradas | Salidas | Depende de | Criterio de aceptación | Esf. |
|---|---|---|---|---|---|---|
| H1-01 | Sombreador de desaturación y uniforms por sala | spec en §6 | `game/shaders/desaturacion.gdshader`; globals `desaturacion` y `tinte` en Ajustes del proyecto; propiedad `desaturacion` y `tinte` en `room.gd` con interpolación de 0,6 s (código (game)); material aplicado a terreno, fondos, props y enemigos | H0-01 | Sala de prueba que pasa de nivel 0 a 3: el píxel del Caminante, del Ancla y del HUD es idéntico antes y después (comprobado en una captura); el terreno llega a < 5 % de saturación; prueba de humo comprueba los uniforms y el grupo de exclusión; se juega cruzando dos salas de niveles distintos | M (3) |
| H1-02 | Autotiling de 4 bits y letras nuevas | decisión C-03 y C-04, tabla de máscaras (`06` §2.3) | `TextTileMap` calcula la forma por vecinas (`core`) con variantes por `hash2(x, y, semilla)`; letras `g p m h a` en la leyenda definitiva; pruebas | H1-03 en paralelo | Prueba de humo: un bloque de 3×3 de `G` da relleno al centro, esquinas y bordes correctos; la misma sala dos veces da la misma imagen; los 8 mapas actuales cargan sin cambios con la hoja nueva | M (4), código |

**Baldosas**

| Id | Objetivo | Entradas | Salidas | Depende de | Criterio de aceptación | Esf. |
|---|---|---|---|---|---|---|
| H1-03 | Generador de baldosas y tileset del Umbral | `06` §2.4-2.6, §3.1, 12 piezas maestras del Umbral | `tools/arte_tiles.js` (definición de región, 16 máscaras, esquinas interiores, variantes, `g`, fronteras, grietas, resoluciones); `art/source/tiles_umbral.sprite` regenerado (hoja de 256×144); `tools/build_tilesets.gd` que genera el `TileSet` `.tres`; labio de luz continuo; tablón con labio `b`; muro tapiado | H0-02, H1-02 | Tablero de prueba 8×8 de cada baldosa y de cada pareja de vecinas sin costura (comprobación automática de bordes); las posiciones 0-4 conservan la misma baldosa lógica; captura de `ultimo_umbral` en gris: el suelo pisable se distingue de la hierba decorativa; smoke en verde | L (6) |
| H1-04 | Tileset del Cinturón y húmedo; migración de los 8 mapas | `06` §3.2-3.3 | `tiles_cinturon` y `tiles_humedo` (variante con otra rampa de piedra y decales de humedad) generados con la misma herramienta; `.tscn` de las salas apuntan a su tileset; parche gris `g` con frontera de 1 px `w` en las terrazas | H1-03 | Las 8 salas cargan con su tileset (prueba de humo recorre las salas); captura en gris de `terrazas_secas` y `cisterna`: plataformas legibles; el parche gris es un cambio de forma, no un filtro | M (4) |

**Fondos**

| Id | Objetivo | Entradas | Salidas | Depende de | Criterio de aceptación | Esf. |
|---|---|---|---|---|---|---|
| H1-05 | Generador de fondos y fondos del Umbral y el Cinturón | `06` §4.1-4.2, §6 (generador) | `tools/arte_fondo.js` con definición de región; tiras de 864 px periódicas; `Backdrop` por región en `world.gd` con fundido de 0,6 s (código (game)); `Parallax2D`; los cinco polígonos actuales del Umbral convertidos a tiras | H0-08, H1-01 | El validador confirma que las tiras son periódicas (columna 0 continúa a la última), no tienen tono 4 salvo cielo y luces, y no tienen rojo; VRAM de fondos ≤ 3 MB por región (medido); el fundido entre Umbral y Cinturón se ve en el juego sin salto | L (6) |

**Props**

| Id | Objetivo | Entradas | Salidas | Depende de | Criterio de aceptación | Esf. |
|---|---|---|---|---|---|---|
| H1-06 | Manifiesto de props y decorado del Umbral y del Cinturón | `06` §5.1-5.3 | `art/source/props.txt`, lectura de `sala.props` en `room.gd` (código (game)); hojas de celda 64×64 y 128×128; 17 piezas del Umbral (8 reutilizadas) y unas 12 del Cinturón; **estandarte y poste corregidos a `r`/`s`** | H0-08, H1-03 | `validar_arte.gd` ya no marca rojo saturado en decorado; captura en gris: ningún prop compite con el labio de luz; las 13 letras de decorado de los mapas actuales siguen colocando su pieza | M (5) |

**Enemigos y personaje**

| Id | Objetivo | Entradas | Salidas | Depende de | Criterio de aceptación | Esf. |
|---|---|---|---|---|---|---|
| H1-07 | Fila `death` de los cinco comunes | `rig_enemigos.js` | Fila `death` (6-8 fotogramas a 10 fps) en Cascarón, Lancero, Arrojador, Acechador y Coloso; escenas actualizadas | H0-04 | Cada enemigo muere con su animación y se deshace en ceniza (el efecto es el de H1-14); el validador pasa; se juega un combate de cada tipo | M (4) |
| H1-08 | Poses del Caminante sin cambio de esqueleto | `04` §1.5, H0-03 | `land` (3), `wall_grab` (2), `wall_slide` (4), `wall_jump` (3), `die` (12), `respawn` (5); escena del jugador las enlaza con `SheetAnimator` | H0-03 | Cada animación se reproduce en su situación del juego (agarre de pared real, muerte real); el validador pasa; se juega la sala del salto de pared | M (5) |
| H1-09 | Doble salto con `spinPose` | `04` R2 | Helper `spinPose` (rota los desplazamientos de pies y manos, no píxeles) y animación `double_jump` (6 fotogramas a 20 fps) | H1-08 | La voltereta no deja píxeles sueltos (validador); en el juego se enlaza con `fall`; se juega la Torre de Riego | M (3) |

**Jefe**

| Id | Objetivo | Entradas | Salidas | Depende de | Criterio de aceptación | Esf. |
|---|---|---|---|---|---|---|
| H1-10 | Animación `release` del Centinela y revisión de la arena | `05` §6.0, §7.3 | Fila `release` (6 fotogramas a 10 fps) en el atlas; borde `w` entre avisos y decorado de la arena | H0-06 | La hoja sigue ≤ 16 MB; el jefe muere y su cascarón sale corriendo hacia el este y se apaga; se juega la pelea entera | M (3) |

**Interfaz y efectos**

| Id | Objetivo | Entradas | Salidas | Depende de | Criterio de aceptación | Esf. |
|---|---|---|---|---|---|---|
| H1-11 | Tema unificado: fuente m5x7, panel de piedra | `03` §0, D-05 | Fuente en `game/ui/` con su licencia (previa aprobación del usuario para descargarla y registro en `decisiones.md`); `Theme` con `NinePatchRect` de 24×24 generado por script; colores en un recurso | H0-01 | El HUD y la pausa usan el tema; el texto se ve nítido a ×2 y a pantalla completa (captura); las tildes, `ñ`, `¡` y `¿` se pintan | M (3) |
| H1-12 | Muerte del jugador: disolución en Eco y pantalla de muerte | `03` §1.6, §2.7; texto de los escritores | Secuencia de ≈ 3 s saltable desde 1,5 s; el cuerpo se disuelve en motas que forman el Eco | H1-08, H1-11 | Se muere en el juego y la secuencia termina en el Ancla; no hay flash de pantalla completa de más de 0,15 s; el cuerpo no queda a la vista tras el Eco | M (4) |
| H1-13 | Hit stop y temblor estandarizados | `03` §3.5 | Niveles de hit stop (0,06 / 0,12 / 0,08 / 0,2 s) y tres perfiles de temblor con ajuste de intensidad (código (core)) | — | Prueba de humo: cada perfil se aplica y la intensidad 0 lo anula | S (1) |
| H1-14 | `burst_fx` y efectos básicos | `03` §2.1-2.6, `02` §2.6 | Componente `core/components/burst_fx` (color, cantidad, gravedad, vida) que sustituye a los scripts sueltos; chispazo por material, ceniza de muerte, dash, doble salto, salto de pared, curación | H1-07 | Máximo 20 partículas por impacto (prueba); el efecto del jugador es azul/blanco y el de enemigo, rojo; se juega un combate y se salta | M (4) |
| H1-15 | Halos y luces | `06` §7.1-7.2 | `tools/arte_halos.js`: un juego en blanco de cinco tamaños y cuña de claraboya; halos de Ancla, reliquias, faroles y ventanas ámbar | H1-05 | Un halo solo suma (el valor de lo iluminado no baja, comprobado en captura); el Ancla sigue siendo la mayor luz | S (2) |
| H1-16 | Partículas ambientales del Umbral y el Cinturón | `01` §4.2, `06` §7.3 | Brasas, ceniza, polvo y paja con tope de 18 simultáneas | H1-14 | Contador de partículas ≤ 18 ambientales en cada sala (prueba); sin partículas fuera de cámara | S (2) |

Subtotal H1: 3 + 4 + 6 + 4 + 6 + 5 + 4 + 5 + 3 + 3 + 3 + 4 + 1 + 4 + 2 + 2 = **59**.
Hito H1 cerrado cuando se juegan las 8 salas con su baldosa, fondo, props y tinte, el Caminante agarra la pared y muere con animación, y el Centinela cabe en el presupuesto.

### H2. Mundo completo con seis caras: primera pasada automática (≈ 11 puntos)

Objetivo: que se pueda recorrer todo lo que exista del mundo con seis aspectos distintos, aún sin pulir, para decidir ritmo, color y legibilidad con el juego real.

| Id | Objetivo | Entradas | Salidas | Depende de | Criterio de aceptación | Esf. |
|---|---|---|---|---|---|---|
| H2-01 | Definiciones de región de Archivo, Costa, Minas y Herida | `06` §3.4-3.7 | Cuatro definiciones en `arte_tiles.js` (sin retoques); hojas e `.tres` | H1-03 | Una sala de prueba por región con su tileset, sin costuras (comprobación automática) y legible en gris | M (4) |
| H2-02 | Fondos de las cuatro regiones y seis siluetas de interior | `06` §4.2-4.3 | Tiras por región y siluetas I1-I6 (sin animación) | H1-05 | Cada sala de prueba muestra su fondo; ninguna tira rompe las reglas del validador; ≤ 6 MB de fondos cargados a la vez | M (4) |
| H2-03 | Seis props mínimos por región por recolor de familias | `06` §5.5 | Familias de contenedores, luz, colgantes y piedra con rampa simbólica | H1-06 | Las salas de prueba tienen sus props; ningún `t`/`u` | S (2) |
| H2-04 | Tabla de desaturación y tinte por sala | `arte.md` §4 | Datos de nivel/tinte de cada región y sala construidas (en `room.gd`/escena) | H1-01 | Cada sala construida declara su nivel; el Archivo muestra una sala de nivel 1 y una de nivel 3 | S (1) |

Hito H2 cerrado cuando: se recorre desde el Umbral hasta una sala de prueba de cada región con seis aspectos distintos y se anota qué se nota más a primera vista.

### H3. Cinturón completo y primer jefe de región (≈ 38 puntos)

| Id | Objetivo | Entradas | Salidas | Depende de | Criterio de aceptación | Esf. |
|---|---|---|---|---|---|---|
| H3-01 | Tileset, fondo y props del Cinturón pulidos | `06` §3.2, §4.2, §5.3 | Variante "pisada" del suelo, parche gris con frontera, fondo con reloj de ráfaga compartido, 24 props | H1-04, H1-05, H1-06 | Cielo, espigas y primer plano se mueven con la misma ráfaga; captura en gris de dos salas nuevas; los props nuevos pasan el validador | M (4) |
| H3-02 | Rig H v2: cabezas, armas y ropas nuevas | `05` §2.2 (H) | `veil`, `miner`, `mask`, `crown`, `scarecrow`; armas `scythe`, `quill`, `pick`, `lamp`, `staff`, `chain`; ropas `robe`, `sacks`, `straw`, `lino`; poses `crouch`, `armsUp`, `hover` | H0-02 | Cada elemento nuevo se prueba con una figura de muestra; los `.sprite` existentes no cambian (diff vacío) | M (4) |
| H3-03 | Espantapájaros y Segador Vaciado | `05` §3.3, §3.5 | Dos hojas con `idle/walk/windup/strike/hit/death` (+ `wake` el espantapájaros) | H3-02 | Cada ataque parable tiene pose asimétrica y cada uno se identifica en gris; los avisos se leen congelados; se juegan los dos | M (4) |
| H3-04 | Rig Q (cuadrúpedo) y Mastín sin Amo | `05` §2.2 (Q), §3.4 | `quad(spec)` con IK de cuatro patas, fases `trot`/`gallop`/`pounce`, cola con `trailChain`; hoja del mastín | H0-02 | El mastín trota sin deslizarse (los pies fijos respecto al suelo en el ciclo, comprobado por script); la silueta se distingue del Acechador en gris; se juega | L (7) |
| H3-05 | Rig V (volador) y Cuervo de Rastrojo | `05` §2.2 (V), §3.2 | `flyer(spec)` con ala de tres huesos, batido y membrana poligonal; hoja del cuervo (anclaje al centro de masa); sombra pequeña en el suelo | H0-02 | El batido se lee con 6 fotogramas; el picado se ve como flecha; sin píxeles sueltos (validador); se juega | L (7) |
| H3-06 | La Yunta reducida | `05` §11 | Dos Colosos en pareja con yugo y arado dibujado encima (sin cuerpo Q propio) | H3-04 | Se lee como una criatura larga de embestida; ≤ 4 MB | S (2) |
| H3-07 | Jacinto, el Último Segador | `05` §6.1 | Hoja de ~12 filas (`idle`, `walk`, `windup_low`, `swing_low`, `windup_spin`, `spin`, `step_slash`, `throw`, `dive`, `hit`, `stagger`, `death`, `release`), estela de trigo, fase 2 y 3 por capa de daño | H3-02, H0-06 | ≤ 16 MB con atlas; se lee la amenaza congelada; arena con sus reglas (suelo de labio claro, avisos en el suelo, reja común); se juega la pelea | L (10) |

Subtotal: 4 + 4 + 4 + 7 + 7 + 2 + 10 = **38**.
Hito H3 cerrado cuando: el Cinturón se recorre con enemigos propios hasta Jacinto y las lecturas de silueta funcionan con un jugador que no conoce el diseño.

### H4. Umbral habitado y sensación de juego (≈ 43 puntos)

| Id | Objetivo | Entradas | Salidas | Depende de | Criterio de aceptación | Esf. |
|---|---|---|---|---|---|---|
| H4-01 | Cabeza `face` y estilos erguido, encorvado, niño, corpulento | `04` §2.0 | Cabeza con tres tonos de piel y brillo de ojo; cuatro estilos de cuerpo | H3-02 | Captura en gris junto a un cascarón y un lancero: se distinguen por silueta o rostro; el ojo tiene su píxel de brillo | M (5) |
| H4-02 | PNJ del Umbral: Brunel (prueba), Iria, Aldara, Garrán, Cano | `04` §2.2 | Cinco hojas de 64×64 con `idle`, `talk`, `react` y **un segundo estado**; carro de Cano en dos versiones | H4-01 | Cada PNJ se entiende quieto; ninguno lleva rojo; el aviso de tecla aparece a < 64 px; se hablan en el juego | L (11) |
| H4-03 | Emblemas de diálogo de 16×16 | `04` §2.4 | Fila de 12 iconos en `iconos.sprite` | H1-11 | Cada emblema se lee a ×2; el diálogo muestra el emblema junto al nombre | S (1) |
| H4-04 | Barra de jefe, victoria sobre jefe y nombre de zona | `03` §1.7-1.9 | Barra de dos barras con muescas de fase; secuencia de victoria; rótulo de zona por código (alfabeto de 26 glifos) | H1-11, H3-07 | La barra coincide con las fases reales del Centinela y de Jacinto; secuencia de ≤ 4,5 s sin flashes de pantalla completa; se juega con ambos jefes | M (5) |
| H4-05 | La gran escena de "Has recordado" | `03` §1.8, §2.11 | Secuencia de 3,5 s con la silueta del Caminante repitiendo la técnica (versión barata) | H1-09, H4-04 | Se reproduce con las tres habilidades; cualquier botón la cierra tras 1,2 s; la cámara y el sombreador vuelven al estado normal | M (5) |
| H4-06 | `attack_up`, `attack_down` y `heal` | `04` R4, R6; `03` §3.1 | Animaciones del Caminante (6 + 6 + 10 fotogramas); objeto en mano `flask`; beber a través de la tela | H0-03, H1-08 | Se ejecutan con sus mecánicas; el frasco se ve en la mano; sin piel visible | M (5) |
| H4-07 | Evolución del Caminante: hoja tras el Doble salto | `04` §1.3-1.4, R5, R7 | Parámetros de estilo `mods` (bufanda larga, cuerda de vigía), anclajes exportados al manifiesto; sistema de cambio de hoja en la gran escena | H4-05 | La silueta cambia ≥ 4 px o ≥ 2 px de acento; no se tapa ninguno de los cinco rasgos; el cambio no se nota como salto | M (5) |
| H4-08 | `sit`/`rest` en el Ancla y `remember` | `04` §1.5 | Animaciones del Caminante (8 + 4 + 6) | H1-08 | Se enlazan con el menú del Ancla y con la recogida de habilidad | M (3) |
| H4-09 | Fondos y menú de pausa con vista previa viva | `03` §1.2 | Pausa en dos paneles; opciones de accesibilidad solo para lo que existe (intensidad de temblor) | H1-11, H1-13 | La pausa muestra el resumen del personaje con iconos de habilidad a color y el resto en gris | M (3) |

Subtotal: 5 + 11 + 1 + 5 + 5 + 5 + 5 + 3 + 3 = **43**.
Hito H4 cerrado cuando: **se juega Umbral + Cinturón + Jacinto como un juego pequeño y terminado de arte** (línea de corte A).

### H5. El Archivo (≈ 69 puntos)

| Id | Objetivo | Esf. |
|---|---|---|
| H5-01 | Tileset del Archivo (juntas de cal, losa, estante con lomos, cornisa, pasillo en blanco `g` con frontera) — acepta: captura en gris de la Nave Raspada, sin costuras | M (3) |
| H5-02 | Fondo del Archivo con velas, haces y siluetas I1/I2/I5 pulidas — acepta: ≤ 3,4 MB, sin movimiento fuera de velas, motas y haces | M (3) |
| H5-03 | Props del Archivo (estantería-torre apilable, sello gigante, marco sin retrato, mesas) — acepta: módulo de 48×48 apilable hasta 192 px | M (4) |
| H5-04 | Rig A: extraer la API de armadura vacía de `rig_centinela.js` (`plates`, `gap`, `inner`) y construir la Armadura Vacía — acepta: el Centinela regenerado con la API es idéntico (diff vacío); la armadura baja el escudo y se ve | L (7) |
| H5-05 | Novicio, Sellador, Penitente y Relator (élite por escala y libro) — acepta: cada uno distinguible en gris; avisos asimétricos/simétricos según el contrato | M (7) |
| H5-06 | Polilla de Archivo (V) y Custodio Mayor (Armadura ×1,45 con alabarda) — acepta: la polilla no se confunde con el cuervo en gris | S (4) |
| H5-07 | Sor Ilara, la Copista (copias por tinte y alfa sin hoja nueva) — acepta: ≤ 16 MB; la copia se lee como atacante por el trazo | L (10) |
| H5-08 | Hesper, el Prior (hábito que levita, sello trasero que se apaga en el aviso) — acepta: ≤ 16 MB; sombra ovalada en el suelo | L (8) |
| H5-09 | Estilo `túnica larga`; Sabela, Vael, Quiteria y Gaspar (sin animación de transformación: la saturación por fase hace el cambio) — acepta: cada PNJ pasa la prueba de legibilidad | L (15) |
| H5-10 | Mapa en estilo pergamino y árbol de habilidades con nodos hexagonales — acepta: mapa con patrón de relleno por zona (legible sin color) | M (7) |
| H5-11 | Partículas y luces del Archivo — acepta: tope de 18 | S (1) |

Hito H5 cerrado cuando: se recorre el Archivo con salas de niveles 1, 2 y 3 y se juegan Ilara y Hesper (línea de corte B).

### H6. La Costa Retenida (≈ 40 puntos)

| Id | Objetivo | Esf. |
|---|---|---|
| H6-01 | Tileset (muro encalado, arena, mar `a` de cuatro fotogramas, remate de pizarra) | M (3) |
| H6-02 | Fondo (cielo, mar, acantilados, mástiles; gaviotas y olas animadas) | M (3) |
| H6-03 | Props (mástil, red, barca, faro, símbolo tachado) | M (4) |
| H6-04 | Hermano de Cal, Acompañante, Hermano Antiguo (élite) y Gaviota (variante del cuervo) | M (6) |
| H6-05 | Rig Q variante `crab` y Cangrejo Ermitaño — acepta: la concha cerrada/abierta se distingue sin barra | M (5) |
| H6-06 | Ermitaño Mayor reducido (Cangrejo ×2 con barca dibujada sobre la concha) | M (3) |
| H6-07 | Eudora, la Piadosa (anillo de Calma como pieza aparte, sin rojo en el cuerpo) | L (8) |
| H6-08 | Mirena y Casilda — acepta: Mirena cojea con arpón guardado | M (7) |
| H6-09 | Partículas y luces de la Costa | S (1) |

### H7. Las Minas del Origen (≈ 47 puntos)

| Id | Objetivo | Esf. |
|---|---|---|
| H7-01 | Prototipo de oscuridad de un día (`CanvasModulate` + `PointLight2D` sin sombras, emisivos en `CanvasLayer` superior) — acepta: decisión escrita (A, B o plan de reserva "oscuro pero legible") en `docs/decisiones.md` | S (2) |
| H7-02 | Tileset (estratos, vetas emisivas como decal), fondo de tres capas y props (puntales, cristal, hongos) | L (9) |
| H7-03 | Rig S (segmentado) y Madre de Veta reducida (cinco segmentos, dos bolsas golpeables) | L (10) |
| H7-04 | Cavador, Hondo, Geoda (dos piezas: tapa y cuerpo) y Zapador (élite por escala con barril) | M (8) |
| H7-05 | Magda Soler — acepta: ≤ 16 MB; el Latido se pinta en azul `f` (nunca rojo, D-08) | L (9) |
| H7-06 | Dola | M (3) |
| H7-07 | Animación `dig` (R3 puño lejano) y hoja de evolución del Caminante tras Excavar | M (5) |
| H7-08 | Partículas y luces de las Minas | S (1) |

### H8. La Herida y cierre (≈ 41 puntos)

| Id | Objetivo | Esf. |
|---|---|---|
| H8-01 | Terreno `g` en tres resoluciones (1, 2 y 4 px), salas reconstruidas por reutilización de `.map`, fondo (blanco, edificios mal recordados, bloques flotantes) y props | L (7) |
| H8-02 | Estilo plano (`flat:true`), Eco Borrado, Relevo Vacío, Doble Vacío (clon del rig del Caminante) y Quimera (Eco Borrado ×1,3 con tres poses de ataque) | L (10) |
| H8-03 | Soporte de piezas (P) y Maelis (rostro con un fotograma de golpe y dos manos) — acepta: ≤ 20 MB toda la sala del jefe final; rotaciones por pasos de 15° | L (16) |
| H8-04 | Sprites de epílogo (Sellar sentado, Compartir sin máscara) y pantalla de créditos | M (7) |
| H8-05 | Revisión global en escala de grises y de legibilidad de todas las regiones | S (1) |

Totales: H5 = 3+3+4+7+7+4+10+8+15+7+1 = 69; H6 = 3+3+4+6+5+3+8+7+1 = 40; H7 = 2+9+10+8+9+3+5+1 = 47; H8 = 7+10+16+7+1 = 41.

### H9. Opcionales y recortables (≈ 45 puntos)

| Id | Objetivo | Esf. |
|---|---|---|
| H9-01 | Casimar y su cortesano; Rufo y los espejos (jefes opcionales) | L (15) |
| H9-02 | Oda, la Última Mensajera (secreta) | S (3) |
| H9-03 | Intercambio de paleta por sombreador (textura de 32×N) para variantes de enemigo, solo si la repetición de cuerpos molesta jugando | M (3) |
| H9-04 | Generador de retratos de 48×48 por capas y retoque a mano de cuatro principales | L (9) |
| H9-05 | Pantalla de Reliquias (necesita decisión de diseño antes) | L (8) |
| H9-06 | Cuarta hoja del Caminante: ojo ámbar y trapos de Nombrar (necesita decisión del usuario) | M (4) |
| H9-07 | Yunta completa con cuerpo Q de dos bueyes; Pez de Plata, Murciélago, Vela Errante, Contorno | L (10) |

## 4. Plan de extensión del rig por tipo de cuerpo

Regla de la casa: ningún tipo se construye antes del primer paquete que lo necesita, y cada uno se cierra con su criatura más sencilla. La refactorización previa (H0-02) es la única que se hace "por adelantado", porque sin ella cada cuerpo copiaría 300 líneas.

| Orden | Tipo | Paquete | Qué se añade | Primera criatura | Cómo se verifica | Riesgo |
|---|---|---|---|---|---|---|
| 0 | Primitivas | H0-02 | `tools/lib/raster.js`; sin cambio de salida | — | Diff vacío en los `.sprite` regenerados | Bajo |
| 1 | **H** humanoide v2 | H3-02 | Cabezas `veil`, `miner`, `mask`, `crown`, `scarecrow`; armas `scythe`, `quill`, `pick`, `lamp`, `staff`, `chain`; ropas `robe`, `sacks`, `straw`, `lino`; poses `crouch`, `armsUp`, `hover`; luego `face` y estilos de PNJ (H4-01) y `túnica larga` (H5-09) | Espantapájaros y Segador | Figuras de muestra; diff vacío en lo existente | Bajo |
| 2 | **Q** cuadrúpedo | H3-04 | `quad(spec)`: columna de dos tramos, cuatro patas con IK de dos huesos, `trot`/`gallop`/`pounce`, cabeza con mandíbula, cola con `trailChain`. Variante `crab` en H6-05 | Mastín | Script de contacto con el suelo en el ciclo; silueta distinta del Acechador en gris | Medio |
| 3 | **V** volador | H3-05 | `flyer(spec)`: alas de tres huesos con batido sinusoidal y membrana poligonal; variante `flame` solo si hace falta | Cuervo (luego Polilla y Gaviota) | Batido legible a 6 fotogramas; sin píxeles sueltos | Medio |
| 4 | **A** armadura vacía | H5-04 | `head:'none'`, `plates`, `gap`, `inner` (API extraída del código a mano de `rig_centinela.js`) | Armadura Vacía | Centinela regenerado idéntico | Bajo |
| 5 | **S** segmentado | H7-03 | `worm(spec)`: cadena larga con radio variable que sigue una trayectoria, contorno por unión | Madre de Veta reducida | Silueta continua sin huecos entre segmentos | Bajo |
| 6 | **P** piezas | H8-03 | `renderPart(spec)` con pivote y escena de ensamblaje; rotación por pasos de 15° | Maelis | Sin píxeles de distinta escala (rotación solo por pasos) | Alto |

Reglas de reparto: los **élites** son escala (`Z` 1,15-1,3) más un elemento de silueta; los **minijefes** son una base existente a escala mayor con un rasgo propio; los jefes humanoides van por hoja completa con atlas. `rig_caminante` se reutiliza (clon con otra paleta) para el Relevo Vacío, el Doble Vacío y Oda: **se acepta ese acoplamiento**, y esos tres se hacen después de que el Caminante esté estable (H8).

## 5. Generador de baldosas (`tools/arte_tiles.js`)

- **Entrada**: una definición de región (rampas de piedra y vegetación, densidad de grietas, semilla, `piel`, `piel_mezcla`, `veta` en las Minas, `resolucion` en la Herida) y las piezas maestras dibujadas a mano en texto (relleno de `G`, suelo `T` con piel, sillar `B`, remate `C`, tablón `S`, repisa `p`, tres etapas de grietas, muro tapiado y decales).
- **Salida**: hoja de 256×144 (16 columnas × 9 filas, índice `fila × 16 + columna`, mismo orden en todas las regiones; posiciones 0-4 intactas) escrita como `art/source/tiles_<region>.sprite`; un `.tres` por región generado por `tools/build_tilesets.gd` (colisiones, plataformas de franja de 4 px, capa de datos `material`).
- **Reglas que impone**: labio de luz continuo en las máscaras con el norte libre; contorno solo en lados libres; techos con fila de tono 1 y colgantes; muescas en las paredes escalables; ruido determinista (`hash2(x, y, semilla)`) que solo salta entre tonos adyacentes y cambia ≤ 25-30 % de los píxeles; los bordes de las variantes se conservan idénticos para encajar.
- **Comprobaciones automáticas**: cada baldosa repetida 8×8 y cada pareja de vecinas posibles sin costura; ninguna baldosa con rojo `t`/`u`; labio de luz presente; ninguna baldosa que dependa del sombreador para distinguirse en gris.
- **`g` desmemoriada**: se genera por completo (plano `x`, labio `y`, filo `w`, contorno `0` solo donde falta suelo), más las fronteras con 1 px de `w`; en la Herida produce las hojas R1, R2 y R4 por cuantización con vecino más cercano. Sin pendientes (fila reservada vacía) hasta que el motor las soporte.
- **Transiciones entre regiones**: `hoja_mezcla`, una hoja intermedia por interpolación de rampa (por ejemplo 50 % Cinturón y 50 % Archivo); dos salas de transición por frontera.

## 6. Generador de fondos (`tools/arte_fondo.js`) y sombreador

**Fondos.** Parámetros por región: silueta (colinas, ruinas, torres de riego, bóvedas, estanterías, acantilados, bloques), densidad, rampa, altura de horizonte, factor de parallax por capa. Cada capa es una tira de 864 px de ancho (el ruido es periódico con módulo 864) y alto ajustado a la zona útil; cuatro capas de escena más primer plano y niebla. Las animaciones son de tres tipos baratos: autodesplazamiento, sprites pequeños de 2-4 fotogramas y parpadeo de un color. Seis siluetas de interior reutilizables para las salas sin cielo, con pared trasera `m`/`h`. Las luces del fondo (luna, ventanas, claraboyas) quedan fuera del sombreador de desaturación.

**Sombreador de desaturación (propuesta de código; H1-01).**

```
shader_type canvas_item;
global uniform float desaturacion;   // 0-1, por sala
global uniform vec3 tinte;           // por región
uniform float saturacion_local = -1.0; // >= 0: anula la de la sala (PNJ, por fase)
uniform float aviso : hint_range(0.0, 1.0) = 0.0; // solo en el sombreador de enemigo

void fragment() {
    vec4 c = texture(TEXTURE, UV);
    float d = saturacion_local >= 0.0 ? 1.0 - saturacion_local : desaturacion;
    float l = dot(c.rgb, vec3(0.299, 0.587, 0.114));
    vec3 g = mix(c.rgb, vec3(l), d);
    g = pow(g, vec3(1.0 - 0.15 * d));      // sube los negros en los niveles 2-3
    COLOR = vec4(g * tinte, c.a);
    // el tinte de aviso del enemigo se suma después (no se apaga con la sala)
}
```

Reglas: sin filtrado lineal (Nearest); interpolación de 0,6 s al cruzar de sala; el grupo "siempre a color" no lleva el material; el Ancla puede devolver ~30 % del color dentro de su halo con un uniform de posición y radio (una línea más). Una prueba de humo comprueba que existen los uniforms globales y que el jugador no tiene el material.

## 7. Plan de VRAM

| Concepto | Hoy | Presupuesto | Cómo |
|---|---|---|---|
| Centinela | 49,5 MB (132 celdas, 47 vacías, dibujo de 280×236 en celdas de 384×256) | ≤ 16 MB | Atlas recortado (H0-06); si no basta, reducir el lienzo de celda y/o fotogramas |
| Jefes humanoides futuros | — | ≤ 16 MB cada uno | Atlas desde el principio |
| Maelis | — | ≤ 20 MB toda la sala | Tres hojas pequeñas |
| Hoja de criatura | 1,4-3,2 MB | 0,5-4 MB | Sin cambios; el atlas solo si pasa de 4 MB |
| Caminante | 3,1 MB | ~5 MB a 112×96 | Aceptable (una sola hoja residente) |
| Fondos | — | ≤ 3 MB por región, ≤ 6 MB cargados | Tiras de una pantalla; una región cargada a la vez |
| Todo lo residente en una sala | — | ≤ 150 MB | Entre 6 y 8 tipos de enemigo por sala; liberar al cambiar de región |

Además: importación `Lossless` y sin mipmaps (ya así), y el validador (H0-04) suma las hojas referenciadas por una escena y falla por encima del tope.

## 8. Recortes propuestos, en orden de sacrificio

Todos mantienen la lectura de la región; se anota lo que pierde el jugador. Los ahorros son sobre el plan de este documento (365 puntos más opcionales).

| Orden | Recorte | Ahorro | Qué se pierde |
|---|---|---|---|
| 1 | No hacer H9 (jefes opcionales, Oda, retratos, Reliquias, ojo ámbar, Yunta completa, bestias de relleno) | 45 | Dos peleas con identidad propia y el secreto; la mayor parte del color de personaje |
| 2 | Props singulares: de 25 piezas a las 8 más importantes (Hito de Nombres, árbol del primer pantallazo, Ancla por región, Piedras de lectura, sello gigante, trono, barca, arco sin juntas) | ~8 | Detalles de narrativa ambiental secundarios |
| 3 | PNJ a un solo estado visible (más el sombreador de saturación); Casilda, Dola, Mirena y Quiteria se quedan en `idle` y `talk` | ~10 | Cambios de pose del arco |
| 4 | Evolución del Caminante a una sola hoja (la del Doble salto) | ~5 | El cambio visible tras Excavar |
| 5 | `sit/rest/remember` fuera: el Caminante solo cambia de pose con un fundido | 3 | Animaciones de carácter |
| 6 | Costa sin Ermitaño Mayor ni Hermano Antiguo | 4 | Un minijefe y un élite |
| 7 | Minas sin Madre de Veta (la sala de Magda es el clímax) | 10 | La pelea de partes |
| 8 | Herida con rostro de Maelis estático (un fotograma) y la Quimera fuera | 5 | Animación del rostro del jefe final |
| 9 | Una región completa menos (Minas o Costa): decisión de diseño con el usuario | 40-47 | Esa región |

**Nunca se recorta**: los jefes obligatorios, la fila `death` de los comunes, el lienzo 112×96, el validador y la prueba de humo del arte, el sombreador de desaturación, las baldosas del Umbral y del Cinturón.

## 9. Lo que depende de otros documentos

- La **leyenda definitiva** del mapa de texto (letras `g p m h a` frente a `# $ = + l _ * c n < > ) ( u f x k y o` del diseño de puzles, y `D` para el muro excavable) la fija `docs/vertical-slice.md`; H1-02 espera esa decisión.
- El **orden de regiones** y el número de salas son de diseño (`docs/reunion/disenadores/01-mapa-macro.md`).
- El **texto de muerte, victoria y habilidad** es de los escritores.
- Los **materiales de pisada** (hasta ocho) son del sonido (`docs/sonido.md`).
- El **autotiling** en `TextTileMap` y `SheetAnimator` con atlas son cambios en `core/`, y piden actualizar `docs/arquitectura.md` y `core/README.md` en el mismo commit (regla de `CLAUDE.md`).
- El **zoom de cámara en jefes** y el tamaño de las arenas son de diseño técnico.
