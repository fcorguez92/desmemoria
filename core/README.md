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
| `PlatformerMotor` | Movimiento lateral, gravedad, salto con coyote time, jump buffering y salto variable | `step(body, delta)`, `facing`; señal `facing_changed(facing)` |
| `DashComponent` | Empujón horizontal recto que ignora la gravedad | `step(body, facing, delta)`, `is_dashing` |
| `MeleeAttackComponent` | Golpe cuerpo a cuerpo con enfriamiento sobre un `Area2D` | `try_attack(attacker, facing) -> bool`, `set_facing(facing)`; exporta `hitbox` |
| `CameraLookComponent` | Desplaza la `Camera2D` al mirar arriba/abajo | Autónomo (`_physics_process`); exporta `camera` |
| `RespawnComponent` | Punto de reaparición, último suelo pisado, límite de caída | `track_ground(body)`, `is_out_of_bounds(body)`, `set_checkpoint(pos)`, `respawn(body)` |
| `HitFlashComponent` | Parpadeo de color al recibir un golpe | `flash()`; exporta `target` (cualquier `CanvasItem`) |

Valores por defecto y su significado están documentados en los comentarios `##`
de cada variable exportada (se ven en el Inspector).

## Objetos (`core/objects/`)

| Objeto | Base | Responsabilidad |
|---|---|---|
| `ContactDamageArea` | `Area2D` | Daña a los cuerpos del grupo `target_group` (por defecto `player`) que entren en el área |
| `Checkpoint` | `Area2D` | Al pulsar `action_interact` con un cuerpo del grupo objetivo dentro, llama a `rest_at(position)` en él; muestra `prompt` (opcional) mientras hay alguien al alcance |

## Contratos que asumen

- **Golpeable:** cualquier cuerpo que reciba daño implementa
  `take_hit(damage: int, from_direction: int)`.
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
