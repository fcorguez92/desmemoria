# proyecto-souls2d (nombre provisional)

Acción-RPG 2D de vista lateral con exploración metroidvania y dificultad
"souls", en un mundo medieval oscuro y original. Hecho con **Godot 4.7** y
**GDScript**, sin dependencias externas.

El repositorio contiene dos cosas:

- **`core/`** — una base de jugabilidad 2D reutilizable (movimiento, vida,
  ataque, dash, puntos de control...) que puede llevarse a otros proyectos.
- **`game/`** — el juego concreto construido encima.

Estado actual: prototipo de bloques sin arte con el núcleo jugable validado.
Ver [`docs/estado.md`](docs/estado.md).

## Ejecutar

1. Instalar Godot 4.7 (`winget install GodotEngine.GodotEngine`).
2. Abrir esta carpeta como proyecto y pulsar **F5**.

Controles: flechas izq/dcha mover · Espacio saltar · flechas arriba/abajo mirar ·
Espacio en el aire: doble salto · junto a una pared, dirección hacia ella + Espacio: salto de pared · X atacar · V parry · Shift dash · H curarse · Z descansar en un Ancla y abrir su menú.

## Probar

```
godot --headless --path . --script res://tests/smoke_test.gd
```

Devuelve código 0 si todo pasa. Detalles en
[`docs/arquitectura.md`](docs/arquitectura.md#verificación).

## Documentación

| Documento | Contenido |
|---|---|
| [`docs/arquitectura.md`](docs/arquitectura.md) | Capas, reglas, convenciones, cómo reutilizar la base |
| [`core/README.md`](core/README.md) | Catálogo de componentes y contratos |
| [`docs/decisiones.md`](docs/decisiones.md) | Por qué se decidió cada cosa |
| [`docs/estado.md`](docs/estado.md) | Qué está hecho y qué falta |
| [`docs/nucleo-jugable.md`](docs/nucleo-jugable.md) | Diseño del núcleo jugable |
| [`docs/arte.md`](docs/arte.md) | Dirección artística, resolución, paleta y pipeline |
| [`docs/historia.md`](docs/historia.md) · [`docs/mundo.md`](docs/mundo.md) | Premisa, mitología y geografía |
| [`CLAUDE.md`](CLAUDE.md) | Instrucciones permanentes para trabajar con IA |
