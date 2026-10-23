# Puzles de entorno y mecánicas de mundo (propuesta del diseñador de puzles)

Estado: propuesta de la sala de diseño. No modifica el canon (`historia.md`, `guion-maestro.md`, `personajes.md`, `textos-del-juego.md`) ni el código. Rol: diseñador de puzles de entorno y mecánicas de mundo. Sale de aquí: un catálogo de **12 mecánicas**, **41 puzles** repartidos por las seis regiones, el diseño exacto de los tres puzles del canon (Piedra de lectura, Puerta Sin Muro y Sala de Aún), las reglas de secretos, la tabla de estado y guardado, el orden de implementación y las pruebas.

---

## 0. Principios y medidas

### 0.1 Principios (los que mandan sobre cualquier puzle)

1. **Un puzle es una frase del mundo.** Cuenta algo del canon con restos, no con texto: una reja que se abre desde el otro lado dice "alguien cerró por dentro". Si no cuenta nada, se quita.
2. **Cada mecánica nueva se justifica por varios usos.** Ninguna aparece en menos de tres puzles ni en menos de dos regiones (salvo Nombrar, que es una habilidad del canon). Si una mecánica solo sirve para un puzle, el puzle se reescribe con las que ya existen.
3. **Legible sin texto.** Se enseña en este orden: se ve el efecto (una reja cerrada, un puente a medias), se ve la causa (una palanca con su testigo del mismo color), se prueba sin riesgo (primera vez sin enemigos ni pinchos) y solo después se combina.
4. **Sin atasco.** Se puede salir siempre de cualquier sala por donde se entró. Ningún puzle cierra una reja sobre el jugador. Si algo sale mal, morir o descansar reinicia lo temporal (ver §5). Además se propone una válvula de seguridad global (§5.4).
5. **Lo difícil es opcional.** El camino principal no pasa de dificultad 3. Los puzles de 4 y 5 dan reliquias, atajos o lore.
6. **Poco código.** Todo se coloca con marcadores en el mapa de texto, como ya se hace con Anclas, pinchos y rejas de jefe. Todo lo nuevo en `core/` es genérico (no sabe qué es un Nombre ni un Sello) y lo específico del juego (Nombrar, Sellos) vive en `game/`.

### 0.2 Medidas con las que se ha diseñado (motor actual)

Valores sacados de `platformer_motor.gd` (salto -900 px/s con gravedad 2250 y caída 1,4×; doble salto -800; baldosa 16 px; cámara 864×486 = 54×30 baldosas; jugador 24×48 = 1,5×3 baldosas).

| Capacidad | Alcance cómodo para un puzle | Máximo absoluto |
|---|---|---|
| Salto simple | 9 baldosas de altura, 9 de largo | 11 de altura |
| Con doble salto | 16 de altura | 19 |
| Dash en el aire (uno por salto) | hasta 16 de hueco (la Chimenea usa 16) | 22 |
| Salto de pared | pozos de 4 a 8 baldosas de ancho | sin límite de altura |
| Pasillo de paso | 4 baldosas de alto (el jugador mide 3) | 3 |
| Plataforma móvil | 6 baldosas de ancho mínimo | 4 |

Un puzle debe poder **leerse en una pantalla** (54×30) o en dos pantallas contiguas; si la causa y el efecto no caben juntos, la causa lleva testigo (ver M4) y el efecto suena y se marca en el mapa.

---

## 1. Catálogo de mecánicas de mundo

Son doce. M1 es la base de estado que comparten las demás; no se ve, pero sin ella no hay puzles que recuerden nada.

### 1.1 Resumen y marcadores propuestos

Los marcadores son caracteres del mapa de texto. Los de esta tabla no chocan con la leyenda actual (`A E R I i d j w ^ v ~ - Y U H Z K F N X V L M D q Q O b t [ ] r P 1-4` y las baldosas `T G B C S`), pero hay que verificarlo contra cada `.map` antes de usarlos. Una **pieza** es un grupo de marcadores contiguos del mismo carácter: un muro de 2×6 baldosas es una sola pieza con 12 marcadores, no 12 muros (M2 lo necesita; lo resuelve una función de 15 líneas en `TextTileMap`, ver §6).

| # | Mecánica | Marcador(es) | Base | Coste |
|---|---|---|---|---|
| M1 | Estado de mundo (marcas) | no tiene | `core/save/flag_store.gd` | M |
| M2 | Grieta (muro frágil / suelo hondo) | `#` frágil, `$` hondo | `core/objects/breakable_wall.gd` | S / M |
| M3 | Compuerta (reja, tablones, puente, cal) | `=` canal A, `+` canal B | `core/objects/gate.gd` (sale de `arena_gate.gd`) | S |
| M4 | Disparadores (palanca, placa, botón) | `l` palanca, `_` placa, `*` botón | `core/objects/trigger.gd` | S |
| M5 | Receptor (ranura, cerradura) | `c` | `core/objects/receiver.gd` | S |
| M6 | Piedra de lectura (Nombrar) | `n` | `game/environment/reading_stone.gd` | L |
| M7 | Plataforma sobre carril | `<` inicio, `>` fin | `core/objects/rail_platform.gd` | M |
| M8 | Corriente (viento y ascenso) | `)` `(` `u` | `core/objects/air_current.gd` | M |
| M9 | Luz (lámparas y oscuridad) | `f` lámpara, `x` revelado | `core/objects/lamp.gd` + zona | M |
| M10 | Derribo (columna, estantería) | `k` | `core/objects/topple.gd` | M |
| M11 | Ciclo (reloj de mareas y ritmos) | `y` | `core/objects/cycle.gd` | S |
| M12 | Combinación (selector de símbolos) | `o` | `core/objects/dial.gd` | S |


### M1 · Estado de mundo (las marcas)

- **Qué es.** Un diccionario de marcas con nombre (`p:torre_de_riego.rueda`) que dice si algo está hecho. Las mecánicas no se hablan entre sí: una escribe una marca y otra la lee. Así una palanca de la Torre puede abrir una reja de otra sala sin que se conozcan.
- **Comportamiento.** `set_on(id, permanente)`, `is_on(id)`, `clear(id)`, señal `changed(id, valor)`. Una marca **permanente** se guarda; una **temporal** vive hasta el próximo reinicio (descansar o morir). Los objetos se suscriben a su marca y se ponen en el estado que toque al cargar.
- **Qué lo activa.** Cualquier otra mecánica.
- **Qué guarda.** Todas las marcas permanentes, como lista de textos en el JSON de la partida (`flags`), junto a `rooms`, `bosses` y `seen`.
- **Implementación.** Un `Node` en el mundo, dentro del grupo `flag_store`; los objetos de `core/` lo encuentran por el grupo (no importan nada de `game/`). `world.gd` lo vuelca en `save_game()` y lo recarga en `_apply_save()`. Los ids desconocidos al cargar se ignoran, como ya hace el árbol de habilidades con lo que no entiende.
- **Usos.** Todos los puzles. Coste M por el guardado y las pruebas, no por el código.

### M2 · Grieta (muro frágil y suelo hondo)

- **Aspecto.** Frágil: muro o suelo de piedra con **grietas blancas en zigzag** y polvo que cae. Hondo: roca con una **veta de rombos ámbar**, el mismo color del recuerdo de Magda. Son formas distintas, no solo colores, para quien no distingue el color.
- **Reglas.** *Frágil*: se rompe con el Filo, 3 golpes (cada golpe agranda la grieta y suena hueco; sin habilidad alguna). *Hondo*: el Filo rebota con chispa y un tañido metálico, sin daño; con Excavar se rompe en 2 golpes. Excavar se activa con el golpe normal contra un muro hondo, y con **abajo + atacar en el suelo** contra un suelo hondo (golpe bajo los pies). Al romperse, la pieza entera desaparece en 0,4 s con polvo y no vuelve. Nunca daña.
- **Qué guarda.** Permanente (`s:` o `d:` según sea secreto o atajo). Una grieta rota tras un reinicio sigue rota.
- **Implementación.** `StaticBody2D` que implementa "golpeable" como `BreakableProp`, con `hits`, un export `requires` (nombre de una propiedad booleana del atacante, vacío = ninguna; el jugador expone `can_dig`) y la señal `broken`. En `room.gd` se coloca una por pieza. Lo único nuevo en el jugador es una segunda zona de golpe bajo los pies, que solo se activa con abajo + atacar (S).
- **Usos.** 10 puzles y 20 secretos en las seis regiones. Es la mecánica más barata y la que más historia lleva (todo lo cerrado "desde dentro").

### M3 · Compuerta (reja, tablones, puente, cal)

- **Aspecto.** Una pieza que cierra o abre un paso. Cuatro vestidos con la misma lógica: **reja** de hierro (Orden, rastrillo como el del Aljibe), **tablones** clavados (Umbral y Cinturón), **piedra** (Minas) y **cal** (niebla blanca de los Descreídos y de la Herida). Una variante **puente** aparece (en vez de desaparecer) al activarse.
- **Reglas.** Se abre cuando su marca (o todas las de su lista, "Y") está activa. Animación de 0,45 s, igual que el rastrillo actual, con el sonido `gate_open`. **No se cierra encima del jugador**: si algo la ocupa, espera a que quede libre. Opciones: `inverted` (cerrada mientras la marca está activa), `fade_on_stand` (el "tablón de tinta": se borra 1,2 s después de pisarlo y vuelve a los 6 s) y `one_way_side` (la manilla solo existe en un lado, para el patrón "se abre desde el otro lado").
- **Qué guarda.** Lo que diga su marca: permanente si la abrió una palanca o un secreto, temporal si depende de una placa o un ciclo.
- **Implementación.** Es `arena_gate.gd` sacado de `game/boss/` a `core/objects/gate.gd` con tres exports (`flags`, `kind`, `inverted`). `boss_room.gd` pasa a usar la versión de `core/` sin cambiar su comportamiento (el test del jefe lo vigila). Marcador `=` (canal A) y `+` (canal B); el nombre real de la marca se pone en la escena de la sala (`links`), por defecto `<sala>.<carácter>`.
- **Usos.** 16 puzles en las seis regiones. Es el efecto casi universal.

### M4 · Disparadores (palanca, placa de presión, botón en alto)

- **Aspecto.** *Palanca*: mango de hierro en un zócalo, con un **testigo** (una lamparilla o un nudo de cuerda) del mismo color que la compuerta que gobierna. *Placa*: losa hundida a ras de suelo. *Botón en alto*: disco de bronce en la pared, a más de 4 baldosas, que se golpea saltando.
- **Reglas.** *Palanca*: Z o golpe; animación de 0,2 s; **queda activada** (permanente) salvo que se marque `toggle`, en cuyo caso alterna (temporal). *Placa*: activa mientras haya alguien encima y `hold_time` segundos después (0 a 10; la lamparilla se apaga en cuenta atrás). *Botón*: un golpe de Filo o un proyectil, queda activado.
- **Testigo a distancia.** Si la compuerta no cabe en la misma pantalla, al accionar suena su efecto en su posición (`Sfx.play` ya atenúa por distancia) y sale el aviso "Algo se ha abierto, en alguna parte." con un punto en el mapa (`MapData.set_marker`).
- **Qué guarda.** Palanca y botón, permanente; placa, temporal.
- **Implementación.** Un único script `trigger.gd` con `mode` (palanca, placa, botón). Es un `Area2D` que escribe en M1; reutiliza el patrón de `Checkpoint` (Z con un cuerpo del grupo objetivo dentro) y el de `BreakableProp` (golpeable).
- **Usos.** 9 puzles, más todos los atajos de palanca.

### M5 · Receptor (ranura, cerradura, altar)

- **Aspecto.** Un nicho con la **silueta** de lo que espera (disco partido, guijarro con pico, círculo de cal, llave).
- **Reglas.** Z (o mantener Z, ver `hold_time`): si todas las marcas de `requires` están activas, escribe su marca y reproduce su vestido (rompe el Sello, gira la llave); si no, `Readable` muestra su texto de pista. No consume nada: los objetos de la partida no son un inventario, son marcas.
- **Qué guarda.** Permanente.
- **Implementación.** `Area2D` de unas 40 líneas con `requires: Array[StringName]`, `sets: StringName`, `hold_time` y `hint_text`. La Piedra de lectura (M6) hereda de él.
- **Usos.** 4 puzles (los tres Sellos de la Puerta Sin Muro y el relevo del Aljibe) y los nichos de reliquias.

### M6 · Piedra de lectura (Nombrar)

- **Aspecto.** Piedra pulida con la **sombra grabada** de una cosa (un pie alado, un cordel, una silla) y hendiduras donde se apoya la mano.
- **Reglas.** Sin Nombrar: Z muestra "Esta piedra pide un nombre." y nada más. Con Nombrar: **mantener Z 0,6 s** abre una lista de los Nombres que el jugador sostiene (ordenada por región, ver §3.1); se elige uno con arriba/abajo y Z. Acierta: efecto de la piedra. Falla: "La piedra no responde.", 1,5 s de espera, sin castigo. Cada piedra define a quién acepta (un Nombre, varios o "cualquiera de una región") y qué hace (abrir para siempre, iluminar 4 s, hacer aparecer un Eco).
- **Qué guarda.** Permanente salvo las que solo iluminan 4 s (temporales).
- **Implementación.** `reading_stone.gd` en `game/` (conoce los Nombres), hereda de `Receiver` y usa `ModalLayer` y `MenuList` ya existentes. Depende de que exista el diario de Nombres, que hoy no está construido (pregunta 3, §7).
- **Usos.** 8 puzles: 3 del canon obligatorios (nudo de Aldara, Mirador, escalera de los Nombres) y 5 que se pueden recortar sin tocar el camino principal.

### M7 · Plataforma sobre carril

- **Aspecto.** Plataforma de madera o hierro sobre un **carril dibujado** (una línea de clavos o raíl) entre dos puntos. Es de un solo sentido por arriba, como los tablones.
- **Reglas.** Tres modos con el mismo código: **continua** (va y viene, espera 1,5 s en cada extremo), **a demanda** (se mueve al pisarla o al accionar su marca y espera 8 s antes de volver) y **viaje** (Z en el embarcadero: sale, cruza y se queda; para la barca de Mirena). Velocidad 80 px/s por defecto. **Nunca aplasta**: si algo la bloquea más de 0,3 s, se detiene y retrocede. Lleva al jugador con ella (movimiento heredado del suelo).
- **Qué guarda.** Posición temporal; la marca del modo "viaje" o "a demanda con palanca" sigue la de su disparador.
- **Implementación.** `AnimatableBody2D` con `sync_to_physics`, que Godot ya sabe usar para transportar cuerpos. Los extremos son los marcadores `<` y `>` más cercanos entre sí. El motor del jugador solo necesita no cancelar la velocidad que hereda del suelo (a comprobar con la prueba de la plataforma, ver §6).
- **Usos.** 7 puzles en cuatro regiones (rueda de la Torre, torres en cadena, ascensor de las Minas, vagoneta, barca, sillas de la Herida).

### M8 · Corriente (viento y ascenso)

- **Aspecto.** Zonas de **hilos de polvo o páginas** que corren en una dirección, con sonido de soplo. En la Costa son las cortinas y el aire del acantilado; en el Archivo, páginas sueltas que suben; en la Herida, el soplo de la Desmemoria.
- **Reglas.** *Lateral*: suma ±180 px/s a la velocidad horizontal (se puede caminar contra ella, que es de 300 px/s, pero no saltar contra ella a toda marcha). *Ascenso*: reduce la gravedad al 35 % y limita la caída a 150 px/s, con un empuje hacia arriba de hasta 250 px/s. Se anuncia con el dibujo desde 2 baldosas antes de entrar. Puede alternar con un Ciclo (soplo cada 5 s).
- **Qué guarda.** Nada.
- **Implementación.** `Area2D` que llama a `apply_push(velocidad, gravedad)` en cuerpos del grupo objetivo; el motor suma ese empuje en `step()`. Es el único cambio de física de la lista (M).
- **Usos.** 3 puzles y unas 6 salas de tránsito de la Costa y el Archivo.

### M9 · Luz (lámparas y oscuridad)

- **Aspecto.** Salas oscuras (Minas, un faro, un ala del Archivo). Una **lámpara de grasa** (`f`) se enciende con Z y tiene un radio de 7 baldosas. El Caminante lleva un **resplandor propio de 2,5 baldosas** que nunca se apaga: no hay ceguera total y no hace falta la Linterna que el canon descartó.
- **Reglas.** Lo marcado como **revelado** (`x`: plataformas, puentes, inscripciones) **solo existe, con colisión y dibujo, mientras una luz lo alcanza**. Las lámparas duran lo que digan: 60 s para los puzles (se ve la mecha menguar) o permanente en los caminos. Una plataforma no se apaga con el jugador encima sin 2 s de aviso (parpadeo y sonido de mecha).
- **Qué guarda.** Lámpara permanente, sí; la temporal, no.
- **Implementación.** Cada sala oscura tiene un `CanvasModulate` y `PointLight2D` (luces nativas de Godot 2D, sin shaders propios). El revelado es un grupo `lit_only` que alterna `visible` y la colisión según la distancia a las lámparas encendidas. Coste M (arte de luz y rendimiento con todas las salas cargadas: solo se procesa la sala actual).
- **Usos.** 4 puzles y 6 salas oscuras de las Minas.

### M10 · Derribo (columna, estantería-torre)

- **Aspecto.** Un montón alto y estrecho (columna rota, estantería-torre, puntal, mástil) con una **base cuarteada** y una sombra que cae hacia un lado.
- **Reglas.** Un golpe lo hace crujir 0,5 s (polvo y sonido, el jugador tiene tiempo de apartarse) y **cae en la dirección del golpe** (lejos del atacante) girando 90° en 0,9 s. Queda como **plataforma horizontal** de un solo sentido, de largo igual a su altura. Solo cae si tiene el hueco libre; si no, se bambolea y no pasa nada. Hace 1 de daño a quien esté debajo cuando toca el suelo. Si cae sobre una placa la mantiene pulsada **para siempre**.
- **Qué guarda.** Permanente si hace de puente o de peso; temporal si es parte del desafío.
- **Implementación.** Dos formas de colisión (en pie / caído) y una rotación con `Tween`, sin física de rígidos. Marcador `k` en el mapa; la dirección de caída y su hueco se comprueban con un `ShapeCast` en la colocación.
- **Usos.** 3 puzles (estantería-puente, contrapeso del apuntalado, Casa Atada) y 5 secretos.

### M11 · Ciclo (reloj de ritmos y mareas)

- **Aspecto.** Cualquier cosa que late: una lámpara que se enciende y apaga, una marea, un puente de tinta, un soplo.
- **Reglas.** Alterna una marca con `period`, `on_fraction`, `phase` y `warning_time`, exactamente como ya hacen los pinchos de `hazard.gd` (periodo 2,4 s, 40 % activo, aviso de 0,4 s). Ritmos propuestos: **tinta** 4 s / 3 s, **soplo** 5 s, **marea** 40 s (20 s alta, 20 s baja, con 3 s de aviso: rumor y espuma), **ventana** 6 s. Todo ciclo avisa al menos 0,4 s antes de cambiar.
- **Qué guarda.** Nada (arranca en fase 0 al cargar la sala).
- **Implementación.** Un `Node` de 30 líneas. Reutiliza el reloj de `Hazard`.
- **Usos.** 9 puzles en las seis regiones.

### M12 · Combinación (selector de símbolos)

- **Aspecto.** Un grupo de 3 a 5 **piedras o discos grabados** con 4 símbolos que giran al golpearlos o al pulsar Z. La solución nunca está en el propio selector, sino en una inscripción o en el fondo.
- **Reglas.** Cada golpe avanza un símbolo (tic con tono distinto por símbolo). Al coincidir el conjunto con la solución, escribe su marca. No hay "intento fallido": se puede girar sin límite.
- **Qué guarda.** Permanente al resolverse; las posiciones parciales, no.
- **Implementación.** `dial.gd` con un array de estados, 30 líneas.
- **Usos.** 3 puzles de observación (Surco Ciego, Sala de los Lacres, Faro de las Velas).

### 1.2 Dónde se usa cada mecánica (puzles por región)

| Mecánica | Umbral | Cinturón | Archivo | Minas | Costa | Herida | Puzles |
|---|---|---|---|---|---|---|---|
| M2 Grieta | 2 | 3 | 1 | 2 | 1 | 1 | 10 |
| M3 Compuerta | 1 | 3 | 5 | 2 | 1 | 4 | 16 |
| M4 Disparadores | 1 | 3 | 1 | 3 | 1 | 0 | 9 |
| M5 Receptor | 1 | 1 | 0 | 0 | 0 | 2 | 4 |
| M6 Piedra de lectura | 1 | 1 | 1 | 1 | 1 | 3 | 8 |
| M7 Plataforma | 0 | 3 | 0 | 2 | 1 | 1 | 7 |
| M8 Corriente | 0 | 0 | 1 | 0 | 1 | 1 | 3 (+6 salas) |
| M9 Luz | 0 | 1 | 0 | 2 | 1 | 0 | 4 (+6 salas) |
| M10 Derribo | 0 | 0 | 1 | 1 | 1 | 0 | 3 (+5 secretos) |
| M11 Ciclo | 0 | 1 | 1 | 1 | 3 | 3 | 9 |
| M12 Combinación | 0 | 1 | 1 | 0 | 1 | 0 | 3 |

**Por qué cada una merece su coste.** M2, M3, M4 y M11 son casi gratis (reutilizan rastrillo, golpeable y reloj de pinchos). M1 es obligatoria para que el mundo recuerde algo. M5 es una variante de 40 líneas de M4 que sostiene la Puerta Sin Muro. M7 y M10 son de coste medio y de mucha presencia visual. M8 y M9 son las más caras en motor y arte, y las primeras en recortarse (§6). M6 es la más cara, pero es una habilidad del canon.

**Patrones sin código propio** (sacados de las mecánicas anteriores): *puerta de un solo sentido* = M3 con `one_way_side` y una palanca (M4) en el otro lado; *puerta con llave* = M5 + M3; *puente que se reconstruye* = M3 variante puente; *páginas en blanco* = M3 variante tinta + M6; *atajo de ida y vuelta* = M3 que se abre desde el lado difícil.

---

## 2. Cuarenta y un puzles de entorno

Formato de cada ficha: **cabecera** (sala, mecánicas, dificultad de 1 a 5) y un párrafo con **Cuenta** (qué dice del canon), **Pasos**, **Enseña**, **Pista**, **Sin atasco**, **Recompensa** y **Estado** (qué se guarda; "P" = permanente, "T" = temporal, se reinicia al descansar o morir; ver §5). Los nombres de sala son los de `textos-del-juego.md` §9; donde la sala aún no tiene nombre se propone uno entre corchetes. Los cuatro del canon (P03, P12, P35 y P41) llevan aquí un resumen y su diseño exacto en §3.

Reparto: Umbral 4, Cinturón 9, Archivo 8, Minas 7, Costa 6, Herida 7.

### 2.1 El Último Umbral (tutorial sin texto)

**P01 · La Tabla Suelta** · La cabaña del Umbral · M2 frágil · Dificultad 1
**Cuenta:** alguien escondió una página bajo el tablón antes de irse. **Pasos:** en el suelo de la cabaña hay un tablón con grietas blancas y un clavo torcido; tres golpes lo rompen y debajo queda la Página de Corvel 1. **Enseña:** que algunas cosas se rompen y que el golpe sirve para algo más que para pelear. **Pista:** el polvo que cae del tablón, único con grietas en la estancia. **Sin atasco:** nada se bloquea; puede dejarse. **Recompensa:** Página de Corvel 1 y su Nombre (Corvel). **Estado:** P (`s:ultimo_umbral.tabla`).

**P02 · La Verja del Patio** · El Patio de los Nombres y La Escalera del Remiendo · M4 palanca, M3 tablones (un solo sentido) · Dificultad 1
**Cuenta:** el Umbral se cerró deprisa y por dentro, quien se marchó atrancó lo que pudo. **Pasos:** desde el Patio se ve, tras una verja de tablones, el atajo hacia el Rellano de la Vela con una palanca al otro lado. Hay que dar la vuelta por la Escalera del Remiendo, subir al tejado y bajar al otro lado, tirar de la palanca y la verja se abre para siempre. **Enseña:** la palanca, su testigo (lamparilla roja a un lado y a otro) y el patrón "se abre desde el otro lado". **Pista:** el testigo se enciende al tirar y se ve desde ambos lados. **Sin atasco:** la verja nunca se cierra con el jugador dentro. **Recompensa:** atajo permanente en el Umbral (ahorra un recorrido de 40 baldosas). **Estado:** P (`d:ultimo_umbral.verja_patio`).

**P03 · El Cordel de Aldara** · El Patio de los Nombres (Fogón) · M6, M5 · Dificultad 2
Escena del acto IV: la primera vez que se usa Nombrar, con un nudo que no se deshace. Diseño exacto en §3.2. **Estado:** P (`p:ultimo_umbral.nudo_flojo`).

**P04 · La Puerta Tapiada** · La Puerta Tapiada y El Sótano de los Cantores · M2 hondo (Excavar) · Dificultad 2
**Cuenta:** una puerta cerrada "por orden de quienes aún mandaban", con marcas de uñas por dentro. **Pasos:** el muro tapiado tiene la veta ámbar del Golpe Hondo desde el principio; sin Excavar el Filo solo tañe. Con Excavar, 2 golpes abren el paso al Sótano de los Cantores, una sala pequeña con el grabado de Aún y la Medalla del Umbral. **Enseña:** que el mundo guarda cosas para quien vuelva con una habilidad nueva; el primer premio por volver. **Pista:** la veta es visible desde el comienzo y el tañido sorprende a los curiosos. **Sin atasco:** el Sótano tiene una escalera de salida a la altura de la puerta. **Recompensa:** Medalla del Umbral (reliquia) y el texto de los Cantores. **Estado:** P (`d:puerta_tapiada.muro`).

### 2.2 El Cinturón Yermo

**P05 · Las Cuentas del Rosario** · Las Terrazas Secas y La Cisterna · M2 frágil (observación) · Dificultad 2
**Cuenta:** el aviso de las Terrazas dice "cuenta los peldaños para volver". **Pasos:** la escalera de tablones de la Cisterna tiene 7 peldaños; en los peldaños 2, 4 y 6 hay una cuenta de rosario encajada. En el hueco de pared a la altura del peldaño 7, una grieta frágil esconde un nicho con la Cuenta del Rosario. Se salta desde el peldaño 6 y se rompe de tres golpes. **Enseña:** que el texto de un aviso es una pista literal. **Pista:** las cuentas visibles y la cuenta del propio aviso. **Sin atasco:** la escalera sigue sirviendo para volver. **Recompensa:** Cuenta del Rosario (reliquia). **Estado:** P (`s:cisterna.rosario`).

**P06 · La Rueda de Tomasa** · La Torre de Riego · M4 palanca, M7 continua · Dificultad 3
**Cuenta:** "Cerró la última compuerta y nadie más abrió la torre." **Pasos:** la rueda está parada y la cuerda tensa. Con el doble salto se llega a la compuerta alta y se tira de la palanca: los cuatro baldes de la rueda empiezan a subir y bajar (plataformas continuas a 80 px/s con 1,5 s de espera) y forman una escalera móvil hasta la cornisa del Cinturón alto. **Enseña:** la plataforma móvil y que "abrir" también es poner a girar. **Pista:** la cuerda tensa y la lamparilla del testigo, apagada. **Sin atasco:** la rueda gira para siempre una vez abierta; los baldes nunca aplastan. **Recompensa:** acceso al Cinturón alto desde la Torre (atajo del camino principal). **Estado:** P (`p:torre_de_riego.rueda`).

**P07 · Las Torres en Cadena** · La Torre de Riego y La Segunda Torre de Riego (Camino de Ronda) · M7, M4 · Dificultad 3
**Cuenta:** el Segundo Aliento: Tomasa guardaba el aire entre un peldaño y el siguiente. **Pasos:** dos torres con ruedas separadas por 14 baldosas. Hay que saltar de los baldes de la primera cuando llegan arriba (la espera de 1,5 s da ventana) y usar el doble salto para aterrizar en los de la segunda. Cada rueda tiene su palanca. **Enseña:** leer el ritmo de una plataforma. **Pista:** una marca de tiza en el punto alto del carril. **Sin atasco:** fallar cae a una terraza con escalera de vuelta. **Recompensa:** atajo hacia el Camino de Ronda. **Estado:** P (`p:camino_de_ronda.torre_1` y `.torre_2`).

**P08 · El Surco Ciego** · El Surco Ciego · M12, M2 hondo · Dificultad 3
**Cuenta:** «Aquí se sembraba trigo. Se sigue sembrando. Nadie recuerda qué.» **Pasos:** tres mojones giratorios con 4 símbolos (espiga, hoz, pan, ojo). En el fondo del campo (decorado) el espantapájaros lleva tres figuras en el brazo: espiga, pan, hoz. Se giran los mojones a esa secuencia y se abre el depósito de la terraza. El suelo bajo el espantapájaros es hondo y, con Excavar, da más premio. **Enseña:** buscar la solución en el fondo. **Pista:** el espantapájaros mira al foso y levanta tres dedos. **Sin atasco:** los mojones giran sin límite. **Recompensa:** 60 Ecos y, con Excavar, la Semilla gris. **Estado:** P (`p:surco_ciego.mojones`, `s:surco_ciego.hondo`).

**P09 · El Cruce del Pan** · El Cruce del Pan · M4 placa, M3 · Dificultad 3
**Cuenta:** la mesa tiene tres sitios y tres rayas de tiza: hay quien reparte pan entre tres. **Pasos:** tres placas (los tres sitios) separadas por 13 baldosas, cada una activa 6 s después de soltarla. Hay que pisarlas en una carrera de dash y doble salto, y la tercera abre el tablón que da a la Página de Corvel 2. Cada placa tiene una lamparilla que se apaga en cuenta atrás. **Enseña:** la placa y que el tiempo se lee con la luz. **Pista:** las rayas de tiza se van borrando en la mesa conforme se pisan. **Sin atasco:** el tablón abierto por la tercera placa queda abierto para siempre (P). **Recompensa:** Página de Corvel 2. **Estado:** placas T, tablón P (`p:cruce_del_pan.mesa`).

**P10 · El Campo Gris** · El Campo de los Ferrán · M9 (luz de revelado) · Dificultad 3
**Cuenta:** el parche gris de la Desmemoria "con el borde limpio, como cortado con tijera". **Pasos:** dentro del parche el suelo no se dibuja salvo en el resplandor de 2,5 baldosas del Caminante; las plataformas son solo `x` reveladas. Unas huellas de bota (decorado) llevan de lado a lado por la ruta correcta: las de Eulalia, que se llevó el delantal. **Enseña:** avanzar a tientas y confiar en los restos de otros. **Pista:** las huellas son la solución; los mojones del borde también. **Sin atasco:** caer devuelve al borde del parche, sin daño. **Recompensa:** el espantapájaros con el delantal de Eulalia (Nombre Eulalia Ferrán). **Estado:** ninguno (el Nombre sí, por su sistema).

**P11 · El Manantial** · El Brocal, La Acequia y La Torre de Riego (tres salas) · M2 hondo, M3, M7 · Dificultad 4
**Cuenta:** «Sin agua desde que olvidamos dónde estaba el manantial. Hay que cavar más abajo.» **Pasos:** con Excavar se rompe el suelo hondo del fondo del Brocal (abajo + golpe) y brota agua. En la Acequia el cauce seco corre y aparece un puente de tablones; en la Torre la rueda de P06 gira sola y un balde baja al sótano donde espera el Dedal. **Enseña:** una causa en una sala y un efecto en dos más. **Pista:** el sonido del agua nueva y un punto en el mapa. **Sin atasco:** todo es repetible. **Recompensa:** Dedal de la Torre. **Estado:** P (`p:brocal.manantial`).

**P12 · El Mirador de Oda** · El Mirador (Pasarela de los Mensajeros) · M6, M11, M3 · Dificultad 3
Puzle opcional del canon (acto IV en adelante): invocar a Oda con su Nombre y alcanzarla en una carrera de puentes que se hunden. Diseño exacto en §3.3. **Recompensa:** Insignia de Mensajera. **Estado:** P (`p:pasarela.ultima_carrera`).

**P13 · El Relevo de la Guardia** · El Aljibe (después de todo) · M5 · Dificultad 1
Epílogo secreto: una sola interacción que depende de marcas (`final_compartir` e `i:insignia`). Se describe en §3.4. **Estado:** P.

### 2.3 El Archivo

El Archivo se diseña por contraste con el resto: ordenado, simétrico, con pasillos en blanco que son los propios puzles.

**P14 · Pasillo Tres** · Pasillo Tres (sala en blanco) · M11, M3 puente · Dificultad 3
**Cuenta:** «En blanco. No se cierra: a veces vuelve.» **Pasos:** el pasillo tiene 6 tramos de suelo que aparecen 4 s y desaparecen 3, desfasados. La tinta del suelo se desvanece 0,5 s antes y el crujido de página avisa al oído. **Enseña:** el ciclo con aviso. **Pista:** una mancha de tinta en el borde marca el sentido del ritmo. **Sin atasco:** salida y llegada son fijas; caer da a un pasillo inferior con escalera. **Recompensa:** el camino corto a la Estantería Nueve. **Estado:** ninguno (T puro).

**P15 · La Estantería-Puente** · Estantería Nueve · M10 · Dificultad 3
**Cuenta:** "Sección de Linajes. Contenido: dado por perdido." Las hojas están en blanco, los lomos intactos. **Pasos:** una estantería-torre de 12 baldosas se alza junto a un abismo de 11 de ancho. Se golpea desde el lado opuesto al abismo, cruje 0,5 s y cae hacia él, formando un puente de un solo sentido. En la base se lee la Página de Corvel 3. **Enseña:** que la dirección del golpe decide hacia dónde cae. **Pista:** la sombra de la estantería está pintada en el suelo, inclinada hacia el vacío. **Sin atasco:** si se golpea desde el lado equivocado no hace nada (el hueco no está libre) y se puede probar desde el otro. **Recompensa:** acceso a la Sala de los Lacres y la Página 3. **Estado:** P (`p:estanteria_nueve.puente`).

**P16 · La Sala de los Lacres** · La Sala de los Lacres · M12, M3 · Dificultad 3
**Cuenta:** "Todo lo sellado debe constar. Lo que no consta no ha sido sellado." **Pasos:** tres lacres giratorios con 4 símbolos de cera (sello de rango, sello de copia, sello de borrado, sello vacío) y, en la pared, un libro de cuentas con tres renglones: dos sellos de rango, uno de copia, uno de borrado. El orden correcto es leído del libro de arriba abajo. La balanza (un pesapapeles en un plato, nada en el otro) baja al acertar. **Enseña:** lectura de una inscripción como solución. **Pista:** el plato vacío es la clave: el último sello es el "vacío". **Sin atasco:** los lacres giran sin límite. **Recompensa:** Pesa del Archivo (reliquia). **Estado:** P (`p:sala_de_los_lacres.libro`).

**P17 · El Pasaje de las Llaves** · El Pasaje de las Llaves y La Escalera de Caracol (dos salas) · M4, M3 un solo sentido · Dificultad 3
**Cuenta:** el esqueleto apoyado en una puerta cerrada por dentro: "Cerré yo. No me preguntéis por quién." **Pasos:** la puerta del Pasaje no se abre desde fuera. Se sube por la escalera de caracol taponada a medias (se pasa por un hueco entre libros), se baja por un conducto de ventilación al otro lado y se tira de la palanca que ya estaba allí. La puerta se abre hacia el exterior y el esqueleto cae. **Enseña:** la reja de un solo sentido a lo largo de dos salas. **Pista:** se ve el testigo (lamparilla roja) tras una rejilla de la puerta. **Sin atasco:** el conducto permite volver. **Recompensa:** el Llavero del Custodio (objeto de Oriol) y un atajo hacia el Retrato Ausente. **Estado:** P (`d:pasaje_de_las_llaves.puerta`).

**P18 · El Retrato Ausente** · El Retrato Ausente · M2 frágil (observación) · Dificultad 2
**Cuenta:** un marco vacío, un clavo y una sombra: la fundadora no está. **Pasos:** el marco cuelga de un muro que oculta otro cuarto. La sombra más oscura de la pared tiene exactamente la forma de la grieta frágil detrás. Se rompe (3 golpes) y al otro lado, a lápiz, en el reverso del marco: "Ardena y la niña Nía. Que no se pierdan." **Enseña:** que las ausencias (sombras, marcas) son pistas. **Pista:** la sombra y un hilo de polvo que cae sobre el marco. **Sin atasco:** la grieta se rompe desde cualquiera de los dos lados. **Recompensa:** Nombre Ardena. **Estado:** P (`s:retrato_ausente.reverso`).

**P19 · La Tinta que Huye** · Sala de la Tinta [sala nueva del Archivo] · M3 tablón de tinta · Dificultad 4
**Cuenta:** la sala donde la tinta de las estanterías desaparece según se camina. **Pasos:** 9 estanterías como plataformas; cada una se borra 1,2 s después de pisarla y vuelve a los 6 s. Solo se puede avanzar. **Enseña:** la presión del "no mires atrás". **Pista:** la primera ya está borrada, como ejemplo. **Sin atasco:** caer lleva a un corredor con escalera de vuelta. **Recompensa:** la rama alta del Archivo con el Folio en blanco. **Estado:** ninguno.

**P20 · El Pozo Blanco** · El Pozo Blanco [sala nueva] · salto de pared, M8 ascenso · Dificultad 4
**Cuenta:** el pozo de paredes en blanco: se ve dónde agarrarse solo por contraste. **Pasos:** el pozo mide 10 baldosas de ancho y solo hay franjas de pared real de 2, marcadas con tinta, cada 5 de altura; el resto es blanco sin colisión. Entre franjas, una corriente de páginas ascendentes ayuda. **Enseña:** leer el Agarre por contraste. **Pista:** las franjas entintadas. **Sin atasco:** el fondo es suelo con escalera. **Recompensa:** una sala oculta si se sube sin tocar el fondo. **Estado:** ninguno.

**P21 · El Arco del Silencio** · La Escalera de Caracol · M6, M3 · Dificultad 2 (opcional, tras Nombrar)
**Cuenta:** "Por orden del Archivo: no leer en voz alta bajo este arco." **Pasos:** bajo el arco hay una Piedra de lectura que acepta cualquier Nombre del Archivo. Al decirlo, los libros que taponan la escalera se desatan y caen. Arriba, el corredor que la Orden mandó callar. **Enseña:** Nombrar sirve para deshacer el silencio impuesto. **Pista:** la silueta de una boca tapada. **Sin atasco:** quien no tenga Nombrar no pierde nada. **Recompensa:** Aguja del Escriba (reliquia). **Estado:** P (`p:escalera_de_caracol.libros`).

### 2.4 Las Minas del Origen

Las Minas son cálidas y excesivas: la luz, la cuerda y el exceso son su idioma.

**P22 · La Vagoneta Quieta** · La Vagoneta Quieta · M7 a demanda, M4 palanca · Dificultad 3
**Cuenta:** «Cargamos más de lo que podía mover. Seguimos cargando.» **Pasos:** una vagoneta cruza un hueco de 40 baldosas que ni el dash cubre. Una palanca de desvío elige entre dos ramales: uno lleva al otro lado, el otro a un nicho de ofrendas. Z en la vagoneta la pone en marcha (14 s, sin poder bajar). **Enseña:** el viaje y una decisión de ramal. **Pista:** los raíles dibujan los dos ramales. **Sin atasco:** la vagoneta vuelve a su origen 8 s después de llegar. **Recompensa:** Diente de la Mina (en el nicho). **Estado:** palanca T, nicho P (`s:vagoneta_quieta.nicho`).

**P23 · La Galería de las Lámparas** · Galería del Primer Pico [sala nueva] · M9 · Dificultad 2
**Cuenta:** el hambre de luz de los Cavadores. **Pasos:** sala oscura con tres lámparas de grasa. La primera está encendida; las otras dos se encienden con Z y dejan ver tramos de plataforma. Cada lámpara dura 60 s y su luz se solapa con la siguiente, así que hay que encenderlas en cadena. **Enseña:** la mecánica de la luz sin riesgo de pinchos. **Pista:** la mecha menguando y la sombra de las plataformas, ya visible. **Sin atasco:** el resplandor propio nunca se apaga y el suelo de partida es fijo. **Recompensa:** acceso al Andén de los Picos. **Estado:** T.

**P24 · La Cuerda de Mil Nudos** · La Cuerda de Mil Nudos · M7 ascensor, M4, M11 · Dificultad 4
**Cuenta:** en cada nudo, un papel: «Estoy bien. Que lo sepan arriba.» **Pasos:** un pozo de 60 baldosas con un montacargas que sube 15 por tramo. En cada descanso una palanca lo envía al siguiente, y cada 4 tramos se detiene 6 s (ciclo). En el último nudo, un papel distinto. **Enseña:** una subida larga hecha de decisiones cortas. **Pista:** la letra de los papeles es cada vez más temblorosa. **Sin atasco:** cada descanso es fijo y tiene barandilla. **Recompensa:** Nombre Dimas. **Estado:** palancas P (`d:cuerda_de_mil_nudos.tramo_1` a `.tramo_4`).

**P25 · La Cámara de las Voces** · La Cámara de las Voces · M6, M9 · Dificultad 2 (opcional, tras Nombrar)
**Cuenta:** "Quien baje, que baje callado." Un círculo de piedras con marcas de rodillas. **Pasos:** cinco velas fundidas en círculo se encienden cuando se dice un Nombre de las Minas (Berenguer, Dimas, Rosendo, Magda). Al encender las cinco, el muro del fondo se abre al Cuarto del Capataz. **Enseña:** que Nombrar enciende cosas. **Pista:** las marcas de rodillas llevan a la piedra. **Sin atasco:** se puede repetir con cualquier otro Nombre de la región. **Recompensa:** acceso al Cuarto del Capataz y la Página de Corvel 4. **Estado:** P (`p:camara_de_las_voces.velas`).

**P26 · La Fila de Espera** · La Fila de Espera · M2 hondo · Dificultad 2
**Cuenta:** esqueletos sentados mirando un túnel tapiado: aguardan relevo. **Pasos:** con Excavar, 2 golpes al tapiado del fondo. Tras él, un túnel que conecta con la base de la Cuerda de Mil Nudos. **Enseña:** que Excavar abre atajos. **Pista:** los esqueletos miran todos el mismo muro. **Sin atasco:** el túnel permite el paso en ambos sentidos. **Recompensa:** atajo y ficha de turno (objeto). **Estado:** P (`d:fila_de_espera.tapiado`).

**P27 · La Red de Pasos Hondos** · Minas, Cinturón, Costa y Umbral (cuatro salas) · M2 hondo, M3 · Dificultad 3
**Cuenta:** los Hondos abrieron galerías para que nadie volviera a cavar por donde ellos cavaron. **Pasos:** cinco suelos y muros hondos (Veta Tapiada hacia el Cinturón, Taller de Dola hacia la Costa, uno hacia el Umbral, dos entre salas de las Minas) forman la red de atajos del acto III. **Enseña:** que el mundo se vuelve una red. **Pista:** Dola enumera "los cinco pasos" en su fase 3. **Sin atasco:** ningún paso cierra la ida. **Recompensa:** velocidad (unos 25 minutos menos de recorrido). **Estado:** P ×5 (`d:veta_tapiada.paso`, etc.).

**P28 · El Contrapeso del Apuntalado** · Cámara de Apuntalamiento (antesala) · M10, M4 placa, M3 · Dificultad 4
**Cuenta:** "Apuntalad lo que cavasteis. Lo que no se sostiene cae sobre quien lo sostuvo." **Pasos:** un puntal de 10 baldosas está junto a una placa de presión en un hueco que el jugador no puede cargar. Se golpea el puntal desde el lado contrario y cae sobre la placa, que queda pulsada para siempre y abre la reja de piedra. **Enseña:** que el Derribo puede ser un peso. **Pista:** la placa tiene un puntal dibujado encima. **Sin atasco:** si cae en la dirección equivocada (el hueco no está libre), no cae. **Recompensa:** el camino a Magda y 80 Ecos. **Estado:** P (`p:camara_de_apuntalamiento.contrapeso`).

### 2.5 La Costa Retenida

La Costa es nítida y luminosa; sus puzles son de ritmo y de dejar ir.

**P29 · El Acantilado de Cortinas** · Acantilado de Cortinas · M8, M11 · Dificultad 3
**Cuenta:** «Dicen que cantan los que no recuerdan.» Cortinas de lino al viento. **Pasos:** el viento sopla 5 s hacia dentro y 5 s hacia el mar. A favor, los saltos llegan a 18 baldosas; en contra, no se alcanza el borde. Las cortinas se hinchan 1 s antes del cambio. **Enseña:** cuándo esperar. **Pista:** las cortinas. **Sin atasco:** plataforma fija al principio y al final. **Recompensa:** Campanilla de la Costa. **Estado:** ninguno.

**P30 · La Playa de Nombres** · La Playa de Nombres · M11 marea, M3 roca · Dificultad 2
**Cuenta:** "La marea ya ha tocado el último." **Pasos:** las letras de piedras ocupan una playa. Con marea baja (20 s de cada 40) aparece un camino de rocas hasta el zapato de Telmo, que se recoge con Z. Con marea alta el camino se cubre y el agua arrastra suavemente hacia atrás. **Enseña:** la marea como reloj. **Pista:** la espuma 3 s antes de cada cambio. **Sin atasco:** la playa seca siempre vuelve; nunca se ahoga. **Recompensa:** Zapato pequeño (misión de Iria), Nombres Marta y Julián. **Estado:** Zapato P (`i:zapato_de_telmo`).

**P31 · El Faro de las Velas** · El Faro de las Velas · M9, M4, M12 · Dificultad 3
**Cuenta:** «Cuando el faro se apaga, la costa se queda sin nombre.» **Pasos:** la escalera, a oscuras, tiene una vela por peldaño y los peldaños solo existen con luz. Una combinación de tres discos en el rellano elige cuáles se encienden; la solución es el orden de las ofrendas del altar de abajo: cuenco, cinta, peine. **Enseña:** que la luz es una elección. **Pista:** las tres ofrendas. **Sin atasco:** la vela más alta está siempre encendida. **Recompensa:** acceso a la lámpara del faro. **Estado:** P (`p:faro_de_las_velas.luz`).

**P32 · La Casa Atada** · La Casa Atada · M10, M2 frágil · Dificultad 3
**Cuenta:** casa llena de cosas sujetas con una cuerda a un clavo. **Pasos:** hay dos caminos. Cortar la cuerda con el Filo hace caer los estantes (Derribo) y llegar al peine con el nombre de Elvira en un instante, pero Casilda lo pierde todo. El camino largo trepa por los estantes con doble salto y sin tocarlos. **Enseña:** que el atajo tiene un coste humano. **Pista:** la cuerda brilla; Casilda mira la cuerda. **Sin atasco:** el Nombre Elvira tiene una segunda fuente (la intervención ante Vael). **Recompensa:** Nombre Elvira. **Estado:** P (`s:casa_atada.cuerda`).

**P33 · El Primer Olvido** · El Rellano de Cal · M6 · Dificultad 1 (opcional, tras Eudora)
**Cuenta:** "Aquí se dijo el Primer Olvido. No se dijo en voz alta." **Pasos:** con Nombrar, tras vencer a Eudora, se dice Mateo ante el círculo de cal del suelo. Se enciende y aparece una piedra blanca. **Enseña:** que lo callado también se puede decir. **Pista:** el círculo vacío. **Sin atasco:** ninguno. **Recompensa:** Piedra blanca de la Costa (reliquia). **Estado:** P (`p:rellano_de_cal.mateo`).

**P34 · El Embarcadero** · La Barca Varada y el Embarcadero · M7 viaje, M11 · Dificultad 1
**Cuenta:** Mirena lleva al jugador de una cala a otra. **Pasos:** Z en el embarcadero y 18 s de viaje con las olas (ciclo) sin riesgo. **Enseña:** que no todo es esfuerzo. **Pista:** el remo. **Sin atasco:** la barca regresa sola. **Recompensa:** atajo al pie del Cinturón. **Estado:** P (`d:barca_varada.viaje`).

### 2.6 La Herida

La Herida reconstruye fragmentos de las salas anteriores. Sus puzles repiten las mecánicas de las regiones en versión más extraña.

**P35 · La Puerta Sin Muro** · La Puerta Sin Muro · M5 ×3, M3 · Dificultad 3
Canon: Cera, Piedra y Cal. Diseño exacto en §3.5. **Estado:** P ×4.

**P36 · El Círculo Colgado** · El Círculo Colgado · M7, M8, M11 · Dificultad 4
**Cuenta:** cinco sillas suspendidas, cada una con una máscara azul. **Pasos:** las sillas son plataformas que giran en círculo bajo un viento que cambia de lado cada 5 s. Cada una lleva una placa con un Nombre (Íñigo, Leocadia, Tadeo, Brígida, Álvar) que se lee al posarse. **Enseña:** ritmo y viento a la vez. **Pista:** las sillas giran de la primera a la quinta. **Sin atasco:** suelo fijo de partida y de llegada. **Recompensa:** los cinco Nombres de la Herida. **Estado:** ninguno (el Nombre lo guarda su sistema).

**P37 · La Escalera de Hojas** · La Escalera de Hojas · M3 tinta, M6 · Dificultad 4
**Cuenta:** "Lo último que se escribió fue lo primero que se perdió." **Pasos:** los peldaños son libros sin cubierta; cada uno se borra al pisarlo, igual que en P19, y el último está en blanco desde el principio. A mitad de la subida hay una Piedra de lectura: al decir Corvel, el último peldaño se llena de tinta. **Enseña:** que un Nombre repara lo perdido. **Pista:** la hoja arrancada en el rellano. **Sin atasco:** la Piedra funciona aunque se cayera en los peldaños. **Recompensa:** la Página de Corvel 6. **Estado:** P (`p:escalera_de_hojas.corvel`).

**P38 · La Pared Raspada** · La Pared Raspada · M2 frágil (observación) · Dificultad 2
**Cuenta:** cientos de nombres, todos con una raya diagonal. **Pasos:** todas las rayas bajan de izquierda a derecha, salvo una que sube. El nombre bajo esa raya es una grieta frágil que da a una cámara con una lámpara apagada. **Enseña:** buscar la anomalía en una trama. **Pista:** la raya que sube. **Sin atasco:** ninguno. **Recompensa:** la lámpara encendida sin llama (objeto) y un atajo. **Estado:** P (`s:pared_raspada.raya`).

**P39 · El Eco Quieto** · El Eco Quieto · M11, M3 · Dificultad 3
**Cuenta:** una figura abre una puerta que no existe, una y otra vez. **Pasos:** cada 6 s la puerta aparece 1,5 s durante el gesto del Eco. Hay que cruzarla en ese instante. **Enseña:** copiar un gesto sin que se pida. **Pista:** el Eco abre con la mano izquierda 1 s antes. **Sin atasco:** la puerta se repite sin límite. **Recompensa:** el Eco de una puerta (objeto) y un atajo. **Estado:** P (`d:eco_quieto.puerta`).

**P40 · La Mesa de Dos** · La Mesa de Dos · M6 ×2, M11 · Dificultad 5 (opcional)
**Cuenta:** una taza llena y otra volcada: se dijeron que volverían mañana. **Pasos:** dos Piedras de lectura separadas por 22 baldosas. Un Nombre dicho en la primera la ilumina 4 s; hay que decir otro, distinto, en la segunda antes de que se apague. Hacen falta dos voces. **Enseña:** Compartir: una voz dura un instante, dos duran más. **Pista:** la segunda piedra tiene la sombra exacta de la primera. **Sin atasco:** repetible sin límite. **Recompensa:** la Taza volcada y la vía corta al último Ancla. **Estado:** P (`p:mesa_de_dos.voces`).

**P41 · La Sala de Aún y la Escalera de los Nombres** · La Sala de Aún · M5, M6, M3 · Dificultad 2 mecánica, 5 emocional
Canon: las tres salidas y los 20 peldaños. Diseño exacto en §3.6. **Estado:** P.

---

## 3. Los puzles del canon, con precisión

### 3.1 Piedra de lectura: reglas comunes (M6)

| Estado | Condición | Qué ve y oye el jugador |
|---|---|---|
| Muda | Sin Nombrar | Z: "Esta piedra pide un nombre." Sin icono de mantener |
| Atenta | Con Nombrar, piedra sin resolver | Aviso "Mantén Z: nombrar". Al mantener 0,6 s, el Caminante abre la boca (pose de 3 fotogramas) y suena un aliento |
| Eligiendo | Lista abierta (`ModalLayer` + `MenuList`, juego en pausa) | Título "Nombres que sostienes", ordenados por región y, dentro, por orden de lectura. Se cierra con atrás sin gastar nada |
| Dicha | Se elige un Nombre | 1,2 s de pronunciación: tono propio del Nombre (la altura depende de su posición en el diario), la piedra palpita |
| Resuelta | Acierta | Efecto de la piedra (ver tabla) |
| Callada | Falla | "La piedra no responde." Espera de 1,5 s. Sin daño ni coste |

**Lista de Nombres.** Muestra solo los **sostenidos** (los callados con el Paño no aparecen: ya no se pueden decir porque el mundo ya no los sostiene). Hasta 30 entradas más, si se ha pronunciado, **Linde** (que no cuenta entre los 30). Se acepta por Nombre exacto, por región o por lista. Probar a ciegas es posible; cada piedra lleva una **sombra grabada** que hace de pista.

**Piedras previstas** (id, sala, a quién acepta y qué hace):

| Id | Sala | Acepta | Efecto |
|---|---|---|---|
| `nudo` | El Patio de los Nombres | Linde | Afloja el nudo (permanente) |
| `mirador` | El Mirador | Oda Bellver | Invoca el Eco de Oda y empieza la carrera |
| `escalera` | La Sala de Aún | todos los sostenidos | Enciende peldaños (§3.6) |
| `arco` | La Escalera de Caracol | cualquier Nombre del Archivo | Deshace los libros (opcional) |
| `voces` | La Cámara de las Voces | cualquier Nombre de las Minas (cinco veces) | Enciende las velas (opcional) |
| `rellano` | El Rellano de Cal | Mateo | Piedra blanca (opcional) |
| `hojas` | La Escalera de Hojas | Corvel | Llena el último peldaño |
| `mesa_a`, `mesa_b` | La Mesa de Dos | cualquiera, distintos | Dos voces en 4 s |

**Recorte.** Si hay que reducir Nombrar a lo mínimo del guion (acto IV, Mirador y escalera), se quitan `arco`, `voces`, `rellano`, `hojas` y `mesa_*`, y quedan **tres piedras** (`nudo`, `mirador`, `escalera`). Ninguna de las cinco extra abre nada del camino principal.

### 3.2 El nudo de Aldara (acto IV)

Es el tutorial de Nombrar y debe enseñar su regla de fondo: **una voz sola sostiene un instante; dos sostienen**.

- **Dónde.** El Patio de los Nombres, junto al Fogón, tras la escena del Hito. Aldara tiende el cordel.
- **Qué se ve.** El cordel tiene tantos nudos como Nombres **no** sostenidos (30 menos los llevados); cada Nombre nuevo lo afloja visiblemente la próxima vez que se pasa por el Umbral. Y **un nudo extra, oscuro y apretado**, sin Nombre.
- **Pasos.** Z ante el cordel: el aviso dice "Mantén Z: nombrar". Se elige **Linde** (aparece en la lista desde que el Caminante la dijo ante el Hito). El nudo tiembla, se afloja, brilla 4 s y vuelve a apretarse a medias: queda **flojo, no deshecho**. Aldara dice: "No se deshace. Todavía no." Es lo único que dice.
- **Qué guarda.** `p:ultimo_umbral.nudo_flojo` (permanente). La marca solo cambia el dibujo del nudo y una línea de Aldara.
- **Cierre.** El nudo solo se deshace en el final Compartir (texto de epílogo: "El último nudo ya no está atado."). Es una promesa jugable que cumple el final, no un puzle con recompensa.

### 3.3 El Mirador y La Última Carrera (opcional)

- **Condición.** Nombrar y haber visto la carta de Oda. La piedra está al pie de la linterna encendida del Mirador, con la sombra de un pie alado.
- **Pasos.** Mantener Z y elegir **Oda Bellver**. La linterna se apaga, el viento se detiene y un **Eco de Oda** (silueta azul traslúcida) aparece en el extremo este de la Pasarela y echa a correr hacia el oeste. No es un combate: es una carrera de **ritmo**.
- **Reglas.** El Eco corre a 330 px/s (el jugador, 300 más el dash). En cada uno de los tres huecos de 17 baldosas deja un **puente de luz** (compuerta puente) que dura 2 s, así que el recorrido se puede seguir sin dash si se llega a tiempo; con dash se acorta. Si el jugador se queda a más de 24 baldosas, el Eco espera de pie hasta que se acerca. Termina en lo alto de La Chimenea: al tocarla, el Eco se arrodilla un segundo y se deshace, y deja la Insignia de Mensajera.
- **Caída.** Caer a los pinchos cuesta 1 de vida y devuelve al último suelo firme, como en la Chimenea. Si el jugador muere o descansa, el Eco desaparece y la piedra vuelve a poder usarse.
- **Estado.** Insignia P (`i:insignia`) y `p:pasarela.ultima_carrera` P. La invocación en sí es T.

### 3.4 El Relevo de la Guardia (epílogo)

Receptor (M5) en el pecho de la coraza arrodillada del Aljibe. Solo existe si `p:aun.compartido` e `i:insignia` están activas. Mantener Z 1,5 s ("Z: Relevar la guardia"). Lo que sigue (la coraza que se deshace, Oda corriendo hasta la Casa Varga) es una secuencia de la escena final, no un puzle. Estado P (`p:aljibe.relevo`).

### 3.5 La Puerta Sin Muro (Cera, Piedra y Cal)

- **Sala.** Un páramo gris de 108×30 baldosas. En el centro, un marco de piedra de 8 baldosas de ancho y 6 de alto, de pie sin muro. Al este del marco, 30 baldosas de suelo llano que acaban en una **niebla de cal** (compuerta variante cal, cerrada). Antes de la puerta, un Ancla.
- **Qué pasa al cruzar el marco.** Nada: se pasa y se llega a la niebla, que no se atraviesa. Es el "nada cambia" del canon.
- **Los tres huecos.** En la jamba izquierda, el dintel y la jamba derecha hay tres nichos con silueta: un disco partido (Cera), un guijarro con pico (Piedra) y un círculo (Cal). Los marcadores `c` los dan; las marcas que exigen son `i:sello_cera` (Hesper), `i:sello_piedra` (Magda) e `i:sello_cal` (Eudora). En el nicho vacío el texto de pista es el del canon: «Cera. Piedra. Cal. Todo lo que hicimos para que no hablase.»
- **Cómo se usa.** Mantener Z 1 s ante un nicho cuyo Sello se tiene: "Romper el Sello" (el canon dice que romper es **devolver**, no robar). Cada uno tiene su efecto: la Cera suelta hojas que vuelan hacia el oeste, la Piedra hace temblar el suelo 1 s, la Cal levanta un polvo blanco que se disuelve. El orden es libre. Marcas `p:puerta_sin_muro.cera`, `.piedra`, `.cal`.
- **Al tercero.** El páramo se queda en silencio 2 s, aparece durante 1,5 s un muro de ladrillo enorme con tres huecos vacíos (el muro que la Orden levantó y que "nunca estuvo"), se resquebraja y cae. La niebla se abre. Marca `d:puerta_sin_muro.abierta`.
- **Qué se guarda.** Las tres marcas y la de apertura, permanentes.
- **Sin atasco.** Se puede llegar con 0, 1, 2 o 3 Sellos y volver. El menú de la pausa muestra los Sellos con `IconRow` (0 a 3) y a qué región pertenece cada uno (Cera: el Archivo, Piedra: las Minas, Cal: la Costa), para que quien llegue de pronto sepa qué falta. Cano, delante de la puerta, dice la frase de su fase 3.

### 3.6 La Sala de Aún: Sellar, Soltar y Compartir

**Disposición.** Una sala de 54×30 baldosas a la que se llega por una Ancla (el "último Ancla sin nombre" del canon), con tres salidas visibles desde la entrada. Una torre vertical de 54×70 baldosas, **La Escalera**, se abre sobre el centro.

| Salida | Dónde | Cómo se usa | Qué la abre |
|---|---|---|---|
| El Asiento | Derecha, sobre una tarima de 2 baldosas | Mantener Z 1,5 s: "Sentarte" | Siempre |
| El Margen | Izquierda, un borde de suelo que se vuelve blanco | Mantener Z 1,5 s: "Entrar" | Siempre |
| La Escalera de los Nombres | Centro, hacia arriba | Mantener Z 3 s ante el pie de la escalera, ver abajo | 20 Nombres sostenidos y Nombrar |

Mantener, en vez de un menú, evita pulsar sin querer y respeta la regla "ningún menú". El cuerpo de Ansel yace a los pies del Asiento y es solo un `Readable` ("Es tu cuerpo. Todavía no.") hasta el final Compartir.

**La escalera, exactamente.**

1. **El pie.** Con Nombrar, "Mantén Z: nombrar" 3 s. Los Nombres sostenidos se pronuncian de uno en uno (0,15 s cada uno) y cada uno enciende un peldaño, empezando por el de abajo. Los peldaños se ordenan por región (Umbral, Cinturón, Archivo, Minas, Costa, Herida) y cada uno toma el color de su región, así que la escalera es una banda de colores.
2. **Peldaños.** 20 en total, de 5 baldosas de ancho y 3 de salto, en cuatro tramos en zigzag. Son de un solo sentido y **sólidos solo si están encendidos**. Los que faltan se dibujan como contorno, sin colisión.
3. **Si faltan Nombres.** Se encienden los que hay y el cartel dice: "Cada peldaño pide un nombre. Faltan {n}." (con n = 20 menos los sostenidos). Se puede subir hasta el último encendido y volver: **no se compromete nada**. Bajo el límite se ve el contorno del resto.
4. **Compromiso.** Si hay 20 o más, el primer peldaño pisado activa `p:aun.escalera_comprometida`: las salidas del Asiento y del Margen se cubren de cal y dejan de usarse. Junto con el Asiento y el Margen, es el único punto sin retorno del canon. Se puede caer o bajar a voluntad; los peldaños quedan encendidos. No hay daño por caída.
5. **La cima.** Aún es una presencia de luz y nombres repetidos. Mantener Z 4 s con Nombrar: los nombres salen como hilos y cada Hito del mundo se enciende un instante (la escena del canon). Se dispara el final **Compartir**.
6. **Después.** El cuerpo pasa a "Z: Recogerte" (mantener Z 1,5 s). Se recoge a sí mismo y fin.

**Qué se guarda.** `p:aun.escalera_comprometida`, y el final elegido (`p:aun.final = sellar | soltar | compartir`) para decidir el epílogo (Relevo, §3.4). Los peldaños encendidos no se guardan (se vuelven a encender al repetir el ritual).

**Sin atasco ni azar.** Hay un Ancla justo antes. El número de Nombres que faltan se ve en el diario y en el cartel. Los Nombres callados no cuentan; la opción de callar ya avisó de ello.

---

## 4. Secretos

### 4.1 Tipos

| Tipo | Qué es | Cómo se anuncia |
|---|---|---|
| Muro frágil | Pieza de M2 frágil, rompible con el Filo | Grietas blancas, polvo que cae, un hueco sonoro al golpear cerca |
| Suelo o muro hondo | M2 hondo, solo con Excavar | Veta ámbar y tañido metálico; invita a volver |
| Camino oculto | Un paso tapado por decorado sin colisión (enredaderas `q`, cadenas `N`, hierba `H`) | Una brizna de luz o un rastro de polvo que lo cruza |
| Atajo | Un camino de ida que se abre desde el lado difícil (M3 + palanca) | La reja se ve desde el lado cerrado |
| Sala oculta | Una sala completa tras un secreto; cuenta para las ocho "secretas y atajos" | Lo que la rodea se queda sin explicar (una sala demasiado corta, un hueco en el mapa) |
| Nombre escondido | Un Nombre tras un secreto | Un susurro cuando se está a menos de 6 baldosas |

### 4.2 Reglas de colocación

1. **Máximo un secreto por cada tres salas** de media y nunca dos seguidos en la misma sala.
2. **Una pista visible en la misma pantalla**, siempre. Si la pista no se ve, no hay secreto. Cada región tiene su idioma de pista (Archivo: sombra o ausencia; Minas: polvo y veta; Costa: luz o cortina; Cinturón: un objeto fuera de lugar).
3. **Ningún secreto exige una habilidad desconocida** ni un dato que el juego no haya enseñado antes.
4. **Recompensas por categoría**: Ecos (40 a 100), objeto de lore, reliquia, Nombre, atajo. Ninguna recompensa de secreto da más poder que una reliquia, y solo 7 de las 15 reliquias están en puzles o secretos.
5. **Nombres.** A lo sumo **5 de los 30** están tras un secreto (propuesta: 4). Con 28 alcanzables sin opcionales, el final Compartir (20) **nunca** depende de un secreto: perderlos todos deja 24 o 25. Un Nombre escondido no pasa de dificultad 2.
6. **Reliquia «Llave sin puerta»** (sugerencia del canon): revela los muros frágiles en un radio de 5 baldosas. Se vende (Cano), no se encuentra, para que el secreto siga siendo un descubrimiento.
7. El **mapa** marca con un punto discreto los secretos encontrados, para saber cuántos faltan (sin decir dónde).

### 4.3 Total propuesto por región

| Región | Frágil | Hondo | Camino oculto | Atajo | Sala oculta | Nombre | **Total** | Reliquias en puzles y secretos |
|---|---|---|---|---|---|---|---|---|
| El Último Umbral | 1 | 0 | 1 | 1 | 1 | 0 | **4** | Medalla del Umbral |
| El Cinturón Yermo | 2 | 2 | 2 | 1 | 1 | 1 | **9** | Cuenta del Rosario, Dedal de la Torre |
| El Archivo | 2 | 0 | 1 | 1 | 1 | 2 | **7** | Aguja del Escriba |
| Las Minas del Origen | 1 | 3 | 1 | 1 | 2 | 0 | **8** | Diente de la Mina |
| La Costa Retenida | 1 | 1 | 2 | 1 | 0 | 1 | **6** | Campanilla, Piedra blanca |
| La Herida | 1 | 1 | 0 | 1 | 0 | 0 | **3** | — |
| **Total** | 8 | 7 | 7 | 6 | 5 | 4 | **37** | 7 |

Cinco salas ocultas más tres salas de atajo suman las 8 "secretas y atajos" del presupuesto de salas. El último suelo hondo de la Herida es el que el canon dice que se rompe "hacia abajo, hacia el origen".

---

## 5. Estado y guardado

### 5.1 Reglas

1. **Un estado es permanente (P) si abre un camino, paga una recompensa o ya cuesta más de dos pasos.** Todo lo demás es temporal (T).
2. **T se reinicia al descansar o morir**, igual que los enemigos: los objetos temporales entran en el grupo `resettable` y responden a `reset()`. **No se reinicia al cambiar de sala**, para no castigar entrar y salir.
3. **Siempre se carga desde un Ancla**, así que T arranca de cero al cargar. No hace falta guardarlo.
4. **Una cadena de más de dos pasos se registra paso a paso**: el paso completado queda P.
5. La partida añade una clave `flags` (lista de textos) al JSON. Un guardado antiguo sin ella carga como si no hubiera marcas; no hace falta subir `FORMAT_VERSION`. Un id desconocido se ignora al cargar.

### 5.2 Ids estables

Formato `prefijo:sala.objeto`, en minúsculas y sin acentos. Prefijos: `p:` puzle, `s:` secreto, `d:` puerta o atajo, `i:` objeto o sello conseguido, `n:` Nombre (lo gestiona el diario). El id nace en el campo `links` de la escena de la sala (nombre explícito) y, si falta, de `sala.carácter_columna_fila` de la primera celda de la pieza; mover una pieza en el mapa cambia su id, y por eso los ids de cosas permanentes **se ponen siempre a mano**. La prueba de humo comprueba que no hay duplicados y que todos los ids de este documento aparecen en alguna escena.

### 5.3 Qué se guarda y qué se reinicia

| Elemento | Prefijo | Ejemplo | Se guarda | Reinicia al descansar o morir |
|---|---|---|---|---|
| Grieta rota (secreto) | `s:` | `s:cisterna.rosario` | Sí | No |
| Grieta rota (atajo) | `d:` | `d:fila_de_espera.tapiado` | Sí | No |
| Palanca (latch) | `d:` o `p:` | `p:torre_de_riego.rueda` | Sí | No |
| Palanca `toggle` | `p:` | desvío de la vagoneta | No | Sí |
| Placa de presión | `p:` | placas del Cruce del Pan | No | Sí (la reja que abre, si es P, se queda) |
| Reja o compuerta | según su marca | `d:ultimo_umbral.verja_patio` | La marca | Si depende de T, sí |
| Receptor (Sellos) | `p:` | `p:puerta_sin_muro.cera` | Sí | No |
| Sello conseguido | `i:` | `i:sello_cal` | Sí | No |
| Piedra de lectura | `p:` | `p:pasarela.ultima_carrera` | Sí (excepto las de 4 s) | La de 4 s, sí |
| Plataforma sobre carril | — | rueda, vagoneta | No (posición) | Sí |
| Derribo (puente o peso) | `p:` | `p:estanteria_nueve.puente` | Sí | No |
| Lámpara temporal | — | Galería de las Lámparas | No | Sí |
| Ciclo | — | marea, tinta | No | Reinicia fase |
| Combinación resuelta | `p:` | `p:sala_de_los_lacres.libro` | Sí | No |
| Final elegido | `p:` | `p:aun.final` | Sí | No |

### 5.4 Válvula de seguridad global

Una opción nueva en el menú de la pausa, **«Volver al Ancla»**, que lleva al último Ancla usado, reinicia lo temporal y no cuesta Ecos. Sirve de red de seguridad frente a cualquier atasco no previsto: el diseño no debe apoyarse en ella.


---

## 6. Orden de implementación, costes y pruebas

Coste: **S** = unas horas con su prueba; **M** = una sesión larga; **L** = varias sesiones.

| Fase | Mecánica | Coste | Depende de | Desbloquea (puzles) | Pruebas automáticas |
|---|---|---|---|---|---|
| 0 | `TextTileMap.marker_groups(char)` (piezas contiguas) | S | — | Todo lo demás | Un muro 2×3 de marcadores devuelve 1 pieza; dos separadas, 2 |
| 1 | M1 Estado de mundo + guardado | M | `world.gd` | Todos | Poner, leer, guardar, cargar, ignorar id desconocido, ids únicos, partida antigua sin `flags` |
| 2 | M3 Compuerta (sacada de `arena_gate`) | S | M1 | P02, P09, P14 | Se abre con su marca, "Y" de varias, no se cierra encima del jugador; la sala del Aljibe se comporta igual que antes |
| 3 | M4 Disparadores | S | M1, M3 | P02, P06, P09 | Palanca latch/toggle, placa con `hold_time`, botón con golpe, reinicio de T tras descansar |
| 4 | M2 Grieta frágil | S | M1 | P01, P05, P18, P38 | 3 golpes la rompen, 2 no, rota tras guardar y cargar |
| 5 | M7 Plataforma sobre carril | M | M3, M4 | P06, P07, P11, P22, P24, P34, P36 | Mueve y lleva al jugador, no aplasta (queda bloqueada y retrocede), espera en los extremos |
| 6 | M11 Ciclo | S | M1 | P12, P14, P24, P29, P30, P34, P36, P39, P40 | Periodo, fase y aviso respetados |
| 7 | M5 Receptor | S | M1 | P13, P35 | Con y sin marcas, `hold_time`, no consume |
| 8 | M12 Combinación | S | M1, M3 | P08, P16, P31 | Giro cíclico, solución exacta, resuelta se guarda |
| 9 | M10 Derribo | M | M4, M3 | P15, P28, P32 | Cae en la dirección del golpe, no cae sin hueco, mantiene una placa, 1 de daño debajo |
| 10 | M2 Grieta honda + Excavar | M | M2, habilidad Excavar | P04, P08, P11, P26, P27 | Rebota sin Excavar; con ella, 2 golpes; abajo+golpe rompe suelo |
| 11 | M9 Luz | M | M1 | P10, P23, P25, P31 | El revelado alterna visibilidad y colisión según la distancia; lámpara temporal se apaga a los 60 s |
| 12 | M8 Corriente | M | motor | P20, P29, P36 | Empuja ±180 px/s, reduce la caída, no saca al jugador de la sala |
| 13 | M6 Piedra de lectura y Nombrar | L | M5, diario de Nombres, habilidad Nombrar | P03, P12, P21, P25, P33, P37, P40, P41 | Muda sin Nombrar; atenta con ella; acierta, falla; sin callados; recorta a tres piedras |

Después de cada fase hay que **jugar** el puzle (CLAUDE.md lo exige). Cada puzle lleva además una **maniobra de referencia** en `tests/puzzle_plans.json` (el mecanismo de la Chimenea), que la prueba de humo repite en el motor.

**Pruebas globales.** (1) Ids únicos y presentes. (2) Guardado completo: resolver, guardar, cargar y comprobar. (3) Cada sala con puzle tiene una salida alcanzable desde cada estado intermedio (recorrido por baldosas con los saltos de la tabla 0.2). (4) Tras `reset()` lo T vuelve a su origen y lo P no se mueve.

**Orden de recorte** si hace falta bajar alcance (primero lo primero): M8 Corriente, M9 Luz, M10 Derribo, las cinco Piedras extra de Nombrar, M12 Combinación, P20 y P36, los secretos de camino oculto. Lo que nunca se recorta: M1 a M5 y las tres piedras del canon.

---

## 7. Preguntas abiertas y riesgos

### 7.1 Preguntas para el usuario

1. **Excavar.** Este documento supone que Excavar rompe muros con el golpe normal y suelos con abajo + atacar en el suelo. El canon pide un "ataque hacia abajo" como parte del Filo (`nucleo-jugable.md`), que hoy no existe. ¿Se prefiere implementar primero el ataque hacia abajo en el aire (con rebote) y que Excavar lo use, o dejarlo en el suelo?
2. **Diario de Nombres.** M6 y la Sala de Aún dependen de un sistema que aún no está construido (30 Nombres, sostenidos, callados). ¿Se construye antes de las Piedras?
3. **¿Se acepta que lo temporal se reinicie al descansar?** Es coherente con los enemigos, pero obliga a rehacer un puzle a medias. La regla de §5.1 (paso a paso) lo suaviza.
4. **Válvula «Volver al Ancla».** ¿Se añade, o los atascos forman parte del reto?
5. **Posición de la Puerta Sin Muro.** El canon no dice cómo se llega desde el Mirador. Este documento solo la diseña como sala y no fija el acceso.
6. **Incoherencia menor del canon.** `textos-del-juego.md` §4 pone la primera Página de Corvel en la cabaña del Umbral (con el Nombre Corvel) y `guion-maestro.md` §10.1 cuenta Corvel como Nombre del Archivo. P01 la deja en la cabaña; hay que decidir a qué región se suma.
7. **Una inscripción por sala.** Varios puzles (P05, P08, P16, P18) necesitan más de un texto por sala. Hace falta un marcador de inscripción con texto propio (ya anunciado en `textos-del-juego.md`).
8. **Nombrar extra.** Los cinco usos opcionales (P21, P25, P33, P37, P40) ¿se quieren o se quedan en el mínimo del guion?

### 7.2 Riesgos

| Riesgo | Efecto | Mitigación |
|---|---|---|
| Ids que cambian al mover piezas | Se pierden puzles resueltos | Ids a mano en `links`; prueba de humo de ids |
| El Derribo cae donde no debe | Atasco o puente inútil | Comprobar el hueco con `ShapeCast`; no cae si no hay sitio; solo en salas con salida alternativa |
