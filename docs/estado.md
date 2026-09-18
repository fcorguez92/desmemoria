# Estado del proyecto (documento vivo)

Última actualización: validación del núcleo jugable completa.

## Dónde estamos en la metodología

1. Descubrimiento y definición del concepto — hecho.
2. Investigación técnica — hecho (ver `docs/decisiones.md`).
3. Elección del stack — hecho: Godot 4 + GDScript.
4. Diseño de la arquitectura — pendiente de formalizar (ver "Próximos pasos técnicos").
5. Diseño del núcleo jugable — hecho (ver `docs/nucleo-jugable.md`).
6. Prototipo jugable mínimo — hecho.
7. **Validación del núcleo — hecho.** Los cuatro pilares se han probado en un nivel de bloques sin arte y se sienten bien: movimiento (coyote time + jump buffering), combate (arma con alcance, enemigos de prueba), vida/muerte/Ecos (con recuperación en el punto de muerte), y una habilidad de progresión (dash) que abre una zona antes inaccesible.
8. Vertical slice — siguiente fase, todavía no empezada.

## Qué existe ahora mismo en el proyecto

- `scenes/player/` — personaje jugable: movimiento, ataque, vida, Ecos, dash, cámara con "mirar arriba/abajo".
- `scenes/enemy/` — enemigo de prueba (sin IA, referencia de alcance de ataque).
- `scenes/echo/` — el Eco que marca el último punto de muerte (pickup pasivo).
- `scenes/test_level/` — nivel de bloques de prueba, sin arte, con huecos y una zona solo cruzable con dash.

Todo es geometría de colores planos (`Polygon2D`), sin arte final. Es intencionado: el objetivo de esta fase era validar que el juego se siente bien, no cómo se ve.

## Controles actuales

- Flecha izq/dcha: moverse.
- Espacio: saltar.
- Flecha arriba/abajo: mirar (desplaza la cámara, no mueve al personaje).
- X: atacar.
- Shift izquierdo: dash.

## Qué falta del núcleo jugable (ver `docs/nucleo-jugable.md`, sección "pendiente")

- Anclas de Memoria (puntos de control: guardado, curación, reinicio de enemigos).
- Objeto de curación de usos limitados.
- Tiers de mejora del arma y qué se compra con Ecos.
- Resto de habilidades de progresión (trepar/pared, doble salto).
- Sistema de estadísticas del personaje más allá de vida.

## Próximos pasos técnicos (arquitectura, sin decidir aún)

Por ahora todo el estado del jugador vive en `player.gd`, que ya es bastante grande. Mientras el prototipo era pequeño esto era lo más simple; si seguimos añadiendo sistemas (Anclas, mejora de armas, más habilidades), conviene revisar si separar responsabilidades en nodos/scripts propios (por ejemplo, un componente de salud, uno de habilidades) sigue mereciendo la pena o sería sobreingeniería todavía. Se decidirá cuando el archivo empiece a doler de verdad, no antes.

## Cómo probar el prototipo

Abrir el proyecto con Godot 4.7 (`godot_v4.7.2-stable`, instalado vía winget) y pulsar F5 desde el editor. Escena principal: `scenes/test_level/test_level.tscn`.
