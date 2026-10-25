class_name DashComponent
extends Node
## Empujón horizontal recto que ignora la gravedad durante `duration`.
##
## Se llama a `step()` DESPUÉS de PlatformerMotor.step() y antes de
## move_and_slide(): mientras dura el dash pisa la velocidad del cuerpo.

@export var speed: float = 900.0
@export var duration: float = 0.15
@export var cooldown: float = 0.4
@export var action_dash: StringName = &"dash"
## Si es false el dash no se puede usar (habilidad aún no conseguida).
@export var unlocked: bool = true
## Si es true, en el aire solo cabe un dash por salto: se recarga al tocar suelo.
## Sin esto, con enfriamiento corto se encadenan dos dashes en un solo salto y
## ninguna distancia pensada para "salto + dash" queda cerrada.
@export var once_per_air_time: bool = false

var is_dashing: bool = false

var _timer: float = 0.0
var _cooldown_timer: float = 0.0
var _direction: int = 1
var _air_dash_used: bool = false


## Corta el dash en curso (p. ej. un rebote). No recarga el dash en el aire.
func cancel() -> void:
	is_dashing = false


func step(body: CharacterBody2D, facing: int, delta: float) -> void:
	_cooldown_timer = maxf(_cooldown_timer - delta, 0.0)
	var on_floor := body.is_on_floor()
	if on_floor:
		_air_dash_used = false

	var air_blocked := once_per_air_time and not on_floor and _air_dash_used
	if unlocked and Input.is_action_just_pressed(action_dash) and not is_dashing and _cooldown_timer <= 0.0 and not air_blocked:
		is_dashing = true
		_air_dash_used = _air_dash_used or not on_floor
		_timer = duration
		_cooldown_timer = cooldown
		_direction = facing

	if is_dashing:
		_timer -= delta
		body.velocity = Vector2(_direction * speed, 0.0)
		if _timer <= 0.0:
			is_dashing = false
			# Un dash que arranca en el suelo y acaba en el aire también es "el del salto".
			if not body.is_on_floor():
				_air_dash_used = true
