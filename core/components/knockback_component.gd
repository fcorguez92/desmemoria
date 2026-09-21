class_name KnockbackComponent
extends Node
## Retroceso horizontal breve al recibir un golpe.
##
## Mientras `is_active` es true el dueño debe dejar que `step()` mande sobre la
## velocidad horizontal (y no aplicar su propio movimiento u otros impulsos).

@export var speed: float = 300.0
@export var duration: float = 0.15

var is_active: bool = false

var _direction: int = 0
var _timer: float = 0.0


## Empuja en `direction` (-1 izquierda, 1 derecha). Con 0 no hace nada.
func apply(direction: int) -> void:
	if direction == 0:
		return
	_direction = direction
	_timer = duration
	is_active = true


func step(body: CharacterBody2D, delta: float) -> void:
	if not is_active:
		return
	body.velocity.x = _direction * speed
	_timer -= delta
	if _timer <= 0.0:
		is_active = false
