extends Node2D
## Marca el punto donde perdiste tus Ecos (o tu última posición en suelo, si
## moriste cayendo). No es hostil: tocarlo los recupera al instante. Si
## mueres otra vez antes de tocarlo, Player.die() lo borra sin más y se
## pierden para siempre.

@export var ecos_held: int = 0
## Segundos tras aparecer durante los que ignora al jugador. El motor de
## físicas tarda un paso en reflejar que el jugador ya reapareció lejos; sin
## este margen lo "tocaría" en su posición antigua y se recogería al instante.
@export var arm_delay: float = 0.3

@onready var pickup_area: Area2D = $PickupArea


func _ready() -> void:
	pickup_area.monitoring = false
	pickup_area.body_entered.connect(_on_pickup_area_body_entered)
	get_tree().create_timer(arm_delay).timeout.connect(_arm)


func _arm() -> void:
	pickup_area.monitoring = true


func _on_pickup_area_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	body.add_ecos(ecos_held)
	if body.active_echo == self:
		body.active_echo = null
	queue_free()
