extends CharacterBody2D
## Personaje jugable. Orquesta los componentes de core/ y añade lo propio de
## este juego: los Ecos, el Eco que marca la última muerte, el HUD y los menús.
##
## El orden de _physics_process es deliberado (ver docs/arquitectura.md).

## Hay algo que conviene guardar: al descansar en un Ancla (y al mejorar el Filo
## en ella) y al reaparecer tras morir. Quien guarda es el mundo
## (game/levels/world.gd), que también guarda al cambiar de sala.
signal save_requested
## Se ha elegido en la pausa volver al menú principal (lo atiende el mundo).
signal title_requested

const EchoScene := preload("res://game/echo/echo.tscn")
const Hud := preload("res://game/ui/hud.gd")
const AnchorMenu := preload("res://game/ui/anchor_menu.gd")
const PauseMenu := preload("res://game/ui/pause_menu.gd")
const Skills := preload("res://game/player/skills.gd")
const ABILITY_NAMES := {
	&"dash": "Dash",
	&"double_jump": "Doble salto",
	&"wall_jump": "Salto de pared",
}
const MESSAGE_SECONDS := 3.0
## Hasta dónde mira el jugador, a cada lado, si hay suelo al resbalar de un enemigo.
const SLIDE_PROBE_DISTANCE := 56.0
## Y cuánto por debajo cuenta como "suelo" (más allá es un foso).
const SLIDE_PROBE_DEPTH := 100.0
## Para textos que hay que leer (inscripciones): tiempo mínimo y por carácter,
## a un ritmo de lectura tranquilo (unos 15 caracteres por segundo).
const MIN_READING_SECONDS := 4.0
const READING_CHARS_PER_SECOND := 15.0

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
@onready var skills: SkillTree = $SkillTree
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
	for skill in Skills.LIST:
		skills.define(skill.id, PackedInt32Array(skill.costs), skill.requires)
	skills.changed.connect(_apply_skills)
	anchor_menu.skill_requested.connect(_on_skill_requested)
	pause_menu.title_requested.connect(title_requested.emit)
	_apply_skills()


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
	_slide_off_enemies()
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
	save_requested.emit()
	_refresh_anchor_menu()
	anchor_menu.open()


## El mapa del mundo (lo crea el mundo, ver game/levels/world.gd): lo dibujan el
## minimapa del HUD y el mapa del menú de pausa.
func set_map(data: MapData) -> void:
	hud.set_map(data)
	pause_menu.set_map(data)


## Al entrar por primera vez en una sala, su nombre aparece un momento.
func announce_area(title: String) -> void:
	_show_message(title)


## Lo que el jugador guarda en la partida (ver game/levels/world.gd). No se
## guarda dónde está ni su vida: al cargar se reaparece en la última Ancla, con
## la vida y las curaciones completas, como al descansar.
func get_save_data() -> Dictionary:
	var abilities: Array[String] = []
	for id in ABILITY_NAMES:
		if has_ability(id):
			abilities.append(String(id))
	var data := {
		spawn = [respawn.spawn_position.x, respawn.spawn_position.y],
		ecos = ecos,
		skills = skills.get_save_data(),
		abilities = abilities,
	}
	if is_instance_valid(active_echo):
		data.echo = {
			position = [active_echo.global_position.x, active_echo.global_position.y],
			ecos = active_echo.ecos_held,
		}
	return data


## Restaura lo guardado por `get_save_data()`. Hay que llamarlo con el jugador
## ya dentro del mundo (el Eco se crea junto a él). Desconfía de los tipos: una
## partida editada a mano o estropeada se carga hasta donde tiene sentido, sin
## errores. Que las posiciones sigan siendo válidas en el mundo actual lo
## comprueba el mundo.
func load_save_data(data: Dictionary) -> void:
	var spawn: Variant = _vector_from(data.get("spawn"))
	if spawn != null:
		respawn.set_checkpoint(spawn)
		global_position = spawn
		velocity = Vector2.ZERO
	ecos = maxi(0, _int_from(data.get("ecos")))
	skills.load_save_data(data.get("skills"))
	health.restore()
	var abilities: Variant = data.get("abilities")
	if abilities is Array:
		for id in abilities:
			if id is String and ABILITY_NAMES.has(StringName(id)):
				_grant_ability(StringName(id))
	var echo: Variant = data.get("echo")
	if echo is Dictionary:
		var echo_position: Variant = _vector_from(echo.get("position"))
		if echo_position != null:
			_spawn_echo(echo_position, maxi(0, _int_from(echo.get("ecos"))))
	_update_hud()


## [x, y] guardado como JSON -> Vector2, o null si no tiene esa forma.
static func _vector_from(value: Variant) -> Variant:
	if value is Array and value.size() == 2 and (value[0] is float or value[0] is int) and (value[1] is float or value[1] is int):
		return Vector2(value[0], value[1])
	return null


static func _int_from(value: Variant) -> int:
	return int(value) if value is float or value is int else 0


func add_ecos(amount: int) -> void:
	ecos += amount
	_update_hud()


## Esc o Start abren la pausa. Esta capa solo funciona con el juego en pausa, así
## que la tecla que la abre la escucha el jugador, que sí recibe entrada mientras se
## juega. Es la acción `pause` y no `ui_cancel`: en el mando, el botón de cancelar
## (B / Círculo) es curarse.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause") and not get_tree().paused:
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
	if _grant_ability(id):
		_show_message("Has recordado: %s" % ABILITY_NAMES[id])


func _grant_ability(id: StringName) -> bool:
	match id:
		&"dash":
			dash.unlocked = true
		&"double_jump":
			motor.max_air_jumps = 1
		&"wall_jump":
			motor.can_wall_jump = true
		_:
			push_warning("Habilidad desconocida: %s" % id)
			return false
	return true


## Gasta Ecos en subir un nivel de una mejora del árbol de habilidades. Devuelve
## false si no se pudo (sin Ecos suficientes, bloqueada o al máximo). Lo llama el
## menú del Ancla.
func try_buy_skill(id: StringName) -> bool:
	if not skills.can_buy(id, ecos):
		return false
	ecos -= skills.next_cost(id)
	skills.advance(id)
	_update_hud()
	return true


func _on_skill_requested(id: StringName) -> void:
	if try_buy_skill(id):
		save_requested.emit()
	_refresh_anchor_menu()


## Los datos del árbol para el menú: una entrada por mejora, con su nivel, coste y textos.
func _skill_menu_data() -> Array:
	var data := []
	for skill in Skills.LIST:
		var level: int = skills.level(skill.id)
		var maxed: bool = skills.is_max(skill.id)
		data.append({
			id = skill.id, name = skill.name, text = skill.text, branch = skill.branch, row = skill.row,
			requires = skill.requires, level = level, max = skills.max_level(skill.id),
			cost = skills.next_cost(skill.id), unlocked = skills.is_unlocked(skill.id),
			affordable = skills.can_buy(skill.id, ecos),
			missing = maxi(0, skills.next_cost(skill.id) - ecos),
			now = Skills.describe(skill.id, level),
			next = "" if maxed else Skills.describe(skill.id, level + 1),
		})
	return data


func _refresh_anchor_menu() -> void:
	anchor_menu.show_state(ecos, _skill_menu_data(), PackedStringArray(Skills.BRANCHES))


func die() -> void:
	# El Eco de una muerte anterior que no se recuperó se pierde para siempre.
	if is_instance_valid(active_echo):
		active_echo.queue_free()

	# Siempre se marca el punto de muerte, aunque no llevaras Ecos: sirve de
	# señal de "aquí moriste" (el mapa lo marca). Se coloca en el último suelo
	# pisado, no donde acaba la caída, para que sea alcanzable.
	_spawn_echo(respawn.last_grounded_position, ecos)

	ecos = 0
	health.reset_health()
	respawn.respawn(self)
	_update_hud()
	_reset_world()
	save_requested.emit()


func _spawn_echo(at: Vector2, ecos_held: int) -> void:
	var echo := EchoScene.instantiate()
	echo.ecos_held = ecos_held
	echo.global_position = at
	get_parent().add_child(echo)
	active_echo = echo


## Al morir o descansar, todo lo "reiniciable" (enemigos) vuelve a su estado
## inicial. Ver EntitySpawner en core/objects/.
func _reset_world() -> void:
	get_tree().call_group(&"resettable", &"reset")


## Un enemigo no es un suelo: si se cae encima de uno, el jugador resbala hacia un
## lado (el mismo retroceso de un golpe, sin daño) y no puede quedarse subido. Prefiere
## el lado contrario al centro del enemigo, pero no el que acabe en el vacío.
func _slide_off_enemies() -> void:
	for i in get_slide_collision_count():
		var hit := get_slide_collision(i)
		var other := hit.get_collider() as Node2D
		if other != null and other.is_in_group("enemy") and hit.get_normal().y < -0.5:
			var side := 1 if hit.get_position().x >= other.global_position.x else -1
			if not _has_ground_beside(side) and _has_ground_beside(-side):
				side = -side
			knockback.apply(side)
			return


## ¿Hay suelo del mundo a ~56 px a un lado, por debajo de los pies?
func _has_ground_beside(side: int) -> bool:
	var from := global_position + Vector2(side * SLIDE_PROBE_DISTANCE, 0.0)
	var query := PhysicsRayQueryParameters2D.create(from, from + Vector2(0.0, SLIDE_PROBE_DEPTH), 1, [get_rid()])
	return not get_world_2d().direct_space_state.intersect_ray(query).is_empty()


func _update_animation() -> void:
	if dash.is_dashing:
		animator.play("dash")
		return
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
	# Si el golpe llega a mitad de un ataque propio, se corta (arco y animación)
	# antes de poner la pose de encajar el golpe: comparten el mismo hueco de
	# "acción" del SheetAnimator, y si no, la pose se vería con el brillo del
	# espadazo aún desvaneciéndose por encima (ver enemy.gd take_hit()).
	attack_visual.reset()
	animator.play_action("hit")


## Feedback de un golpe propio que alcanza algo: chispazo y un temblor leve.
func _on_hit_landed(body: Node) -> void:
	HitSpark.spawn(get_parent(), (body as Node2D).global_position)
	screen_shake.shake(3.0, 0.08)
	HitStop.trigger(self)


func _show_message(text: String, duration: float = MESSAGE_SECONDS) -> void:
	_message_id += 1
	var this_message := _message_id
	hud.set_message(text)
	await get_tree().create_timer(duration).timeout
	if this_message == _message_id:
		hud.set_message("")


## Contrato "lector": lo llama core/objects/readable.gd. El tiempo en pantalla
## se ajusta a lo largo que sea el texto, para dar tiempo a leerlo.
func read_text(text: String) -> void:
	var duration := maxf(MIN_READING_SECONDS, text.length() / READING_CHARS_PER_SECOND)
	_show_message(text, duration)


## Golpe desviado: sin daño, con efectos azules, y el atacante queda aturdido.
func _on_parried(attacker: Node) -> void:
	parry_flash.flash()
	screen_shake.shake(5.0, 0.12)
	if attacker is Node2D:
		HitSpark.spawn(get_parent(), (global_position + attacker.global_position) / 2.0, Color(0.66, 0.89, 0.95))
	if attacker and attacker.has_method("on_parried"):
		attacker.on_parried(Skills.stat(&"contragolpe", skills.level(&"contragolpe")))


## Aplica a las estadísticas del personaje los niveles actuales del árbol. Si sube la
## vida máxima o los frascos, también se llenan en esa cantidad (comprar vida cura).
func _apply_skills() -> void:
	var old_health := health.max_health
	var old_flasks := health.max_heal_charges
	health.max_health = int(Skills.stat(&"vitalidad", skills.level(&"vitalidad")))
	health.max_heal_charges = int(Skills.stat(&"frascos", skills.level(&"frascos")))
	health.invulnerability_time = Skills.stat(&"temple", skills.level(&"temple"))
	if health.max_health > old_health:
		health.health += health.max_health - old_health
	health.health = mini(health.health, health.max_health)
	if health.max_heal_charges > old_flasks:
		health.heal_charges += health.max_heal_charges - old_flasks
	health.heal_charges = mini(health.heal_charges, health.max_heal_charges)
	melee.damage = int(Skills.stat(&"filo", skills.level(&"filo")))
	melee.cooldown = Skills.stat(&"ritmo", skills.level(&"ritmo"))
	melee.reach = Skills.stat(&"alcance", skills.level(&"alcance"))
	melee.set_facing(motor.facing)
	parry.window = Skills.stat(&"guardia", skills.level(&"guardia"))
	dash.cooldown = Skills.stat(&"impulso", skills.level(&"impulso"))
	_update_hud()


func _update_hud() -> void:
	hud.set_health(health.health, health.max_health)
	hud.set_heal_charges(health.heal_charges, health.max_heal_charges)
	hud.set_ecos(ecos)


func _refresh_pause_menu() -> void:
	var abilities := {}
	for id in ABILITY_NAMES:
		abilities[ABILITY_NAMES[id]] = has_ability(id)
	var stats := PackedStringArray([
		"%s  ·  %s" % [Skills.describe(&"filo", skills.level(&"filo")), Skills.describe(&"alcance", skills.level(&"alcance"))],
		Skills.describe(&"ritmo", skills.level(&"ritmo")),
	])
	pause_menu.show_character(health.health, health.max_health, health.heal_charges, health.max_heal_charges, ecos, stats, abilities)
