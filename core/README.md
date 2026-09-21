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
| `PlatformerMotor` | Movimiento lateral, gravedad, salto con coyote time, jump buffering y salto variable, y saltos extra en el aire (`max_air_jumps`: 0 = ninguno, 1 = doble salto) | `step(body, delta)`, `facing`; señal `facing_changed(facing)` |
| `DashComponent` | Empujón horizontal recto que ignora la gravedad | `step(body, facing, delta)`, `is_dashing`; `unlocked` (false = habilidad aún no conseguida) |
| `MeleeAttackComponent` | Golpe cuerpo a cuerpo con enfriamiento sobre un `Area2D`. Con `target_group` solo golpea a ese grupo (vacío = a todo lo golpeable) | `try_attack(attacker, facing) -> bool`, `set_facing(facing)`; señal `hit_landed(body)` por cada cuerpo alcanzado; exporta `hitbox` |
| `KnockbackComponent` | Retroceso horizontal breve al recibir un golpe. Mientras `is_active`, el dueño deja que mande sobre la velocidad | `apply(direction)`, `step(body, delta)`, `is_active` |
| `PatrolChaseAI` | IA de enemigo terrestre: patrulla, persigue al objetivo, ataca con aviso previo (esquivable) y no se cae por los bordes. No aplica gravedad ni daña: el dueño llama a `step()` y decide cómo golpear | `step(body, delta)`, `interrupt(stagger_time)`, `state`, `facing`; señales `facing_changed`, `attack_started`, `attack_landed`; exporta tiempos, rangos y `ledge_probe` (`RayCast2D`, opcional) |
| `CameraLookComponent` | Desplaza la `Camera2D` al mirar arriba/abajo | Autónomo (`_physics_process`); exporta `camera` |
| `RespawnComponent` | Punto de reaparición, último suelo pisado, límite de caída | `track_ground(body)`, `is_out_of_bounds(body)`, `set_checkpoint(pos)`, `respawn(body)` |
| `AttackVisualComponent` | Animación básica de ataque (solo presentación): un brazo (`Node2D`) que se levanta en el aviso y golpea, y un destello opcional del arco del golpe | `windup(duration)`, `strike()`, `swing()` (ataque sin aviso), `reset()`, `set_facing(facing)`; exporta `arm`, `slash` y los ángulos |
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

## Efectos (`core/effects/`)

| Efecto | Responsabilidad |
|---|---|
| `HitSpark` | Chispazo breve de impacto que se autodestruye. Uso: `HitSpark.spawn(parent, posición_global)` |

## Contratos que asumen

- **Reiniciable:** los `EntitySpawner` pertenecen al grupo `reset_group` (por
  defecto `resettable`). Quien decide cuándo reiniciar el mundo llama a
  `get_tree().call_group("resettable", "reset")`. En este juego lo hace el
  jugador al morir y al descansar.

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

## Ejemplo: enemigos que reaparecen

En el nivel se colocan `EntitySpawner` (con `scene` = la escena del enemigo) en
lugar de instanciar el enemigo directamente. No hace falta nada más en el enemigo.
