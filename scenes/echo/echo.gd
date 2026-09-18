extends Node2D

## Marca el punto donde perdiste tus Ecos (o tu última posición en suelo, si
## moriste cayendo). No es hostil: tocarlo los recupera al instante. Si
## mueres otra vez antes de tocarlo, Player.die() lo borra sin más y se
## pierden para siempre.

@export var ecos_held: int = 0

@onready var pickup_area: Area2D = $PickupArea


func _ready() -> void:
	pickup_area.body_entered.connect(_on_pickup_area_body_entered)


func _on_pickup_area_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	body.add_ecos(ecos_held)
	if body.active_echo == self:
		body.active_echo = null
	queue_free()
