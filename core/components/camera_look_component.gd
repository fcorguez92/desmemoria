class_name CameraLookComponent
extends Node
## Mirar arriba/abajo: desplaza la cámara suavemente sin mover al personaje,
## para ver fuera de pantalla antes de saltar a ciegas.

@export var camera: Camera2D
@export var look_offset: float = 100.0
@export var look_speed: float = 4.0
@export var action_up: StringName = &"ui_up"
@export var action_down: StringName = &"ui_down"


func _physics_process(delta: float) -> void:
	var look := 0.0
	if Input.is_action_pressed(action_up):
		look = -1.0
	elif Input.is_action_pressed(action_down):
		look = 1.0
	camera.offset = camera.offset.lerp(Vector2(0.0, look * look_offset), look_speed * delta)
