extends CharacterBody2D
## El Centinela Hueco: la armadura vacía de un Custodio de la Orden, que sigue
## guardando el Aljibe por costumbre. Jefe de la primera zona; ver docs/jefes.md.
##
## La pelea tiene tres fases. En cada una hay que **romper la armadura** (aguanta
## `ARMOR[fase]` puntos de daño, sin aturdirla ni apartarla) y entonces queda
## **expuesto**: arrodillado, con el cascarón de dentro al aire, durante unos
## segundos. Solo ahí se le hace daño de verdad (al núcleo). Si al levantarse
## no se ha bajado de la marca de la fase (`CORE_FLOORS`), repone la armadura y
## sigue en la misma fase; si sí, pasa a la siguiente y se enfurece (`rage`).
## Un parry en su mazazo también lo deja expuesto un momento, sin romper nada.
##
## Ataques (siempre con aviso, ver PHASES para los tiempos):
## - Mazazo: golpe de área delante de él y una onda de polvo por el suelo (se
##   salta, o se desvía con un parry y vuelve contra él). Desde la fase 2 caen rocas.
## - Salto: se agazapa y cae junto al jugador; el golpe es rasante, se evita saltando.
## - Furia: al empezar las fases 2 y 3, una serie de mazazos en el sitio con ondas
##   a los dos lados y rocas por toda la sala.
##
## Quien lo coloca (game/boss/boss_room.gd) le da los límites de la sala con
## `arena_left`, `arena_right` y `arena_ceiling`, y lo despierta con `wake()`.

## Ha muerto del todo (tras su animación): se libera justo después.
signal defeated
## Cambió la armadura, el núcleo o la fase (para la barra de vida).
signal status_changed

enum State {
	DORMANT, WAKING, IDLE, WALK,
	SLAM_WINDUP, SLAM_STRIKE, LEAP_CROUCH, LEAP_AIR, RECOVER,
	RAGE_WINDUP, RAGE_STRIKE, RAGE_GAP,
	STAGGER, GETUP, DYING,
}

const ShockwaveScene := preload("res://game/boss/shockwave.tscn")
const RockScene := preload("res://game/boss/falling_rock.tscn")

const TELEGRAPH_COLOR := Color(1.0, 0.85, 0.3)
const STUN_COLOR := Color(0.7, 0.9, 1.0)
const DORMANT_COLOR := Color(0.55, 0.55, 0.6)
const FLASH_COLOR := Color(1.0, 0.45, 0.4)
const FLASH_TIME := 0.08
const ARMOR_SPARK_COLOR := Color(0.85, 0.8, 0.7)
const CORE_SPARK_COLOR := Color(0.85, 0.2, 0.18)

## Puntos de daño que aguanta la armadura en cada fase.
const ARMOR := [8, 9, 10]
## Vida del núcleo al terminar cada fase (empieza en `core_health`).
const CORE_FLOORS := [10, 5, 0]
## Mitad de la altura de su cuerpo (sus pies están a esta distancia del origen).
const HALF_HEIGHT := 80.0
## Mitad de su anchura (el cuerpo mide 112 x 160).
const HALF_WIDTH := 56.0
## Alcance del mazazo: si el jugador está más cerca, ataca; si no, se acerca.
const SLAM_RANGE := 230.0
const WALK_RANGE := 180.0
## Dónde cae la cabeza del mazo, delante de sus pies.
const SLAM_REACH := 150.0
## A qué distancia del jugador cae tras el salto (no encima: ahí no se puede estar).
const LEAP_STANDOFF := 90.0
## Si el jugador está al menos esto por debajo de sus pies, baja de un tablón.
const DROP_IF_BELOW := 60.0
## Como el jugador al bajar de un tablón: se hunde un poco y cae.
const DROP_DISTANCE := 5.0
const DROP_SPEED := 60.0
## Fotograma de la animación en el que la cabeza del mazo toca el suelo (strike) y en el
## que el cuerpo se estrella contra él (land): ahí, y no antes, se hace el daño y se
## sueltan las ondas y las rocas. Ver art/source/centinela.sprite / tools/rig_centinela.js.
const STRIKE_IMPACT_FRAME := 5
const LAND_IMPACT_FRAME := 1
## Tiempos en segundos.
const WAKE_TIME := 1.6
const SLAM_STRIKE_TIME := 0.3
const GETUP_TIME := 0.6
const STAGGER_TIME := 3.0
const PARRY_STAGGER_TIME := 1.5
const LEAP_FLIGHT_TIME := 0.85
const RAGE_WINDUP_TIME := 0.5
const RAGE_GAP_TIME := 0.5
const DEATH_TIME := 1.8
## Lo que dura la animación de morir (12 fotogramas a 10 fps) antes de desvanecerse.
const DEATH_ANIMATION_TIME := 1.2
## Ajuste por fase: aviso, recuperación y pausa entre ataques; agachado del
## salto y su probabilidad; rocas y ondas del mazazo y del aterrizaje; mazazos de
## la furia con la que empieza la fase.
const PHASES := [
	{ windup = 0.85, recovery = 0.9, think = 0.6, crouch = 0.55, leap_chance = 0.35, slam_rocks = 0, slam_both = false, land_rocks = 0, land_waves = false, rage = 0 },
	{ windup = 0.7, recovery = 0.8, think = 0.45, crouch = 0.5, leap_chance = 0.4, slam_rocks = 2, slam_both = false, land_rocks = 2, land_waves = false, rage = 4 },
	{ windup = 0.58, recovery = 0.65, think = 0.3, crouch = 0.42, leap_chance = 0.35, slam_rocks = 3, slam_both = true, land_rocks = 2, land_waves = true, rage = 6 },
]

@export var display_name: String = "El Centinela Hueco"
@export var core_health: int = 15
@export var ecos_reward: int = 40
@export var gravity: float = 2250.0
@export var walk_speed: float = 100.0

## Límites de la sala (coordenadas globales): los fija quien lo coloca.
var arena_left: float = -INF
var arena_right: float = INF
var arena_ceiling: float = -INF

var state: State = State.DORMANT
var phase: int = 0
var armor_hp: int = ARMOR[0]
var core_hp: int = 15

var _timer: float = 0.0
var _facing: int = -1
var _air_time: float = 0.0
var _rage_left: int = 0
var _rage_pending: bool = false
var _last_was_leap: bool = false
var _flash_left: float = 0.0
## Acaba de aterrizar del salto y aún no ha dado el golpe (llega en el fotograma de impacto).
var _landing: bool = false

@onready var visual: Sprite2D = $Visual
@onready var animator: SheetAnimator = $SheetAnimator
@onready var slam_melee: MeleeAttackComponent = $SlamMelee
@onready var land_melee: MeleeAttackComponent = $LandMelee


func _ready() -> void:
	add_to_group("enemy")
	core_hp = core_health
	armor_hp = ARMOR[0]
	_set_facing(_facing)
	animator.frame_changed.connect(_on_animation_frame)


func _physics_process(delta: float) -> void:
	_timer -= delta
	_flash_left = maxf(_flash_left - delta, 0.0)
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y += gravity * delta

	match state:
		State.WAKING:
			velocity.x = 0.0
			if _timer <= 0.0:
				_to_idle(0.4)
		State.IDLE:
			velocity.x = 0.0
			_face_player()
			_drop_if_player_is_below()
			if _timer <= 0.0:
				_decide()
		State.WALK:
			_face_player()
			_drop_if_player_is_below()
			velocity.x = _facing * walk_speed
			if _distance_to_player() <= WALK_RANGE or _timer <= 0.0:
				_to_idle(0.0)
		State.SLAM_WINDUP:
			velocity.x = 0.0
			if _timer <= 0.0:
				_slam_strike()
		State.SLAM_STRIKE:
			velocity.x = 0.0
			if _timer <= 0.0:
				_recover()
		State.LEAP_CROUCH:
			velocity.x = 0.0
			if _timer <= 0.0:
				_leap()
		State.LEAP_AIR:
			_air_time += delta
			animator.play("jump" if velocity.y < 0.0 else "fall")
			if _air_time > 0.15 and is_on_floor():
				_land()
		State.RECOVER:
			velocity.x = 0.0
			if _timer <= 0.0:
				_to_idle(PHASES[phase].think)
				_drop_if_player_is_below()
		State.RAGE_WINDUP:
			velocity.x = 0.0
			if _timer <= 0.0:
				_rage_strike()
		State.RAGE_STRIKE:
			velocity.x = 0.0
			if _timer <= 0.0:
				_rage_left -= 1
				if _rage_left > 0:
					state = State.RAGE_GAP
					_timer = RAGE_GAP_TIME
				else:
					_recover()
		State.RAGE_GAP:
			velocity.x = 0.0
			if _timer <= 0.0:
				_rage_windup()
		State.STAGGER:
			velocity.x = 0.0
			if _timer <= 0.0:
				_end_stagger()
		State.GETUP:
			velocity.x = 0.0
			if _timer <= 0.0:
				if _rage_pending:
					_rage_pending = false
					_rage_left = PHASES[phase].rage
					_rage_windup()
				else:
					_to_idle(0.3)
		_:
			velocity.x = 0.0

	move_and_slide()
	global_position.x = clampf(global_position.x, arena_left + HALF_WIDTH, arena_right - HALF_WIDTH)
	if state != State.DYING:
		visual.modulate = FLASH_COLOR if _flash_left > 0.0 else _tint()
	if state == State.IDLE:
		animator.play("idle")
	elif state == State.WALK:
		animator.play("walk")


## Quien lo coloca lo despierta cuando empieza la pelea.
func wake() -> void:
	if state != State.DORMANT:
		return
	state = State.WAKING
	_timer = WAKE_TIME
	_face_player()
	Sfx.play(&"centinela_alert", global_position, -2.0)
	_shake(6.0, 0.6)
	status_changed.emit()


## Puntos de armadura de la fase actual (para la barra de vida).
func armor_max() -> int:
	return ARMOR[phase]


## ¿Está la pelea en marcha (despierto y sin haber muerto)?
func is_fighting() -> bool:
	return state != State.DORMANT and state != State.DYING


## Contrato "golpeable" (ver docs/arquitectura.md). La armadura no se aparta ni se
## interrumpe: solo gasta puntos; el núcleo solo se alcanza con ella rota.
func take_hit(damage: int, _from_direction: int, attacker: Node = null) -> void:
	if state == State.DORMANT or state == State.WAKING or state == State.GETUP or state == State.DYING:
		return
	# Una onda devuelta con un parry le hace el doble.
	if attacker is Projectile:
		damage *= 2
	if state == State.STAGGER:
		_hit_core(damage)
	else:
		_hit_armor(damage)


## Le han desviado el mazazo (o el aterrizaje): queda expuesto un momento.
func on_parried(extra_stun: float = 0.0) -> void:
	match state:
		State.SLAM_WINDUP, State.SLAM_STRIKE, State.RAGE_WINDUP, State.RAGE_STRIKE, State.LEAP_AIR, State.RECOVER:
			_enter_stagger(PARRY_STAGGER_TIME + extra_stun)


# --- Daño --------------------------------------------------------------------

func _hit_armor(damage: int) -> void:
	armor_hp = maxi(armor_hp - damage, 0)
	_flash_left = FLASH_TIME
	Sfx.play(&"armor_hit", global_position, -4.0)
	HitSpark.spawn(get_parent(), global_position + Vector2(0.0, -40.0), ARMOR_SPARK_COLOR, 1.3)
	DamageNumber.spawn(get_parent(), global_position + Vector2(0.0, -HALF_HEIGHT - 8.0), damage, Color(0.75, 0.75, 0.8))
	status_changed.emit()
	if armor_hp <= 0:
		Sfx.play(&"armor_break", global_position, -2.0)
		_shake(8.0, 0.3)
		_enter_stagger(STAGGER_TIME)


func _hit_core(damage: int) -> void:
	var floor_hp: int = CORE_FLOORS[phase]
	core_hp = maxi(core_hp - damage, floor_hp)
	_flash_left = FLASH_TIME
	Sfx.play(&"centinela_hurt", global_position, -6.0)
	HitSpark.spawn(get_parent(), global_position + Vector2(0.0, -20.0), CORE_SPARK_COLOR, 1.1)
	DamageNumber.spawn(get_parent(), global_position + Vector2(0.0, -HALF_HEIGHT - 8.0), damage, Color(1.0, 0.85, 0.3))
	status_changed.emit()
	if core_hp <= floor_hp:
		if phase >= PHASES.size() - 1:
			_die()
		else:
			_end_stagger()


func _enter_stagger(duration: float) -> void:
	_landing = false
	state = State.STAGGER
	_timer = duration
	_rage_left = 0
	velocity.x = 0.0
	animator.release_action()
	animator.play("stagger")


## Se levanta: si bajó de la marca de la fase pasa a la siguiente y se enfurece;
## si no, repone la armadura que rompió y sigue igual.
func _end_stagger() -> void:
	if core_hp <= CORE_FLOORS[phase] and phase < PHASES.size() - 1:
		phase += 1
		armor_hp = ARMOR[phase]
		_rage_pending = PHASES[phase].rage > 0
	elif armor_hp <= 0:
		armor_hp = ARMOR[phase]
	state = State.GETUP
	_timer = GETUP_TIME
	animator.play_action("getup", true)
	status_changed.emit()


func _die() -> void:
	state = State.DYING
	_landing = false
	velocity.x = 0.0
	visual.modulate = Color.WHITE
	_rage_left = 0
	animator.release_action()
	animator.play_action("death", true)
	Sfx.play(&"centinela_die", global_position, -2.0)
	_shake(10.0, 1.2)
	# Lo que quedaba en vuelo de su último ataque no debe herir durante la muerte.
	for debris in get_tree().get_nodes_in_group(&"boss_debris"):
		debris.queue_free()
	status_changed.emit()
	var tween := create_tween()
	tween.tween_interval(DEATH_ANIMATION_TIME)
	tween.tween_property(visual, "modulate:a", 0.0, DEATH_TIME - DEATH_ANIMATION_TIME)
	tween.tween_callback(_finish_death)


func _finish_death() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.add_ecos(ecos_reward)
	defeated.emit()
	queue_free()


# --- Decisiones y ataques ------------------------------------------------------

func _decide() -> void:
	var near := _distance_to_player() <= SLAM_RANGE
	var leap: bool = randf() < float(PHASES[phase].leap_chance) and not _last_was_leap
	if not near and not leap and _distance_to_player() > WALK_RANGE * 2.0 and randf() < 0.5:
		state = State.WALK
		_timer = 1.2
		return
	if leap or (not near and not _last_was_leap):
		_start_leap()
	else:
		_start_slam()


func _start_slam() -> void:
	_last_was_leap = false
	state = State.SLAM_WINDUP
	_timer = PHASES[phase].windup
	animator.play_action("windup", true, _timer)
	Sfx.play(&"centinela_attack", global_position, -4.0)


func _slam_strike() -> void:
	state = State.SLAM_STRIKE
	_timer = SLAM_STRIKE_TIME
	animator.play_action("strike")


func _start_leap() -> void:
	_last_was_leap = true
	state = State.LEAP_CROUCH
	_timer = PHASES[phase].crouch
	animator.play_action("crouch", true, _timer)
	Sfx.play(&"centinela_attack", global_position, -4.0)


func _leap() -> void:
	state = State.LEAP_AIR
	_air_time = 0.0
	# Cae un poco antes que el jugador, no encima: ahí no se puede estar.
	var player := _player()
	var target := global_position.x + _facing * 240.0
	var rise := 0.0
	if player:
		var side := signf(player.global_position.x - global_position.x)
		target = player.global_position.x - side * LEAP_STANDOFF
		# Si el jugador está en un tablón más alto, salta hasta su altura (si está más
		# abajo, cae a su lado desde donde esté). Limitado para no salir de la sala.
		rise = clampf(player_feet_y(player) - feet_y(), -200.0, 0.0)
	target = clampf(target, arena_left + HALF_WIDTH, arena_right - HALF_WIDTH)
	velocity.x = (target - global_position.x) / LEAP_FLIGHT_TIME
	# y = vy*t + g*t²/2 = rise al cabo de LEAP_FLIGHT_TIME
	velocity.y = (rise - 0.5 * gravity * LEAP_FLIGHT_TIME * LEAP_FLIGHT_TIME) / LEAP_FLIGHT_TIME
	animator.release_action()
	animator.play("jump")
	Sfx.play(&"boss_leap", global_position, -4.0)


func _land() -> void:
	velocity.x = 0.0
	state = State.RECOVER
	_timer = PHASES[phase].recovery
	_landing = true
	animator.release_action()
	animator.play_action("land")


## El golpe llega en el fotograma de impacto de la animación (ver las constantes
## STRIKE_IMPACT_FRAME y LAND_IMPACT_FRAME).
func _on_animation_frame(animation: String, frame: int) -> void:
	if animation == "strike" and frame == STRIKE_IMPACT_FRAME:
		if state == State.SLAM_STRIKE:
			slam_melee.try_attack(self, _facing)
			_impact(_facing * SLAM_REACH, PHASES[phase].slam_both, PHASES[phase].slam_rocks)
		elif state == State.RAGE_STRIKE:
			slam_melee.try_attack(self, _facing)
			_impact(_facing * SLAM_REACH, true, 2)
	elif animation == "land" and frame == LAND_IMPACT_FRAME and _landing:
		_landing = false
		land_melee.try_attack(self, _facing)
		Sfx.play(&"boss_land", global_position, -2.0)
		_impact(0.0, PHASES[phase].land_waves, PHASES[phase].land_rocks, false)


func _rage_windup() -> void:
	state = State.RAGE_WINDUP
	_timer = RAGE_WINDUP_TIME
	_face_player()
	animator.play_action("windup", true, _timer)
	Sfx.play(&"centinela_attack", global_position, -6.0)


func _rage_strike() -> void:
	state = State.RAGE_STRIKE
	_timer = SLAM_STRIKE_TIME
	animator.play_action("strike")


func _recover() -> void:
	state = State.RECOVER
	_timer = PHASES[phase].recovery


func _to_idle(think_time: float) -> void:
	state = State.IDLE
	_timer = think_time
	animator.release_action()


## Lo que pasa cuando el mazo (o el cuerpo) golpea el suelo: temblor, polvo,
## ondas por el suelo y rocas del techo. `offset_x` es dónde cae el mazo.
func _impact(offset_x: float, both_waves: bool, rocks: int, forward_wave: bool = true) -> void:
	Sfx.play(&"boss_slam", global_position, -2.0)
	_shake(9.0, 0.28)
	var floor_y := global_position.y + HALF_HEIGHT
	var at := Vector2(global_position.x + offset_x, floor_y)
	HitSpark.spawn(get_parent(), at + Vector2(0.0, -14.0), Color(0.7, 0.66, 0.6), 2.0)
	if both_waves:
		_spawn_wave(-1, at.x, floor_y)
		_spawn_wave(1, at.x, floor_y)
	elif forward_wave:
		_spawn_wave(_facing, at.x, floor_y)
	_drop_rocks(rocks, floor_y)


func _spawn_wave(direction: int, from_x: float, floor_y: float) -> void:
	var wave := ShockwaveScene.instantiate() as Projectile
	get_parent().add_child(wave)
	wave.global_position = Vector2(from_x, floor_y - 16.0)
	wave.launch(Vector2(direction, 0.0))


## Rocas que caen del techo: una sobre el jugador (con aviso) y el resto por la sala.
func _drop_rocks(count: int, floor_y: float) -> void:
	if count <= 0 or arena_ceiling == -INF:
		return
	var player := _player()
	for i in count:
		var x := randf_range(arena_left + 60.0, arena_right - 60.0)
		if i == 0 and player:
			x = player.global_position.x
		var rock := RockScene.instantiate()
		get_parent().add_child(rock)
		rock.start(Vector2(x, arena_ceiling + 24.0), floor_y)


# --- Utilidades --------------------------------------------------------------

## Color del cuerpo según el estado: apagado dormido, amarillo mientras avisa de
## un ataque (como los enemigos) y azulado expuesto.
func _tint() -> Color:
	match state:
		State.DORMANT:
			return DORMANT_COLOR
		State.SLAM_WINDUP, State.LEAP_CROUCH, State.RAGE_WINDUP:
			return TELEGRAPH_COLOR
		State.STAGGER:
			return STUN_COLOR
	return Color.WHITE


## Y de los pies del jefe y del jugador (el jugador mide 48 de alto).
func feet_y() -> float:
	return global_position.y + HALF_HEIGHT


func player_feet_y(player: Node2D) -> float:
	return player.global_position.y + 24.0


## Si está sobre un tablón y el jugador está claramente más abajo, baja como lo hace
## el jugador (abajo + salto): se hunde un poco para atravesarlo y cae.
func _drop_if_player_is_below() -> void:
	if not is_on_floor() or not PlatformerMotor.is_standing_on_one_way(self):
		return
	var player := _player()
	if player == null or player_feet_y(player) < feet_y() + DROP_IF_BELOW:
		return
	position.y += DROP_DISTANCE
	velocity.y = DROP_SPEED


func _player() -> Node2D:
	return get_tree().get_first_node_in_group("player") as Node2D


func _distance_to_player() -> float:
	var player := _player()
	return absf(player.global_position.x - global_position.x) if player else INF


func _face_player() -> void:
	var player := _player()
	if player == null:
		return
	var side := int(signf(player.global_position.x - global_position.x))
	if side != 0 and side != _facing:
		_set_facing(side)


func _set_facing(facing: int) -> void:
	_facing = facing
	visual.scale.x = facing
	slam_melee.set_facing(facing)


func _shake(strength: float, duration: float) -> void:
	var player := _player()
	if player and player.get("screen_shake") != null:
		player.screen_shake.shake(strength, duration)
