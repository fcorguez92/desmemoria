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

var is_dashing: bool = false

var _timer: float = 0.0
var _cooldown_timer: float = 0.0
var _direction: int = 1


func step(body: CharacterBody2D, facing: int, delta: float) -> void:
	_cooldown_timer = maxf(_cooldown_timer - delta, 0.0)

	if Input.is_action_just_pressed(action_dash) and not is_dashing and _cooldown_timer <= 0.0:
		is_dashing = true
		_timer = duration
		_cooldown_timer = cooldown
		_direction = facing

	if is_dashing:
		_timer -= delta
		body.velocity = Vector2(_direction * speed, 0.0)
		if _timer <= 0.0:
			is_dashing = false
