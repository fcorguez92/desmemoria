extends CharacterBody2D
## Enemigo de prueba, sin IA: solo tiene vida, hace daño por contacto (con el
## mismo alcance que el ataque del jugador, ver ContactDamageArea en la
## escena) y da Ecos al morir. No es el diseño final de enemigo.

@export var ecos_reward: int = 2

@onready var health: HealthComponent = $HealthComponent
@onready var hit_flash: HitFlashComponent = $HitFlashComponent


func _ready() -> void:
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)


## Contrato "golpeable" (ver docs/arquitectura.md).
func take_hit(damage: int, _from_direction: int) -> void:
	health.take_hit(damage)


func _on_damaged(_amount: int) -> void:
	hit_flash.flash()


func _on_died() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.add_ecos(ecos_reward)
	queue_free()
