# Estado del proyecto (documento vivo)

Última actualización: base reutilizable separada en capas y verificada con pruebas automáticas.

## Dónde estamos en la metodología

1. Descubrimiento y definición del concepto — hecho.
2. Investigación técnica — hecho (ver `decisiones.md`).
3. Elección del stack — hecho: Godot 4 + GDScript.
4. Diseño de la arquitectura — **hecho** (ver `arquitectura.md`): capas `core/`/`game/`, patrón de componentes, contratos.
5. Diseño del núcleo jugable — hecho (ver `nucleo-jugable.md`).
6. Prototipo jugable mínimo — hecho.
7. Validación del núcleo — hecho: movimiento, combate, vida/muerte/Ecos, dash que abre camino, puntos de control con curación.
8. Vertical slice — siguiente fase, todavía no empezada.

## Qué existe ahora mismo

```
core/         Base reutilizable: 8 componentes + 3 objetos (ver core/README.md)
game/         player, enemy (de prueba), echo, memory_anchor, levels/test_level
tests/        smoke_test.gd — 55 comprobaciones, todas en verde
docs/         Diseño, decisiones, arquitectura y estado
```

Todo es geometría de colores planos (`Polygon2D`), sin arte final: el objetivo
de esta fase era validar cómo se siente, no cómo se ve.

## Controles actuales

- Flecha izq/dcha: moverse · Espacio: saltar · Flecha arriba/abajo: mirar
- X: atacar · Shift izquierdo: dash · H: curarse (si quedan cargas y no estás a vida completa) · Z: interactuar (descansar en un Ancla) · C: mejorar el Filo (en un Ancla)

## Qué falta del núcleo jugable

- Reinicio de enemigos por zonas: hoy al morir o descansar reaparecen todos los
  del nivel; cuando haya varias zonas, limitarlo a la zona del Ancla.
- Más usos para los Ecos aparte del Filo, y si el Filo mejora también alcance o velocidad (hoy solo sube el daño).
- Resto de habilidades de progresión (trepar pared, doble salto) — ahora se
  añaden como componentes nuevos en `core/components/` (ver `arquitectura.md`).
- Estadísticas del personaje más allá de la vida.
- Capas de colisión (jugador, enemigos, entorno) cuando crezca el número de entidades.
- Sustituir el HUD de texto plano por uno real.

## Cómo probar

- Jugar: abrir el proyecto en Godot 4.7 y pulsar F5.
- Verificar reglas: `godot --headless --path . --script res://tests/smoke_test.gd`
  (código 0 = todo bien). Ver `arquitectura.md#verificación`.
