extends CharacterBody2D
## Personaje jugable. Orquesta los componentes de core/ y añade lo propio de
## este juego: los Ecos, el Eco que marca la última muerte, el HUD y los menús.
##
## El orden de _physics_process es deliberado (ver docs/arquitectura.md).

const EchoScene := preload("res://game/echo/echo.tscn")
const Hud := preload("res://game/ui/hud.gd")
const AnchorMenu := preload("res://game/ui/anchor_menu.gd")
const PauseMenu := preload("res://game/ui/pause_menu.gd")
const ABILITY_NAMES := {
	&"dash": "Dash",
	&"double_jump": "Doble salto",
	&"wall_jump": "Salto de pared",
}
const MESSAGE_SECONDS := 3.0

var ecos: int = 0
## Eco de la última muerte, si aún no se recuperó.
var active_echo: Node = null

var _message_id: int = 0

@onready var motor: PlatformerMotor = $PlatformerMotor
@onready var dash: DashComponent = $DashComponent
@onready var health: HealthComponent = $HealthComponent
@onready var melee: MeleeAttackComponent = $MeleeAttackComponent
@onready var respawn: RespawnComponent = $RespawnComponent
@onready var hit_flash: HitFlashComponent = $HitFlashComponent
@onready var knockback: KnockbackComponent = $KnockbackComponent
@onready var attack_visual: AttackVisualComponent = $AttackVisualComponent
@onready var screen_shake: ScreenShakeComponent = $ScreenShakeComponent
@onready var parry: ParryComponent = $ParryComponent
@onready var parry_flash: HitFlashComponent = $ParryFlash
@onready var weapon: TieredUpgrade = $WeaponUpgrade
@onready var visual: Sprite2D = $Visual
@onready var animator: SheetAnimator = $SheetAnimator
@onready var hud: Hud = $HUD
@onready var anchor_menu: AnchorMenu = $AnchorMenu
@onready var pause_menu: PauseMenu = $PauseMenu


func _ready() -> void:
	add_to_group("player")
	motor.facing_changed.connect(_on_facing_changed)
	health.changed.connect(_update_hud)
	health.damaged.connect(_on_damaged)
	health.died.connect(die)
	melee.hit_landed.connect(_on_hit_landed)
	parry.parried.connect(_on_parried)
	weapon.changed.connect(_on_weapon_changed)
	anchor_menu.upgrade_requested.connect(_on_upgrade_requested)
	_on_weapon_changed()


func _physics_process(delta: float) -> void:
	respawn.track_ground(self)
	motor.step(self, delta)

	# Con la guardia alzada no se puede atacar.
	if Input.is_action_just_pressed("attack") and not parry.is_active and melee.try_attack(self, motor.facing):
		attack_visual.swing()
	if Input.is_action_just_pressed("parry") and parry.try_start():
		animator.play_action("parry")
	if Input.is_action_just_pressed("heal"):
		health.use_heal_charge()

	# El dash pisa la velocity, así que va después del movimiento normal.
	dash.step(self, motor.facing, delta)

	# El retroceso al recibir un golpe manda sobre todo lo demás.
	knockback.step(self, delta)

	move_and_slide()
	_update_animation()

	if respawn.is_out_of_bounds(self):
		die()


## Contrato "golpeable" (ver docs/arquitectura.md).
func take_hit(damage: int, from_direction: int, attacker: Node = null) -> void:
	if parry.try_deflect(from_direction, motor.facing, attacker):
		return
	if health.take_hit(damage):
		knockback.apply(from_direction)


## Contrato de checkpoint: lo llama core/objects/checkpoint.gd.
func rest_at(anchor_position: Vector2) -> void:
	respawn.set_checkpoint(anchor_position)
	health.restore()
	_reset_world()
	_refresh_anchor_menu()
	anchor_menu.open()


func add_ecos(amount: int) -> void:
	ecos += amount
	_update_hud()


## Esc abre la pausa. Esta capa solo funciona con el juego en pausa, así que la
## tecla que la abre la escucha el jugador, que sí recibe entrada mientras se juega.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel") and not get_tree().paused:
		_refresh_pause_menu()
		pause_menu.open()
		get_viewport().set_input_as_handled()


## ¿Está recordada esta habilidad?
func has_ability(id: StringName) -> bool:
	match id:
		&"dash":
			return dash.unlocked
		&"double_jump":
			return motor.max_air_jumps > 0
		&"wall_jump":
			return motor.can_wall_jump
	return false


## Contrato de habilidades: lo llama core/objects/ability_pickup.gd. Las
## habilidades son permanentes: morir no las pierde.
func unlock_ability(id: StringName) -> void:
	match id:
		&"dash":
			dash.unlocked = true
		&"double_jump":
			motor.max_air_jumps = 1
		&"wall_jump":
			motor.can_wall_jump = true
		_:
			push_warning("Habilidad desconocida: %s" % id)
			return
	_show_message("Has recordado: %s" % ABILITY_NAMES[id])


## Gasta Ecos en subir un nivel el Filo. Devuelve false si no se pudo
## (sin Ecos suficientes o ya al máximo). Lo llama el Ancla de Memoria.
func try_upgrade_weapon() -> bool:
	if weapon.is_max() or ecos < weapon.next_cost():
		return false
	ecos -= weapon.next_cost()
	weapon.advance()
	_update_hud()
	return true


func _on_upgrade_requested() -> void:
	try_upgrade_weapon()
	_refresh_anchor_menu()


func _refresh_anchor_menu() -> void:
	var next_cost := -1 if weapon.is_max() else weapon.next_cost()
	anchor_menu.show_state(ecos, weapon.level + 1, weapon.current_value(), next_cost)


func die() -> void:
	# El Eco de una muerte anterior que no se recuperó se pierde para siempre.
	if is_instance_valid(active_echo):
		active_echo.queue_free()

	# Siempre se marca el punto de muerte, aunque no llevaras Ecos: sirve de
	# señal de "aquí moriste" (útil para un futuro mapa). Se coloca en el
	# último suelo pisado, no donde acaba la caída, para que sea alcanzable.
	var echo := EchoScene.instantiate()
	echo.ecos_held = ecos
	echo.global_position = respawn.last_grounded_position
	get_parent().add_child(echo)
	active_echo = echo

	ecos = 0
	health.reset_health()
	respawn.respawn(self)
	_update_hud()
	_reset_world()


## Al morir o descansar, todo lo "reiniciable" (enemigos) vuelve a su estado
## inicial. Ver EntitySpawner en core/objects/.
func _reset_world() -> void:
	get_tree().call_group(&"resettable", &"reset")


func _update_animation() -> void:
	if not is_on_floor():
		animator.play("jump" if velocity.y < 0.0 else "fall")
	elif absf(velocity.x) > 10.0:
		animator.play("run")
	else:
		animator.play("idle")


func _on_facing_changed(facing: int) -> void:
	visual.scale.x = facing
	melee.set_facing(facing)
	attack_visual.set_facing(facing)


func _on_damaged(_amount: int) -> void:
	hit_flash.flash()
	screen_shake.shake(7.0, 0.18)


## Feedback de un golpe propio que alcanza algo: chispazo y un temblor leve.
func _on_hit_landed(body: Node) -> void:
	HitSpark.spawn(get_parent(), (body as Node2D).global_position)
	screen_shake.shake(3.0, 0.08)


func _show_message(text: String) -> void:
	_message_id += 1
	var this_message := _message_id
	hud.set_message(text)
	await get_tree().create_timer(MESSAGE_SECONDS).timeout
	if this_message == _message_id:
		hud.set_message("")


## Golpe desviado: sin daño, con efectos azules, y el atacante queda aturdido.
func _on_parried(attacker: Node) -> void:
	parry_flash.flash()
	screen_shake.shake(5.0, 0.12)
	if attacker is Node2D:
		HitSpark.spawn(get_parent(), (global_position + attacker.global_position) / 2.0, Color(0.66, 0.89, 0.95))
	if attacker and attacker.has_method("on_parried"):
		attacker.on_parried()


func _on_weapon_changed() -> void:
	melee.damage = weapon.current_value()
	_update_hud()


func _update_hud() -> void:
	hud.set_health(health.health, health.max_health)
	hud.set_heal_charges(health.heal_charges, health.max_heal_charges)
	hud.set_ecos(ecos)


func _refresh_pause_menu() -> void:
	var abilities := {}
	for id in ABILITY_NAMES:
		abilities[ABILITY_NAMES[id]] = has_ability(id)
	pause_menu.show_character(health.health, health.max_health, ecos, weapon.level + 1, weapon.current_value(), abilities)
