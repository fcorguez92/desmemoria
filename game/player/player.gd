extends CharacterBody2D
## Personaje jugable. Orquesta los componentes de core/ y añade lo propio de
## este juego: los Ecos, el Eco que marca la última muerte y el HUD.
##
## El orden de _physics_process es deliberado (ver docs/arquitectura.md).

const EchoScene := preload("res://game/echo/echo.tscn")

var ecos: int = 0
## Eco de la última muerte, si aún no se recuperó.
var active_echo: Node = null

@onready var motor: PlatformerMotor = $PlatformerMotor
@onready var dash: DashComponent = $DashComponent
@onready var health: HealthComponent = $HealthComponent
@onready var melee: MeleeAttackComponent = $MeleeAttackComponent
@onready var respawn: RespawnComponent = $RespawnComponent
@onready var hit_flash: HitFlashComponent = $HitFlashComponent
@onready var visual: Polygon2D = $Visual
@onready var health_label: Label = $HUD/HealthLabel
@onready var ecos_label: Label = $HUD/EcosLabel
@onready var heal_label: Label = $HUD/HealLabel


func _ready() -> void:
	add_to_group("player")
	motor.facing_changed.connect(_on_facing_changed)
	health.changed.connect(_update_hud)
	health.damaged.connect(_on_damaged)
	health.died.connect(die)
	_update_hud()


func _physics_process(delta: float) -> void:
	respawn.track_ground(self)
	motor.step(self, delta)

	if Input.is_action_just_pressed("attack"):
		melee.try_attack(self, motor.facing)
	if Input.is_action_just_pressed("heal"):
		health.use_heal_charge()

	# El dash pisa la velocity, así que va después del movimiento normal.
	dash.step(self, motor.facing, delta)

	move_and_slide()

	if respawn.is_out_of_bounds(self):
		die()


## Contrato "golpeable" (ver docs/arquitectura.md).
func take_hit(damage: int, _from_direction: int) -> void:
	health.take_hit(damage)


## Contrato de checkpoint: lo llama core/objects/checkpoint.gd.
func rest_at(anchor_position: Vector2) -> void:
	respawn.set_checkpoint(anchor_position)
	health.restore()
	_reset_world()


func add_ecos(amount: int) -> void:
	ecos += amount
	_update_hud()


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


func _on_facing_changed(facing: int) -> void:
	visual.scale.x = facing
	melee.set_facing(facing)


func _on_damaged(_amount: int) -> void:
	hit_flash.flash()


func _update_hud() -> void:
	health_label.text = "Vida: %d/%d" % [health.health, health.max_health]
	ecos_label.text = "Ecos: %d" % ecos
	heal_label.text = "Curación: %d/%d" % [health.heal_charges, health.max_heal_charges]
