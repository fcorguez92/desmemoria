class_name FlyAI
extends Node
## IA de enemigo volador: merodea en el aire cerca de su punto de origen, persigue
## al objetivo colocándose por encima de él con una oscilación, y ataca en picado
## con un aviso previo. Es la hermana sin gravedad de PatrolChaseAI y comparte su
## contrato: el dueño llama a `step()` y después a `move_and_slide()` (con el cuerpo
## en modo FLOATING, para que no haya suelo ni "arriba"), y la IA avisa con señales.
##
## Respeta el terreno por la propia colisión del cuerpo: no atraviesa suelo, techo ni
## paredes (un picado que choca contra algo termina ahí). No hace daño: durante el
## picado (estado DIVE) el dueño golpea con su ataque cuerpo a cuerpo y avisa con
## `end_dive()` cuando acierta.
##
## Estados: PATROL -> CHASE -> WINDUP (aviso, quieto en el aire) -> DIVE (picado) ->
## RECOVER (pausa: sube de nuevo a su altura) -> ...

enum State { PATROL, CHASE, WINDUP, DIVE, RECOVER }

## Cambia la dirección a la que mira (-1 o 1).
signal facing_changed(facing: int)
## Empieza el aviso del picado.
signal attack_started
## Termina el aviso: aquí empieza el picado.
signal attack_landed
## Se cancela el aviso porque el objetivo ha salido del territorio.
signal attack_cancelled
## El picado termina (acierta, choca con el terreno o se acaba el recorrido).
signal dive_ended

@export var target_group: StringName = &"player"
@export_group("Vuelo")
@export var patrol_speed: float = 70.0
@export var chase_speed: float = 130.0
## Merodeo: cuánto se aleja de su origen en horizontal (x) y cuánto sube y baja (y).
@export var patrol_extent: Vector2 = Vector2(90.0, 14.0)
## Distancia (en 2D) a la que detecta al objetivo y a la que lo pierde.
@export var detect_range: float = 260.0
@export var lose_range: float = 380.0
## Altura sobre el objetivo a la que se coloca al perseguirlo.
@export var hover_height: float = 90.0
## Oscilación al perseguir: amplitud horizontal (x) y vertical (y) y velocidad angular.
@export var sway: Vector2 = Vector2(36.0, 10.0)
@export var sway_speed: float = 2.4
## Zona en la que actúa (coordenadas globales); sin área, no hay límite. Fuera de ella
## el objetivo no cuenta (ver PatrolChaseAI.territory).
@export var territory: Rect2 = Rect2()
@export_group("Picado")
## Diferencia horizontal máxima con el objetivo para iniciar el aviso.
@export var attack_range: float = 70.0
## Altura mínima sobre el objetivo para picar (si está por debajo, primero sube).
@export var min_dive_height: float = 40.0
@export var windup_time: float = 0.45
@export var dive_speed: float = 260.0
## Recorrido máximo del picado (si no choca antes).
@export var dive_distance: float = 190.0
## Pausa entre picados (y aturdimiento mínimo tras el golpe).
@export var recovery_time: float = 1.2

var state: State = State.PATROL
var facing: int = 1

var _timer: float = 0.0
var _stun: float = 0.0
var _clock: float = 0.0
var _home: Vector2
var _patrol_direction: int = 1
var _dive_direction: Vector2 = Vector2.ZERO
var _dive_travelled: float = 0.0
var _target: Node2D


func _ready() -> void:
	_home = (get_parent() as Node2D).global_position
	_clock = randf() * TAU


func step(body: CharacterBody2D, delta: float) -> void:
	_timer -= delta
	_clock += delta

	var target := _find_target()
	var offset := Vector2.ZERO
	if target:
		offset = target.global_position - body.global_position
	var in_range := target != null and offset.length() <= detect_range

	match state:
		State.PATROL:
			if in_range:
				state = State.CHASE
			else:
				_patrol(body)
		State.CHASE:
			if target == null or offset.length() > lose_range:
				state = State.PATROL
			else:
				_seek(body, _hover_point(target), chase_speed)
				_face(offset.x)
				if absf(offset.x) <= attack_range and offset.y >= min_dive_height and _timer <= 0.0 and _line_is_clear(body, target):
					body.velocity = Vector2.ZERO
					_timer = windup_time
					state = State.WINDUP
					attack_started.emit()
		State.WINDUP:
			body.velocity = Vector2.ZERO
			if target == null and territory.has_area():
				_timer = recovery_time
				state = State.RECOVER
				attack_cancelled.emit()
			else:
				if target:
					_face(offset.x)
				if _timer <= 0.0:
					_start_dive(body, target)
		State.DIVE:
			_step_dive(body, delta)
		State.RECOVER:
			if _stun > 0.0:
				_stun -= delta
				body.velocity = Vector2.ZERO
			elif target != null:
				_seek(body, _hover_point(target), chase_speed)
			else:
				_seek(body, _home, patrol_speed)
			if _timer <= 0.0 and _stun <= 0.0:
				state = State.CHASE if in_range else State.PATROL


## El picado ha acertado: termina y empieza la pausa. No hace nada fuera de DIVE.
func end_dive() -> void:
	if state != State.DIVE:
		return
	state = State.RECOVER
	_timer = recovery_time
	dive_ended.emit()


## Cancela lo que hacía y lo deja quieto `stagger_time` segundos (golpe o parry).
func interrupt(stagger_time: float = 0.3) -> void:
	if state == State.DIVE:
		dive_ended.emit()
	_stun = stagger_time
	_timer = maxf(stagger_time, 0.0)
	state = State.RECOVER


## ¿Está persiguiendo? (Para que el dueño gruña al empezar.)
func is_chasing() -> bool:
	return state == State.CHASE


## Un volador nunca está dormido: mismo contrato que PatrolChaseAI.
func is_dormant() -> bool:
	return false


## ¿Hay camino libre de terreno hacia el objetivo? Si hay un sólido de por medio no pica
## (evita picados que acaben contra el techo o una repisa, en bucle).
func _line_is_clear(body: CharacterBody2D, target: Node2D) -> bool:
	var query := PhysicsRayQueryParameters2D.create(body.global_position, target.global_position, 1, [body.get_rid()])
	var hit := body.get_world_2d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or hit.collider is CharacterBody2D


func _start_dive(body: CharacterBody2D, target: Node2D) -> void:
	var aim := Vector2(float(facing), 1.0)
	if target:
		aim = target.global_position - body.global_position
	_dive_direction = aim.normalized()
	_dive_travelled = 0.0
	state = State.DIVE
	attack_landed.emit()


func _step_dive(body: CharacterBody2D, delta: float) -> void:
	body.velocity = _dive_direction * dive_speed
	_dive_travelled += dive_speed * delta
	# Choca con el terreno (suelo, techo o pared) o agota el recorrido.
	var blocked := body.get_slide_collision_count() > 0 and _dive_travelled > 4.0
	if blocked or _dive_travelled >= dive_distance:
		end_dive()


func _patrol(body: CharacterBody2D) -> void:
	var goal := _home + Vector2(_patrol_direction * patrol_extent.x, sin(_clock * 1.7) * patrol_extent.y)
	_seek(body, goal, patrol_speed)
	_face(float(_patrol_direction))
	if absf(body.global_position.x - goal.x) < 8.0 or body.is_on_wall():
		_patrol_direction = -_patrol_direction


## Punto sobre el objetivo al que se dirige al perseguir, con la oscilación.
func _hover_point(target: Node2D) -> Vector2:
	return target.global_position + Vector2(sin(_clock * sway_speed) * sway.x, -hover_height + sin(_clock * sway_speed * 1.9) * sway.y)


func _seek(body: CharacterBody2D, point: Vector2, speed: float) -> void:
	var to_point := point - body.global_position
	# Frena al llegar para no vibrar sobre el punto.
	body.velocity = to_point.normalized() * minf(speed, to_point.length() * 6.0)


func _face(horizontal: float) -> void:
	if absf(horizontal) < 2.0:
		return
	var direction := 1 if horizontal > 0.0 else -1
	if direction != facing:
		facing = direction
		facing_changed.emit(facing)


func _find_target() -> Node2D:
	if not is_instance_valid(_target):
		_target = get_tree().get_first_node_in_group(target_group) as Node2D
	if _target != null and territory.has_area() and not territory.has_point(_target.global_position):
		return null
	return _target
