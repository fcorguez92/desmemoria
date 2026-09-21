# Estado del proyecto (documento vivo)

Última actualización: base reutilizable separada en capas y verificada con pruebas automáticas.

## Dónde estamos en la metodología

1. Descubrimiento y definición del concepto — hecho.
2. Investigación técnica — hecho (ver `decisiones.md`).
3. Elección del stack — hecho: Godot 4 + GDScript.
4. Diseño de la arquitectura — **hecho** (ver `arquitectura.md`): capas `core/`/`game/`, patrón de componentes, contratos.
5. Diseño del núcleo jugable — hecho (ver `nucleo-jugable.md`).
6. Prototipo jugable mínimo — hecho.
7. Validación del núcleo — hecho: movimiento, combate con enemigos y feedback, vida/muerte/Ecos, mejora del arma, puntos de control con curación y las tres habilidades de movimiento (dash, doble salto, salto de pared) que se consiguen en el mundo y abren caminos.
8. Vertical slice — **en marcha.**  Estilo de arte decidido (pixel art oscuro, ver `arte.md`) y Godot configurado para pixel art (864×486, escalado entero). Primer arte hecho (caminante con espada y cascarón con cuchillo, con animaciones básicas de movimiento y ataque, ver `arte.md`). El terreno de El Último Umbral ya existe (mapa de texto + baldosas, ver `vertical-slice.md`) y es el nivel principal. Falta: fondos y atmósfera, objetos y narrativa ambiental, y jugarlo para ajustar el recorrido.

## Qué existe ahora mismo

```
core/         Base reutilizable: 14 componentes + 4 objetos + 1 efecto (ver core/README.md)
game/         player, enemy (de prueba), echo, memory_anchor, ability_pickup, levels (El Último Umbral + banco de pruebas)
tests/        smoke_test.gd — 116 comprobaciones, todas en verde
docs/         Diseño, decisiones, arquitectura y estado
```

Los personajes ya usan sprites de píxeles; el entorno, los objetos y los Ecos siguen siendo geometría de colores planos (`Polygon2D`) sin arte final: el objetivo
de esta fase era validar cómo se siente, no cómo se ve.

## Controles actuales

- Flecha izq/dcha: moverse · Espacio: saltar · Flecha arriba/abajo: mirar
- En el aire, Espacio otra vez: doble salto (tras conseguirlo) · Junto a una pared, mantén la dirección hacia ella para agarrarte y pulsa Espacio para saltar de ella (tras conseguirlo)
- X: atacar · V: parry · Shift izquierdo: dash · H: curarse (si quedan cargas y no estás a vida completa) · Z: interactuar (descansar en un Ancla) · C: mejorar el Filo (en un Ancla)

## Qué falta del núcleo jugable

- Reinicio de enemigos por zonas: hoy al morir o descansar reaparecen todos los
  del nivel; cuando haya varias zonas, limitarlo a la zona del Ancla.
- Más usos para los Ecos aparte del Filo, y si el Filo mejora también alcance o velocidad (hoy solo sube el daño).
- Ajustar el ritmo del combate jugando (tiempos de aviso y recuperación, retroceso) y más tipos de enemigo (a distancia, voladores) y jefes.
- Estadísticas del personaje más allá de la vida.
- Capas de colisión (jugador, enemigos, entorno) cuando crezca el número de entidades.
- Sustituir el HUD de texto plano por uno real.

## Cómo probar

- Jugar: abrir el proyecto en Godot 4.7 y pulsar F5.
- Verificar reglas: `godot --headless --path . --script res://tests/smoke_test.gd`
  (código 0 = todo bien). Ver `arquitectura.md#verificación`.
