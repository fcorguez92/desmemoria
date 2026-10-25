class_name PatrolChaseAI
extends Node
## IA básica de enemigo terrestre: patrulla cerca de su punto de origen, persigue
## al objetivo si lo detecta y ataca con un aviso previo que da tiempo a esquivar.
##
## No aplica gravedad ni se mueve sola: el dueño llama a `step()` y después a
## `move_and_slide()`. Tampoco hace daño: emite `attack_landed` y el dueño decide
## cómo golpear (normalmente con un MeleeAttackComponent).
##
## Estados: PATROL -> CHASE -> WINDUP (aviso) -> RECOVER (recuperación) -> ...
##
## Con `starts_dormant` empieza en DORMANT: inmóvil, fingiendo que no está, hasta que
## el objetivo entra en `wake_radius` o le golpean. Entonces pasa a WAKING (se
## levanta `wake_time` segundos, sin atacar) y de ahí a CHASE.

enum State { PATROL, CHASE, WINDUP, RECOVER, DORMANT, WAKING }

## Cambia la dirección a la que mira (-1 o 1).
signal facing_changed(facing: int)
## Empieza el aviso del ataque (el dueño puede mostrar una señal visual).
signal attack_started
## Termina el aviso: aquí cae el golpe.
signal attack_landed
## Se cancela el aviso porque el objetivo ha salido del territorio (no hay golpe).
signal attack_cancelled
## Empieza a despertar (DORMANT -> WAKING): el dueño puede mostrar que se levanta.
signal woke_up

@export var target_group: StringName = &"player"
@export var patrol_speed: float = 60.0
@export var chase_speed: float = 140.0
## Cuánto se aleja de su punto de origen al patrullar.
@export var patrol_distance: float = 60.0
## Distancia horizontal a la que detecta al objetivo.
@export var detect_range: float = 220.0
## Distancia horizontal a la que deja de perseguirlo.
@export var lose_range: float = 320.0
## Diferencia de altura máxima para considerar que ve al objetivo.
@export var vertical_tolerance: float = 80.0
## Distancia horizontal a la que empieza el aviso del ataque.
## Zona en la que actúa (en coordenadas globales). Con área, un objetivo fuera de ella
## no cuenta: ni se detecta, ni se persigue, ni se le ataca (un aviso en curso se
## cancela). Sin área (por defecto) no hay límite.
@export var territory: Rect2 = Rect2()
@export var attack_range: float = 44.0
@export var windup_time: float = 0.4
@export var recovery_time: float = 0.7
## RayCast2D hijo del cuerpo que apunta hacia abajo; si no toca suelo por delante,
## el enemigo no avanza (no se cae de los bordes). Opcional.
@export var ledge_probe: RayCast2D
## Distancia horizontal del sondeo de bordes al centro del cuerpo.
@export var ledge_probe_offset: float = 22.0

@export_group("Dormido")
## Si es true, empieza dormido (DORMANT) en vez de patrullando.
@export var starts_dormant: bool = false
## Distancia (en 2D, de centro a centro) a la que el objetivo lo despierta.
@export var wake_radius: float = 100.0
## Segundos que tarda en levantarse; durante ellos no ataca ni avanza.
@export var wake_time: float = 1.0

var state: State = State.PATROL
var facing: int = 1

var _timer: float = 0.0
var _patrol_direction: int = 1
var _home_x: float = 0.0
var _target: Node2D


func _ready() -> void:
	_home_x = (get_parent() as Node2D).global_position.x
	if starts_dormant:
		state = State.DORMANT


func step(body: CharacterBody2D, delta: float) -> void:
	_timer -= delta

	var dx := 0.0
	var in_sight := false
	var target := _find_target()
	if target:
		dx = target.global_position.x - body.global_position.x
		in_sight = absf(target.global_position.y - body.global_position.y) <= vertical_tolerance
	var toward := 1 if dx >= 0.0 else -1

	match state:
		State.PATROL:
			if in_sight and absf(dx) <= detect_range:
				state = State.CHASE
			else:
				var free := _walk(body, _patrol_direction, patrol_speed)
				var offset := body.global_position.x - _home_x
				if not free or (absf(offset) >= patrol_distance and int(signf(offset)) == _patrol_direction):
					_patrol_direction = -_patrol_direction
		State.CHASE:
			if not in_sight or absf(dx) > lose_range:
				state = State.PATROL
			elif absf(dx) <= attack_range:
				_set_facing(toward)
				body.velocity.x = 0.0
				_timer = windup_time
				state = State.WINDUP
				attack_started.emit()
			else:
				_walk(body, toward, chase_speed)
		State.WINDUP:
			body.velocity.x = 0.0
			if target == null and territory.has_area():
				_timer = recovery_time
				state = State.RECOVER
				attack_cancelled.emit()
			elif _timer <= 0.0:
				attack_landed.emit()
				_timer = recovery_time
				state = State.RECOVER
		State.RECOVER:
			body.velocity.x = 0.0
			if _timer <= 0.0:
				state = State.CHASE if in_sight and absf(dx) <= detect_range else State.PATROL
		State.DORMANT:
			body.velocity.x = 0.0
			if target != null and body.global_position.distance_to(target.global_position) <= wake_radius:
				wake(toward)
		State.WAKING:
			body.velocity.x = 0.0
			if _timer <= 0.0:
				state = State.CHASE


## Despierta a un enemigo dormido: empieza a levantarse (`wake_time` s) mirando hacia
## `facing_to` (-1 o 1; 0 = como estaba). No hace nada si no estaba dormido.
func wake(facing_to: int = 0) -> void:
	if state != State.DORMANT:
		return
	if facing_to != 0:
		_set_facing(facing_to)
	_timer = wake_time
	state = State.WAKING
	woke_up.emit()


## ¿Está dormido (fingiendo, inmóvil)?
func is_dormant() -> bool:
	return state == State.DORMANT


## ¿Está persiguiendo? (Para que el dueño gruña al empezar a perseguir.)
func is_chasing() -> bool:
	return state == State.CHASE


## Cancela el ataque en curso y deja al enemigo aturdido `stagger_time` segundos.
## Un golpe a un enemigo dormido lo despierta (se levanta en vez de quedar aturdido).
func interrupt(stagger_time: float = 0.3) -> void:
	if state == State.DORMANT:
		wake()
		return
	if state == State.WAKING:
		return
	_timer = stagger_time
	state = State.RECOVER


## Camina en `direction`. Devuelve false si no puede avanzar (pared o borde).
func _walk(body: CharacterBody2D, direction: int, speed: float) -> bool:
	_set_facing(direction)
	if _wall_ahead(body, direction) or _ledge_ahead(body):
		body.velocity.x = 0.0
		return false
	body.velocity.x = direction * speed
	return true


## ¿Hay una pared justo delante, en la dirección en la que se quiere caminar?
## Una pared a la espalda no cuenta: si no, un enemigo pegado a una pared daría la
## vuelta cada frame (viendo siempre "pared") y nunca se apartaría, vibrando.
func _wall_ahead(body: CharacterBody2D, direction: int) -> bool:
	return body.is_on_wall() and int(signf(body.get_wall_normal().x)) == -direction


func _ledge_ahead(body: CharacterBody2D) -> bool:
	if ledge_probe == null or not body.is_on_floor():
		return false
	ledge_probe.position.x = ledge_probe_offset * facing
	ledge_probe.force_raycast_update()
	return not ledge_probe.is_colliding()


func _set_facing(direction: int) -> void:
	if direction != facing:
		facing = direction
		facing_changed.emit(facing)


func _find_target() -> Node2D:
	if not is_instance_valid(_target):
		_target = get_tree().get_first_node_in_group(target_group) as Node2D
	if _target != null and territory.has_area() and not territory.has_point(_target.global_position):
		return null
	return _target
