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
| `PlatformerMotor` | Movimiento lateral (todo o nada: con la palanca, pasada la zona muerta se va a toda velocidad), gravedad, salto con coyote time, jump buffering y salto variable, saltos extra en el aire (`max_air_jumps`: 0 = ninguno, 1 = doble salto) y agarre/salto de pared (`can_wall_jump`, con `wall_slide_speed`, `wall_jump_push`, etc.) y bajada de plataformas de un solo sentido con abajo + salto (`can_drop_through`; funciona con baldosas de TileMapLayer y con formas de colisión con `one_way_collision`; sobre suelo sólido, abajo + salto sigue siendo un salto). Al pulsar salto: suelo > pared > salto extra | `step(body, delta)`, `facing`; señal `facing_changed(facing)` |
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
| `SkillTree` | Árbol de habilidades: mejoras por niveles (`define(id, costs, requires)`) con coste por nivel y una mejora previa opcional. No gestiona la moneda ni aplica efectos: el dueño comprueba el saldo (`can_buy`), cobra, llama a `advance()` y aplica los niveles a sus estadísticas al oír `changed` | `level(id)`, `max_level(id)`, `next_cost(id)`, `is_unlocked(id)`, `can_buy(id, saldo)`, `advance(id)`, `set_level(id, n)` (sin coste), `get_save_data()` / `load_save_data(datos)` (desconfía de lo guardado); señal `changed` |
| `HitFlashComponent` | Parpadeo de color al recibir un golpe | `flash()`; exporta `target` (cualquier `CanvasItem`) |

Valores por defecto y su significado están documentados en los comentarios `##`
de cada variable exportada (se ven en el Inspector).

## Objetos (`core/objects/`)

| Objeto | Base | Responsabilidad |
|---|---|---|
| `Checkpoint` | `Area2D` (se puede heredar: ver `game/memory_anchor/`; `targets_in_range` es público) | Al pulsar `action_interact` con un cuerpo del grupo objetivo dentro, llama a `rest_at(position)` en él; emite la señal `activated` (para efectos); muestra `prompt` (opcional) mientras hay alguien al alcance |
| `AbilityPickup` | `Area2D` | Al entrar un cuerpo del grupo objetivo, llama a `unlock_ability(ability_id)` en él y desaparece. No conoce las habilidades: solo entrega el identificador |
| `EntitySpawner` | `Node2D` | Crea `scene` al cargar; al recibir `reset()` (vía el grupo `reset_group`) destruye la instancia actual y crea una nueva desde cero. `instance` es la entidad actual |
| `Projectile` | `Area2D` | Proyectil recto: vuela a `speed` en `direction` hasta herir a algo golpeable del grupo `target_group` (`damage`), chocar con el escenario o agotar `lifetime`. Ignora cuerpos con movimiento que no son su objetivo (quien lo lanzó, otros enemigos). Si el objetivo lo desvía con un parry llama a `on_parried()`: se devuelve y pasa a herir a `reflect_group`. Quien lo crea llama a `launch(dirección)` |
| `BreakableProp` | `StaticBody2D` | Objeto rompible decorativo: implementa "golpeable" y se destruye con un chispazo tras `hits` golpes (1 por defecto). No suelta nada ni afecta a la partida, así que no forma parte de `resettable`. Se atraviesa caminando: está en la capa de física 2 ("rompibles") sin máscara, y solo lo alcanzan los hitbox de ataque que incluyan esa capa (máscara 3). Se dibuja detrás del personaje |
| `Readable` | `Area2D` | Objeto legible: con la acción de interacción y un cuerpo del grupo objetivo dentro, llama a `read_text(text: String)` en él (contrato "lector"). No decide cómo se muestra el texto ni afecta a la partida |
| `TextTileMap` | `TileMapLayer` | Construye el nivel desde un `.map` de texto (un carácter por baldosa, según `legend`). Los caracteres que no están en la leyenda son **marcadores**: no ponen baldosa y su posición queda en `markers[carácter]` para que el nivel coloque entidades. `map_size` es el tamaño del mapa de texto en baldosas, vacío incluido (a diferencia de `get_used_rect()`). Al exportar hay que incluir `*.map` en los filtros de recursos no gráficos |

## Interfaz (`core/ui/`)

Controles genéricos para el HUD y los menús. No saben de dónde vienen los números: el dueño llama a `set_values()` (o, en el mapa, rellena un `MapData`).

| Control | Base | Responsabilidad |
|---|---|---|
| `OverheadBar` | `Node2D` | Barra de vida flotante sobre una entidad: oculta hasta que recibe daño, entonces aparece unos segundos y un trozo claro se encoge tras el golpe. Escucha el `HealthComponent` de `health` (necesita `node_paths`) |
| `InputGlyphs` | `RefCounted` (estático) | Iconos de botones que se adaptan al dispositivo en uso (teclado, Xbox, PlayStation, Nintendo): dada una *acción* del Mapa de entrada, dibuja la tecla o el botón con el aspecto del mando (colores de Xbox, símbolos de PlayStation, letras de Nintendo), sin texto explicativo. `InputGlyphs.draw(canvas, acción, centro)` dentro de un `_draw()`; `ensure_tracker()` crea el `InputGlyphTracker` que detecta el dispositivo por la última entrada |
| `InputPrompt` | `Node2D` | Aviso de botón en el mundo: el icono de `action` y una flecha que señala a lo que se refiere (`hint`). Es un `CanvasItem`: el `prompt` de Checkpoint y Readable lo muestra y oculta con `visible`. Solo gasta tiempo mientras se ve |
| `InputHintBar` | `Control` | Fila centrada de iconos de botón con un símbolo que dice qué hacen (aceptar, volver, elegir, menú) y puntos de color para leyendas, para los pies de los menús. `set_entries([{ action, hint }, { color }])` |
| `SegmentedBar` | `Control` | Barra con un segmento por punto de `max_value`, dibujada con rectángulos (marco, fondo, relleno con luz y sombra). `set_values(valor, máximo)`; colores y tamaño de segmento configurables |
| `IconRow` | `Control` | Fila de iconos de una hoja de sprites: `count` llenos y el resto hasta `max_count` vacíos (`full_frame`/`empty_frame`). Sirve para cargas de curación, llaves, munición. `set_values(cantidad, máximo)` |
| `MenuList` | `VBoxContainer` | Lista de opciones con teclado o mando (`ui_up`/`ui_down`/`ui_accept`/`ui_cancel`). La palanca del mando mueve una opción por inclinación (hay que volver al centro para mover otra), no una por cada evento de movimiento. Con `accept_actions` se añaden otras teclas de aceptar (este juego añade `interact`, la Z). `set_entries(textos, activas)`, `select_first_enabled()`; avisa con `chosen(índice)` y `cancelled`. Las opciones desactivadas salen atenuadas y no se pueden elegir. Lee las teclas en `_input` (antes que la interfaz de Godot) Para menús con el juego en pausa, el nodo necesita `process_mode = When Paused` |
| `ModalLayer` | `CanvasLayer` | Capa de interfaz modal: `open()` la muestra y pausa el juego, `close()` la oculta y reanuda dos frames de física DESPUÉS (para que la tecla que cierra no se cuele en el juego: Espacio acepta en el menú y también salta). Señales `opened`/`closed`. Exporta `root` (el Control que se muestra u oculta); hay que poner `process_mode = When Paused` en la capa y `node_paths` en el `.tscn` |
| `MapData` | `RefCounted` | Datos del mapa del mundo, en baldosas: zonas (`add_area(id, título, rect, imagen)`), que se marcan como visitadas (`visit(id)`, devuelve true la primera vez) y se **descubren baldosa a baldosa** (`reveal_around(celda, radio)`, `is_seen(celda)`, `seen_bounds()`); marcadores (`set_marker(id, celda, color)`, `remove_marker`) y foco (`set_focus(celda)`, normalmente el jugador). Avisa con `changed`. Lo visto se exporta e importa para guardarlo (`get_seen_data()` / `set_seen_data()`). `image_from_layer(capa, tamaño, color, colores_por_atlas)` dibuja una `TileMapLayer` a un píxel por baldosa. No sabe qué es una zona ni qué significa cada marcador |
| `MapView` | `Control` | Dibuja un `MapData` (asignado a `data`): solo las baldosas vistas, con su fondo; los marcadores que caen en baldosas vistas y el foco. Con `follow_focus` se centra en el foco a `cell_pixels` px por baldosa (minimapa); sin él encaja todo lo visto con la escala entera mayor que quepa (mapa completo). Varias vistas pueden compartir los mismos datos |

## Guardado (`core/save/`)

| Pieza | Base | Responsabilidad |
|---|---|---|
| `SaveSlot` | `RefCounted` | Una partida en un archivo JSON (`SaveSlot.new("user://partida.json")`). `write(diccionario) -> bool`, `read() -> Dictionary` (vacío si no hay partida, si el archivo está roto o si es de otra `FORMAT_VERSION`), `exists()`, `erase()`. Escribe en un temporal y lo renombra, para que un cierre a mitad no estropee la partida anterior. No sabe qué se guarda: quien lo usa convierte lo que JSON no entiende (`Vector2` → `[x, y]`) y recuerda que al leer los números llegan como decimales |

## Efectos (`core/effects/`)

| Efecto | Responsabilidad |
|---|---|
| `HitSpark` | Chispazo breve de impacto que se autodestruye. Uso: `HitSpark.spawn(parent, posición_global, color)` (el color es opcional) |
| `HitStop` | Pausa breve del tiempo de juego al golpear ("hit stop"): escala `Engine.time_scale` un instante y lo restaura solo, en tiempo real (no de juego), para no alargarse con su propia pausa. Uso: `HitStop.trigger(caller, duration, scale)` (`caller` solo hace falta para llegar a `get_tree()`); si dos golpes se solapan, el más reciente manda y el anterior no restaura encima de él |

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
- **Lector:** el cuerpo objetivo de un `Readable` implementa `read_text(text: String)`
  y pertenece al grupo configurado en `target_group`.
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
