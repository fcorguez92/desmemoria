# Estado del proyecto (documento vivo)

Última actualización: entorno recargado (decorado, cajas y barriles, fondo en capas).

## Dónde estamos en la metodología

1. Descubrimiento y definición del concepto — hecho.
2. Investigación técnica — hecho (ver `decisiones.md`).
3. Elección del stack — hecho: Godot 4 + GDScript.
4. Diseño de la arquitectura — **hecho** (ver `arquitectura.md`): capas `core/`/`game/`, patrón de componentes, contratos.
5. Diseño del núcleo jugable — hecho (ver `nucleo-jugable.md`).
6. Prototipo jugable mínimo — hecho.
7. Validación del núcleo — hecho: movimiento, combate con enemigos y feedback, vida/muerte/Ecos, mejora del arma, puntos de control con curación y las tres habilidades de movimiento (dash, doble salto, salto de pared) que se consiguen en el mundo y abren caminos.
8. Vertical slice — **en marcha.**  Estilo de arte decidido (pixel art oscuro, ver `arte.md`) y Godot configurado para pixel art (864×486, escalado entero). Primer arte hecho (caminante con espada y cascarón con cuchillo, con animaciones básicas de movimiento y ataque, ver `arte.md`). El terreno de El Último Umbral ya existe (mapa de texto + baldosas, ver `vertical-slice.md`) y es la sala de inicio del mundo. Ya tiene fondo con parallax, objetos rompibles y narrativa ambiental (una inscripción legible, restos en la cabaña, marcas de arrastre; ver `docs/vertical-slice.md`), geometría de colores sin arte final todavía. El mundo ya crece por salas conectadas sin pantallas de carga (ver `mundo.md`): a El Último Umbral le siguen Las Terrazas Secas, La Cisterna y La Torre de Riego, donde se consiguen el dash y el doble salto. Minimapa en el HUD y mapa completo en la pausa, que solo muestran lo explorado (baldosa a baldosa alrededor del jugador). La partida se guarda sola (al cambiar de sala, descansar, reaparecer y salir) y el juego arranca en un menú principal (continuar, nuevo juego, opciones); al continuar se aparece en la última Ancla. Falta jugarlo para ajustar el recorrido.

## Qué existe ahora mismo

```
core/         Base reutilizable: 14 componentes + 6 objetos + 2 efectos + 5 piezas de interfaz + guardado (ver core/README.md)
game/         player, enemy (de prueba), echo, memory_anchor, ability_pickup, levels (el mundo y sus 4 salas + banco de pruebas)
tests/        smoke_test.gd — 317 comprobaciones, todas en verde
docs/         Diseño, decisiones, arquitectura y estado
```

Los personajes ya usan sprites de píxeles; el entorno, los objetos siguen siendo geometría de colores planos (`Polygon2D`) sin arte final: el objetivo
de esta fase era validar cómo se siente, no cómo se ve.

## Controles actuales

- Flecha izq/dcha: moverse · Espacio: saltar · Flecha arriba/abajo: mirar · Abajo + Espacio sobre un tablón: bajar atravesándolo
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

Medido con ventana real (RTX 2060, 4 salas, ~285 nodos, 32-42 draw calls): 480-680 FPS
sin vsync con Forward+, así que en un equipo normal el juego va con mucho margen sobre
60 FPS. Aun así se ha recortado trabajo evitable: el minimapa solo se redibuja al cambiar
de baldosa, el animador solo toca el sprite cuando cambia el fotograma, solo procesan la
sala actual y sus vecinas (`World._activate_nearby_rooms`) y el autoguardado se difiere
un fotograma al cambiar de sala. **No se ha cambiado de renderizador** (Compatibility fue
más lento). Pendiente de medir en un equipo flojo (portátil con gráfica integrada) con
un script de medición; si hay tirones allí, mirar vsync y la interpolación de físicas.
