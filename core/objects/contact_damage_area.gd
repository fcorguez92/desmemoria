class_name ContactDamageArea
extends Area2D
## Daña, al entrar en el área, a los cuerpos del grupo objetivo que tengan
## `take_hit(damage, from_direction)`.
##
## Filtrar por grupo (y no por "cualquier cosa golpeable") evita que un
## enemigo dañe a otros enemigos u objetos que también implementan take_hit.

@export var damage: int = 1
@export var target_group: StringName = &"player"


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group(target_group) and body.has_method("take_hit"):
		body.take_hit(damage, 0)
