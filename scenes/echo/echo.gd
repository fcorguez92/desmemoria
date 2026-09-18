extends CharacterBody2D

## Un fragmento hostil de ti mismo que queda en el punto exacto de tu última
## muerte, aferrado a los Ecos que perdiste. Derrótalo para recuperarlos.
## Si vuelves a morir antes de conseguirlo, se pierde para siempre (ver
## Player.die()).

@export var ecos_held: int = 0

@onready var visual: Polygon2D = $Visual
@onready var flash_timer: Timer = $FlashTimer
@onready var hurt_area: Area2D = $HurtArea

var health: int = 1


func _ready() -> void:
	hurt_area.body_entered.connect(_on_hurt_area_body_entered)


func take_hit(_damage: int, _from_direction: int) -> void:
	health -= 1
	if health <= 0:
		var player := get_tree().get_first_node_in_group("player")
		if player:
			player.add_ecos(ecos_held)
			player.active_echo = null
		queue_free()
		return
	visual.modulate = Color(1.0, 0.35, 0.35)
	flash_timer.start()


func _on_hurt_area_body_entered(body: Node) -> void:
	if body == self:
		return
	if body.has_method("take_hit"):
		body.take_hit(1, 0)


func _on_flash_timer_timeout() -> void:
	visual.modulate = Color(1.0, 1.0, 1.0)
