class_name PlatformerMotor
extends Node
## Movimiento lateral con salto ágil: coyote time, jump buffering, altura de
## salto variable y caída más rápida que la subida.
##
## No se mueve solo: el dueño llama a `step()` cada frame de físicas y después
## a `move_and_slide()`. Así el orden respecto a otros componentes (p. ej. el
## dash, que pisa la velocidad) queda visible en un único sitio.

## Se emite cuando cambia la dirección a la que mira el cuerpo (-1 o 1).
signal facing_changed(facing: int)

@export var speed: float = 300.0
@export var jump_velocity: float = -900.0
@export var gravity: float = 2250.0
@export var fall_gravity_multiplier: float = 1.4
## Margen tras salir de una plataforma en el que aún se puede saltar.
@export var coyote_time: float = 0.1
## Margen en el que un salto pulsado justo antes de aterrizar se recuerda.
@export var jump_buffer_time: float = 0.12
## Fracción de la velocidad de subida que se conserva al soltar el salto pronto.
@export_range(0.0, 1.0) var jump_cut_factor: float = 0.5
## Saltos extra en el aire (0 = ninguno, 1 = doble salto). Se recargan al tocar suelo.
@export var max_air_jumps: int = 0
@export var air_jump_velocity: float = -800.0
@export var action_left: StringName = &"ui_left"
@export var action_right: StringName = &"ui_right"
@export var action_jump: StringName = &"ui_accept"

var facing: int = 1

var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _air_jumps_left: int = 0


func step(body: CharacterBody2D, delta: float) -> void:
	var on_floor := body.is_on_floor()

	if on_floor:
		body.velocity.y = 0.0
		_coyote_timer = coyote_time
		_air_jumps_left = max_air_jumps
	else:
		var g := gravity * fall_gravity_multiplier if body.velocity.y > 0.0 else gravity
		body.velocity.y += g * delta
		_coyote_timer = maxf(_coyote_timer - delta, 0.0)

	var jump_pressed := Input.is_action_just_pressed(action_jump)
	if jump_pressed:
		_jump_buffer_timer = jump_buffer_time
	else:
		_jump_buffer_timer = maxf(_jump_buffer_timer - delta, 0.0)

	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		body.velocity.y = jump_velocity
		_jump_buffer_timer = 0.0
		_coyote_timer = 0.0
	elif jump_pressed and not on_floor and _air_jumps_left > 0:
		# Solo si el salto normal no pudo usarse (ni suelo ni margen de coyote).
		body.velocity.y = air_jump_velocity
		_air_jumps_left -= 1
		_jump_buffer_timer = 0.0

	if Input.is_action_just_released(action_jump) and body.velocity.y < 0.0:
		body.velocity.y *= jump_cut_factor

	var direction := Input.get_axis(action_left, action_right)
	body.velocity.x = direction * speed

	if direction != 0.0 and int(signf(direction)) != facing:
		facing = int(signf(direction))
		facing_changed.emit(facing)
