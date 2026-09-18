extends CharacterBody2D

## Enemigo de prueba, sin IA todavía: solo existe para poder golpear algo
## y comprobar si el ataque se siente bien (impacto, feedback visual, ritmo).

@export var max_health: int = 3

var health: int

@onready var visual: Polygon2D = $Visual
@onready var flash_timer: Timer = $FlashTimer


func _ready() -> void:
	health = max_health


func take_hit(damage: int, _from_direction: int) -> void:
	health -= damage
	visual.modulate = Color(1.0, 0.35, 0.35)
	flash_timer.start()
	if health <= 0:
		queue_free()


func _on_flash_timer_timeout() -> void:
	visual.modulate = Color(1.0, 1.0, 1.0)
