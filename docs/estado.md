# Estado del proyecto (documento vivo)

Última actualización: ciclo (`Cycle`) y plataforma sobre carril (`RailPlatform`) con un rincón de ejemplo en las Galerías Bajas (fase W3); antes, registro de Nombres y el Paño (K22 y K23: `game/names.gd`, pestaña de la pausa, "Callar un nombre" en el menú del Ancla); antes, pinchos laterales `{ }` (fase W4, con un pozo de ejemplo en la Torre de Riego); antes, compuerta, disparadores y muro frágil (fase W2, sin "Volver al Ancla"); antes, FlagStore y coleccionables `!` con id guardado (fase W1); antes, primer jefe (el Centinela Hueco), pinchos y el puzle del dash.

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
core/         Base reutilizable: 14 componentes + 12 objetos + 2 efectos + 5 piezas de interfaz + guardado y marcas del mundo (ver core/README.md)
game/         player, enemy, boss (el Centinela Hueco y su sala), echo, memory_anchor, ability_pickup, pickups (coleccionables `!`), environment, levels (el mundo y sus 8 salas + banco de pruebas)
tests/        smoke_test.gd — 547 comprobaciones, todas en verde
docs/         Diseño, decisiones, arquitectura y estado
```

Los personajes ya usan sprites de píxeles; el entorno, los objetos siguen siendo geometría de colores planos (`Polygon2D`) sin arte final: el objetivo
de esta fase era validar cómo se siente, no cómo se ve.

Base de arte (H0-01 a H0-03, rama `art/base-pipeline`): paleta de 31 colores (`z` reservado); primitivas de rasterizado en `tools/lib/raster.js` (los rigs regeneran `art/source/` idéntico byte a byte); lienzo del Caminante a 112×96, con `Sprite2D.offset` (0, -24) y el Caminante del título subido 32 px para que los pies no se muevan. `node tools/comparar_lienzo.js <antiguo.sprite> <nuevo.sprite>` comprueba que los 58 fotogramas nuevos son idénticos a los antiguos desplazados.

Ataques verticales (K06, K07, K08, rama `feat/ataque-arriba-y-abajo`): Arriba + X golpea sobre la cabeza (36×44) y Abajo + X en el aire golpea bajo los pies (30×36) con rebote de ~126 px si el blanco está en el grupo `pogoable` (enemigos y jefe); el rebote no recarga dash ni doble salto y los pinchos no rebotan. `MeleeAttackComponent` gana golpe direccional; el Caminante gana `attack_up` y `attack_down` (hoja de 10 filas). Falta jugarlo a mano para afinar la sensación.

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
- Colocar el salto de pared en el mundo (hoy solo está en el banco de pruebas) y
  seguir ampliando el Cinturón Yermo desde la Torre de Riego.
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
