extends CharacterBody2D
## Enemigo: patrulla, persigue al jugador y ataca con un aviso (se pone amarillo)
## que da tiempo a esquivar. Un golpe suyo o del jugador lo hace retroceder y
## cancela su ataque. Da Ecos al morir.
##
## Todos los enemigos comparten este script y se diferencian por su escena (hoja
## de sprites, vida, alcance, tiempos) y por `attack_kind`, que decide qué hace
## el golpe cuando cae:
## - MELEE: golpea lo que haya dentro de su hitbox (tajo, estocada, mazazo).
## - PROJECTILE: lanza `projectile_scene` desde `muzzle` (a distancia).
## - LUNGE: se lanza hacia delante a `lunge_speed` durante `lunge_time` y golpea
##   a lo que toque por el camino (embestida).

enum AttackKind { MELEE, PROJECTILE, LUNGE }

const TELEGRAPH_COLOR := Color(1.0, 0.85, 0.3)
const STUN_COLOR := Color(0.7, 0.9, 1.0)

@export var ecos_reward: int = 2
@export var gravity: float = 2250.0
## Segundos de aturdimiento tras un parry, durante los que recibe doble daño.
@export var parry_stun_time: float = 1.2

@export_group("Ataque")
@export var attack_kind: AttackKind = AttackKind.MELEE
## PROJECTILE: escena del proyectil y punto de salida (con el enemigo mirando a la derecha).
@export var projectile_scene: PackedScene
@export var muzzle: Vector2 = Vector2(24.0, -8.0)
## LUNGE: velocidad y duración de la embestida.
@export var lunge_speed: float = 520.0
@export var lunge_time: float = 0.22

var _stun_timer: float = 0.0
var _lunge_timer: float = 0.0
var _lunge_hit: bool = false

@onready var health: HealthComponent = $HealthComponent
@onready var hit_flash: HitFlashComponent = $HitFlashComponent
@onready var ai: PatrolChaseAI = $PatrolChaseAI
@onready var melee: MeleeAttackComponent = $MeleeAttackComponent
@onready var knockback: KnockbackComponent = $KnockbackComponent
@onready var attack_visual: AttackVisualComponent = $AttackVisualComponent
@onready var visual: Sprite2D = $Visual
@onready var animator: SheetAnimator = $SheetAnimator


func _ready() -> void:
	add_to_group("enemy")
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
		_lunge_timer = 0.0
		knockback.step(self, delta)
	else:
		ai.step(self, delta)
		if _lunge_timer > 0.0:
			_step_lunge(delta)

	move_and_slide()
	if _lunge_timer > 0.0 and is_on_wall():
		_lunge_timer = 0.0
	animator.play("walk" if absf(velocity.x) > 5.0 else "idle")


## Contrato "golpeable" (ver docs/arquitectura.md).
func take_hit(damage: int, from_direction: int, _attacker: Node = null) -> void:
	var stunned := _stun_timer > 0.0
	var dealt := damage * 2 if stunned else damage
	if health.take_hit(dealt):
		_show_damage(dealt, stunned)
		_lunge_timer = 0.0
		knockback.apply(from_direction)
		ai.interrupt(maxf(0.3, _stun_timer))
		visual.modulate = STUN_COLOR if stunned else Color.WHITE
		# reset() cancela su propio ataque en curso (windup/strike) si lo había;
		# va antes de la animación de golpe recibido porque las dos usan el mismo
		# hueco de "acción" del SheetAnimator y si no, reset() la borraría.
		attack_visual.reset()
		animator.play_action("hit")


## Feedback del golpe recibido: el número de daño sobre la cabeza (amarillo si estaba
## aturdido y recibe doble) y unas gotas rojas en el punto del golpe.
func _show_damage(amount: int, stunned: bool) -> void:
	var shape := $CollisionShape2D.shape as RectangleShape2D
	var head := global_position + Vector2(0.0, -shape.size.y / 2.0 - 6.0)
	DamageNumber.spawn(get_parent(), head, amount, Color(1.0, 0.85, 0.3) if stunned else Color(1.0, 0.97, 0.9))
	HitSpark.spawn(get_parent(), global_position, Color(0.78, 0.18, 0.16), 0.55)


## Le han desviado el golpe: se queda aturdido, sin poder atacar, y recibe doble
## daño mientras dure. Lo llama el jugador (ver Player._on_parried), que puede alargar
## el aturdimiento con `extra_stun` segundos.
func on_parried(extra_stun: float = 0.0) -> void:
	var stun := parry_stun_time + extra_stun
	_stun_timer = stun
	_lunge_timer = 0.0
	ai.interrupt(stun)
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
	match attack_kind:
		AttackKind.MELEE:
			melee.try_attack(self, ai.facing)
		AttackKind.PROJECTILE:
			_shoot()
		AttackKind.LUNGE:
			_lunge_timer = lunge_time
			_lunge_hit = false


func _shoot() -> void:
	if projectile_scene == null:
		return
	var shot := projectile_scene.instantiate() as Projectile
	get_parent().add_child(shot)
	shot.global_position = global_position + Vector2(muzzle.x * ai.facing, muzzle.y)
	shot.launch(Vector2(ai.facing, 0.0))


## Durante la embestida avanza a velocidad fija (pisa la de la IA) y golpea una
## sola vez a lo primero que toque.
func _step_lunge(delta: float) -> void:
	_lunge_timer -= delta
	# No se lanza al vacío: la embestida se corta en el borde.
	if ai._ledge_ahead(self):
		_lunge_timer = 0.0
		return
	velocity.x = ai.facing * lunge_speed
	if not _lunge_hit:
		melee.try_attack(self, ai.facing)


func _on_hit_landed(body: Node) -> void:
	_lunge_hit = true
	_lunge_timer = 0.0 if attack_kind == AttackKind.LUNGE else _lunge_timer
	HitSpark.spawn(get_parent(), (body as Node2D).global_position)
	HitStop.trigger(self)
