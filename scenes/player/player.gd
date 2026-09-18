extends CharacterBody2D

## Movimiento ágil tipo Hollow Knight: coyote time y jump buffering son lo que
## hace que saltar "se sienta bien" aunque el jugador pulse un poco tarde o
## un poco pronto.

@export var speed: float = 300.0
@export var jump_velocity: float = -900.0
@export var gravity: float = 2250.0
@export var fall_gravity_multiplier: float = 1.4
@export var coyote_time: float = 0.1
@export var jump_buffer_time: float = 0.12
@export var fall_death_y: float = 900.0
@export var attack_cooldown: float = 0.25
@export var attack_reach: float = 20.0

var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var facing: int = 1
var attack_cooldown_timer: float = 0.0
@onready var spawn_position: Vector2 = global_position
@onready var visual: Polygon2D = $Visual
@onready var attack_hitbox: Area2D = $AttackHitbox


func _physics_process(delta: float) -> void:
	var was_on_floor := is_on_floor()

	if not is_on_floor():
		var current_gravity := gravity * fall_gravity_multiplier if velocity.y > 0.0 else gravity
		velocity.y += current_gravity * delta
	else:
		velocity.y = 0.0

	if was_on_floor:
		coyote_timer = coyote_time
	else:
		coyote_timer = max(coyote_timer - delta, 0.0)

	if Input.is_action_just_pressed("ui_up"):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer = max(jump_buffer_timer - delta, 0.0)

	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		velocity.y = jump_velocity
		jump_buffer_timer = 0.0
		coyote_timer = 0.0

	# Saltar más bajo si se suelta el botón pronto (salto de altura variable).
	if Input.is_action_just_released("ui_up") and velocity.y < 0.0:
		velocity.y *= 0.5

	var direction := Input.get_axis("ui_left", "ui_right")
	velocity.x = direction * speed

	if direction != 0.0:
		facing = sign(direction)
		visual.scale.x = facing
		attack_hitbox.position.x = attack_reach * facing

	attack_cooldown_timer = max(attack_cooldown_timer - delta, 0.0)
	if Input.is_action_just_pressed("attack"):
		_try_attack()

	move_and_slide()

	if global_position.y > fall_death_y:
		global_position = spawn_position
		velocity = Vector2.ZERO


func _try_attack() -> void:
	if attack_cooldown_timer > 0.0:
		return
	attack_cooldown_timer = attack_cooldown
	for body in attack_hitbox.get_overlapping_bodies():
		if body.has_method("take_hit"):
			body.take_hit(1, facing)
