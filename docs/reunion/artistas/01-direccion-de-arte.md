# Biblia visual: dirección de arte

Autor: Director de Arte (sala de artistas). Estado: propuesta para la reunión; nada de esto está aprobado hasta que lo decida el usuario. Se apoya en `docs/arte.md`, `art/palette.txt`, `docs/mundo.md`, `docs/historia.md` y `docs/jefes.md`, y respeta sus restricciones: pixel art, 864×486 con escalado entero, rejilla de 16×16, un único autor con herramientas de código, máximo 32 colores.

Referencias como lenguaje, no como modelo: de *Hollow Knight* tomamos la legibilidad de la silueta sobre fondos densos; de *Blasphemous* y *Death's Gambit*, la paleta contenida y el peso de la arquitectura; de *Salt and Sanctuary*, la pobreza material creíble; de *Ori*, el uso de la luz como guía; de *Dead Cells*, la claridad del peligro en movimiento. La identidad propia es una sola idea: **el color es memoria**.

---

## 1. Pilares visuales

**P1. El color es memoria.** Lo recordado tiene color; lo olvidado, no. Un objeto cálido y saturado en un mundo apagado significa "alguien lo recuerda". Es la regla que manda sobre todas las demás: ante la duda, se quita color, no se añade.

**P2. Legibilidad antes que atmósfera.** A 864×486 un píxel de 1/486 de pantalla cuenta. Todo lo que el jugador pisa, golpea o esquiva se lee en un vistazo por *valor* (claro/oscuro) antes que por color. El fondo nunca compite con la capa de juego.

**P3. Siluetas contra luz.** El mundo es oscuro, pero lo importante se recorta contra una zona más clara (niebla, halo, cielo, página en blanco). Personajes y enemigos se reconocen por la forma de su contorno: encapuchado, lanza, mazo, encorvado.

**P4. Ruina con oficio.** Todo ha sido construido por alguien (piedra tallada, hierro forjado, estantes ordenados) y luego abandonado u olvidado. Nada de naturaleza caótica "porque sí": las formas orgánicas (musgo, raíces) invaden lo geométrico, y la Desmemoria lo borra por partes, no lo rompe.

### 1.1 Qué significa cada color

| Color (rampa) | Significa | Dónde aparece | Dónde **nunca** aparece |
|---|---|---|---|
| Ámbar (`a b c d`) | Memoria viva, calor, algo que alguien recuerda | Ancla, faroles, ribetes del Caminante, runas, hogueras, ventanas habitadas | Daño, enemigos |
| Azul frío (`e f g h`) | Recuerdo cristalizado, Eco, habilidad, la Desmemoria "desde dentro" | Eco, reliquias, máscara del Caminante, minerales de las Minas, agua de la Costa lejana | Peligro (para no confundir luz de ayuda con trampa) |
| Rojo (`r s t u`) | Peligro, sangre, aviso de ataque, enemigo | Ropas y detalles de enemigos, avisos, pinchos con la punta, proyectiles | Decorado inocuo, UI de ayuda |
| Musgo (`m n o p`) | Vida lenta, lo que sigue creciendo | Musgo, hierba, raíces, enredaderas | Zonas de desaturación 3 |
| Piedra (`1 2 3 4`) | El mundo construido | Muros, suelos, arquitectura | Nada: es el fondo por defecto |
| Neutros (nuevos `0 x y w`) | Lo olvidado: sin color ni dueño | Herida, pasillos en blanco, cascarones sin vendas rojas | Zonas de desaturación 0 |
| Tierra y paja (nuevos `5 6 7`) | Oficio humano pobre: madera, tierra, cultivo | Umbral, Cinturón, andamios, tejados | Herida |
| Hueso y sal (nuevos `8 9 v`) | Papel, hueso, cal, espuma | Archivo, Costa, huesos del decorado | — |

Regla de oro: **las tres señales activas (ámbar, azul, rojo) no se mezclan en un mismo objeto**, salvo el Ancla (azul + ámbar) y el Centinela (hierro + ámbar + rojo de aviso), que son excepciones deliberadas y ya existen.

### 1.2 Gramática de forma y silueta

| Familia | Forma dominante | Ejemplo | Lectura |
|---|---|---|---|
| Jugador | Diagonal agazapada, capucha puntiaguda, capa que arrastra | Caminante | "Rápido, ágil, solitario" |
| Enemigo humano-cascarón | Vertical encorvada, sin rostro | Cascarón, Lancero | "Cuerpo sin dueño" |
| Enemigo pesado | Bloque ancho y bajo con arma enorme | Coloso, Centinela | "Lento, golpe fuerte; esquiva, no bloquees" |
| Enemigo ágil | Horizontal, a cuatro patas | Acechador | "Embestida; salta" |
| Arquitectura | Rectángulos y arcos de medio punto | Muros, arco ciego | "Orden, intención" |
| Naturaleza | Curvas y diagonales irregulares | Raíces, árbol muerto | "Invasión, tiempo" |
| Lo olvidado | Bordes **rectos y sin textura**, superficies planas | Herida | "Borrado": la ausencia de detalle es la señal |

### 1.3 Capas de valor y contraste (el sistema de legibilidad)

La imagen se construye en cinco capas con un **rango de valor propio**. Es la regla más importante para el autor único: no hace falta mirar cada sala, basta respetar el rango.

| Capa | Rango de valor (rampa de 4 tonos; 1 = oscuro) | Saturación | Contorno |
|---|---|---|---|
| Fondo lejano (parallax 1) | tono 1–2, ligeramente más claro en el horizonte (niebla) | muy baja | ninguno |
| Fondo medio (parallax 2) | tono 1–2 | baja | ninguno |
| Fondo cercano (parallax 3) | tono 1–3 | media-baja | oscuro, solo siluetas |
| **Capa de juego** (plataformas, enemigos, jugador) | tono 2–4 | normal de la región | oscuro 1 px donde toque otra superficie |
| Primer plano (columnas, hierba, niebla baja) | tono 1 (casi negro), alguna silueta con borde de luz | — | ninguno; semitransparente si tapa algo importante |

Consecuencias prácticas:

- **Plataformas transitables.** Toda superficie que se pisa lleva un **borde superior de 1 px en el tono 4 de la rampa de la región** (el "labio de luz") y una cara frontal en tono 2. Es lo único de la capa de juego con tono 4 fuera de enemigos y reliquias, así que el ojo aprende "línea clara = suelo". Plataformas de una sola dirección (andamios, pasarelas): labio de luz en **ámbar tono 2 (`b`)** con soportes visibles debajo. Nunca hay un labio claro en el fondo.
- **Paredes escalables** (salto de pared): bordes con muescas verticales y 1 px de tono 3 cada 3–4 tiles; las no escalables son lisas.
- **Peligros del entorno.** Los pinchos conservan la punta en tono claro rojizo (`u`, ya existente) sobre fondo siempre de piedra oscura; **ningún rojo en el fondo ni en el decorado** de ninguna región (se prohíbe `t` y `u` fuera de lo dañino). Agua o ácido dañinos, cuando existan: azul tono 3 con borde de espuma, nunca rojo ni ámbar.
- **Jugador.** El Caminante es oscuro: sobre la capa de juego (tono 2–4) se recorta por la máscara azul, el ribete ámbar y el contorno. Regla: **el fondo detrás del jugador nunca baja del tono 2 de la región en la capa de juego**, o se pierde. En salas de oscuridad (Minas) se usa luz propia del jugador (apartado 4).
- **Enemigos.** Se leen por el rojo (vendas, penacho) sobre cuerpos pálidos. Es el único objeto de la capa de juego con rojo saturado. El aviso de ataque mantiene el destello `u`/`t` (por decidir en Diseño de combate, no aquí).
- **Prueba de legibilidad obligatoria**: cada tileset y cada fondo se revisa con la captura convertida a escala de grises. Si el jugador, los enemigos o las plataformas no se distinguen en gris, el arte no se da por bueno.

---

## 2. Paleta ampliada (31 de 32 colores)

La paleta actual tiene 20 colores (cinco rampas de 4). Se añaden **11 colores nuevos** y se deja **1 hueco libre** (`z` reservado) para lo que aparezca al jugar.

| Cód. | Hex | Nombre | Rampa | Uso principal |
|---|---|---|---|---|
| `1` | `#1b1a1f` | Piedra 1 | Piedra | existente |
| `2` | `#3a3840` | Piedra 2 | Piedra | existente |
| `3` | `#6a6670` | Piedra 3 | Piedra | existente |
| `4` | `#a39fa8` | Piedra 4 | Piedra | existente |
| `a` | `#4a2b12` | Ámbar 1 | Memoria | existente |
| `b` | `#8a5320` | Ámbar 2 | Memoria | existente |
| `c` | `#d18a2e` | Ámbar 3 | Memoria | existente |
| `d` | `#f3c46a` | Ámbar 4 | Memoria | existente |
| `e` | `#12283a` | Azul 1 | Recuerdo | existente |
| `f` | `#1f5573` | Azul 2 | Recuerdo | existente |
| `g` | `#4aa3c7` | Azul 3 | Recuerdo | existente |
| `h` | `#a9e3f2` | Azul 4 | Recuerdo | existente |
| `r` | `#3a1218` | Sangre 1 | Sangre | existente |
| `s` | `#7a2430` | Sangre 2 | Sangre | existente |
| `t` | `#c2453f` | Sangre 3 | Sangre | existente |
| `u` | `#f08a6a` | Sangre 4 | Sangre | existente |
| `m` | `#15241a` | Musgo 1 | Musgo | existente |
| `n` | `#2c4a30` | Musgo 2 | Musgo | existente |
| `o` | `#587a4a` | Musgo 3 | Musgo | existente |
| `p` | `#9cb57a` | Musgo 4 | Musgo | existente |
| `0` | `#0a090d` | Vacío | Neutros | **nuevo**: negro de contorno y oscuridad total; más oscuro que Piedra 1 para que haya un "bajo" por debajo de todo |
| `x` | `#55555a` | Gris oscuro | Neutros | **nuevo**: lo olvidado, sombra sin tinte |
| `y` | `#8c8c8f` | Gris medio | Neutros | **nuevo**: lo olvidado, plano medio sin tinte |
| `w` | `#efe9d6` | Página en blanco | Neutros | **nuevo**: el blanco de la Herida y de las hojas rasuradas; el color más claro del juego |
| `5` | `#3d2a22` | Madera oscura | Tierra | **nuevo**: vigas, tierra húmeda, cuero |
| `6` | `#6b4a36` | Madera/tierra | Tierra | **nuevo**: tablas, tierra seca, cuero claro |
| `7` | `#8f7d45` | Paja seca | Tierra | **nuevo**: cultivo muerto, tejados de paja, hierba seca |
| `8` | `#cfc4a8` | Hueso / pergamino | Cal | **nuevo**: papel, hueso, cal de muro (sustituye a mezclar Piedra 4 con ámbar) |
| `9` | `#b9d6d2` | Sal | Cal | **nuevo**: espuma, escarcha de sal, vidrio de la Costa |
| `v` | `#2f6f73` | Mar | Cal | **nuevo**: agua marina, algas, pátina de bronce de la Costa |
| `z` | — | libre | — | reservado; no usar hasta decidir |

Notas de diseño de la paleta:

- Los nuevos **no forman rampas completas de 4**; son tres mini-rampas de 2-3 tonos (Tierra, Cal/Mar, Neutros). Es una decisión consciente: el coste en colores de una rampa nueva completa (4) es demasiado alto para 6 regiones. La tercera dimensión de cada región sale de **mezclar rampas** (por ejemplo, el Cinturón usa Piedra + Tierra + Musgo), no de añadir una por región.
- **Cada región usa como máximo 3 rampas principales + las señales activas** (ámbar, azul, rojo en pequeñas dosis). Así cada una tiene personalidad inmediata aunque comparta paleta global.
- Los **neutros** (`0 x y w`) son lo que queda cuando la desaturación llega al máximo: la Herida es, literalmente, la paleta sin color.
- Antes de añadir cualquier color a `art/palette.txt` debe revisarse que los generadores existentes no usan `0 5 6 7 8 9 v w x y` con otro sentido (la leyenda de `.sprite` y `.map` no coincide necesariamente; **comprobarlo** antes de integrar). Pregunta abierta nº 1.

---

## 3. Progresión de la desaturación

### 3.1 Concepto

La desaturación no es un filtro estético, es **la lectura del estado de la memoria**. Tres principios:

1. **Se mide por distancia a la Herida, no por orden de visita.** La Costa Retenida (periferia) es la zona *menos* afectada aunque el jugador la visite tarde. Esto evita que el mapa se lea como un túnel gris lineal y refuerza la lógica radial de `mundo.md`.
2. **El protagonista no se desatura jamás.** No puede olvidar: el Caminante, el Eco, las Anclas y las reliquias son lo único que **conserva su color completo en toda región**. Cuanto más gris está el mundo, más destacan. Es el efecto narrativo más fuerte y no cuesta nada.
3. **La desaturación varía dentro de una región**: la Cisterna y los pasillos del Archivo alternan salas a nivel 1 con salas a nivel 3 ("pasillos en blanco"). El nivel se declara **por sala**, no por región.

### 3.2 Los niveles

| Nivel | Nombre | Saturación restante | Efecto sobre el valor | Ejemplo |
|---|---|---|---|---|
| 0 | Recordado | 100 % | normal | Último Umbral, Costa |
| 1 | Desgastado | ~70 % | normal | Cinturón (parches sanos), Archivo intacto |
| 2 | Deshilachado | ~35 % | sube ligeramente el tono 1 (menos contraste en sombras) | Minas, Archivo erosionado |
| 3 | Borrado | ~5 % | planos más lisos y más claros; contorno más fino | Herida, pasillos en blanco |

Los enemigos de una zona se desaturan con ella, **excepto el rojo de aviso**, que se mantiene al 100 % siempre: la legibilidad del peligro no se sacrifica a la narrativa.

### 3.3 Cómo se implementa (recomendación: lo más simple)

Se evaluaron tres opciones:

| Opción | Cómo | Ventajas | Inconvenientes | Veredicto |
|---|---|---|---|---|
| A. Paletas alternativas horneadas | Regenerar cada tileset/fondo en 4 versiones | Control total, sin sombreador | x4 en PNG, tiempo de generación y memoria; difícil mezclar niveles dentro de una región | Descartada |
| B. Sombreador de reemplazo de paleta (LUT) | Mapea cada color a otro por tabla | Preciso | Complejo; exige que el arte use solo los colores exactos | Descartada por ahora |
| **C. Sombreador de desaturación con parámetro global** | Un único `canvas_item` shader que mezcla el color con su luminancia (`mix(color, gris, d)`) y un tinte opcional | Una línea de lógica; sirve para fondos, tiles y enemigos; el nivel se interpola entre salas | El resultado no está limitado a 32 colores exactos | **Recomendada** |

Detalle de C:

- Un **uniform global** (`global uniform float desaturacion` y `global uniform vec3 tinte`) definido en el proyecto. Cada sala fija su valor al cargarse; al cruzar de sala se interpola en ~0,6 s junto con el desplazamiento de cámara.
- El material con el sombreador se asigna a: capas del `TileMap`, capas de parallax, decorado y **enemigos**. **No** al jugador, al Eco, al Ancla, a las reliquias ni a la UI (todo eso queda a color completo por diseño, ver 3.1.2).
- `d` (0-1) por nivel: 0 → 0, 1 → 0,3, 2 → 0,65, 3 → 0,95. El sombreador también aplica un gamma suave en niveles 2-3 para subir los negros.
- El tinte (`vec3`) permite que cada región tenga una dominante (cálida en el Yermo, verdosa en las Minas, cian en la Costa) sin duplicar assets.
- **Coste de producción**: un sombreador de ~15 líneas, y una propiedad `desaturacion` y `tinte` en el script de sala (`room.gd`). El arte se pinta siempre a color pleno (nivel 0) y el sombreador hace el resto. Importante para la carga de trabajo del autor único: **no se mantienen versiones.**
- Si algún día se quiere forzar los 32 colores exactos, se puede añadir una cuantización tras el sombreador. No ahora.

Lo que se ve en el juego: entrar en una sala de nivel 3 con el Caminante a color completo sobre un fondo casi gris.

---

## 4. Iluminación y partículas

### 4.1 Reglas de iluminación

El mundo es oscuro de base, pero **sin negro absoluto** salvo en las Minas: el tono 1 de la rampa de la región es el "negro" de la capa de juego; `0` solo se usa para contorno y oscuridad total.

| Fuente | Tratamiento | Reglas |
|---|---|---|
| **Ancla de Memoria** | Halo aditivo ámbar (ya existe) + charco de luz en el suelo + motas | Radio ≈ 96 px. Es la única luz ámbar grande de la zona; define una "isla segura". Dentro del halo el sombreador de desaturación **se suaviza** (el color vuelve ~30 %), porque la memoria se reaviva ahí. Coste: un solo efecto adicional en el sombreador usando un uniform de posición/radio. Opcional, ver preguntas. |
| **Reliquias de habilidad** | Halo aditivo azul, más pequeño (radio ≈ 48 px), latido lento | Nunca más brillante que el Ancla. Latido a ~0,5 Hz. |
| **Eco** | Brillo azul propio, sin halo proyectado | Se lee por silueta y por parpadeo; evitar que ilumine el entorno para no confundirse con una reliquia. |
| **Faroles, antorchas, brasas** | Halo aditivo ámbar pequeño (radio 32-48 px), parpadeo irregular | Fuente de **calor humano**: solo donde alguien vive o vivió. Ausentes en Herida. |
| **Linterna del jugador** (sólo Minas y salas oscuras) | Halo circular blanco-cálido de ~64 px alrededor del Caminante, recorte duro con un anillo tenue | Permite oscuridad total sin perder legibilidad. Si se prefiere no tener herramienta, el Caminante lleva un amuleto ámbar (ya hay ribete ámbar). Ver preguntas. |
| **Luz de ventana / cielo** | Cuña clara (tono 3-4) desde arriba con polvo | Ayuda a leer verticalidad; no proyecta sombras duras |
| **Luz de la Herida** | Luz blanca difusa sin foco (`w`) | No tiene origen; ilumina por igual y sin sombras (lo contrario de la iluminación del resto del juego) |

Técnica: toda la luz se hace con **sprites aditivos precalculados** (círculos con degradado en pasos de 4 tonos, no gradiente suave, para mantener el aspecto pixel art), no con iluminación dinámica de Godot. El motivo: control total, coste mínimo y el aspecto "por bandas" encaja con la estética. Un nodo `Light2D` de Godot se puede usar solo si se desactivan las sombras.

**Oscuridad total** (Minas): sala con un `CanvasModulate` casi negro y solo se ven luces. Regla de seguridad: **los peligros del entorno (pinchos, abismos) deben tener siempre un tono ámbar tenue propio o un reflejo azul** que se ve incluso sin luz directa; no se permite matar al jugador por algo invisible. La primera vez que el jugador entra a una zona de oscuridad total debe haber una fuente de luz visible desde la entrada.

### 4.2 Partículas ambientales

Máximo **30 partículas simultáneas por pantalla**, 1-2 px, siempre en tonos de la rampa de la región (sin colores propios). Se implementan con `GPUParticles2D` o `CPUParticles2D` sin texturas especiales.

| Región | Partícula | Movimiento | Color |
|---|---|---|---|
| Último Umbral | Brasas, ceniza de hoguera, polvo en haces de luz | Ascienden despacio / derivan | `c`, `d`, `4` |
| Cinturón Yermo | Polvo, briznas de paja, hojas secas | Horizontales, viento constante con ráfagas | `7`, `6`, `3` |
| Archivo | Motas de papel y polvo en haces de luz; hojas de pergamino que caen | Caen lentas y se mecen | `8`, `4` |
| Minas | Esporas luminosas, goteo, polvo de roca | Flotan; gotas caen | `g`, `h`, `3` |
| Costa | Espuma, sal, gaviotas lejanas (silueta, no partícula) | Horizontales rápidas con el viento | `9`, `4` |
| Herida | Fragmentos de "página" que **no caen ni suben**: se desprenden del entorno y se disuelven | Giro lento, sin gravedad | `w`, `y` |
| Todas | Chispas del golpe, polvo del salto, hojas del aterrizaje | Eventos del jugador | tonos del suelo |

---

## 5. Fichas por región

Convenciones: las capas de parallax se numeran de lejos a cerca con su factor de desplazamiento respecto a la cámara (0 = fijo, 1 = igual que la capa de juego). Todas son tiras de 16 px de rejilla repetibles horizontalmente salvo indicación.

### 5.1 El Último Umbral — "el último lugar que se acuerda"

| Aspecto | Propuesta |
|---|---|
| **Desaturación** | **0** |
| **Rampas** | Piedra, Ámbar, Tierra (`5 6 7`), Musgo; azul solo en el Ancla |
| **Tinte** | cálido (+ámbar suave) |
| **Iluminación** | Crepúsculo anaranjado; farolillos y hogueras de refugiados; Ancla como centro visual |
| **Atmósfera** | Niebla baja ligera; ceniza y brasas |
| **Arquitectura y materiales** | Chabolas de tablas y tejados de paja y lona remendada; muro de piedra bruta con parches de madera; barricadas de carros. Todo **pobre y reparado**: tela atada, cuerdas, clavos |
| **Flora/fauna** | Hierba amarillenta, zarzas, un árbol muerto grande; cuervos en silueta; ningún bicho hostil de fondo |
| **Parallax** | (0,05) cielo en degradado por bandas de 4 tonos, luna incompleta; (0,15) colinas lejanas con silueta de la muralla; (0,35) tejados y humo de chozas; (0,6) postes, banderines y árboles muertos; primer plano (1,3) hierba y vigas |
| **Motivos** | Banderines remendados, cadenas, pozos, **el ámbar de las ventanas**; marcas de tiza en muros ("nombres de los desaparecidos") |
| **Al entrar** | Primera pantalla: es el cuadro más colorido del juego y debe establecer el **estándar de "memoria viva"** contra el que se medirá el resto |
| **Cambio de tono** | — (punto de partida) |

### 5.2 El Cinturón Yermo — "el campo que olvidó que daba de comer"

| Aspecto | Propuesta |
|---|---|
| **Desaturación** | **1 con parches de 3** (mancha de gris plano en una terraza concreta) |
| **Rampas** | Piedra, Tierra/Paja (`5 6 7`), Musgo; Ámbar en faroles |
| **Tinte** | ocre seco |
| **Iluminación** | Luz de mediodía lavada, cielo pálido sin sol; sombras largas hacia abajo; poca luz cálida (hogueras escasas) |
| **Atmósfera** | Viento constante, polvo, niebla de calor en el horizonte |
| **Arquitectura y materiales** | Terrazas de piedra seca apiladas; torres de riego con acueductos secos; graneros de madera a medio caer; andamios de tablas atados con cuerda (**plataformas de una sola dirección**) |
| **Flora/fauna** | Espigas muertas, cercas, espantapájaros; **campos grises**: un parche de hierba con la textura eliminada (plano, sin brizna) |
| **Parallax** | (0,05) cielo blanquecino; (0,15) cadena de colinas escalonadas en terrazas; (0,35) torres de riego y molinos de agua sin aspas; (0,6) cercas, espigas y andamios sueltos; primer plano (1,3) tallos secos |
| **Motivos** | Espantapájaros con ropa de rojo apagado (ojo: nada de rojo saturado en decorado, solo `s` sobre `r`, nunca `t`/`u`), aspas rotas, surcos, acequias secas, **parches grises con borde recto** |
| **Al entrar** | Se baja del refugio y el cielo se abre; el jugador ve por primera vez un parche gris con bordes rectos: la Desmemoria como forma, no como niebla |
| **Cambio de tono** | Del cobijo cálido al espacio abierto y polvoriento; de "pobre pero vivo" a "vacío con vida residual". La paleta pierde ámbar y gana ocre |

Zona de transición **Terrazas Secas → Cisterna** (caída): salas de piedra más oscura, humedad, musgo y goteo; el tinte pasa de ocre a azul-verdoso a mitad de la caída (fundido por sala).

### 5.3 El Archivo — "una biblioteca que ya no recuerda sus libros"

| Aspecto | Propuesta |
|---|---|
| **Desaturación** | **1 en salas intactas, 2 en las erosionadas, 3 en los pasillos en blanco** (varía por sala) |
| **Rampas** | Piedra, Hueso/Pergamino (`8`), Ámbar (velas y lámparas), Azul (sellos y runas de las salas de sellado) |
| **Tinte** | cálido casi neutro |
| **Iluminación** | Haces verticales polvorientos desde claraboyas altas; velas y lámparas de aceite (halos ámbar pequeños y estables); salas de sellado con luz azul tenue de runas |
| **Atmósfera** | Polvo en suspensión, hojas sueltas, silencio visual (**poco movimiento**: contraste con el Yermo ventoso) |
| **Arquitectura y materiales** | Bóvedas de cañón, arcos apuntados, **estanterías-torre** de cuatro a seis pisos con escaleras de caracol (la plataforma vertical natural); pupitres de escriba; sellos de cera; hierro y bronce deslucido; los **pasillos en blanco** son tiles planos de `w`/`y` sin junta ni textura |
| **Flora/fauna** | Casi ninguna. Palomas disecadas, polillas (partículas lentas), libros que "respiran" (animación de 2 frames) |
| **Parallax** | (0,05) pared de la sala con ventanales altos; (0,2) filas de estanterías en perspectiva (siluetas muy oscuras); (0,45) arcos y columnas con velas; (0,7) escaleras y pasarelas; primer plano (1,4) cortinajes y lámparas colgantes |
| **Motivos** | **Páginas**: hojas flotando, lomos de libros ordenados por colores (la diferencia entre ordenado y vacío narra la Desmemoria), sellos azules, tinteros, cadenas de archivo, **estantes que acaban de golpe en blanco** |
| **Al entrar** | La escala: espacios verticales gigantes y ordenados tras el campo abierto. Silencio |
| **Cambio de tono** | Del viento y el cielo al interior cerrado y reverente; de la ruina natural a la ruina **burocrática**. Más frío y estático |

### 5.4 Las Minas del Origen — "se cavó hacia dentro, buscando algo que ya estaba dentro"

| Aspecto | Propuesta |
|---|---|
| **Desaturación** | **2** (roca) pero **el mineral y los hongos conservan color** (se renderizan sin el sombreador, igual que el Ancla) |
| **Rampas** | Piedra muy oscura (tonos 1-2 casi todo), Azul (mineral luminoso), Musgo (hongos), Ámbar (farolillos de la Orden y vagonetas) |
| **Tinte** | verde-azulado frío |
| **Iluminación** | **Oscuridad casi total**: solo luz de los minerales (azul, halos 24-48 px), lámparas ámbar viejas y la linterna del jugador. Charcos reflectantes |
| **Atmósfera** | Goteo, vapor tenue, esporas |
| **Arquitectura y materiales** | Galerías apuntaladas con vigas de madera (`5 6`), raíles, vagonetas, ascensores de cadena, picos clavados en la roca; **estratos de roca visibles**; cada tanto, un arco del Archivo "enterrado" para marcar el nexo con la superficie |
| **Flora/fauna** | Hongos bioluminiscentes, cristales, murciélagos silueta, criaturas pálidas de ojos grandes y sin color |
| **Parallax** | Poco parallax: (0,1) negro con puntos de mineral lejano; (0,3) paredes de roca con vetas luminosas; (0,6) vigas y raíles; primer plano (1,3) estalactitas y cadenas |
| **Motivos** | Vetas azules que **laten con el Eco más cercano**; marcas de pico; tarjetas de turno y nombres tallados en vigas; **raíles que bajan siempre** |
| **Al entrar** | Casi negro; se enciende la luz del jugador o el primer cristal. Lo primero que se ve es una luz azul a lo lejos |
| **Cambio de tono** | De lo ordenado y alto a lo oscuro y claustrofóbico; la paleta se invierte: el color está **en la luz**, no en el entorno |

### 5.5 La Costa Retenida — "lo que se aferra al borde"

| Aspecto | Propuesta |
|---|---|
| **Desaturación** | **0** (la más viva después del Umbral), pero con un matiz de frío |
| **Rampas** | Piedra clara, Cal/Sal (`8 9 v`), Azul, Ámbar (faroles de los Descreídos), un poco de Tierra |
| **Tinte** | cian fresco |
| **Iluminación** | Cielo tormentoso con rendijas de luz fría; faros y faroles ámbar en los asentamientos; reflejos de mar |
| **Atmósfera** | Viento salino fuerte, espuma, nubes rápidas, lluvia ocasional |
| **Arquitectura y materiales** | Asentamientos altos sobre acantilados: muros encalados (`8`), contrafuertes, tejados de pizarra, puentes colgantes de cuerda, faros apagados, anclas y cadenas de barco; **defensas** (ballestas, empalizadas) hacia el interior |
| **Flora/fauna** | Hierba rasa, líquenes, gaviotas, cangrejos; algas en los muros bajos |
| **Parallax** | (0,05) cielo con nubes en bandas; (0,15) mar con horizonte y rocas lejanas; (0,35) acantilados lejanos con asentamientos; (0,6) mástiles, redes y velas rasgadas; primer plano (1,3) cuerdas y espuma |
| **Motivos** | Velas rotas, redes, cuerdas, anclas, balizas; **símbolos tachados** de la Orden (el rechazo de los Descreídos al archivo): lo opuesto a las marcas del Archivo |
| **Al entrar** | Un horizonte abierto de mar con **color vivo** tras las Minas oscuras. Alivio visual, no alivio narrativo: hay gente hostil |
| **Cambio de tono** | Del subsuelo gris-verde a la luz fría y el color; el jugador siente que "el mundo aún recuerda" aquí, y por eso es político: los Descreídos eligen olvidar |

### 5.6 La Herida — "el sitio donde nunca ocurrió nada"

| Aspecto | Propuesta |
|---|---|
| **Desaturación** | **3** (todo, salvo el jugador y la Memoria que lleva) |
| **Rampas** | Solo Neutros (`0 x y w`) y Piedra; **un único acento**: lavanda tenue `z` (reservado) para "lo que no existe", o ninguno |
| **Tinte** | ninguno |
| **Iluminación** | Luz blanca sin fuente y sin sombras; **ausencia total de halos** salvo el del Caminante y de su Ancla |
| **Atmósfera** | Fragmentos de página que se desprenden y se disuelven; silencio de partículas; sin niebla (la niebla sería "algo") |
| **Arquitectura y materiales** | Los elementos de las demás regiones **reaparecen sin textura**: arcos sin juntas, estanterías en bloques planos, un árbol hecho de un solo tono. Los bordes pierden la resolución: pasa de píxeles pequeños a **bloques de 2×2 y 4×4** (pixelado grueso) a medida que se avanza |
| **Flora/fauna** | Ninguna. Cascarones sin vendas rojas (**solo ellos conservan el rojo de aviso**, para que se lea el peligro) |
| **Parallax** | (0,05) blanco con degradado a gris; (0,2) siluetas de edificios de las otras regiones, mal recordadas; (0,5) bloques planos flotantes; primer plano: ninguno (el primer plano sería "algo") |
| **Motivos** | **La página rasurada**: líneas de texto que se borran, lomos sin título, arquitectura que es "el recuerdo de una arquitectura"; el Eco del Caminante es la única mancha azul |
| **Al entrar** | Un pasillo en el que el color del mundo termina por una línea recta; el jugador cruza y se queda como único objeto con color |
| **Cambio de tono** | De la oscuridad con luces a la **claridad sin nada**. Inquietud por ausencia, no por sombra |

### 5.7 Resumen comparativo

| Región | Desat. | Dominante | Luz principal | Silueta de fondo | Sensación |
|---|---|---|---|---|---|
| Último Umbral | 0 | Ámbar / tierra | Hogueras, Ancla | Muralla y tejados | Refugio |
| Cinturón Yermo | 1 (+parches 3) | Ocre / paja | Cielo lavado | Terrazas y torres de riego | Vacío ventoso |
| Archivo | 1-3 por sala | Hueso / piedra | Claraboyas y velas | Estanterías-torre | Reverencia y borrado |
| Minas | 2 (+luz a color) | Azul-verde / negro | Minerales | Roca y raíles | Claustrofobia |
| Costa | 0 | Cian / cal | Cielo tormentoso | Acantilados y mar | Viento y hostilidad |
| Herida | 3 | Blanco / gris | Sin origen | Ecos mal recordados | Ausencia |

---

## 6. Motivos transversales (para unir el mundo)

Para que las regiones no parezcan "biomas aislados", cuatro motivos reaparecen en todas, transformados:

| Motivo | Umbral | Cinturón | Archivo | Minas | Costa | Herida |
|---|---|---|---|---|---|---|
| **Cadenas** | de pozo | de arado | de archivo | de ascensor | de ancla | sin eslabones |
| **Estandartes / velas** | banderines remendados | espantapájaros | cortinajes | tarjetas de turno | velas rasgadas | un rectángulo plano |
| **El arco ciego** (arco sin puerta, ya en el decorado) | portal de entrada | acueducto | bóvedas | boca de mina | puertas de muralla | un arco sin nada |
| **Marcas de nombres** | tiza en muros | grabados en postes | lomos | tallados en vigas | tachados | líneas borradas |

Un jugador que haya recorrido el mundo reconocerá "el arco" en todas partes, y verá cómo se va quedando sin contenido.

---

## 7. Lista de producción por prioridad

Esfuerzo relativo en **puntos** (1 punto ≈ una sesión corta de trabajo con las herramientas actuales; S = 1-2, M = 3-5, L = 6-10, XL = 11+). Las estimaciones suponen reutilizar los generadores y la cadena de `rig_lib.js` ya existentes.

### Fase A. Fundamentos (para que todo lo que ya existe se vea coherente)

| # | Tarea | Esfuerzo | Por qué primero |
|---|---|---|---|
| A1 | Ampliar `art/palette.txt` con los 11 colores y fijar convenciones de código | S (1) | Todo depende de ello; comprobar conflictos con los caracteres actuales |
| A2 | Sombreador de desaturación + uniform global + propiedad por sala | S (2) | Desbloquea cuatro regiones con un único tileset base |
| A3 | Prueba de escala de grises y checklist de legibilidad (apartado 1.3) | S (1) | Define el listón de aprobación |
| A4 | Revisar el tileset del Umbral con el "labio de luz" y la regla de pisables | M (3) | Corrige la legibilidad de lo ya hecho antes de multiplicarlo |
| A5 | Sistema de halos aditivos (sprites por bandas) y reglas del apartado 4 | M (3) | Ancla, reliquias y faroles ya lo necesitan |

### Fase B. Vertical slice completo (Umbral + Cinturón + Cisterna + Aljibe)

| # | Tarea | Esfuerzo |
|---|---|---|
| B1 | Fondo de parallax del Último Umbral (4 capas) | M (4) |
| B2 | Tileset del Cinturón Yermo (suelo, terraza, andamio, parche gris) | M (5) |
| B3 | Fondo de parallax del Cinturón (4 capas) | M (4) |
| B4 | Tileset y fondo de Cisterna/Galerías (transición húmeda) | M (4) |
| B5 | Props de las cuatro salas actuales (barriles, cajas ya hechas; sumar andamios, espantapájaros, aspas) | M (4) |
| B6 | Partículas del Umbral y Cinturón | S (2) |
| B7 | Retoque del Aljibe como sala de jefe (luz propia, atmósfera) | S (2) |

### Fase C. Contenido de las demás regiones, en el orden de construcción previsto

| # | Tarea | Esfuerzo |
|---|---|---|
| C1 | Archivo: tileset, 4 capas de fondo, estanterías-torre, páginas, salas en blanco | L (9) |
| C2 | Minas: tileset oscuro, minerales, hongos, vagonetas, luz del jugador | L (8) |
| C3 | Costa: tileset, mar, acantilado, velas, puentes | L (8) |
| C4 | Herida: tileset plano, bloques de 2×2/4×4, fondo, partículas | M (5) |
| C5 | Partículas por región | S (3) |

### Fase D. Personajes y jefes

| # | Tarea | Esfuerzo |
|---|---|---|
| D1 | Enemigos nuevos por región con el mismo `rig_enemigos.js`: 2 por región (12 total), reutilizando esqueletos con estilos nuevos | L (10) |
| D2 | Jefes de región (4-5 más, cada uno con su rig, ver `jefes.md`) | XL (15 por jefe) |
| D3 | PNJ (refugiados del Umbral, escribas, mineros, Descreídos; retratos opcionales) | L (8) |
| D4 | Variantes del Caminante (equipo, ropa) si hay progresión visible | M (4) |

### Fase E. Interfaz y acabado

| # | Tarea | Esfuerzo |
|---|---|---|
| E1 | HUD real (vida, frasco, Ecos, mapa) con marco en la paleta | M (4) |
| E2 | Fuente tipográfica propia en píxeles (de la misma familia que el logotipo) | S (2) |
| E3 | Pantalla de mapa en el estilo del Archivo (pergamino) | M (3) |
| E4 | Efectos de combate (impactos, estelas, polvo) y estados | M (4) |
| E5 | Transiciones de región y pantallas de muerte/descanso | S (2) |

Orden recomendado: **A (≈10) → B (≈25) → C1-C2 (≈17) → D1 parcial → resto**. Total estimado hasta tener las seis regiones con fondo, tiles y props básicos: **~95-110 puntos**, sin jefes de región ni PNJ. Con ellos: **~170-190**. Es mucho trabajo para una sola persona; el vertical slice (fase A+B) es un hito suficiente para decidir si se continúa.

Criterio de corte: **si el tiempo aprieta, se hace primero la Costa y el Archivo en versión reducida** (tileset + un fondo) y se deja la Herida como la última, porque su estilo (plano, sin textura) es el más barato de producir y el más fácil de mejorar al final.

---

## 8. Preguntas abiertas

1. **Caracteres de paleta.** ¿Los códigos `0 5 6 7 8 9 v w x y` chocan con algún `.sprite`, `.map` o generador existente? Hay que verificarlo antes de integrar los 11 colores.
2. **Sombreador y límite de 32 colores.** La desaturación continua produce colores fuera de la paleta. ¿Es aceptable (recomendado) o el usuario quiere que cada nivel use colores exactos? En el segundo caso hay que pasar a paletas horneadas (opción A, más trabajo).
3. **Jugador siempre a color.** ¿Se confirma que el Caminante, el Eco, las Anclas y las reliquias no se desaturan en ningún caso? Es la decisión narrativa más fuerte de este documento.
4. **Desaturación por sala.** ¿Se acepta declarar el nivel sala a sala (en vez de región a región), incluidos los parches grises dentro del Cinturón y los pasillos en blanco del Archivo?
5. **Linterna del jugador en las Minas.** ¿Luz propia del Caminante, lámpara como objeto que se consigue, o ninguna (luces sólo del entorno)? Cambia el diseño de nivel de las Minas.
6. **Halo del Ancla y desaturación.** ¿El Ancla debe "devolver color" a su alrededor (efecto bonito, coste moderado)?
7. **Rojo en el decorado.** La regla "rojo = peligro" excluye espantapájaros rojos o banderas rojas: ¿se acepta, o hace falta una excepción para el Umbral?
8. **Resolución en la Herida.** ¿Se acepta degradar el pixelado a bloques de 2×2 y 4×4 solo en esa región? Rompe la regla de "un píxel = un píxel", pero es muy expresivo.
9. **Color adicional libre (`z`).** ¿Se reserva o se asigna a un acento lavanda de la Herida?
10. **Orden de producción.** ¿Se prefiere cerrar el Cinturón completo antes de empezar el Archivo, o abrir un esqueleto mínimo de cada región para decidir antes?
11. **Costa y color.** ¿Es aceptable que una región tardía sea tan colorida como el inicio? Rompe la expectativa de "cada vez más gris" pero apoya la lógica radial. Habrá que contarlo con claridad en el mapa (marca visual de distancia a la Herida).
12. **Escala de personajes en primer plano.** ¿Admite el diseño elementos de primer plano que tapen parcialmente al jugador (hierba alta, cadenas)? Se propone semitransparentes y muy oscuros; podría resultar molesto en plataformas finas.
