# core/ — base reutilizable

Componentes y objetos de jugabilidad 2D genéricos. **No saben nada de este
juego**: ninguna referencia a `game/`, ni a Ecos, ni a lore. Léase junto con
[`docs/arquitectura.md`](../docs/arquitectura.md), que explica las reglas y
cómo integrarlo en otro proyecto.

## Cómo se usan

Cada componente es un `Node` con un script (`class_name`) que se añade como
**hijo** del cuerpo que lo necesita. Se configura con variables exportadas en el
Inspector. Los componentes de comportamiento (`PlatformerMotor`, `DashComponent`)
no se mueven solos: el dueño llama a su `step()` en un orden explícito.

## Componentes (`core/components/`)

| Componente | Responsabilidad | API principal |
|---|---|---|
| `HealthComponent` | Vida, invulnerabilidad tras daño, cargas de curación | `take_hit(amount) -> bool`, `use_heal_charge() -> bool`, `reset_health()`, `restore()`; señales `changed`, `damaged(amount)`, `died` |
| `PlatformerMotor` | Movimiento lateral, gravedad, salto con coyote time, jump buffering y salto variable, saltos extra en el aire (`max_air_jumps`: 0 = ninguno, 1 = doble salto) y agarre/salto de pared (`can_wall_jump`, con `wall_slide_speed`, `wall_jump_push`, etc.) y bajada de plataformas de un solo sentido con abajo + salto (`can_drop_through`; funciona con baldosas de TileMapLayer y con formas de colisión con `one_way_collision`; sobre suelo sólido, abajo + salto sigue siendo un salto). Al pulsar salto: suelo > pared > salto extra | `step(body, delta)`, `facing`; señal `facing_changed(facing)` |
| `DashComponent` | Empujón horizontal recto que ignora la gravedad | `step(body, facing, delta)`, `is_dashing`; `unlocked` (false = habilidad aún no conseguida) |
| `MeleeAttackComponent` | Golpe cuerpo a cuerpo con enfriamiento sobre un `Area2D`. Con `target_group` solo golpea a ese grupo (vacío = a todo lo golpeable) | `try_attack(attacker, facing) -> bool`, `set_facing(facing)`; señal `hit_landed(body)` por cada cuerpo alcanzado; exporta `hitbox` |
| `ParryComponent` | Parry: al pulsar se abre una ventana breve (por defecto 0,2 s) en la que un golpe frontal se desvía en vez de hacer daño; después hay un enfriamiento. No sabe qué pasa al desviar: emite `parried` | `try_start() -> bool`, `try_deflect(blow_direction, facing, attacker) -> bool`, `is_active`; señales `started`, `parried(attacker)` |
| `KnockbackComponent` | Retroceso horizontal breve al recibir un golpe. Mientras `is_active`, el dueño deja que mande sobre la velocidad | `apply(direction)`, `step(body, delta)`, `is_active` |
| `PatrolChaseAI` | IA de enemigo terrestre: patrulla, persigue al objetivo, ataca con aviso previo (esquivable) no se cae por los bordes y da la vuelta al topar con una pared (solo si está delante, no a su espalda). No aplica gravedad ni daña: el dueño llama a `step()` y decide cómo golpear | `step(body, delta)`, `interrupt(stagger_time)`, `state`, `facing`; señales `facing_changed`, `attack_started`, `attack_landed`; exporta tiempos, rangos y `ledge_probe` (`RayCast2D`, opcional) |
| `CameraLookComponent` | Desplaza la `Camera2D` al mirar arriba/abajo | Autónomo (`_physics_process`); exporta `camera` |
| `RespawnComponent` | Punto de reaparición, último suelo pisado, límite de caída | `track_ground(body)`, `is_out_of_bounds(body)`, `set_checkpoint(pos)`, `respawn(body)` |
| `SheetAnimator` | Anima un `Sprite2D` con hoja de sprites: cada animación es una fila y cada fotograma una columna. Distingue animaciones normales (`play`) y acciones (`play_action`, p. ej. un ataque) que no pisa el movimiento. Solo presentación | `play(animation)`, `play_action(animation, hold, duration)`, `release_action()`, `current`; exporta `sprite` y `animations` (nombre → `[fila, nº de fotogramas, fps, bucle]`) |
| `AttackVisualComponent` | Presentación de un ataque: pide al `SheetAnimator` las animaciones de aviso y golpe (con el arma dibujada en el sprite) y hace destellar opcionalmente el arco del golpe | `windup(duration)`, `strike()`, `swing()` (ataque sin aviso), `reset()`, `set_facing(facing)`; exporta `animator`, `slash` y los nombres de las animaciones |
| `ScreenShakeComponent` | Temblor breve de la cámara. Mueve `camera.position`, independiente del `offset` de `CameraLookComponent` | `shake(strength, duration)`; exporta `camera` |
| `TieredUpgrade` | Mejora por niveles con coste y valor por nivel (daño de un arma, vida máxima...). No gestiona la moneda: el dueño comprueba el saldo y cobra | `current_value()`, `is_max()`, `next_cost()`, `advance()`, `level`; señal `changed`; exports `values` y `costs` |
| `HitFlashComponent` | Parpadeo de color al recibir un golpe | `flash()`; exporta `target` (cualquier `CanvasItem`) |

Valores por defecto y su significado están documentados en los comentarios `##`
de cada variable exportada (se ven en el Inspector).

## Objetos (`core/objects/`)

| Objeto | Base | Responsabilidad |
|---|---|---|
| `Checkpoint` | `Area2D` (se puede heredar: ver `game/memory_anchor/`; `targets_in_range` es público) | Al pulsar `action_interact` con un cuerpo del grupo objetivo dentro, llama a `rest_at(position)` en él; muestra `prompt` (opcional) mientras hay alguien al alcance |
| `AbilityPickup` | `Area2D` | Al entrar un cuerpo del grupo objetivo, llama a `unlock_ability(ability_id)` en él y desaparece. No conoce las habilidades: solo entrega el identificador |
| `EntitySpawner` | `Node2D` | Crea `scene` al cargar; al recibir `reset()` (vía el grupo `reset_group`) destruye la instancia actual y crea una nueva desde cero. `instance` es la entidad actual |
| `TextTileMap` | `TileMapLayer` | Construye el nivel desde un `.map` de texto (un carácter por baldosa, según `legend`). Los caracteres que no están en la leyenda son **marcadores**: no ponen baldosa y su posición queda en `markers[carácter]` para que el nivel coloque entidades. Al exportar hay que incluir `*.map` en los filtros de recursos no gráficos |

## Interfaz (`core/ui/`)

Controles genéricos para el HUD. No saben de dónde vienen los números: el dueño llama a `set_values()`.

| Control | Base | Responsabilidad |
|---|---|---|
| `SegmentedBar` | `Control` | Barra con un segmento por punto de `max_value`, dibujada con rectángulos (marco, fondo, relleno con luz y sombra). `set_values(valor, máximo)`; colores y tamaño de segmento configurables |
| `IconRow` | `Control` | Fila de iconos de una hoja de sprites: `count` llenos y el resto hasta `max_count` vacíos (`full_frame`/`empty_frame`). Sirve para cargas de curación, llaves, munición. `set_values(cantidad, máximo)` |
| `MenuList` | `VBoxContainer` | Lista de opciones con teclado o mando (`ui_up`/`ui_down`/`ui_accept`/`ui_cancel`). `set_entries(textos, activas)`, `select_first_enabled()`; avisa con `chosen(índice)` y `cancelled`. Las opciones desactivadas salen atenuadas y no se pueden elegir. Lee las teclas en `_input` (antes que la interfaz de Godot) Para menús con el juego en pausa, el nodo necesita `process_mode = When Paused` |

## Efectos (`core/effects/`)

| Efecto | Responsabilidad |
|---|---|
| `HitSpark` | Chispazo breve de impacto que se autodestruye. Uso: `HitSpark.spawn(parent, posición_global, color)` (el color es opcional) |

## Contratos que asumen

- **Reiniciable:** los `EntitySpawner` pertenecen al grupo `reset_group` (por
  defecto `resettable`). Quien decide cuándo reiniciar el mundo llama a
  `get_tree().call_group("resettable", "reset")`. En este juego lo hace el
  jugador al morir y al descansar.

- **Golpeable:** cualquier cuerpo que reciba daño implementa
  `take_hit(damage: int, from_direction: int, attacker: Node = null)`. `attacker` es
  quien golpea (puede ser null) y permite, p. ej., aturdirlo si el golpe se desvía.
- **Checkpoint:** el cuerpo objetivo implementa `rest_at(position: Vector2)` y
  pertenece al grupo configurado en `target_group`.
- **Acciones de entrada:** los nombres de acción son variables exportadas
  (`action_left`, `action_jump`, `action_dash`...). Por defecto usan las
  acciones integradas de Godot (`ui_left`, `ui_right`, `ui_accept`, `ui_up`,
  `ui_down`), más `dash` e `interact` (usada por `Checkpoint`), que deben
  existir en el Mapa de entrada del proyecto.
  Ver la sección `[input]` de `project.godot` de este repo como ejemplo.

## Referencias entre nodos en escenas `.tscn`

Las variables exportadas que apuntan a otros nodos (`hitbox`, `camera`,
`target`) deben declararse con `node_paths` en la cabecera del nodo, o llegarán
vacías. El editor lo escribe solo; si editas a mano:

```
[node name="HitFlashComponent" type="Node" parent="." node_paths=PackedStringArray("target")]
script = ExtResource("...")
target = NodePath("../Visual")
```

## Ejemplo mínimo: un cuerpo golpeable con vida

```
Enemy (CharacterBody2D)            <- script propio: take_hit() -> health.take_hit()
├── CollisionShape2D
├── HealthComponent                <- max_health = 3
└── HitFlashComponent              <- target = ../Visual
```

Ver `game/enemy/` para un ejemplo real y `game/player/` para uno completo.

## Ejemplo: enemigos que reaparecen

En el nivel se colocan `EntitySpawner` (con `scene` = la escena del enemigo) en
lugar de instanciar el enemigo directamente. No hace falta nada más en el enemigo.
