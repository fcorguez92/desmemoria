extends CharacterBody2D
## Enemigo básico: patrulla, persigue al jugador y ataca con un aviso (se pone
## amarillo) que da tiempo a esquivar. Un golpe suyo o del jugador lo hace
## retroceder y cancela su ataque. Da Ecos al morir.

const TELEGRAPH_COLOR := Color(1.0, 0.85, 0.3)
const STUN_COLOR := Color(0.7, 0.9, 1.0)

@export var ecos_reward: int = 2
@export var gravity: float = 2250.0
## Segundos de aturdimiento tras un parry, durante los que recibe doble daño.
@export var parry_stun_time: float = 1.2

var _stun_timer: float = 0.0

@onready var health: HealthComponent = $HealthComponent
@onready var hit_flash: HitFlashComponent = $HitFlashComponent
@onready var ai: PatrolChaseAI = $PatrolChaseAI
@onready var melee: MeleeAttackComponent = $MeleeAttackComponent
@onready var knockback: KnockbackComponent = $KnockbackComponent
@onready var attack_visual: AttackVisualComponent = $AttackVisualComponent
@onready var visual: Sprite2D = $Visual
@onready var animator: SheetAnimator = $SheetAnimator


func _ready() -> void:
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)
	ai.facing_changed.connect(_on_facing_changed)
	ai.attack_started.connect(_on_attack_started)
	ai.attack_landed.connect(_on_attack_landed)
	melee.hit_landed.connect(_on_hit_landed)


func _physics_process(delta: float) -> void:
	if _stun_timer > 0.0:
		_stun_timer -= delta
		if _stun_timer <= 0.0:
			visual.modulate = Color.WHITE

	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y += gravity * delta

	if knockback.is_active:
		knockback.step(self, delta)
	else:
		ai.step(self, delta)

	move_and_slide()
	animator.play("walk" if absf(velocity.x) > 5.0 else "idle")


## Contrato "golpeable" (ver docs/arquitectura.md).
func take_hit(damage: int, from_direction: int, _attacker: Node = null) -> void:
	var stunned := _stun_timer > 0.0
	if health.take_hit(damage * 2 if stunned else damage):
		knockback.apply(from_direction)
		ai.interrupt(maxf(0.3, _stun_timer))
		visual.modulate = STUN_COLOR if stunned else Color.WHITE
		# reset() cancela su propio ataque en curso (windup/strike) si lo había;
		# va antes de la animación de golpe recibido porque las dos usan el mismo
		# hueco de "acción" del SheetAnimator y si no, reset() la borraría.
		attack_visual.reset()
		animator.play_action("hit")


## Le han desviado el golpe: se queda aturdido, sin poder atacar, y recibe doble
## daño mientras dure. Lo llama el jugador (ver Player._on_parried).
func on_parried() -> void:
	_stun_timer = parry_stun_time
	ai.interrupt(parry_stun_time)
	attack_visual.reset()
	visual.modulate = STUN_COLOR


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
	HitStop.trigger(self)
