extends CharacterBody2D
## Enemigo básico: patrulla, persigue al jugador y ataca con un aviso (se pone
## amarillo) que da tiempo a esquivar. Un golpe suyo o del jugador lo hace
## retroceder y cancela su ataque. Da Ecos al morir.

const TELEGRAPH_COLOR := Color(1.0, 0.85, 0.3)

@export var ecos_reward: int = 2
@export var gravity: float = 2250.0

@onready var health: HealthComponent = $HealthComponent
@onready var hit_flash: HitFlashComponent = $HitFlashComponent
@onready var ai: PatrolChaseAI = $PatrolChaseAI
@onready var melee: MeleeAttackComponent = $MeleeAttackComponent
@onready var knockback: KnockbackComponent = $KnockbackComponent
@onready var attack_visual: AttackVisualComponent = $AttackVisualComponent
@onready var visual: Polygon2D = $Visual


func _ready() -> void:
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)
	ai.facing_changed.connect(_on_facing_changed)
	ai.attack_started.connect(_on_attack_started)
	ai.attack_landed.connect(_on_attack_landed)
	melee.hit_landed.connect(_on_hit_landed)


func _physics_process(delta: float) -> void:
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y += gravity * delta

	if knockback.is_active:
		knockback.step(self, delta)
	else:
		ai.step(self, delta)

	move_and_slide()


## Contrato "golpeable" (ver docs/arquitectura.md).
func take_hit(damage: int, from_direction: int) -> void:
	if health.take_hit(damage):
		knockback.apply(from_direction)
		ai.interrupt()
		visual.modulate = Color.WHITE
		attack_visual.reset()


func _on_damaged(_amount: int) -> void:
	hit_flash.flash()


func _on_died() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.add_ecos(ecos_reward)
	queue_free()


func _on_facing_changed(facing: int) -> void:
	visual.scale.x = facing
	melee.set_facing(facing)
	attack_visual.set_facing(facing)


func _on_attack_started() -> void:
	visual.modulate = TELEGRAPH_COLOR
	attack_visual.windup(ai.windup_time)


func _on_attack_landed() -> void:
	visual.modulate = Color.WHITE
	attack_visual.strike()
	melee.try_attack(self, ai.facing)


func _on_hit_landed(body: Node) -> void:
	HitSpark.spawn(get_parent(), (body as Node2D).global_position)
