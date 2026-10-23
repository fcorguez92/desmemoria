# Decisiones del editor de diseño de mundo y puzles

Registro de lo que se resolvió al unificar las propuestas de la sala de diseño (`01-mapa-macro.md`, `02-puzles-de-movimiento.md`, `03-puzles-de-entorno-y-mecanicas.md`, y para coordinar `04-combate-enemigos-jefes.md`, `05-progresion-y-economia.md` y `../artistas/06-entornos-tilesets-props.md`) en los documentos vivos `docs/mundo.md`, `docs/puzles.md` y `docs/vertical-slice.md` (leyenda). El criterio fue, por este orden: **coherencia con el canon y con el código real; simplicidad; alcance para una sola persona** (el camino principal solo usa mecánicas de núcleo; todo lo demás es opcional o tiene versión base). Los datos del código salen de `room.gd`, `world.gd`, `boss_room.gd`, `text_tile_map.gd`, `save_slot.gd` y de los nueve `.map` actuales.

## 1. Tabla de decisiones

### Caracteres del mapa

| Asunto | Propuestas | Decisión | Por qué |
|---|---|---|---|
| Muro o suelo excavable | 01: tile nuevo `D` (I1, I6). 03: `#` frágil y `$` hondo. 06: pide mantener `D` como decorado | **`#` frágil y `$` hondo.** `D` sigue siendo el arco ciego de decorado | `D` está en uso en 10 sitios de los mapas actuales (Aljibe, Cisterna, Torre); cambiarlo rompe lo construido. 03 distingue además dos reglas distintas (golpes sin habilidad / solo con Excavar) |
| Alfabeto: reglas | Sin regla común; 03 usa minúsculas gemelas de las mayúsculas del decorado (`c/C`, `k/K`, `n/N`...) | **Minúscula = mecánica o lógica; mayúscula = decorado, enemigo u objeto.** Las gemelas se mantienen | Las letras libres no dan para más; la regla las hace legibles. C12 (carácter no listado = error) cubre las equivocaciones |
| Palanca | 03: `l` | **`z`** | `l` se confunde con `1` (lancero) e `I`/`i` (inscripciones) en pantalla; un error se convierte en silencio en un lancero donde iba una palanca |
| Resto de marcadores de 03 | `# $ = + _ * c n < > ) ( u f x k y o` | **Se adoptan tal cual** (los de M8 y M9 quedan "reservados") | Se comprobó contra los 9 `.map` y `room.gd`: ninguno choca con lo en uso |
| Letras de baldosa de 06 | `g p m h a / \` | **Se adoptan `g p m h a`. `/` y `\` se recortan.** Se añade `%` (pared lisa, de 02) | Las pendientes exigen que `PlatformerMotor` las soporte y rehacer todos los márgenes de salto (el simulador asume cuadrados); 06 misma las deja condicionadas a esa pregunta |
| Pared lisa `%` | 02: imprescindible. 06 pregunta 4: ¿distingue el motor paredes escalables? | **Obligatoria (fase W0).** Es el cambio más barato (un dato en el `TileSet` + una comprobación) | Sin ella el Agarre convierte cualquier pared en escalera y rompe el diseño vertical (hallazgo medido en 02) |
| Pinchos laterales `{ }` | 02: S a M | **Se adoptan, fase W4 (antes de las Minas).** Fallback: tiras de `^`/`v` en repisas | Solo MIN-13 y SEC-07 los necesitan; no hay prisa y el fallback existe |
| Muro de cera `&` | 02: M, para que el dash sea llave propia | **Recortado.** Dash y doble salto se parecen hasta 21 de hueco: las llaves se diseñan como "dash o doble salto" y se combinan a partir de 25 | Un objeto nuevo para 3 salas; 02 pregunta 6 lo deja explícitamente opcional. SEC-06 se acepta con el doble salto (margen 17) |
| Coleccionables | 02 usa `!` solo en dibujos; 05 pide un pickup genérico con id; 01/03 los citan por sala | **`!` = coleccionable**; tipo e id en `pickups` de la escena, en orden de lectura | Un solo carácter para fragmentos, bolsas, páginas, reliquias y objetos de lore; el id estable no cabe en un carácter |
| PNJ | 01/03/05 los nombran; ningún carácter asignado | **`@`**; cuál, en `npcs` de la escena | Se reserva ahora para no chocar luego; se construye en la fase de PNJ |
| Enemigos nuevos | 01: ≤ 3 nuevos por región. 04: 23 nuevos (hasta 6 por región) | **`5` volador, `6` guardia, `7` corredor, `8` zona/apoyo, `9` élite**; `enemy_set` de la escena dice cuál es en esa sala | La letra es el rol (como en 06 para el terreno); caben los 23 sin 23 caracteres. El tope por región lo fija el editor de combate |
| Varias inscripciones por sala | 03 pregunta 7: hace falta un marcador | **`i` k-ésima toma `notes[k]`**; si solo hay `note`, todas lo usan | Compatible con lo construido; sin carácter nuevo |
| Props singulares | 06: archivo `sala.props` por sala | **Se acepta** (no usan letra) | ~100 piezas no caben en las letras libres |
| Decorado como rol | 06: las 13 letras pasan a ser roles que la región dibuja | **Se acepta** | No cambia ningún `.map`; `Y` apilable de 06 sigue siendo el rol "alzado vertical" |

### IDs, tamaños y salas

| Asunto | Propuestas | Decisión | Por qué |
|---|---|---|---|
| IDs duplicados o tamaños distintos 01 ↔ 02 | 02 reutiliza los IDs y tamaños de 01 | **No hay colisión.** Las 29 salas de 02 que existen en 01 coinciden en ID y tamaño; las 4 nuevas (SEC-09, SEC-10, SEC-11, HER-17) no chocan | Comprobado sala por sala |
| 136 o 140 salas | 01: 136. 02: 140 | **136.** Las 4 de 02 son **reserva** con ID reservado | Una persona sola; todas son maestría de dificultad 4-5 |
| Salas nuevas de 03 sin ID | "Sala de la Tinta", "El Pozo Blanco", "Galería del Primer Pico" | **Ninguna se construye.** P19 se integra en ARC-10; P20 desaparece (ARC-01 hace su papel con `%`); P23 se recorta | Más salas = más producción; cada una duplicaba una sala de 01 |
| Nombres de sala distintos | 03: "Escalera de Caracol", "Cámara de Apuntalamiento (antesala)", "Camino de Ronda" para las torres | **Escalera de Caracol = ARC-15 La Escalera Taponada; antesala = MIN-14; las torres en cadena son CIN-13** | Un solo nombre por sala; los ids de marca usan el nombre del archivo `.map` |
| Presupuesto de enemigos nuevos | 01 ≤ 3 por región; 04 más | **Pendiente del editor de combate** (la leyenda ya admite 4 roles + élite por sala) | Es una decisión de combate, no de mundo |
| Carga de las 136 salas | 01 riesgo 1 (memoria) | **Hoy todas; con ~40 salas, por región** (el manifiesto define las regiones) | No construir "por si acaso" |

### La Puerta Sin Muro, el Mirador y el viaje

| Asunto | Propuestas | Decisión | Por qué |
|---|---|---|---|
| Acceso a la Puerta Sin Muro desde el Mirador | 03 pregunta 5: el canon no lo dice; 01: HER-02 al sur de HER-01 | **El Mirador no conecta.** Camino único: Pilar de Lacre → Páramo Gris (HER-01) → HER-02; atajo tras Magda: Pozo del Latido → HER-01 | 01 ya lo traza así; el Mirador es una vista (fondo) y un callejón sin salida con Ancla; "ver antes de poder" a escala de mundo |
| Mirador: fondo o sala a 450 baldosas | 01 pregunta 6 | **Fondo de arte** dentro de la sala de la Pasarela | Lo propone 01 y encaja con `world.tscn` |
| Tamaño y forma de la Puerta Sin Muro | 01: HER-02 96×48 (N→S). 03: páramo de 108×30 con salida al este | **96×48**, entrada N, niebla de cal al sur | Las conexiones de 01 ya están encajadas en el manifiesto |
| Sellos y puertas intermedias | 01: ARC-23 "Requiere Cera", COS-04 "Cera, Piedra, Cal (puerta)" | **El Puente y el Pilar no piden Sellos**; solo HER-02 los pide | La Cera es lo que suelta Hesper, y pedirla para salir del Archivo sería un bucle absurdo; los huecos del Pilar son vista |
| Pilar de Lacre como nudo | 01 pregunta 2: el Archivo desemboca en el cruce central | **Aceptado** | Cambia el guion solo en que el Puente de Cera sustituye "la salida del Archivo" |
| Viaje rápido | 01 pregunta 1; 05 §5.2 | **Ninguno libre antes del acto IV; "Decir los nombres" desde el acto IV (Hito del Umbral)** | Con 14 atajos físicos basta; la construcción pertenece a 05 |
| La barca | 01: viaje fijo con Mirena, o a nado. 03: 18 s. 05: viaje de pago Costa ↔ "pie del Cinturón" | **Barca del Cauce Hundido (MIN-20): palanca `z` en cada orilla, M7 a demanda, ~30 s (160 px/s), sin peaje; Mirena solo añade su línea. Sin "a nado"** | El motor no tiene agua que se nade ni hay "pie del Cinturón" donde atracar; 300 baldosas a 80 px/s serían 60 s; sin Mirena la barca no puede dejar atrapado al que llega por el lado de las Minas |

### Corvel, Nombres y coleccionables

| Asunto | Propuestas | Decisión | Por qué |
|---|---|---|---|
| Primera Página de Corvel | `textos-del-juego` §4: cabaña del Umbral con el Nombre Corvel. `guion-maestro` §10.1: Corvel entre los cinco Nombres del Archivo. 01 pregunta 4: contarlo donde se lee | **Página 1 en el Umbral (P01). El Nombre Corvel cuenta como del Archivo** en las listas por región y en el color del peldaño | Respeta los dos textos del canon sin reasignar ningún Nombre |
| Página 6 y HER-17 | 02: HER-17 da "Página de Corvel (Herida)". 01/03: la 6.ª está en HER-03 | **Página 6 al pie de la Escalera de Hojas, sin Nombrar.** HER-17 (reserva) da Ecos y un objeto de lore | Son seis páginas; una séptima rompería la cuenta |
| Fragmentos de vida y de frasco | 05: 12 FV (1/3/3/3/2/0) y 3 FF, ubicaciones propias (varias en salas ya construidas y en las dos primeras horas). 01 coloca ~14 FV y ~8 FF | **12 FV y 3 FF con la tabla de `puzles.md`** (ninguno en salas construidas; los de más pasan a Bolsa o reliquia) | Cuadra las cuotas por región de 05 con las salas de 01 y respeta la cadencia de 05 ("nunca en las dos primeras horas"), que su propia lista de ubicaciones incumplía |
| Medalla del Umbral, Llave sin puerta, Cuenta del Rosario | 01: Medalla en UMB-05, Llave sin puerta en UMB-08, Cuenta en CIN-01. 03: Medalla en el Sótano, Llave sin puerta se vende, Cuenta en la Cisterna | **Medalla en UMB-05; Llave sin puerta se vende (Cano); Cuenta del Rosario en la Cisterna (en Terrazas solo el aviso)** | El Sótano queda con el FV y el grabado de Aún; la tienda de Cano es de 05; el aviso de las Terrazas sí está en 01 |
| Nombres tras secretos | 03: ≤ 5 de 30, dificultad ≤ 2 | **Se mantiene (4-5)**; 28 alcanzables sin opcionales | Compartir (20) nunca depende de un secreto |
| Nombres detrás de puzles duros | P10 (Eulalia), P36 (cinco de la Herida) | **Se leen sin puzle** (mojón; sillas fijas) | Un Nombre en el camino principal no puede depender de una mecánica recortada |

### Mecánicas y puzles

| Asunto | Propuestas | Decisión | Por qué |
|---|---|---|---|
| Qué mecánicas de 03 son obligatorias | 03 §6: recorte en orden M8, M9, M10, 5 piedras, M12 | **Núcleo:** M1, M2 (frágil y hondo), M3, M4, M5, M6 (3 piedras), M7, M11. **Ampliación:** M10, M12. **Recortadas:** M8, M9 | El camino principal pasa por M7 (vagoneta, barca) y M11 (Pasillo Tres, marea); M10 y M12 solo alimentan opcionales; M8 y M9 son las más caras y ninguna llave las pide |
| Versión base de cada sala | — | **Cada sala que usaba M8, M9 o M10 en el camino principal tiene versión base** (COS-05 plataformas fijas; HER-04 sillas fijas; MIN-14 palanca; CIN-10 combate con parche visual) | Principio 6 de `puzles.md` |
| Piedras de lectura | 03: 8 | **Tres** (`nudo`, `mirador`, `escalera`); `arco`, `voces`, `rellano`, `hojas`, `mesa_*` diferidas | Son lo mínimo del guion; ninguna extra abre el camino principal |
| Nombrar y la Herida | 01: HER-12 "Requiere Nombrar" | **HER-12 no exige Nombrar** (el puzle es el ciclo de la puerta, P39) | `02` §1.3 y el canon: Nombrar nunca bloquea el camino de la Herida |
| Pozo de las Minas MIN-06 | 01/02: pozo de Agarre. 03 P24: montacargas de 60 baldosas | **Pozo de Agarre con descansos; el montacargas es un ascensor opcional de vuelta** | El camino principal no depende de M7 en una sala de 110 filas |
| Estantería-puente P15 / Contrapeso P28 | 03: P15 da "acceso a la Sala de los Lacres"; P28 "el camino a Magda" | **P15 es una rama opcional (Página 3); P28 tiene versión base con palanca** | No se cierra el camino principal con una mecánica de ampliación |
| Sala de los Lacres | 03: puzle de 4 símbolos; 01: Ancla pre-jefe | **Opcional (Pesa del Archivo); no bloquea ARC-08** | M12 es ampliación |
| Excavar | 03: abajo + atacar en el suelo. 04: Golpe Hondo como golpe pesado; ataque hacia abajo con pogo. Editor de sistemas: el ataque hacia abajo rompe lo hondo (suelos), el tajo los muros | **Se adopta lo del editor de sistemas** (`nucleo-jugable.md`): tajo contra muro hondo; ataque hacia abajo (suelo o aire) contra suelo hondo. Sin Excavar, el ataque hacia abajo rebota sobre `$` | Una sola acción para el jugador y coherente con el documento de núcleo jugable; MIN-16 y SEC-07 funcionan igual |
| Piezas | 06: de 1×1 a 4×8. 01 (Silo): 3×9 | **Hasta 4×10** | R6 necesita 9 de alto para atravesar el suelo de la Cisterna |
| Red de pasos hondos P27 | 03: cinco pasos con Dola | **Siete marcas con las salas de 01** (Hueco del Pico, Veta, Silo, Cantores, Latido, Marea, Puerta Tapiada) | Las salas de 03 no coinciden con las de 01 |
| P26 Fila de Espera | 03: túnel a la base de la Cuerda | **Recortado** | MIN-05 ya conecta con MIN-06 |
| P11 Manantial | 03: tres salas | **Recortado** | Complejo y sin reliquia propia (el Dedal está en CIN-07) |
| HER-04 / P36 | 03: sillas móviles con viento (dif. 4) | **Sillas fijas** | Los cinco Nombres de la Herida están en el camino principal |
| P05 | 03: escalera de 7 peldaños | **5 peldaños** (los que tiene la Cisterna) | Se rehace el texto, no la sala construida |
| Sentido único Chimenea ↔ Cruce del Pan | 01: CIN-05 "O alto [1→]→CIN-11" y CIN-11 "E [1→]→CIN-05" se contradicen; S3 dice "desde la Chimenea" | **Abre solo desde CIN-11 hacia la Chimenea** | Si abriera desde la Chimenea, se entraría al Cinturón alto sin el doble salto |

### Orden, guardado y verificación

| Asunto | Propuestas | Decisión | Por qué |
|---|---|---|---|
| Orden de implementación | 03 §6: M1, M3, M4, M2 frágil, M7, M11, M5, M12, M10, M2 hondo, M9, M8, M6. 02: `%` primero. 04: ataque abajo/arriba y E2/E5 antes del Archivo. 05: fases A-H. 06: autotiling | **W0-W9, WA, WR de `puzles.md`**, siguiendo el orden del mundo (Cinturón alto → Agarre → Archivo/Minas/Costa → Herida → acto IV) | Cada fase desbloquea contenido que se puede construir y jugar; las dependencias de 04/05/06 se citan |
| Dónde se guardan los puzles | 03: lista `flags` (M1). 05: claves `fragments`, `bags`, `relics`, `names`... | **Las dos**: `flags` para lo hecho en el mundo; las claves de 05 para lo que se recoge y cuenta; mismo formato de id | Cada una tiene su semántica (inventario frente a hecho); la prueba de ids únicos mira ambas |
| Versión del guardado | 03: no subir `FORMAT_VERSION`. 05: `version: 2` | **No se sube** | `SaveSlot` rechaza versiones distintas: subir descartaría todas las partidas existentes. Las claves nuevas son opcionales |
| Ids estables | 03: `prefijo:sala.objeto` | **`sala` = nombre del archivo `.map`**; lo permanente se nombra a mano en `links`; `t:` para lo temporal sin nombre | No depende del título mostrado ni de mover piezas |
| `FlagStore` | M1 en `core/save/` | **Sí, en `core/`** (grupo `flag_store`) | Genérico (no conoce Nombres ni Sellos) |
| "Volver al Ancla" | 03 §5.4 | **Adoptado** (el editor de sistemas lo fijó en `nucleo-jugable.md`); se construye con W2 | Es la red de seguridad frente a atascos imprevistos; coste S; igual que morir, sin contar como muerte |
| Simulador de saltos | 02: prototipo ampliado en un directorio temporal | **Hay que rehacerlo** (W0); hoy `sim_saltos.js` solo conoce el dash | El prototipo no está en el repositorio; sin él no se pueden validar Doble ni Agarre |
| Verificación del mundo | 01 §8: manifiesto + script con C1-C15 | **Script `tools/verifica_mundo.js` + manifiesto**, por etapas (C1-C4, C8, C12 en W0; el resto con el simulador) | Un solo sitio para las comprobaciones estáticas; la prueba de humo conserva las del motor |
| Archivo en Blanco sin mapa | 01 pregunta 7 | **Aceptado**: `reveal_map = false` por sala | Coste mínimo en `world.gd` |
| Mapa/minimapa grande | 01 riesgo 6 | Fuera de este alcance (pertenece a 05, "Mapa, marcadores, planos") | — |

## 2. Retoques a las salas ya construidas (fijados)

Seis propuestos en `01` §3.4 (I1-I6, ahora R1-R6) más uno nuevo (R7) y dos diferidos de puzle (R8, R9). Filas y columnas se cuentan desde 0 (arriba a la izquierda del `.map`). **Ningún retoque con un marcador nuevo (`$`, `#`, `=`) puede aplicarse antes de que exista su mecánica**: un carácter desconocido se convierte en un marcador sin colisión y deja un hueco en la pared. Tras cada retoque: prueba de humo, `sim_saltos.js` sobre lo tocado y jugar.

| # | Sala (mapa) | Cambio exacto | Cuándo | Observaciones |
|---|---|---|---|---|
| **R1** (I1) | `ultimo_umbral.map` | Sustituir `BB` por `$$` en las columnas 0-1, filas 14-19 (una pieza `$` de 2×6, 12 marcadores). El resto del muro (filas 5-13) no se toca | Con W5 (grieta honda) y al construir UMB-07 (suelo en la fila 20, igual que el Umbral) | 01 pedía "tile nuevo `D`": sustituido por `$`. Abierto deja 6 baldosas de alto. La veta debe verse desde el primer pantallazo |
| **R2** (I2) | `ultimo_umbral.map` | Añadir tres tablones `S` de 6 de ancho, 3 filas de separación: fila 8 columnas 66-71, fila 5 columnas 72-77, fila 2 columnas 66-71. La escalera actual acaba en la fila 11 (columnas 72-77, Ancla en la 74). UMB-02 debe abrir su suelo en las columnas 56-79 y poner un cuarto tablón en su fila 59 (y absoluta -1), columnas 72-77 | Al construir UMB-02 | El techo del Umbral ya es cielo abierto (filas 0-4 vacías): no hay que romper nada. Probar la subida con `sim_saltos.js` (subidas de 3: trivial). No pisar los marcadores `Q`, `A`, `O` de la fila 10 |
| **R3** (I3) | `torre_de_riego.map` | Sustituir `BB` por `..` en las columnas 54-55, filas 1-6 (6 baldosas de alto). El suelo de la cornisa (fila 7) y el techo (fila 0) siguen. El Ancla (fila 6, columna 47) y `Q O K` (columnas 51-53) no se tocan | Al construir CIN-08 (suelo de CIN-08 a la y absoluta -13, fila 23 de su mapa) | Abierta deja 6 de alto: cumple la regla. Probar con `sim_saltos.js` que la cornisa sigue exigiendo el doble salto |
| **R4a** (I4) | `chimenea.map` | Sustituir `BB` por `==` (compuerta de un sentido, canal A) en las columnas 0-1, filas 11-16 (6 de alto; y absoluta -10 a -5). **Abre solo desde CIN-11** (manilla en ese lado, testigo visible desde dentro) | Con W2 (compuerta) y al construir CIN-11 | 01 la daba como `[1→]` con dirección contradictoria; aquí se fija. Al abrirse desde CIN-11 se entra cayendo al rellano del Ancla de mitad (fila 32, columnas 2-11): no salta ningún cruce de dash |
| **R4b** (I4) | `chimenea.map` | Sustituir `BB` por `..` en las columnas 38-39, filas 61-66 (6 de alto; y absoluta 40-45) y `BB` por `TT` en las columnas 38-39 de la fila 67 (continuidad del suelo con SEC-06, suelo a y absoluta 46) | Al construir SEC-06 (en el eje y 24-50) | La plataforma de la fila 62 (columnas 28-37) queda junto al hueco: está bien. El Ancla de la fila 66 (columna 33) queda a 5 de la salida: sin enemigos cerca |
| **R5** (I5) | `pasarela.map` | **Sin cambios de baldosas** (la sala no tiene techo). El hueco de caída se abre en el **suelo de CIN-23** (Rampa de Servicio) en x 504-516 absolutos (columnas 80-91 de la Pasarela), sobre la plataforma larga del Mirador (columnas 77-96). La cuerda de vuelta es una palanca `z` en esa plataforma que baja un puente (`=` variante puente) | Al construir CIN-23 | 01 daba x 456-480, que cae sobre el abismo de pinchos (columnas 34-50 de la Pasarela): corregido |
| **R6** (I6) | `cisterna.map` | Sustituir las columnas 54-56, filas 22-30 por `$` (una pieza de 3 de ancho × 9 de alto) para atravesar el suelo (fila 22 = `B`, filas 23-30 = `G`). El Silo (96,55) queda debajo: sus columnas 38-40 locales abren su techo | Con W5 y al construir SEC-01 | 01 pedía "tile nuevo `D`". Columnas 54-56 caen a 18 baldosas del lancero (columna 74) y lejos de la escalera de tablones (columnas 24-45), como pedía 01 |
| **R7** (nuevo) | `terrazas_secas.map` y `torre_de_riego.map` | Ensanchar la abertura de 4 a 6: en Terrazas, cambiar `B` por `.` en la columna 63, filas 14-15; en la Torre, cambiar `BB` por `..` en las columnas 0-1, filas 34-35 (abertura final: filas 14-19 de Terrazas = 34-39 de la Torre = y absoluta 14-19) | **Sin dependencias: puede hacerse ya** | Riesgo 3 de 01 y regla "≥ 6 baldosas de hueco" de `decisiones.md` (2026-10-20). El tablón de la Torre en la fila 36 (columnas 8-13) y `Q O` de la fila 35 no estorban |
| R8 (diferido) | `ultimo_umbral.map` | P01 (Tabla Suelta): dos `#` en la fila 20, columnas 17-18 (suelo de la cabaña, dentro de los pilares de las columnas 16 y 21), y un `!` oculto hasta romperlas (`hidden_until`) en la fila 19, columna 17 | Con W2 | La página aparece al romper el tablón; la cavidad de 1 baldosa se dibuja como hueco oscuro |
| R9 (diferido) | `cisterna.map` | P05 (Cuentas del Rosario): una pieza `#` de 2×3 junto al 5.º tablón (el de la fila 2, columnas 30-34), con un nicho detrás; las cuentas en los peldaños 2 y 4 (decorado). Condiciones: ≥ 6 baldosas de techo, no tocar las plataformas del puzle de la escalera | Con W2 | La escalera tiene 5 peldaños (filas 18, 14, 10, 6, 2) |

Dos retoques más sin cambios de baldosa, para cuando se construyan: el Receptor del Relevo (`c`) en el Aljibe junto a la salida, sin tocar las rejas, y la piedra `n` del Mirador junto al Ancla de la Pasarela (fila 7, entre las columnas 88 y 96, a ≥ 2 de la `i` y del Ancla).

## 3. Lo que sigue abierto para el usuario

1. **Cuántos enemigos nuevos por región** (01 dice 3; 04 propone hasta 6): decisión del editor de combate y del usuario; la leyenda ya admite cuatro roles más un élite por sala.
2. **¿El Agarre recarga el dash y el doble salto?** Hoy no (todos los márgenes medidos así). Cambiarlo obliga a rehacer los márgenes de las salas con pared.
3. **Reliquias:** el reparto de las 22 de `05` en las salas queda para el editor de progresión; aquí solo se fijaron las que cambiaron de sitio.

## 4. Qué hay que hacer en el código y cuándo

Nada de esto está hecho: **no se ha tocado código**. Primera tanda (W0, un PR): `marker_groups`, `%`, ampliación de `sim_saltos.js` con comprobación cruzada de la Chimenea, `tools/verifica_mundo.js` mínimo y retoque R7. Después W1 (`FlagStore` y `!`) y W2 (compuerta, disparadores y grieta frágil), con lo que ya se puede construir el Cinturón alto entero. Detalle y pruebas en `docs/puzles.md`.
