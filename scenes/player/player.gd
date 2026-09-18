extends CharacterBody2D

## Movimiento ágil tipo Hollow Knight: coyote time y jump buffering son lo que
## hace que saltar "se sienta bien" aunque el jugador pulse un poco tarde o
## un poco pronto.

const EchoScene := preload("res://scenes/echo/echo.tscn")

@export var speed: float = 300.0
@export var jump_velocity: float = -900.0
@export var gravity: float = 2250.0
@export var fall_gravity_multiplier: float = 1.4
@export var coyote_time: float = 0.1
@export var jump_buffer_time: float = 0.12
@export var fall_death_y: float = 900.0
@export var attack_cooldown: float = 0.25
@export var attack_reach: float = 20.0
@export var camera_look_offset: float = 100.0
@export var camera_look_speed: float = 4.0
@export var max_health: int = 5
@export var hit_invulnerability_time: float = 0.6
@export var max_heal_charges: int = 3
@export var dash_speed: float = 900.0
@export var dash_duration: float = 0.15
@export var dash_cooldown: float = 0.4

var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var facing: int = 1
var attack_cooldown_timer: float = 0.0
var health: int
var heal_charges: int
var ecos: int = 0
var invulnerable_timer: float = 0.0
var active_echo: Node = null
var last_grounded_position: Vector2
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_direction: int = 1

@onready var spawn_position: Vector2 = global_position
@onready var visual: Polygon2D = $Visual
@onready var attack_hitbox: Area2D = $AttackHitbox
@onready var camera: Camera2D = $Camera2D
@onready var flash_timer: Timer = $FlashTimer
@onready var health_label: Label = $HUD/HealthLabel
@onready var ecos_label: Label = $HUD/EcosLabel
@onready var heal_label: Label = $HUD/HealLabel


func _ready() -> void:
	add_to_group("player")
	health = max_health
	heal_charges = max_heal_charges
	last_grounded_position = global_position
	_update_hud()


func _physics_process(delta: float) -> void:
	var was_on_floor := is_on_floor()

	if was_on_floor:
		last_grounded_position = global_position

	if not is_on_floor():
		var current_gravity := gravity * fall_gravity_multiplier if velocity.y > 0.0 else gravity
		velocity.y += current_gravity * delta
	else:
		velocity.y = 0.0

	if was_on_floor:
		coyote_timer = coyote_time
	else:
		coyote_timer = max(coyote_timer - delta, 0.0)

	if Input.is_action_just_pressed("ui_accept"):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer = max(jump_buffer_timer - delta, 0.0)

	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		velocity.y = jump_velocity
		jump_buffer_timer = 0.0
		coyote_timer = 0.0

	# Saltar más bajo si se suelta el botón pronto (salto de altura variable).
	if Input.is_action_just_released("ui_accept") and velocity.y < 0.0:
		velocity.y *= 0.5

	# Mirar arriba/abajo desplaza la cámara sin mover al personaje, para ver
	# fuera de pantalla antes de saltar a ciegas.
	var look_direction := 0.0
	if Input.is_action_pressed("ui_up"):
		look_direction = -1.0
	elif Input.is_action_pressed("ui_down"):
		look_direction = 1.0
	var target_camera_offset := Vector2(0.0, look_direction * camera_look_offset)
	camera.offset = camera.offset.lerp(target_camera_offset, camera_look_speed * delta)

	var direction := Input.get_axis("ui_left", "ui_right")
	velocity.x = direction * speed

	if direction != 0.0:
		facing = sign(direction)
		visual.scale.x = facing
		attack_hitbox.position.x = attack_reach * facing

	attack_cooldown_timer = max(attack_cooldown_timer - delta, 0.0)
	if Input.is_action_just_pressed("attack"):
		_try_attack()

	if Input.is_action_just_pressed("heal") and heal_charges > 0 and health < max_health:
		heal_charges -= 1
		health = max_health
		_update_hud()

	invulnerable_timer = max(invulnerable_timer - delta, 0.0)

	# El dash es un empujón horizontal recto que ignora la gravedad durante
	# su duración: por eso pisa la velocity calculada arriba justo antes de
	# mover al personaje, en vez de mezclarse con el resto del movimiento.
	dash_cooldown_timer = max(dash_cooldown_timer - delta, 0.0)
	if Input.is_action_just_pressed("dash") and not is_dashing and dash_cooldown_timer <= 0.0:
		is_dashing = true
		dash_timer = dash_duration
		dash_cooldown_timer = dash_cooldown
		dash_direction = facing
	if is_dashing:
		dash_timer -= delta
		velocity = Vector2(dash_direction * dash_speed, 0.0)
		if dash_timer <= 0.0:
			is_dashing = false

	move_and_slide()

	if global_position.y > fall_death_y:
		die()


func _try_attack() -> void:
	if attack_cooldown_timer > 0.0:
		return
	attack_cooldown_timer = attack_cooldown
	for body in attack_hitbox.get_overlapping_bodies():
		if body == self:
			continue
		if body.has_method("take_hit"):
			body.take_hit(1, facing)


func take_hit(damage: int, _from_direction: int) -> void:
	if invulnerable_timer > 0.0:
		return
	health -= damage
	invulnerable_timer = hit_invulnerability_time
	visual.modulate = Color(1.0, 0.4, 0.4)
	flash_timer.start()
	_update_hud()
	if health <= 0:
		die()


func add_ecos(amount: int) -> void:
	ecos += amount
	_update_hud()


func die() -> void:
	# Si el Eco de una muerte anterior aún no se recuperó, se pierde para
	# siempre en cuanto vuelves a morir.
	if is_instance_valid(active_echo):
		active_echo.queue_free()

	# Siempre se marca el punto de muerte, aunque no llevaras Ecos encima:
	# sirve como señal de "aquí moriste la última vez" (útil de cara a un
	# futuro mapa), no solo como contenedor de Ecos.
	var echo := EchoScene.instantiate()
	echo.ecos_held = ecos
	# La última posición en suelo, no la posición exacta de la muerte: así
	# una caída a un hueco no deja el Eco fuera de tu alcance.
	echo.global_position = last_grounded_position
	get_parent().add_child(echo)
	active_echo = echo

	ecos = 0
	health = max_health
	global_position = spawn_position
	velocity = Vector2.ZERO
	_update_hud()


func rest_at(anchor_position: Vector2) -> void:
	spawn_position = anchor_position
	last_grounded_position = anchor_position
	health = max_health
	heal_charges = max_heal_charges
	_update_hud()


func _update_hud() -> void:
	health_label.text = "Vida: %d/%d" % [health, max_health]
	ecos_label.text = "Ecos: %d" % ecos
	heal_label.text = "Curación: %d/%d" % [heal_charges, max_heal_charges]


func _on_flash_timer_timeout() -> void:
	visual.modulate = Color(1.0, 1.0, 1.0)
