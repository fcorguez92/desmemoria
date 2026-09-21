class_name ScreenShakeComponent
extends Node
## Temblor breve de la cámara (al golpear o recibir un golpe).
##
## Mueve `camera.position`, que es independiente del `offset` que usa
## CameraLookComponent, así que ambos pueden convivir.

@export var camera: Camera2D

var _strength: float = 0.0
var _duration: float = 0.0
var _time_left: float = 0.0


## Sacude la cámara `strength` píxeles durante `duration` segundos. Si ya hay
## un temblor más fuerte en curso, no lo sustituye.
func shake(strength: float, duration: float) -> void:
	if _time_left > 0.0 and strength < _strength * (_time_left / _duration):
		return
	_strength = strength
	_duration = maxf(duration, 0.001)
	_time_left = _duration


func _physics_process(delta: float) -> void:
	if _time_left <= 0.0:
		return
	_time_left -= delta
	var fade := maxf(_time_left / _duration, 0.0)
	camera.position = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _strength * fade
	if _time_left <= 0.0:
		camera.position = Vector2.ZERO
