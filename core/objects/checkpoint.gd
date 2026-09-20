class_name Checkpoint
extends Area2D
## Punto de control que se activa al entrar un cuerpo del grupo objetivo.
##
## Contrato con el objetivo: debe tener `rest_at(position: Vector2)`, que
## decide qué significa "descansar" (curar, fijar reaparición...).

@export var target_group: StringName = &"player"


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group(target_group) and body.has_method("rest_at"):
		body.rest_at(global_position)
