# Arte: dirección y reglas (documento vivo)

Estado: dirección elegida y unificada tras la reunión de artistas (octubre de 2026). Hay arte provisional hecho con el pipeline de texto (Caminante, cinco enemigos, jefe, Ancla, habilidades, baldosas y decorado del Umbral); todo lo demás está por producir. Este documento fija **las reglas vigentes**. El detalle largo de cada área está en las propuestas de `docs/reunion/artistas/` (se cita en cada sección) y la hoja de ruta de producción, en `docs/produccion-arte.md`. Las decisiones tomadas al unificar las propuestas, con su razonamiento, están en `docs/reunion/artistas/DECISIONES-EDITOR-ARTE.md`.

Lo que sigue **no está aprobado por el usuario hasta que lo confirme** salvo lo que ya era vigente antes de la reunión (dirección pixel art oscuro, 864×486, rejilla de 16 px, pipeline de sprites como texto). Los puntos que dependen de otros documentos o de una decisión del usuario se marcan con "(pendiente)".

## 1. Dirección y pilares

**Pixel art oscuro con paletas limitadas**, en la línea de *Blasphemous* o *Death's Gambit*, con identidad propia. Decisión tomada por el usuario entre tres opciones (ver `decisiones.md`). Referencias como lenguaje, no como modelo: la legibilidad de silueta de *Hollow Knight*, el peso de la arquitectura de *Blasphemous*, la pobreza material creíble de *Salt and Sanctuary*, la luz como guía de *Ori* y el peligro claro en movimiento de *Dead Cells*.

La identidad es una sola idea: **el color es memoria.** Lo recordado tiene color; lo olvidado, no. Cuanto más cerca de la Herida, más se desatura el mundo, y el Caminante, el Eco, las Anclas y las reliquias son lo único que conserva el color completo en todas partes.

| Pilar | Qué obliga |
|---|---|
| P1. El color es memoria | Ante la duda, se quita color, no se añade. Un objeto cálido y saturado en un mundo apagado significa "alguien lo recuerda" |
| P2. Legibilidad antes que atmósfera | Lo que se pisa, golpea o esquiva se lee por *valor* (claro/oscuro) antes que por color. El fondo nunca compite con la capa de juego |
| P3. Siluetas contra luz | Lo importante se recorta contra una zona más clara. Los personajes se reconocen por la forma del contorno |
| P4. Ruina con oficio | Todo lo construyó alguien y luego se abandonó o se olvidó. Lo orgánico invade lo geométrico; la Desmemoria borra por partes, no rompe |

### 1.1 Qué significa cada color

| Rampa (códigos) | Significa | Aparece en | Nunca aparece en |
|---|---|---|---|
| Ámbar (`a b c d`) | Memoria viva, calor humano, algo que alguien recuerda | Ancla, faroles, ribetes del Caminante, runas, ventanas habitadas, testigos de mecanismos | Daño, enemigos, decorado de peligro |
| Azul (`e f g h`) | Recuerdo cristalizado, Eco, habilidad, la Desmemoria "desde dentro" | Eco, reliquias, máscara del Caminante, minerales, agua, sellos del Archivo | Peligro (la luz de ayuda no se confunde con una trampa) |
| Rojo (`r s t u`) | Peligro, sangre, aviso de ataque, enemigo | Vendas y detalles de enemigos, pinchos, proyectiles, avisos | UI de ayuda, terreno, fondos, mecanismos |
| Musgo (`m n o p`) | Vida lenta | Musgo, hierba, hongos, raíces | Zonas de desaturación 3 |
| Piedra (`1 2 3 4`) | El mundo construido | Muros, suelos, arquitectura | (es el fondo por defecto) |
| Neutros (`0 x y w`) | Lo olvidado: sin color ni dueño | Herida, pasillos en blanco, parches grises | Zonas de desaturación 0 |
| Tierra (`5 6 7`) | Oficio humano pobre: madera, tierra, paja, cuero | Umbral, Cinturón, andamios, tejados | Herida |
| Cal y mar (`8 9 v`) | Papel, hueso, cal, espuma, bronce marino | Archivo, Costa, huesos | — |

**Regla de oro**: ámbar, azul y rojo no se mezclan en un mismo objeto. Excepciones fijadas: el Ancla (azul + ámbar), el Centinela (hierro + ámbar + rojo de aviso), el Caminante (azul = Eco, ámbar = lo humano que sobrevive; jamás rojo).

**Reglas del rojo** (ver decisión D-08):

1. `t` y `u` (rojos saturados) solo en lo dañino: enemigos, proyectiles, pinchos, avisos y las superficies hostiles de una arena de jefe. Nunca en terreno, fondo, decorado, mecanismos ni UI de ayuda.
2. `r` y `s` (rojos oscuros apagados) se admiten en **tela remendada del decorado** del Umbral y del Cinturón (estandarte, trapos del poste, ropa de espantapájaros). Es una corrección de lo ya hecho: hoy el estandarte y el poste usan `t`/`u`.
3. Los testigos de mecanismos y el lacre de los puzles son **ámbar apagado** (`a b`), no rojos.
4. El rojo de aviso de ataque se mantiene al 100 % aunque la sala esté desaturada.

**Aviso de ataque** (ver `docs/reunion/artistas/05`, 1.2): es una **capa de código** (tinte aditivo sobre el sprite y marca en el suelo), no píxeles de la hoja. Parable: destello aditivo `d` con destello blanco corto en el arma. No parable: tinte `t` más marca de suelo en `t`/`u` con bandas diagonales. Es el único ámbar "de peligro" del juego y nunca está en un sprite ni en el decorado. Los sprites de `windup` deben leerse también congelados: pose asimétrica (arma echada atrás, un solo brazo) para lo parable y pose simétrica y ensanchada (los dos brazos arriba, el cuerpo entero) para lo no parable. Esta "regla de la simetría" es contrato de arte provisional (pendiente de validar jugando).

## 2. Paleta (31 de 32 colores)

`art/palette.txt` define un carácter por color (el punto `.` es transparente y no se define). **Los códigos de `.sprite` y los del mapa de texto `.map` son dos espacios de nombres distintos**: en un `.sprite`, `4` es Piedra 4; en un `.map`, `4` es el acechador. Nunca se mezclan.

| Cód. | Hex | Nombre | Rampa | Uso principal |
|---|---|---|---|---|
| `1` | `#1b1a1f` | Piedra 1 | Piedra | contorno de todo el rig, sombras |
| `2` | `#3a3840` | Piedra 2 | Piedra | cara en sombra, juntas |
| `3` | `#6a6670` | Piedra 3 | Piedra | planos medios |
| `4` | `#a39fa8` | Piedra 4 | Piedra | labio de luz del suelo, filos |
| `a` | `#4a2b12` | Ámbar 1 | Memoria | brasa apagada, ámbar tenue en la oscuridad |
| `b` | `#8a5320` | Ámbar 2 | Memoria | labio de plataformas de una dirección, ribetes |
| `c` | `#d18a2e` | Ámbar 3 | Memoria | luz cálida, UI de acento |
| `d` | `#f3c46a` | Ámbar 4 | Memoria | brillo, texto resaltado, tinte de aviso (por código) |
| `e` | `#12283a` | Azul 1 | Recuerdo | sombra azul, tinta |
| `f` | `#1f5573` | Azul 2 | Recuerdo | cuerpo del mineral, pulso del Latido |
| `g` | `#4aa3c7` | Azul 3 | Recuerdo | Eco, máscara, agua |
| `h` | `#a9e3f2` | Azul 4 | Recuerdo | brillo del recuerdo |
| `r` | `#3a1218` | Sangre 1 | Sangre | rojo apagado de tela; sombra de heridas |
| `s` | `#7a2430` | Sangre 2 | Sangre | vendas, tela apagada |
| `t` | `#c2453f` | Sangre 3 | Sangre | enemigo, daño, aviso |
| `u` | `#f08a6a` | Sangre 4 | Sangre | punta de pinchos, destello de aviso |
| `m` | `#15241a` | Musgo 1 | Musgo | sombra vegetal |
| `n` | `#2c4a30` | Musgo 2 | Musgo | musgo |
| `o` | `#587a4a` | Musgo 3 | Musgo | hierba |
| `p` | `#9cb57a` | Musgo 4 | Musgo | brote claro |
| `0` | `#0a090d` | Vacío | Neutros | **nuevo**: contorno de oscuridad total; más oscuro que Piedra 1 |
| `x` | `#55555a` | Gris oscuro | Neutros | **nuevo**: lo olvidado, sombra sin tinte |
| `y` | `#8c8c8f` | Gris medio | Neutros | **nuevo**: lo olvidado, plano medio |
| `w` | `#efe9d6` | Página en blanco | Neutros | **nuevo**: el color más claro del juego; Herida y hojas rasuradas |
| `5` | `#3d2a22` | Madera oscura | Tierra | **nuevo**: vigas, tierra húmeda, cuero |
| `6` | `#6b4a36` | Madera/tierra | Tierra | **nuevo**: tablas, tierra seca, piel cálida en sombra |
| `7` | `#8f7d45` | Paja seca | Tierra | **nuevo**: cultivo muerto, tejados |
| `8` | `#cfc4a8` | Hueso / pergamino | Cal | **nuevo**: papel, hueso, cal, piel cálida clara |
| `9` | `#b9d6d2` | Sal | Cal | **nuevo**: espuma, escarcha de sal |
| `v` | `#2f6f73` | Mar | Cal | **nuevo**: agua marina, algas, bronce con pátina |
| `z` | — | libre | — | reservado; **no se define en `palette.txt`** (usarlo en un `.sprite` da error). Decisión D-02 |

Comprobado: ningún `.sprite` existente usa los códigos nuevos (el conversor rechaza cualquier carácter que no esté en la paleta), y las palabras clave del formato (`sheet out part anim frame`) no incluyen ningún carácter nuevo. La integración no cambia ningún PNG existente.

Reglas de paleta:

- Los 11 nuevos forman mini-rampas de 2-3 tonos, no rampas de 4. La personalidad de cada región sale de **mezclar rampas** (máximo tres principales más las señales activas en pequeñas dosis), no de añadir una por región.
- Contorno de 1 px en `1` (o `0` en oscuridad total y solo donde se limita con aire). Nunca negro puro.
- El ruido determinista de los generadores **solo salta entre tonos adyacentes** de una rampa (nunca del 1 al 4) y no cambia más del 25-30 % de los píxeles de una baldosa.
- Cualquier PNG pintado a mano debe usar exactamente estos colores (lo comprueba la validación, ver sección 14).

## 3. Legibilidad: capas de valor

La imagen se construye en capas con rango de valor propio (tono 1 = oscuro de la rampa de la región):

| Capa | Valor | Saturación | Contorno |
|---|---|---|---|
| Fondo lejano (parallax) | 1-2, algo más claro en el horizonte | muy baja | ninguno |
| Fondo medio | 1-2 | baja | ninguno |
| Fondo cercano | 1-3 | media-baja | oscuro, solo siluetas |
| **Capa de juego** | 2-4 | normal de la región | 1 px oscuro donde toque otra superficie |
| Primer plano | 1 (casi negro), semitransparente si tapa algo | — | ninguno |

- **Labio de luz**: toda superficie pisable lleva 1 px en el tono 4 de la rampa de la región en su borde superior y 2-3 filas de tono 2 debajo. Es lo único de la capa de juego con tono 4 fuera de enemigos y reliquias. Plataformas de una sola dirección: labio **ámbar `b`** con soportes visibles. Excepción documentada: en las Minas el labio baja a tono 3 (el 4 sería un faro en la oscuridad).
- **Paredes escalables**: muescas verticales (1 px de tono 3 cada 3-4 filas); las no escalables son lisas.
- **Peligros del entorno**: pinchos con la punta `u` sobre piedra oscura. En salas oscuras, todo peligro lleva ámbar tenue (`a`) o un reflejo azul: no se mata al jugador por algo invisible.
- **El fondo detrás del jugador nunca baja del tono 2** de la región en la capa de juego.
- **Prueba de escala de grises obligatoria**: cada tileset, fondo, enemigo y PNJ se revisa convertido a grises. Si el jugador, los enemigos o las plataformas no se distinguen, el arte no se da por bueno.

## 4. Desaturación por sala

La desaturación es la lectura del estado de la memoria, no un filtro estético.

1. Se mide por **distancia a la Herida**, no por orden de visita (la Costa, periférica, es la menos afectada).
2. El nivel se declara **por sala**, no por región; el tinte, por región.
3. **A color completo siempre**: Caminante, Eco, Ancla, reliquias, Hitos y Piedras de lectura, halos y luces, vetas y minerales emisivos, testigos ámbar de mecanismos, UI. Los PNJ llevan su propio parámetro de saturación según la fase de su arco (no el de la sala).
4. Pasan por el sombreador: terreno, fondos, props y decorado, y enemigos (salvo el rojo de aviso, que se aplica después).

| Nivel | Nombre | `desaturacion` | Ejemplo |
|---|---|---|---|
| 0 | Recordado | 0,00 | Último Umbral, Costa |
| 1 | Desgastado | 0,30 | Cinturón, Archivo intacto |
| 2 | Deshilachado | 0,65 | Minas, Archivo erosionado |
| 3 | Borrado | 0,95 | Herida, pasillos en blanco |

**Implementación (decidida)**: un sombreador `canvas_item` con dos uniforms globales (`desaturacion` 0-1 y `tinte` vec3) que mezcla el color con su luminancia, más un gamma suave en los niveles 2-3 para subir los negros. Se interpola 0,6 s al cruzar de sala. El arte se pinta siempre a color pleno y **no se mantienen versiones por región**. Un único sombreador de enemigo suma el uniform de aviso de ataque. Se descartan las paletas horneadas por región y, por ahora, el intercambio de paleta por tabla (solo se hará si hace falta variar enemigos; ver `produccion-arte.md`, paquete H9-03).

Complemento sin sombreador: la baldosa **desmemoriada** (`g` en el mapa, neutros horneados, plana y de borde recto) hace los parches grises del Cinturón, los pasillos en blanco del Archivo y toda la Herida. Los dos mecanismos no se pisan. Opcional recomendado: el halo del Ancla devuelve ~30 % del color alrededor (una línea más de sombreador).

Valores de partida (a ajustar jugando):

| Región | Nivel | `tinte` (R, G, B) |
|---|---|---|
| Umbral | 0 | (1,05; 0,97; 0,88) cálido |
| Cinturón | 1 | (1,04; 1,00; 0,88) ocre |
| Cisterna y Galerías | 1 | (0,88; 1,00; 1,02) azul verdoso |
| Archivo (intacto / erosionado / en blanco) | 1 / 2 / 3 | (1,02; 1,00; 0,95) |
| Minas | 2 | (0,85; 1,00; 1,00) |
| Costa | 0 | (0,92; 1,00; 1,06) cian |
| Herida | 3 | (1,00; 1,00; 1,00) |

## 5. Resolución, rejilla y tamaños

- **Resolución interna 864×486**, escalada por enteros (×2 = 1728×972). Ya configurado: filtro Nearest, escalado entero, estirado "viewport", ajuste de transformaciones al píxel. Importación de hojas en `Lossless` y sin mipmaps (comprobado en las existentes; no usar nunca compresión VRAM con pérdida).
- **Rejilla de nivel 16×16.** Lienzos de sprites en **múltiplos de 8**, orientados a la derecha, volteo con `scale.x = -1`, luz arriba-atrás en todo lo generado.
- **Anclaje**: pies/base centrados en la última fila (voladores: centro de masa; colgantes: techo). El tipo de anclaje lo declara el manifiesto.

| Elemento | Colisión | Lienzo | Cuerpo dibujado | Notas |
|---|---|---|---|---|
| Jugador (Caminante) | 24×48 | **112×96** (antes 112×64; hecho en H0-03) | 20×44 | `Sprite2D.offset` es (0, -24) |
| Enemigo pequeño | 20-28 × 24-32 | 64×48 (96×64 con arma larga) | hasta 20×28 | |
| Enemigo mediano | 32×48 | 96×64 (144×64 con lanza) | 24×44 | Cascarón, Lancero, Arrojador |
| Enemigo grande | 44×64 | 144×96 | hasta 44×64 | Coloso |
| Élite / minijefe | 56×88 | 192×128 (144×96 si no lleva arma larga) | hasta 56×88 | |
| Jefe humanoide | según fases | el recuadro real, múltiplo de 8 (160×96 a 224×160; el Centinela, 384×256) | 112×160 el Centinela | Atlas recortado |
| Jefe no humanoide | — | por piezas (solo Maelis) | — | ver sección 9 |
| PNJ | sin colisión de combate | 64×64 (80×64 con arpón, 96×64 con carro) | 20×44 | |
| Objeto / pickup | — | 32×32 o 48×48 | — | |
| Proyectil | pequeña | 16×16 (32×16) | — | |
| Prop | ninguna | celda 64×64 o 128×128 | — | ver sección 11 |

Cifras reales de lienzo hoy (cabecera `sheet` de cada `.sprite`): Caminante 112×96, Cascarón 96×64, Lancero 144×64, Arrojador 96×64, Coloso 144×96, Acechador 112×64, Centinela 384×256, Jacinto 224×128 (y su hoz lanzada 72×72), Eco 48×64, Ancla 64×80, habilidades 48×48, decorado 48×64.

## 6. Hojas, animaciones y manifiesto

**Una fila por animación y una columna por fotograma.** Vocabulario único, siempre en este orden de fila para criaturas (las que no existan se omiten del final, nunca del medio):

| Fila | Nombre | fps | Bucle |
|---|---|---|---|
| 0 | `idle` | 6-8 | sí |
| 1 | `walk` | 12-24 | sí |
| 2 | `windup` (3-5 fotogramas + retención; mínimo 0,28 s) | 10-12 | no |
| 3 | `strike` (con el fotograma de impacto marcado) | 24-30 | no |
| 4 | `hit` | 14-16 | no |
| 5 | `death` | 10 | no |
| 6+ | extras: `stagger`, `jump`, `fall`, `land`, `alert`, `windup2`, `strike2`, `block`, `spawn`... | — | — |

- **Idioma**: los nombres de animación, parámetros y claves del manifiesto, en **inglés** (como el código). Los ids de criatura y los nombres de archivo, en **español sin tildes** (continuidad con `lancero`, `coloso`, `centinela`: `mastin`, `espantapajaros`). Los nombres en español de las propuestas (`pluma`, `cetro`, `tizon`) se traducen al nombrar la animación (`strike_quill`, `strike_scepter`).
- fps entre 6 y 40 (el jugador va a 40; el resto, ≤ 30).
- **Manifiesto `<nombre>.anim.json`** junto a cada hoja (una sola fuente de verdad para la hoja y la escena): celda, anclaje, paleta, animaciones (`row`, `frames`, `fps`, `loop`, `impact`) y puntos (`weapon_tip_strike`, `head`, `fist`, `neck`, `shoulder`, `hip`, origen de proyectil). Sustituye a la tabla `animations` duplicada a mano en cada `.tscn`. (Paquete H0-04.)
- **Jacinto sin atlas recortado**: 17 filas por 8 columnas de 224×128 = 1792×2176 (14,9 MiB de textura, por debajo del tope de 16 de un jefe), porque no tiene animaciones largas. Si se le añaden filas o fotogramas, hay que pasarlo al atlas recortado.
- **Atlas recortado** solo para hojas que pasen de 4 MB (hoy, el Centinela): se recorta cada fotograma a su recuadro mínimo y se empaquetan solo los existentes; `SheetAnimator` usará región y desplazamiento en lugar de `hframes/vframes` para esas hojas. (Paquete H0-06.)
- **Fotogramas intermedios sin dibujar piezas nuevas** (pipeline manual): se recorta progresivamente la pierna que va a desaparecer, siempre por filas completas (primero el pie, luego la pantorrilla), nunca caracteres sueltos, o la silueta queda rota.
- Reglas de movimiento: anticipación proporcional a la amenaza; golpe en 1-2 fotogramas; recuperación que da la ventana al jugador; squash y stretch mínimos (±8 %), solo con `scale` en fotogramas concretos; la capa del Caminante se retrasa 2-3 fotogramas respecto al cuerpo.

## 7. Cómo se produce (pipeline)

El usuario no dibuja y Claude no genera imágenes, así que los sprites se escriben **como texto** y un programa los convierte en PNG:

- `art/palette.txt` — la paleta, un carácter por color.
- `art/source/*.sprite` — sprites en texto: se definen **piezas** y las animaciones se componen apilando piezas (formato en la cabecera de `tools/build_sprites.gd`: `sheet`, `out`, `part`, `anim`, `frame`, con `pieza@x,y` para superponer).
- `tools/build_sprites.gd` — genera las hojas PNG junto a su escena y vistas previas ×8 en `art/preview/` (no se guarda en Git):

  ```
  godot --headless --path . --script res://tools/build_sprites.gd
  godot --headless --path . --import
  ```

- **Generadores por código (Node.js, solo para quien retoque el arte; el juego no lo necesita)**: `rig_lib.js` (esqueleto humanoide lateral), `rig_caminante.js`, `rig_enemigos.js`, `rig_centinela.js`, `rig_jacinto.js` (Jacinto y su hoz), `rig_eco.js`, `arte_ancla.js`, `arte_habilidades.js`, `arte_titulo.js`. Para cambiar un sprite generado se edita su generador y se regenera (`node tools/rig_enemigos.js`, etc.); el `.sprite` generado se sobrescribe.
- **Una sola fuente de verdad por sprite**: mientras exista su `.sprite` o su generador, ese texto manda. Si se retoca un PNG a mano (Pixelorama, LibreSprite), se borra antes su fuente. Recomendación pendiente de aprobación (D-12): no versionar en Git los `.sprite` generados por rigs (el del Centinela pesa 8,4 MB; en total hay 11 MB de texto); versionar los generadores y los PNG.
- Qué se genera y qué se dibuja: **por código** lo que se repite o se mueve mucho (ciclos de movimiento, variantes, baldosas, fondos, props en familia, halos, fuentes de rótulo, iconos sencillos); **a mano** lo que se ve quieto y de cerca o lleva identidad (piezas maestras de baldosa, props singulares, retoque de lo icónico). Quién dibuja ese 15-20 % es una decisión de proyecto abierta (el usuario no dibuja): hasta que se decida, se usa solo código y las piezas singulares se hacen en texto.
- Rotación de pixel art: solo por pasos (15° o 22,5°), sin interpolar; evita píxeles de distinta escala.

### 7.1 Extensión del rig por tipo de cuerpo

Seis tipos cubren el bestiario (detalle en `docs/reunion/artistas/05`, sección 2, y orden de construcción en `produccion-arte.md`): **H** humanoide con estilos nuevos (la mayoría), **A** armadura vacía, **Q** cuadrúpedo y artrópodo, **V** volador, **S** segmentado y **P** multiparte por piezas. Primero se extrae `tools/lib/raster.js` (primitivas) sin cambiar ninguna salida; cada tipo se construye cuando su primera criatura entra en el calendario, no antes.

## 8. Regiones (fichas resumidas)

Detalle largo en `docs/reunion/artistas/01` (sección 5) y `06` (secciones 3 y 4). Convención de parallax: factor de desplazamiento por capa (0 = fijo, 1 = igual que la capa de juego), tiras de 864 px periódicas.

| Región | Nivel | Rampas | Tinte | Luz | Fondo (capas) | Sensación |
|---|---|---|---|---|---|---|
| **Último Umbral** | 0 | Piedra, Tierra, Musgo; azul solo en el Ancla | cálido | Crepúsculo; Ancla y hogueras | cielo en bandas `1 a b c` con luna (0), colinas y muralla (0,15), tejados y humo (0,35), postes y árboles muertos (0,6) + niebla baja + primer plano | Refugio. Estándar de "memoria viva" |
| **Cinturón Yermo** | 1 (parches `g`) | Piedra, Tierra/Paja, Musgo | ocre | Mediodía lavado sin sol | cielo blanquecino, colinas en terraza (0,15), torres de riego y molinos (0,35), cercas y andamios (0,6) | Vacío ventoso. Viento con reloj de ráfaga compartido |
| *Cisterna, Galerías, Aljibe* | 1 | variante húmeda del Cinturón (piedra un tono más oscura, musgo, hilo `e f`) | azul verdoso | — | silueta de interior I1 | Transición, no región nueva |
| **Archivo** | 1 / 2 / 3 por sala | Piedra, Hueso (`8`), Ámbar (velas), Azul (sellos) | cálido casi neutro | Cuñas de claraboya, velas | pared de nave (0,05), estanterías (0,2), arcos y velas (0,45), escaleras (0,7) | Reverencia y borrado. Poco movimiento |
| **Minas** | 2 (emisivos a color) | Piedra muy oscura, Azul, Musgo (hongos), Tierra (vigas) | verdoso frío | Minerales, farolillos, resplandor del Caminante | negro con puntos (0,1), roca con vetas (0,3), vigas y raíles (0,6) | Claustrofobia. El color está en la luz |
| **Costa Retenida** | 0 (frío) | Piedra clara, Cal/Sal/Mar, Azul, Ámbar | cian | Cielo tormentoso, faroles | cielo (0,05), mar (0,15), acantilados (0,35), mástiles y velas (0,6) | Viento y hostilidad |
| **Herida** | 3 | Neutros y Piedra | ninguno | Blanca sin origen; sin halos | blanco (0,05), edificios mal recordados (0,2), bloques flotantes (0,5), sin primer plano | Ausencia |

- **Orden de construcción de regiones** (sujeto al mapa macro): Umbral, Cinturón, Archivo, Costa, Minas, Herida. Costa antes que Minas porque es la más barata (todo por código) y da el color de contraste.
- **Motivos transversales** que unen el mundo (reaparecen transformados en todas las regiones): cadenas (de pozo, arado, archivo, ascensor, ancla, sin eslabones), estandartes/velas/cortinajes, **el arco ciego** (portal, acueducto, bóveda, boca de mina, puerta de muralla, arco sin nada) y las marcas de nombres (tiza, grabados, lomos, tallados, tachados, líneas borradas).
- **Herida**: los bordes pierden resolución (hojas de terreno a 1, 2 y 4 px por bloque, declaradas por sala; los sprites del jugador y los enemigos no cambian). Solo conservan rojo los cascarones y los avisos. Estilo "plano" de enemigo (relleno plano, borde `x`) en lugar del contorno `1`.
- **Salas de jefe**: el fondo baja un tono respecto al de la región; el suelo mantiene el labio de luz; todo aviso rojo va en el suelo o en el aire sobre el suelo (decals de borde recto y dos tonos); misma reja de arena en todas; un solo foco narrativo por sala con la única luz cálida.

## 9. Personajes

### 9.1 El Caminante (Ansel Varga)

Cinco rasgos que no se tocan nunca: capucha puntiaguda con ribete ámbar, máscara azul en la mitad inferior del rostro, bufanda azul con inercia, daga curva empuñada del revés junto a la cadera, postura agazapada. Azul = Eco; ámbar = lo humano que sobrevive; rojo, jamás (los destellos de daño son del sistema de feedback). **No se desatura nunca.** Hoy (generado por `rig_caminante.js`): 58 fotogramas (reposo 10, correr 14, salto 4, caída 4, ataque 12, guardia 4, golpe 4, dash 6).

- **Lienzo 112×96** (el golpe hacia arriba y el Golpe Hondo no cabían en el antiguo 112×64; hecho en H0-03). La colisión no cambia. Es lo primero que se hace, antes de dibujar animaciones nuevas.
- **Animaciones que faltan**, por prioridad (detalle de poses en `04`, 1.5): *alta* `land`, `wall_grab`, `wall_slide`, `wall_jump`, `double_jump`, `die`, `respawn`, `attack_up`, `attack_down`, `heal`; *media* `dig` (cuando exista Excavar), `sit`/`rest`, `remember`, `climb`, `turn`, `listen`, `name`; *baja* `idle_long`, `interact`, `parry_ok`, `crouch`, `slide`, `knockback`, `win`. Las de prioridad alta salen casi todas con poses nuevas sin tocar el esqueleto; los cambios de rig (R2 `spinPose`, R3 puño lejano, R4 objetos en mano, R6 cabeza sin máscara, R7 anclajes exportados) se hacen cuando se pide la animación que los necesita.
- `heal`: se bebe **a través de la tela** de la máscara, sin mostrar piel (el rostro de Ansel solo se ve en el final Compartir). Decisión D-15.
- **Evolución visual**: cambios acumulativos con dueño (Oda, Tomasa, Jacinto, el Archivo, Magda, Linde), legibles en ≥ 4 px de silueta o ≥ 2 px de acento de color, nunca rojo y sin tapar los cinco rasgos. Se hornean en el rig en **tres hojas**: inicio; tras el Doble salto (bufanda larga con punta `h` y cuerda de vigía); tras Excavar (vendas de paja en los brazos, puño de tinta, muñequera, veta azul en la hoja). El cambio de textura se hace en la gran escena de la habilidad. El **ojo ámbar** y los trapos de Nombrar (etapa E6) quedan diferidos como cuarta hoja, a decidir con el usuario tras jugar (pendiente). Finales (sprites de epílogo): Sellar (sentado), Soltar (sin arte nuevo, el sombreador lo desvanece hacia `w`), Compartir (sin máscara, el único rostro visible).

### 9.2 PNJ

- **Cabeza `face`** nueva (óvalo con tres tonos de piel y un píxel de brillo en el ojo) y estilos de cuerpo `erguido`, `encorvado`, `niño`, `corpulento`, `túnica larga`, `armadura` y postura sentada. Detalle de los 12 PNJ en `04`, sección 2.
- **Regla de legibilidad principal: piel cálida contra piel gris.** PNJ: piel `8/6/5` con un píxel de brillo (`d` u `8`) en el ojo; enemigos y cascarones: piel `4/3/2` (cascarón: cabeza lisa sin rostro). Ningún PNJ lleva rojo; el lacre de la Orden es ocre `a/b`. Sin arma alzada, hombros horizontales, una luz ámbar propia (o dentro de un halo), solo en salas de calma, aviso de tecla a < 64 px.
- Lienzo 64×64 y paquete `idle` (8), `talk` (6), `react` (4). Los **estados del arco** se hornean como poses extra o `idle_2`; el plan reduce a **dos estados** por PNJ (ver cuadro de recortes en `produccion-arte.md`).
- **Saturación por fase**: el sombreador de desaturación acepta un parámetro por material; Iria, Quiteria, Casilda, Eudora y Gaspar se apagan literalmente al olvidar, sin arte nuevo.
- Prueba obligatoria: captura en grises junto a un cascarón y un lancero; captura a 864×486 con el PNJ a 8 px de un enemigo; el PNJ se entiende quieto.
- **Retratos**: hasta que haya diálogo con retrato, un **emblema de 16×16** junto al nombre (clavo, nudo, martillo, carro, círculo de cal, sello vacío, pluma, vela, pizarra, arpón). El generador de retratos de 48×48 por capas queda como recorte opcional.

## 10. Bestiario visual

Resumen y reglas; las 43 fichas, las nueve arenas, los VFX de jefe y la tabla de esfuerzo están en `docs/reunion/artistas/05`.

- **Cinco comunes ya existen** (cascarón, lancero, arrojador, coloso, acechador) y solo les falta la fila `death`. El bestiario completo del diseño tiene 48 entradas; el plan de arte construye una versión **reducida** (ver `produccion-arte.md`).
- **Lecturas obligatorias de silueta**: alcance (la longitud del arma a la vista = el alcance real, ±15 %), peso (lento = más ancho que alto), rol (quien invoca o apoya no lleva arma), estado (escudo arriba/abajo, cerrado/abierto se ven en la pieza, no en una barra). Cada diseño añade un rasgo de contorno propio (joroba, cuerno, arma, tamaño, cola); el tinte nunca basta.
- **Rojo en criaturas**: un enemigo *lleva* 2-8 píxeles de `s`/`t` (vendas, penacho, cinta), no *es* rojo. Los no hostiles se distinguen por no llevar rojo.
- **Ámbar** nunca en enemigos (salvo el hueco del Centinela y el trigo de Jacinto: la estela de su hoz y el campo que vuelve al caer; son efectos, no su cuerpo, y su ropa es de tierra y lino). Quien lleva luz la lleva apagada; la llama es un halo de Godot.
- **Élite** = misma familia que su base, +1 plantilla de tamaño (×1,15-1,3), un elemento nuevo de silueta y paleta propia. **Minijefe**: cuando se pueda, escala + recolor + un rasgo de una base existente.
- **Variantes**: un cuerpo se declara con cuatro ranuras de paleta (`skin`, `cloth`, `metal`, `accent`). Mientras no exista intercambio de paleta en sombreador, las variantes se obtienen regenerando el rig con otro estilo.
- **Jefes**: una persona con nombre y un verbo; el arte muestra *quién fue* (un objeto personal siempre visible) y *qué hace* (una silueta que cambia con el ataque). Llevan la menor cantidad de rojo posible. La fase 2 añade un rasgo visual con una capa de daño (sin cambiar de hoja). Los jefes humanoides van por hoja completa con atlas recortado (≤ 16 MB cada uno); solo los no humanoides de gran tamaño van por piezas, y solo se construye ese soporte para Maelis.
- **Muertes con restos** (capa del Sellador, tela del Hermano de Cal): máximo 3 restos vivos en una sala.

## 11. Entornos: baldosas, fondos y props

Detalle en `docs/reunion/artistas/06`.

**Baldosas.** Principio: **la letra del mapa dice el rol, el `TileSet` de la sala decide el material.** `T` suelo con piel, `G` roca de relleno, `B` sillar labrado, `C` remate, `S` tablón: el mismo `.map` con el tileset del Cinturón o con el del Archivo cambia de aspecto sin tocar una letra. El mapa sigue siendo una letra por baldosa.

- **Autotiling por código** (máscara de 4 bits de vecinas: 16 formas más esquinas interiores) en `TextTileMap`, no terrenos de Godot. Preferencia de arte; la decisión de implementación es de programación (pendiente, choque C-03).
- **Hoja de región de 256×144 px** (16 columnas × 9 filas = 144 baldosas) con el mismo orden de índices en todas las regiones; las cinco baldosas actuales conservan las posiciones 0-4. Filas: sueltas; `G` roca; `T` piel; `B` sillar; remates y plataformas; interiores y variantes; `g` desmemoriado; fronteras (la fila de pendientes se **reserva vacía**: el motor no tiene pendientes); daño y decales. El `TileSet` (`.tres`) se **genera por script**, no a mano.
- Se pintan a mano solo unas 12 piezas maestras de 16×16 por región; el resto lo deriva `tools/arte_tiles.js` (variantes con ruido determinista, esquinas, `g`, fronteras con 1 px de `w`, grietas en tres etapas). Comprobación automática de costuras (cada baldosa repetida 8×8 y cada pareja de vecinas).
- **Letras nuevas de arte** (preferencia; la leyenda definitiva la fija `docs/vertical-slice.md`): `g` terreno desmemoriado, `p` plataforma de una dirección no de madera, `m` muro trasero liso, `h` muro trasero con vano, `a` agua. Se descartan `/` y `\` (pendientes) hasta que el motor las soporte. Choques con otros documentos en `DECISIONES-EDITOR-ARTE.md`.
- Material por baldosa (capa de datos `material` del `TileSet`) para el sonido de pisadas: como mucho ocho sonidos distintos; la tabla de materiales por región está en `06`, sección 2.7, y la selección final es del sonido (ver `sonido.md`). La Herida no suena (`void`).

**Fondos.** Tiras PNG periódicas de 864 px generadas por `tools/arte_fondo.js` (cuatro capas de escena más una de primer plano y una de niebla cuando procede), `Parallax2D` con repetición (el proyecto está en Godot 4.7). Ninguna capa de fondo con tono 4 (salvo cielo y luces), sin rojo, capas lejanas sin contorno. ~2-3 MB de VRAM por región, una región cargada a la vez, fundido de 0,6 s al cruzar. Las salas sin cielo usan pared trasera (`m`/`h`) y seis siluetas de interior reutilizables (bóveda de cañón, arcadas, vigas, roca y raíles, muro con ventanas, blanco con huecos) que cambian de rampa con la región. Animación barata: autodesplazamiento, pequeños sprites de 2-4 fotogramas y parpadeo de un color de paleta.

**Props.** Las 13 letras de decorado actuales pasan a ser **roles** (árbol, columna, hierba, zarza, restos, estandarte, cadenas, estatua, mojón, poste, farol, arco ciego, enredadera) y la región decide el dibujo. Las piezas únicas van en un archivo de texto `sala.props` por sala (`id x y [espejo] [z]`). Hojas de celda 64×64 y 128×128 con manifiesto `props.txt`. Capas: `F2` z -2, `F1` z -1, `D1` z +1; sin colisión. Reglas: rango de valor 1-3, sin `t`/`u`, rastro humano en todo prop de región habitada, la pista en el dibujo y no en un cartel. Familias generadas por código con una forma maestra y recolor por rampa simbólica; solo lo singular se dibuja (la lista de 25 piezas se recorta, ver `produccion-arte.md`).

**Mecánicas visibles** (detalle en `06`, sección 6): toda causa y todo efecto remoto llevan un *testigo* de 6×6 px (apagado gris; ámbar fijo = hecho para siempre; ámbar que mengua = temporal); forma antes que color; lo interactuable muestra marca de uso; aviso previo uniforme (la pieza alterna dos fotogramas a ~12 Hz durante ≥ 0,4 s); nada en rojo.

## 12. Luz y atmósfera

- **Toda la luz son sprites aditivos precalculados con degradado en cuatro bandas** (no iluminación dinámica): un único juego de halos en blanco (48, 64, 96, 128 y 192 px de diámetro) que se tiñe con `modulate`; charco de luz bajo hogueras y Ancla; cuñas de claraboya de 48×192. `PointLight2D` solo con sombras desactivadas y solo si hace falta oscuridad. Un halo solo suma: nunca baja el valor de lo que ilumina.
- Fuentes: Ancla (la mayor luz ámbar de la zona, define una isla segura), reliquias (azul, más pequeñas, nunca más brillantes que el Ancla, latido a ~0,5 Hz), Eco (brillo propio, sin halo proyectado), faroles y antorchas (ámbar pequeño, parpadeo irregular, ausentes en la Herida), luz blanca sin origen en la Herida (sin halos salvo el Ancla y el Caminante). Toda luz pequeña conserva su color en cualquier nivel de desaturación.
- **Oscuridad total** (Minas): hay que hacer un prototipo de un día antes de comprometerse. Plan de reserva: sala de valor bajo (tonos 1-2) con los halos como únicas luces claras. Reglas de seguridad: peligros siempre visibles; la primera sala oscura tiene una luz visible desde la entrada; las plataformas reveladas muestran su contorno punteado. El resplandor propio del Caminante no se apaga nunca (80 px de diámetro según el diseño, pendiente de confirmar).
- **Partículas ambientales**: máximo 18 fijas por región (1-2 px, tonos de la rampa de la región, sin texturas propias: puntos de 1×1 a 4×4). Presupuesto global: ≤ 200 partículas vivas en pantalla y ≤ 20 por impacto; las 30 de la biblia de dirección se refieren a las ambientales más los eventos del jugador. Un componente genérico `burst_fx` en `core/` sustituye a los scripts sueltos de efectos.

## 13. Interfaz, efectos e iconografía

Detalle en `docs/reunion/artistas/03`.

- **Lenguaje**: la interfaz sigue la regla del color (lo que el jugador sabe, en color; lo que no, en piedra apagada). Cuatro colores de significado (ámbar = tuyo/interactuable, azul = recuerdo/habilidad/Eco, rojo = peligro/daño/jefe, musgo solo ambiental) más piedra. **Marcos de piedra**: borde de 2 px en `3`, relleno `1` casi opaco, una esquina cortada a 45°, filete interior en `2`; una única textura `NinePatchRect` de 24×24 generada por script. Todo en la rejilla de 8 px y a escala entera. Entrada de paneles "por enfoque" (0,18 s), salida 0,10 s; nada rebota en la interfaz.
- **Tipografía** (D-05): texto de juego y menús en **m5x7** (Daniel Linssen), fuente pixel de 7 px de altura; la página oficial (managore.itch.io/m5x7) la publica bajo **Creative Commons Zero 1.0** con atribución apreciada pero no exigida. Importarla con `antialiasing = none`, `hinting = none`, posicionamiento de subpíxel desactivado y tamaños enteros (7, 14, 21). Antes de incluirla: descargarla con permiso del usuario, comprobar que el archivo trae el texto de licencia, que cubre `ñ`, tildes, `¡` y `¿`, y apuntarlo en `docs/decisiones.md`. Rótulos grandes ("HAS RECORDADO", nombres de zona, muerte): alfabeto de 26 glifos dibujado por código a partir del generador del logotipo (`arte_titulo.js`), con serifas angulosas. Color de texto: principal `4`, resaltado `d`, desactivado `3`; contorno de 1 px en `1` para texto sobre el mundo.
- **Pantallas**: HUD (vida en placas de piedra con gema roja, frascos, Ecos, minimapa con oscurecido radial), pausa con vista previa viva, mapa por salas con patrón de relleno por zona (accesible sin color), menú del Ancla con nodos hexagonales de 32×32 y cadenas que se encienden, muerte ("HAS OLVIDADO", rótulo de piedra con un trazo ámbar, no rojo; texto pendiente de los escritores), victoria sobre jefe, "Has recordado: X" a pantalla casi completa, barra de jefe de dos barras (armadura gris, núcleo rojo, muescas de fase). El panel de **Reliquias** es contenido de diseño no decidido: fuera del alcance de arte hasta que el diseño lo pida.
- **Efectos**: golpes con chispazo por material (carne, hierro, piedra), parry con anillo azul, estela del dash, doble salto, salto de pared, curación ámbar, disolución del jugador en motas que forman el Eco, descanso en el Ancla, la gran escena de la habilidad recordada (la que más merece pulirse), impactos y muertes de jefe. Colores por origen: efectos del jugador en azul/blanco, de enemigos en rojo/naranja, de jefes con ámbar añadido. Estandarización de hit stop (golpe 0,06 s; parry 0,12; recibir daño 0,08; romper armadura 0,2) y temblor de cámara en tres perfiles con ajuste de intensidad: propuesta a validar jugando.
- **Iconografía**: silueta clara, contorno de 1 px en `1`, tres tonos de la rampa del significado y un punto de luz de 1 px. 16×16 (HUD, árbol, objetos) y 24×24 (habilidades, reliquias); 8×8 o 16×16 en el mapa. 32 iconos definidos en `03`, sección 4. Producción: los de 16×16 a mano en texto (`art/source/iconos.sprite`), los de 24×24 por script.

## 14. Accesibilidad

- La información crítica se apoya en forma además de color (rojo y azul se separan bien; el verde nunca lleva información de juego). Leyenda del mapa y marcadores con forma distinta por categoría. El aviso de ataque tiene forma (destello blanco en el arma, pulso a 8 Hz y, opcional, exclamación de 8×8 sobre la cabeza).
- Opciones que se añaden **solo cuando existe su efecto**: intensidad del temblor (0/50/100 %), reducir destellos (sin flashes de pantalla completa de más de 0,15 s ni más de 3 por segundo), contraste alto (contorno blanco de 1 px en enemigos y proyectiles), modo daltónico (aviso blanco-azulado y pulso más rápido), tamaño de texto 100/150 % (la fuente solo escala por enteros), remapeo de controles.
- Siluetas distintas por enemigo: se identifican por forma antes que por color.

## 15. Cómo se verifica el arte

1. **Prueba de escala de grises** (apartado 3) en cada tileset, fondo, enemigo y PNJ; se hace con la vista previa en grises generada por el validador.
2. **Validación al generar** (`build_sprites.gd`, paquetes H0-04 y H0-08), con salida 1 y mensaje en español: todos los píxeles en `palette.txt`; ninguna celda declarada vacía (< 12 píxeles opacos); ningún par de fotogramas consecutivos idéntico salvo lista `hold`; ningún píxel opaco en el borde del lienzo (salvo suelo); pies en la misma fila en `idle` y `walk` ± 1 px; cuerpo dentro de la colisión; porcentaje de contorno `1`; manifiesto coherente con el `.sprite`; presupuesto de VRAM; sin `t`/`u` en terreno, fondo ni decorado; tiras de fondo periódicas.
3. **Prueba de humo del arte** (`tests/smoke_test.gd`, sin regenerar): existe cada hoja, el tamaño de la textura coincide con el manifiesto, cada animación que declara una escena existe en su `SheetAnimator`, cada hoja respeta su presupuesto. Sustituye a las dos comprobaciones sueltas de hoy (96×64 del enemigo, 112×96 del jugador).
4. **Presupuesto de VRAM**: 0,5-4 MB por hoja de criatura, ≤ 16 MB por jefe, ≤ 150 MB residentes por sala, ≤ 6 MB de fondos cargados a la vez.
5. **Hoja de contactos por región** (enemigos, props y baldosas juntos, a escala) para revisar la coherencia, no solo cada pieza.
6. **Jugarlo**: los tests miden reglas, no sensaciones (regla de `CLAUDE.md`). Todo hito de arte se cierra jugando la región.

## 16. Sprites actuales (primera pasada)

| Sprite | Dibujo | Lienzo | Animaciones |
|---|---|---|---|
| Caminante (jugador) | 20×44, asesino agazapado y encapuchado, máscara azul, ribete ámbar en la capucha, bolsa en el cinto, capa con inercia; daga curva del revés con el puño junto a la cadera. Lo genera `rig_caminante.js` | 112×96 | reposo (10), correr (14, con líneas de velocidad), salto (4), caída (4), ataque (12, tajo con giro de muñeca y estela), guardia (4), golpe recibido (4), dash (6, con imágenes residuales) |
| Cascarón (enemigo, tajo) | 24×44, pálido y encorvado, sin rostro, vendas y trapos rojos; cuchillo pesado | 96×64 | reposo (8), andar (12), aviso (6), golpe (6), golpe recibido (4) |
| Lancero (estocada larga) | yelmo oxidado con penacho rojo, hombrera, bandolera; lanza de 36 px | 144×64 | las mismas cinco |
| Arrojador (a distancia) | encapuchado de rojo, flaco, esquirlas de hueso | 96×64 | las mismas |
| Coloso (mazazo) | 44×64, hombrera de hierro, mazo de piedra; el golpe levanta escombros | 144×96 | las mismas |
| Acechador (embestida) | casi a cuatro patas, garras; el golpe es un salto horizontal | 112×64 | las mismas |
| Esquirla (proyectil) | hueso afilado con estela roja | 16×16 | 2 fotogramas (`game/enemy/shard_sheet.png`) |
| Decorado del entorno | 13 piezas: árbol muerto, columna rota, hierba, zarza, huesos, estandarte, cadenas, estatua, mojón, poste, farol, arco ciego, enredaderas (a mano). Estandarte y poste usan rojo saturado: se corrigen (D-08) | 48×64 | una fila de 13 (`game/environment/decor_sheet.png`); lo que se apoya toca la fila de abajo y lo que cuelga la de arriba |
| Baldosas del Umbral | 5 baldosas: musgo, relleno, ladrillo, remate, tablón (a mano) | 16×16 | una fila de 5 (`game/levels/tiles_umbral.png`); el `TileSet` las usa por su posición |
| Iconos del HUD | frasco de curación (lleno y vacío, ámbar) y Eco (gota azul) | 16×16 | una fila de 3 (`game/ui/hud_icons.png`) |
| Eco (recuerdo de tu muerte) | 20×44, silueta del Caminante en azul que se deshace en jirones; flota. Lo genera `rig_eco.js` | 48×64 | flotar (4), `game/echo/echo_sheet.png` |
| Ancla de Memoria | Monumento de piedra con escalones, musgo, raíces, grietas, cadena rota y runas que pulsan; cristal azul con llama ámbar | 64×80 | brillo (8, bucle a 7 fps), `game/memory_anchor/anchor_sheet.png` |
| Objetos de habilidad | Tres reliquias de recuerdo cristalizado con núcleo, anillo de runas que gira y chispas: dash (remolino con cheurones), doble salto (ala de tres plumas), salto de pared (mano espectral ámbar-verdosa) | 48×48 | tres filas (`dash`, `double_jump`, `wall_jump`) de 8 en bucle a 8 fps, `game/ability_pickup/ability_sheet.png` |
| Centinela Hueco (jefe) | ~112×160, armadura vacía de un Custodio: hierro oscuro y oxidado, yelmo cerrado con hendidura ámbar, hombreras gigantes y mazo; las grietas laten en ámbar y, aturdido, asoma una figura pálida (punto débil). Lo genera `rig_centinela.js` | 384×256 | idle (12), walk (12), windup (10), strike (8; fotograma 5 = impacto), crouch (5), jump (3), fall (3), land (6), stagger (8), getup (6), death (12); hoja de 12×11 celdas, 49,5 MB (se recorta, H0-06), `game/boss/centinela_sheet.png` |
| Pinchos | Estacas de hierro oxidado con la punta clara sobre una placa; se rotan por código para techo y paredes (a mano) | 16×16 | 3 fotogramas: extendidos, a medias, retraídos; `game/environment/pinchos_sheet.png` |
| Roca | Trozo de techo desprendido, angular, con arista clara (a mano) | 16×16 | 1 fotograma, `game/boss/roca_sheet.png` |
| Logotipo | DESMEMORIA en fuente de píxeles gordos 5×7, ámbar con relieve, que se deshace; brillo azul. Lo genera `arte_titulo.js` | 456×88 | 12 fotogramas, `game/ui/title_logo.png` |

**Generados por código y no editables a mano**: el Ancla (`arte_ancla.js`: piedra, musgo, runas y cristal con ruido determinista; la luz —halo, charco, motas, destello y onda— son nodos de `memory_anchor.tscn`; su base queda 28 px bajo el origen de la escena, ver `room.gd`), los objetos de habilidad (`arte_habilidades.js`; la luz está en `game/ability_pickup/`), el Caminante, los enemigos, el Eco, el Centinela y el logotipo. Para cambiarlos se edita el generador y se regenera.

Son un primer dibujo funcional, no arte final. Las armas van integradas en el sprite (piezas superpuestas al cuerpo en cada pose) y el lienzo ancho deja sitio al arma extendida. Todavía no hay animación de muerte de enemigos, ni de jugador, ni agarre de pared.

El menú principal: el fondo (`game/ui/title_backdrop.gd`) no usa imágenes (cielo, estrellas, luna incompleta, colinas y ruinas, niebla, árboles muertos y brasas, todo por código), sobre un suelo de baldosas del juego (`game/ui/title.map`) con el Caminante y el Ancla. La pantalla **Controles** (`game/ui/controls_diagram.gd`) dibuja teclado y mandos de Xbox, PlayStation y Nintendo, con izquierda y derecha para cambiar de dispositivo.

## 17. Reglas sobre IA en el arte

- El usuario no dibuja. Claude no genera imágenes, pero sí escribe los sprites como texto con la paleta y revisa el resultado en las vistas previas. El usuario decide qué le gusta y puede retocar los PNG en Pixelorama o LibreSprite cuando quiera.
- Si más adelante se usa una herramienta de IA para sprites: revisar cada resultado, mantener la paleta de este documento y registrar qué parte es aportación humana. Steam solo pide declarar la IA cuyo contenido llega al jugador, y lo generado únicamente por IA no es registrable como obra en EE. UU. (ver `decisiones.md`). Ninguna de las dos cosas afecta a un proyecto personal.

## 18. Pendiente de decidir

- Quién dibuja el 15-20 % "a mano" (piezas maestras, props singulares, retoque de lo icónico): el usuario, un artista externo, o nadie (todo en texto).
- Si se versionan o no los `.sprite` generados por rigs (D-12).
- Texto de las pantallas de muerte y victoria (escritores) y de los mensajes de habilidad.
- Ojo ámbar y trapos del Caminante (cuarta hoja de evolución).
- Si el motor admite pendientes y paredes no escalables (afecta a las baldosas).
- Resplandor del Caminante en oscuridad (64 px de radio de la biblia frente a 40 del diseño).
- Equipo mínimo objetivo (afecta a presupuestos de partículas y VRAM).
- Zoom de cámara en jefes frente a arenas del tamaño de pantalla (las arenas propuestas son mayores que la pantalla de 54×30 baldosas).
