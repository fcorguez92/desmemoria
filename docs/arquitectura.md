# Arquitectura

Fuente de verdad sobre cómo está organizado el código y por qué. Pensado para
que una persona (o una IA) que llega de nuevo entienda las reglas antes de
tocar nada. Documentos relacionados: [`core/README.md`](../core/README.md)
(catálogo de componentes), [`decisiones.md`](decisiones.md) (el porqué de las
decisiones), [`estado.md`](estado.md) (qué está hecho).

## Las cuatro capas

| Capa | Carpeta | Qué contiene | Reutilizable |
|---|---|---|---|
| Motor | (Godot 4.7) | Renderizado, físicas, editor. No lo modificamos. | Sí, es externo |
| **core** | `core/` | Componentes y objetos de jugabilidad 2D genéricos | **Sí: es la base** |
| **game** | `game/` | Lo específico de este juego: Ecos, Eco de muerte, enemigos, niveles | No |
| Verificación | `tests/` | Prueba de humo automática de core + game | La parte de core, sí |

Lo que llamamos "el motor" del proyecto es `core/` sobre Godot: una base de
jugabilidad que un juego nuevo puede adoptar.

## Regla de dependencias (la más importante)

```
game/  ──usa──▶  core/  ──usa──▶  Godot
  ✗ core/ NUNCA referencia game/
```

- `core/` no importa, precarga ni nombra nada de `game/`.
- `core/` no contiene conceptos de este juego (Ecos, Anclas de Memoria, lore).
- Si `core/` necesita hablar con el juego, lo hace por **contratos** (métodos y
  grupos con nombre configurable, ver abajo) o por **señales**, nunca por
  referencias directas.
- Si dudas si algo va en `core/` o `game/`: si otro juego podría usarlo tal
  cual, es `core/`; si tiene reglas o nombres de este juego, es `game/`.

## Árbol de archivos

```
.
├── README.md                  Qué es, cómo ejecutar y probar
├── CLAUDE.md                  Instrucciones permanentes para la IA
├── project.godot              Configuración del proyecto y Mapa de entrada
├── core/                      BASE REUTILIZABLE
│   ├── README.md              Catálogo de componentes y contratos
│   ├── components/            Nodos con una responsabilidad cada uno
│   ├── objects/               Checkpoint, objeto de habilidad, generador de entidades, objeto rompible, mapa de baldosas desde texto
│   ├── ui/                    Controles de interfaz genéricos (barra segmentada, fila de iconos, lista de opciones, capa modal)
│   └── effects/               Efectos visuales autodestructivos (chispazo de impacto)
├── game/                      ESPECÍFICO DE ESTE JUEGO
│   ├── player/                Orquesta los componentes + Ecos + HUD
│   ├── enemy/                 Enemigo de prueba
│   ├── echo/                  Marcador de la última muerte
│   ├── memory_anchor/         Punto de control (usa core/objects/checkpoint.gd)
│   ├── environment/           Objetos de ambientación (urna rompible)
│   ├── ui/                    HUD, menú del Ancla y menú de pausa
│   └── levels/                Niveles: El Último Umbral (mapa de texto + baldosas) y el banco de pruebas
├── art/                       Fuentes del arte (no se cargan en el juego)
│   ├── palette.txt            La paleta: un carácter por color
│   └── source/                Sprites escritos como texto (*.sprite)
├── tools/
│   └── build_sprites.gd       Convierte los sprites de texto en hojas PNG
├── tests/
│   └── smoke_test.gd          Prueba de humo automática
└── docs/                      Diseño y decisiones (ver más abajo)
```

Un tipo de entidad = una carpeta con su `.tscn` y su `.gd` juntos. Cuando el
juego crezca, `game/` se subdivide por dominio (`game/enemies/`, `game/ui/`...);
no se crean carpetas vacías por adelantado.

## Patrón de componentes

Un cuerpo (`CharacterBody2D`) se compone de **nodos hijos**, cada uno con una
responsabilidad:

```
Player (CharacterBody2D)      ← game/player/player.gd: orquesta y añade lo propio del juego
├── PlatformerMotor           ← core: movimiento y salto
├── DashComponent             ← core: dash
├── HealthComponent           ← core: vida y curación
├── MeleeAttackComponent      ← core: ataque cuerpo a cuerpo
├── CameraLookComponent       ← core: mirar arriba/abajo
├── RespawnComponent          ← core: reaparición y último suelo
└── HitFlashComponent         ← core: parpadeo al recibir daño
```

Reglas del patrón:

1. **Los datos bajan, los eventos suben.** El dueño llama a métodos de sus
   componentes; los componentes avisan al dueño con **señales**
   (`HealthComponent.died`, `PlatformerMotor.facing_changed`).
2. **Los componentes no se conocen entre sí.** Quien los combina es el dueño
   (`player.gd`). Así se pueden usar por separado (el enemigo usa solo
   `HealthComponent` y `HitFlashComponent`).
3. **Configuración por variables exportadas**, no por constantes en el código.
   Incluye los nombres de acciones de entrada y de grupos objetivo.
4. **Referencias a otros nodos** mediante exports tipados (`@export var hitbox:
   Area2D`), no rutas escritas a mano con `get_node()`.

## Orden de `_physics_process` del jugador

El orden importa y por eso está explícito en `game/player/player.gd`:

1. `respawn.track_ground()` — anota el suelo pisado antes de mover nada.
2. `motor.step()` — gravedad, salto y movimiento lateral.
3. Ataque y curación (entrada del jugador).
4. `dash.step()` — **después** del movimiento, porque pisa la velocidad.
5. `move_and_slide()`.
6. Comprobación de caída al vacío.

## Contratos entre capas

| Contrato | Quién lo implementa | Quién lo usa |
|---|---|---|
| **Golpeable:** `take_hit(damage: int, from_direction: int, attacker: Node = null)` | Jugador, enemigos | `MeleeAttackComponent` |
| **Descansable:** `rest_at(position: Vector2)` + pertenecer al grupo `target_group` | Jugador | `Checkpoint` |
| **Reiniciable:** grupo `resettable` con método `reset()` | `EntitySpawner` | El jugador (`_reset_world()`) al morir y al descansar |
| **Aprendiz:** `unlock_ability(id: StringName)` + pertenecer al grupo `target_group` | Jugador (decide qué activa cada `id`) | `AbilityPickup` |
| **Grupo `player`** | El jugador se añade a sí mismo en `_ready()` | `PatrolChaseAI`, `MeleeAttackComponent` (vía `target_group`), `Checkpoint`, `AbilityPickup`, Eco |
| **Acciones de entrada:** `ui_left/right/up/down/accept` + `attack`, `dash`, `heal`, `interact`, `upgrade` | `project.godot` | `PlatformerMotor`, `DashComponent`, `CameraLookComponent`, `player.gd` |

Los enemigos golpean solo al grupo `player` (`MeleeAttackComponent.target_group`)
y no a "cualquier cosa con `take_hit`": así no se dañan entre sí. El ataque del
jugador no filtra, y puede golpear a cualquier cosa golpeable.

## Convenciones

- **Idioma:** identificadores de código en inglés; documentación, comentarios y
  textos visibles al jugador en español.
- **GDScript tipado** siempre que sea posible (`var x: int`, `-> void`).
- Nombres de archivo en `snake_case`; `class_name` en `PascalCase`, solo en
  `core/` (en `game/` los scripts son de una sola escena y no necesitan uno).
- Un componente por archivo, una responsabilidad por componente.
- Comentarios solo para el *porqué* no evidente; los `##` documentan variables
  exportadas y contratos públicos.
- Sin dependencias externas ni addons: solo Godot.

## Rendimiento

Hoy no hay cuellos de botella; estas prácticas evitan crearlos:

- Referencias a nodos cacheadas con `@onready`, sin `get_node()` por frame.
- Sin asignaciones ni creación de objetos por frame en los bucles de físicas.
- Los cálculos de movimiento viven en un único `_physics_process` (el del
  dueño); los componentes de comportamiento no procesan por su cuenta.
- Las colisiones usan capa/máscara por defecto porque hay pocas entidades. Al
  crecer el número de enemigos hay que definir capas de colisión (jugador,
  enemigos, entorno, áreas) — pendiente, no antes de que haga falta.
- Medir antes de optimizar: usar el Profiler de Godot cuando haya síntomas.

## Cómo añadir algo nuevo

**Una habilidad o mecánica genérica** (p. ej. doble salto):
1. Crear `core/components/<nombre>_component.gd` con `class_name`, exports
   documentados y un `step()` o señales, sin referencias a `game/`.
2. Añadirlo como hijo del jugador en `player.tscn` y llamarlo desde
   `player.gd` en el orden correcto.
3. Añadir su fila a `core/README.md` y su prueba a `tests/smoke_test.gd`.

**Algo específico del juego** (p. ej. un jefe): va en `game/`, reutiliza los
componentes de `core/` y no toca `core/` salvo que descubra que falta algo
genérico.

## Cómo reutilizar la base en otro proyecto

1. Crear un proyecto Godot 4 nuevo.
2. Copiar `core/`, `tests/smoke_test.gd` y (para partir de un ejemplo) las
   escenas de `game/player/` y `game/enemy/`.
3. Copiar la sección `[input]` de `project.godot` (acciones `attack`, `dash`,
   `heal`) o definir las acciones equivalentes y ajustar los exports `action_*`.
4. Escribir el `player.gd` del nuevo juego siguiendo `game/player/player.gd`:
   orquestar los componentes y añadir las reglas propias.
5. Adaptar `tests/smoke_test.gd` al nuevo nivel y ejecutarlo.

Cuando exista un segundo proyecto real se decidirá cómo distribuir `core/`
(plantilla de repositorio, submódulo de Git o addon de Godot). Se decide
entonces, con datos de qué se reutiliza de verdad, no antes.

## Verificación

```
godot --headless --path . --script res://tests/smoke_test.gd
```

Carga el nivel real, simula muertes, checkpoints, combate y dash, y sale con
código 0 (todo bien) o 1 (algo falla). **Debe pasar antes de dar por terminado
cualquier cambio en `core/` o en el ciclo jugable.** No sustituye a jugar: mide
que las reglas se cumplen, no que se sienta bien.

## Trampas conocidas de Godot

- Las exports que apuntan a nodos necesitan `node_paths` en el `.tscn` (ver
  `core/README.md`).
- Tras teletransportar un cuerpo (`global_position = ...`) el motor tarda un
  paso de físicas en reflejar el solapamiento con áreas; por eso el Eco espera
  un margen (`arm_delay`) antes de poder recogerse, y los tests esperan frames.
- Un `Area2D` hijo de un cuerpo se solapa con ese mismo cuerpo: hay que excluir
  al dueño al consultar (`MeleeAttackComponent` lo hace).
- Si un área de daño mide exactamente lo mismo que el cuerpo sólido de quien la
  lleva, el empuje físico puede impedir que llegue a solaparse con el objetivo:
  hacerla más grande que el cuerpo (el hitbox de ataque de los enemigos y del
  jugador sobresale por delante).
- Un `RayCast2D` hijo de un cuerpo ignora a su propio padre, pero sí detecta a
  cualquier otro cuerpo; el sondeo de bordes de `PatrolChaseAI` cuenta cualquier
  cosa sólida como suelo.
