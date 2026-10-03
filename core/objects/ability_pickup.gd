class_name AbilityPickup
extends Area2D
## Objeto que concede una habilidad al recogerlo y desaparece.
##
## Contrato con el objetivo: debe tener `unlock_ability(id: StringName)`, que
## decide qué significa conseguir esa habilidad. El pickup no conoce las
## habilidades: solo entrega su identificador.

## Se emite justo antes de liberarse, con quien lo recogió. Permite a una escena
## concreta añadir efectos sin que el pickup base sepa nada de ellos.
signal collected(body: Node)

@export var ability_id: StringName
@export var target_group: StringName = &"player"


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group(target_group) and body.has_method("unlock_ability"):
		body.unlock_ability(ability_id)
		collected.emit(body)
		queue_free()
