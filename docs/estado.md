# Estado del proyecto (documento vivo)

Última actualización: Jacinto, el Último Segador, segundo jefe (rama `feat/jacinto`: K31 `AttackPicker`, `PhaseTracker`, `Spawner`, modo retorno del `Projectile`, anillo en `TelegraphZone`, `boss_base` mínimo, El Cercado Vacío y La Era); antes, primeras salas del Cinturón alto (El Surco Ciego, El Campo de los Ferrán y El Cruce del Pan, rama `feat/cinturon-alto-1`); antes, ciclo (`Cycle`) y plataforma sobre carril (`RailPlatform`) con un rincón de ejemplo en las Galerías Bajas (fase W3); antes, registro de Nombres y el Paño (K22 y K23: `game/names.gd`, pestaña de la pausa, "Callar un nombre" en el menú del Ancla); antes, pinchos laterales `{ }` (fase W4, con un pozo de ejemplo en la Torre de Riego); antes, compuerta, disparadores y muro frágil (fase W2, sin "Volver al Ancla"); antes, FlagStore y coleccionables `!` con id guardado (fase W1); antes, primer jefe (el Centinela Hueco), pinchos y el puzle del dash.

## Dónde estamos en la metodología

1. Descubrimiento y definición del concepto — hecho.
2. Investigación técnica — hecho (ver `decisiones.md`).
3. Elección del stack — hecho: Godot 4 + GDScript.
4. Diseño de la arquitectura — **hecho** (ver `arquitectura.md`): capas `core/`/`game/`, patrón de componentes, contratos.
5. Diseño del núcleo jugable — hecho (ver `nucleo-jugable.md`).
6. Prototipo jugable mínimo — hecho.
7. Validación del núcleo — hecho: movimiento, combate con enemigos y feedback, vida/muerte/Ecos, mejora del arma, puntos de control con curación y las tres habilidades de movimiento (dash, doble salto, salto de pared) que se consiguen en el mundo y abren caminos.
8. Vertical slice — **en marcha.**  Estilo de arte decidido (pixel art oscuro, ver `arte.md`) y Godot configurado para pixel art (864×486, escalado entero). Primer arte hecho (caminante con espada y cascarón con cuchillo, con animaciones básicas de movimiento y ataque, ver `arte.md`). El terreno de El Último Umbral ya existe (mapa de texto + baldosas, ver `vertical-slice.md`) y es la sala de inicio del mundo. Ya tiene fondo con parallax, objetos rompibles y narrativa ambiental (una inscripción legible, restos en la cabaña, marcas de arrastre; ver `docs/vertical-slice.md`), geometría de colores sin arte final todavía. El mundo ya crece por salas conectadas sin pantallas de carga (ver `mundo.md`): a El Último Umbral le siguen Las Terrazas Secas, La Cisterna, Las Galerías Bajas, El Aljibe (el jefe, que suelta el dash), La Chimenea y La Pasarela con su Mirador (el puzle del dash) y, aparte, La Torre de Riego (el doble salto). Minimapa en el HUD y mapa completo en la pausa, que solo muestran lo explorado (baldosa a baldosa alrededor del jugador). La partida se guarda sola (al cambiar de sala, descansar, reaparecer y salir) y el juego arranca en un menú principal (continuar, nuevo juego, opciones); al continuar se aparece en la última Ancla. El primer tramo ya llega a un **jefe** que suelta el dash (El Aljibe, tras las Galerías Bajas; ver `jefes.md`), con un **puzle de plataformas** exigente con el dash (La Chimenea y La Pasarela de los Mensajeros) hasta un mirador con Ancla al aire libre. Falta jugarlo para ajustar el recorrido, el jefe y el puzle. **W1 hecha:** el mundo guarda marcas (`flags`) y coleccionables (`fragments`, `bags`) como claves opcionales de la partida; hay un fragmento de vida de ejemplo en La Cisterna (la plataforma alta junto al zarzal, fuera del camino). **K10, K11 y K12 hechas** (rama `feat/vida-y-economia`): 4 fragmentos de vida dan +1 de vida máxima y curan del todo (`Stats.life_max`, con el hueco del Trapo a 0); el árbol tiene los precios finales de `nucleo-jugable.md` y la mejora nueva Aliento (1.210 de 1.800 Ecos; Brasa, Castigo, Paso fantasma y Voz quedan como paquetes aparte); las Bolsas de Rastro dan Ecos según la región de la sala (`game/economy.gd`) y hay una prueba informativa del presupuesto de Ecos. Falta jugarlo para ajustar cifras. **W2 hecha** (salvo "Volver al Ancla", otro paquete): `Gate` (la reja del jefe de `core/`, ahora también abre por marcas, con "Y", sin cerrarse encima de nadie), `Trigger` (palanca latch o toggle, placa con `hold_time`, botón) y `BreakableWall` (muro frágil de 3 golpes que se queda roto al guardar y cargar). `room.gd` los crea por pieza de marcadores (`=` `+` `z` `_` `*` `#`) y las marcas permanentes se nombran en el campo `links` de la escena. Ejemplo para jugar: en La Cisterna, la palanca (columna 20, suelo) abre para siempre la reja del rincón izquierdo. **W4 hecha:** `room.gd` pone los pinchos laterales `{` `}` (el mismo `Hazard` girado, con una tira fina pegada a la pared); ejemplo opcional en La Torre de Riego: un pozo de 6 de ancho que se sube con Agarre entre dos tiras de pinchos hasta un fragmento de vida (`torre_de_riego.c50f09`). Falta el arte definitivo, los vestidos de compuerta (tablones, piedra, cal, puente, tinta) y el aviso de efecto fuera de pantalla. **K22 y K23 hechas:** `game/names.gd` guarda los 30 Nombres (leído / callado) en la clave opcional `names` de la partida; las inscripciones con `name_id` (y la `note_name_id` de una sala) lo registran al leerlas y avisan "Nombre: X. Lo sostienes."; la pausa tiene "Nombres que sostienes" por región, sin desvelar lo no leído; el menú del Ancla ofrece "Callar un nombre" (confirmación con "No" por defecto, +50 Ecos). Ejemplo para jugar: la placa de Tomasa, a la izquierda del Ancla de La Torre de Riego (arriba a la derecha). Falta el Paño como objeto (hoy la entrada aparece en cuanto se sostiene un Nombre), pronunciar al descansar, Nombrar y "Decir los nombres".

## Qué existe ahora mismo

```
core/         Base reutilizable: 17 componentes + 16 objetos + 3 efectos + piezas de interfaz + guardado y marcas del mundo (ver core/README.md)
game/         player, enemy, boss (el Centinela Hueco, Jacinto, su base común y sus salas), echo, memory_anchor, ability_pickup, pickups (coleccionables `!`), environment, levels (el mundo y sus 13 salas + banco de pruebas)
tests/        smoke_test.gd — comprobaciones todas en verde (incluye las del Cinturón alto)
docs/         Diseño, decisiones, arquitectura y estado
```

Los personajes ya usan sprites de píxeles; el entorno, los objetos siguen siendo geometría de colores planos (`Polygon2D`) sin arte final: el objetivo
de esta fase era validar cómo se siente, no cómo se ve.

Base de arte (H0-01 a H0-03, rama `art/base-pipeline`): paleta de 31 colores (`z` reservado); primitivas de rasterizado en `tools/lib/raster.js` (los rigs regeneran `art/source/` idéntico byte a byte); lienzo del Caminante a 112×96, con `Sprite2D.offset` (0, -24) y el Caminante del título subido 32 px para que los pies no se muevan. `node tools/comparar_lienzo.js <antiguo.sprite> <nuevo.sprite>` comprueba que los 58 fotogramas nuevos son idénticos a los antiguos desplazados.

Ataques verticales (K06, K07, K08, rama `feat/ataque-arriba-y-abajo`): Arriba + X golpea sobre la cabeza (36×44) y Abajo + X en el aire golpea bajo los pies (30×36) con rebote de ~126 px si el blanco está en el grupo `pogoable` (enemigos y jefe); el rebote no recarga dash ni doble salto y los pinchos no rebotan. `MeleeAttackComponent` gana golpe direccional; el Caminante gana `attack_up` y `attack_down` (hoja de 10 filas). Falta jugarlo a mano para afinar la sensación.

## Cinturón alto (1): Surco Ciego, Campo de los Ferrán y Cruce del Pan

**Elección (criterio):** tras la Torre de Riego, el mapa macro (`01-mapa-macro.md` §4) sigue por el eje CIN-08 Surco Ciego → CIN-10 Campo de los Ferrán → CIN-11 Cruce del Pan. Se eligen estas tres, consecutivas y en la misma franja (y -36 a 0), porque: (1) la salida ya existe (la cornisa de la Torre, retoque R3, que aquí se abre en las filas 1-6); (2) piden solo lo que el jugador ya tiene en ese punto del guion (dash del Aljibe y doble salto de la Torre; el Agarre llega con Jacinto en La Era, que va después); (3) incluyen el Ancla A10 del Cruce del Pan y el Nombre de Eulalia Ferrán; y (4) la Casa Varga (CIN-09) y la Acequia (CIN-12) quedan para la siguiente tanda como ramas hacia arriba. Quedan cerrados a propósito: el norte del Surco (Casa Varga), el norte del Campo y del Cruce (Acequia, Segunda Torre) y el este del Cruce (puerta de un solo sentido a la Chimenea alta, B3/S3).

**Desviaciones del macro:** anchuras 64/66/54 en lugar de 72/72/40 (la regla de 54 de ancho mínimo, C12, y el Cruce no cabe en 40 sin ser "estrecha"; se coloca en x 330 para que acabe pegado a la Chimenea en x 384). Sin mojones giratorios (M12), sin Excavar ni luz (M9): P08 y P10 tienen versión base (ver `puzles.md`). Techo cerrado y sin cielo, como la Torre. Arte provisional con las baldosas existentes.

**Nuevo en la base:** `room.gd` aplica `piece_params` también a palancas, placas y botones (p. ej. `hold_time`), y C17 lo valida para `_`. `tools/maniobras_puzle.js` admite tramos (`legs`) con doble salto y la prueba de humo repite el segundo salto; hay 6 maniobras nuevas en `tests/puzzle_plans.json`. Cuatro pruebas nuevas (conexión caminando, nicho y repisa del Surco, palanca y cercado del Campo, placas y nicho del Cruce).

**A jugar a mano:** el ritmo del recorrido; si el doble salto a la repisa del Surco y el de la repisa alta del Cruce se sienten justos; la ventana de 6 s de las placas yendo de la A a la C; que el cercado del Campo se lea (reja y palanca visibles) y la dificultad del coloso con los cascarones; si las salas anchas piden más enemigos; y que el nicho de la Bolsa se descubra sin pista.

## Piezas de enemigos (1): DORMANT, vuelo y aviso de zona (K30, K28, K29)

Rama `feat/piezas-enemigos-1`, tres piezas en este orden y un commit por pieza. **K30:** estado DORMANT/WAKING en `PatrolChaseAI` (`starts_dormant`, `wake_radius`, `wake_time`, señal `woke_up`) y el **Espantapájaros** (vida 4, 3 Ecos, marcador `6`, ejemplo en el Surco Ciego). **K28:** `FlyAI` (`core/components/fly_ai.gd`: merodeo, colocación sobre el objetivo con oscilación, aviso y picado, pausa) y el **Cuervo de Rastrojo** (vida 2, 2 Ecos, marcador `5`, ejemplo en el Cruce del Pan); `Enemy` admite voladores (`flying`, `AttackKind.DIVE`). **K29:** `TelegraphZone` (`core/objects/telegraph_zone.gd`), marca amarilla o roja con bandas que golpea al terminar el aviso; solo la pieza y su prueba (sin usuario aún). Seis pruebas de humo nuevas. Arte provisional de ambos enemigos desde `tools/rig_enemigos.js` (el cuervo, con las primitivas de `tools/lib/raster.js`).

**Efectos en lo existente:** la prueba de las maniobras de referencia limpia los enemigos del Cruce del Pan (el cuervo las estorbaría); los marcadores `5` y `6` de `docs/vertical-slice.md` ya tienen ocupante por defecto (el `enemy_set` por sala no hace falta hasta que haya un segundo ocupante).

**A jugar a mano:** que el Espantapájaros se lea como falso y la emboscada del Surco (leer la inscripción lo despierta) sea justa; el picado del Cuervo (si 0,45 s de aviso y los 1,2 s de pausa se sienten bien, y que el ataque hacia arriba y el pogo lo alcancen cómodamente); que el cuervo del Cruce del Pan no moleste en las placas de 6 s.

## Jacinto, el Último Segador (K31): segundo jefe, La Era y el Cercado Vacío

Rama `feat/jacinto`. **Piezas de base (K31):** `AttackPicker` (bolsa barajada, sesgo por distancia, equidad y límites), `PhaseTracker` (vida en tramos que no se saltan), `Spawner` con tope de vivas, **modo retorno** del `Projectile` (boomerang) y **anillo** en `TelegraphZone` (`inner_radius`: el hueco seguro pegado al atacante). Del Centinela solo se extrajo a `game/boss/boss_base.gd` lo que usan los dos (buscar al jugador, temblor, mirar suelo, traspasarlo al caer encima); el Centinela sigue igual y pasa todas sus pruebas.

**Jacinto** (`game/boss/jacinto.gd`, 36 de vida en fases 24/12/0, sin armadura, 60 Ecos): siega baja, vuelta amplia (anillo de 130 con hueco de 45), paso de segador, hoz lanzada (boomerang; manos vacías = doble daño), trepa y picado (sombra roja, solo si el jugador huye), llamada (espantapájaros, tope 2) y las tres vueltas del remate (la tercera, una franja roja a ras de suelo). Avisos amarillos (parables) y rojos (con bandas), sincronía con el fotograma de impacto, transiciones de 2 s invulnerable, reinicio sin restos y victoria guardada en `bosses`. Recompensa: el **salto de pared** (por fin colocado en el mundo), la hoz clavada con el Nombre de Jacinto Ferrán y la tablilla de Eloy en la arena. Detalle y números en `jefes.md`.

**Salas:** **El Cercado Vacío** (CIN-17, con el Ancla A12) se alcanza por un pozo abierto en el techo del Cruce del Pan (atajo provisional: se comprimen CIN-13 y CIN-14); la puerta este da a **La Era** (CIN-18), la arena. Registradas en `tests/world_manifest.json` (`node tools/verifica_mundo.js` en verde, 13 salas). Arte provisional de Jacinto desde `tools/rig_jacinto.js` (17 animaciones, unos 15 MB de textura), voz y cinco sonidos nuevos desde `tools/sonidos.js`. Pruebas de humo nuevas: el selector, las fases, el `Spawner`, el boomerang, el anillo, el camino hasta La Era (y el pozo del Cruce con doble salto), la sala y las rejas, las fases y la recompensa, cada ataque (aviso, color, daño, parry, sincronía), la hoz, la trepa, la llamada, las tres vueltas, el reinicio y 60 s de pelea al azar.

**A jugar a mano:** la pelea entera (diseño: 4-6 intentos, pelea limpia de 2:30 a 3:30); si el anillo amarillo de la vuelta se entiende y el hueco central se encuentra en movimiento; si la sombra roja del picado da tiempo; si la franja roja de la tercera vuelta se salta cómoda; que el Cercado, el pozo y el tramo del Ancla a la arena (menos de 10 s) se sientan bien; el final (camina al muro, el trigo) y la lectura de su arte; y la sensación del salto de pared recién conseguido (las salas de después aún no lo piden). Falta música de jefe, la salida este de la arena y las salas CIN-13/14.

## Controles actuales

- Flecha izq/dcha: moverse · Espacio: saltar · Flecha arriba/abajo: mirar · Arriba + X: atacar hacia arriba · Abajo + X en el aire: ataque hacia abajo con rebote (pogo) sobre enemigos · Abajo + Espacio sobre un tablón: bajar atravesándolo
- En el aire, Espacio otra vez: doble salto (tras conseguirlo) · Junto a una pared, mantén la dirección hacia ella para agarrarte y pulsa Espacio para saltar de ella (tras conseguirlo)
- Esc: pausa (continuar, mapa, personaje, controles, menú principal, salir) · X: atacar · V: parry · Shift izquierdo: dash · H: curarse (si quedan cargas y no estás a vida completa) · Z: descansar en un Ancla y abrir su menú (Intro o Z eligen, Esc cierra; en todos los menús Z vale como aceptar)

Con mando, al estilo de Hollow Knight. Los botones van por **posición**, así que
el mismo botón hace lo mismo en todos los mandos (en el de Nintendo las letras
están cambiadas respecto a Xbox):

| Acción | Posición | Xbox | PlayStation | Nintendo |
|---|---|---|---|---|
| Moverse / mirar | palanca izquierda o cruceta | | | |
| Saltar · aceptar en menús | abajo | A | Cruz | B |
| Atacar | izquierda | X | Cuadrado | Y |
| Curarse · volver en menús | derecha | B | Círculo | A |
| Ancla (descansar, interactuar) | arriba | Y | Triángulo | X |
| Dash | gatillo derecho | RT | R2 | ZR |
| Guardia (parry) | gatillo izquierdo | LT | L2 | ZL |
| Pausa | Start | Menú | Options | + |

## Qué falta del núcleo jugable

- Reinicio de enemigos por zonas: hoy al morir o descansar reaparecen todos los
  del mundo; cuando el mundo crezca, limitarlo a la región del Ancla.
- Golpes no parables: `Enemy.parryable = false` hace que el golpe atraviese la guardia y el aviso sea rojo (`TELEGRAPH_RED`) en vez de amarillo. Falta la marca de suelo y usarlo en algún ataque real.
- Jugar el jefe y el puzle a mano y ajustar (ver la lista de "cosas a vigilar" de `jefes.md`).
- El salto de pared ya está colocado en el mundo (lo da Jacinto); falta alguna sala que lo pida y seguir ampliando el Cinturón Yermo (La Cuesta del Segador, CIN-13/14).
- Viaje entre Anclas, cuando el mundo sea lo bastante grande para que haga falta.
- Más usos para los Ecos aparte del Filo, y si el Filo mejora también alcance o velocidad (hoy solo sube el daño).
- Ajustar el ritmo del combate jugando (tiempos de aviso y recuperación, retroceso) y más tipos de enemigo (a distancia, voladores) y jefes.
- Estadísticas del personaje más allá de la vida.
- Capas de colisión (jugador, enemigos, entorno) cuando crezca el número de entidades.
- Cuando existan sus mecánicas, más entradas en el menú del Ancla (tienda, viaje entre Anclas, otras mejoras) y el inventario.

## Cómo probar

- Jugar: abrir el proyecto en Godot 4.7 y pulsar F5.
- Verificar reglas: `godot --headless --path . --script res://tests/smoke_test.gd`
  (código 0 = todo bien). Ver `arquitectura.md#verificación`.

## Rendimiento

Medido con ventana real (RTX 2060, cuando el mundo tenía 4 salas, ~285 nodos, 32-42 draw calls): 480-680 FPS
sin vsync con Forward+, así que en un equipo normal el juego va con mucho margen sobre
60 FPS. Aun así se ha recortado trabajo evitable: el minimapa solo se redibuja al cambiar
de baldosa, el animador solo toca el sprite cuando cambia el fotograma, solo procesan la
sala actual y sus vecinas (`World._activate_nearby_rooms`) y el autoguardado se difiere
un fotograma al cambiar de sala. **No se ha cambiado de renderizador** (Compatibility fue
más lento). Pendiente de medir en un equipo flojo (portátil con gráfica integrada) con
un script de medición; si hay tirones allí, mirar vsync y la interpolación de físicas.


## Frasco rediseñado (K03-K05)

- Hecho: el frasco cura 3 vidas con un sorbo de 0,70 s (`HealthComponent.begin_heal()`); un golpe, saltar o hacer dash lo cancelan sin gastar carga; no se bebe con vida llena ni se ataca o para durante el sorbo. Topes absolutos en `game/player/stats.gd` (vida 13, frascos 5, cura 1-5, sorbo >= 0,30 s). El HUD tiñe los frascos y llena una barrita durante el sorbo.
- Pendiente: animación de beber, Aliento (cura +1) y Aguja del Escriba (sorbo más corto) en el árbol/reliquias, y jugarlo para calibrar la sensación.
