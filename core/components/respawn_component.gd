class_name RespawnComponent
extends Node
## Punto de reaparición, última posición pisando suelo y límite de caída.
##
## Su padre debe ser un Node2D: la posición inicial del padre es el primer
## punto de reaparición.

## Si el cuerpo baja de esta Y (coordenadas globales), se considera caído al vacío.
@export var fall_limit_y: float = 900.0

var spawn_position: Vector2
var last_grounded_position: Vector2


func _ready() -> void:
	var owner_node := get_parent() as Node2D
	spawn_position = owner_node.global_position
	last_grounded_position = owner_node.global_position


## Llamar cada frame de físicas ANTES de mover el cuerpo.
func track_ground(body: CharacterBody2D) -> void:
	if body.is_on_floor():
		last_grounded_position = body.global_position


func is_out_of_bounds(body: Node2D) -> bool:
	return body.global_position.y > fall_limit_y


## Fija un nuevo punto de reaparición (y de "último suelo") en `position`.
func set_checkpoint(position: Vector2) -> void:
	spawn_position = position
	last_grounded_position = position


func respawn(body: CharacterBody2D) -> void:
	body.global_position = spawn_position
	body.velocity = Vector2.ZERO
