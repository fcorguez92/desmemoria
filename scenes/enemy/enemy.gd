extends CharacterBody2D

## Enemigo de prueba, sin IA todavía: solo existe para poder golpear algo
## y comprobar si el ataque y el daño por contacto se sienten bien.

## Enemigo de prueba: ataca al mismo alcance que el jugador (ver
## Player.attack_reach) para poder comparar sensaciones directamente.
## No es el diseño final de enemigo, solo referencia para probar el núcleo.
@export var max_health: int = 3
@export var ecos_reward: int = 2

var health: int

@onready var visual: Polygon2D = $Visual
@onready var flash_timer: Timer = $FlashTimer
@onready var hurt_area: Area2D = $HurtArea


func _ready() -> void:
	health = max_health
	hurt_area.body_entered.connect(_on_hurt_area_body_entered)


func take_hit(damage: int, _from_direction: int) -> void:
	health -= damage
	visual.modulate = Color(1.0, 0.35, 0.35)
	flash_timer.start()
	if health <= 0:
		var player := get_tree().get_first_node_in_group("player")
		if player:
			player.add_ecos(ecos_reward)
		queue_free()


func _on_hurt_area_body_entered(body: Node) -> void:
	# Solo amenaza al jugador: sin esto, también golpea a otros enemigos o
	# a un Eco recién aparecido si nace pegado a él.
	if body.is_in_group("player"):
		body.take_hit(1, 0)


func _on_flash_timer_timeout() -> void:
	visual.modulate = Color(1.0, 1.0, 1.0)
