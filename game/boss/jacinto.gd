extends "res://game/boss/boss_base.gd"
## Jacinto, el Último Segador: campesino de los bancales que sigue segando un campo
## vacío (ver docs/jefes.md y docs/personajes.md). Segundo jefe del juego, en La Era.
##
## Vida simple repartida en tres fases por marcas (`PhaseTracker`, 36 puntos: 24 / 12 / 0)
## y sin armadura. Elige el ataque con un `AttackPicker` (bolsa barajada con pesos por
## fase y por distancia). Todo daño tiene aviso: **amarillo** (el cuerpo se tiñe y sale
## la marca en el suelo) = se puede parar; **rojo** (marca con bandas) = solo esquivar.
##
## Ataques (aviso de la fase 1; en las fases 2 y 3 se acorta, sin bajar del mínimo):
## - Siega baja: barrido a ras delante, 120 px. Salto, parry o dash.
## - Vuelta amplia: giro de 360° con la hoz, radio 130 px, 2 de daño. **Entrar por dentro**:
##   a menos de 45 px de él no llega el arco. Retroceder más de 130 px también vale.
## - Paso de segador: avanza 3 baldosas y siega.
## - Hoz lanzada (fase 2): un boomerang a ras de suelo. Mientras la hoz está fuera, tiene
##   las manos vacías y recibe el doble de daño. Un parry la devuelve contra él.
## - Trepa y picado (fase 2): sube por el muro de la derecha (el salto de pared que el
##   jugador aún no tiene), se agarra y cae sobre una sombra roja. Solo sale si el jugador
##   lleva más de 6 s sin acercarse.
## - Llamada (fases 2 y 3): levanta espantapájaros (tope 2 vivos, sin Ecos).
## - Tres vueltas (fase 3, el remate): dos vueltas amarillas y una tercera roja a ras de
##   suelo, más ancha: saltarla o retroceder.
##
## Quien lo coloca (game/boss/boss_room.gd) le da los límites de la sala (`arena_left`,
## `arena_right`) y lo despierta con `wake()`. La barra lee `core_hp` / `core_health`.

## Ha muerto del todo (tras su animación): se libera justo después.
signal defeated
## Cambió la vida o la fase (para la barra de vida).
signal status_changed

enum State {
	DORMANT, WAKING, IDLE, WALK,
	SWING_WINDUP, SWING_STRIKE,
	SPIN_WINDUP, SPIN, TRIPLE_GAP,
	STEP_WINDUP, STEP_STRIKE,
	THROW_WINDUP, THROW_EMPTY,
	CLIMB_RUN, CLIMB, WALL_HOLD, DIVE,
	SUMMON_WINDUP, SUMMON_END,
	RECOVER, STAGGER, TRANSITION, DYING,
}

const HozScene := preload("res://game/boss/hoz.tscn")
const EspantapajarosScene := preload("res://game/enemy/enemy_espantapajaros.tscn")
const ImpactDust := preload("res://game/boss/impact_dust.gd")

const TELEGRAPH_COLOR := Color(1.0, 0.85, 0.3)
const TELEGRAPH_RED := Color(1.0, 0.45, 0.4)
const STUN_COLOR := Color(0.7, 0.9, 1.0)
const DORMANT_COLOR := Color(0.6, 0.6, 0.66)
const FLASH_COLOR := Color(1.0, 0.45, 0.4)
const FLASH_TIME := 0.08
const SPARK_COLOR := Color(0.95, 0.8, 0.45)
const EXPOSED_NUMBER_COLOR := Color(1.0, 0.85, 0.3)

## Cuerpo de 32 x 80 (el jugador, 24 x 48).
const HALF_HEIGHT := 40.0
const HALF_WIDTH := 16.0
const SEPARATION := 14.0
## La vida de la pelea (36) y dónde termina cada fase (24, 12 y 0).
const HEALTH := 36
const PHASE_FLOORS: Array[int] = [24, 12, 0]
## Cuánto se acorta el aviso en cada fase (nunca por debajo del mínimo del ataque).
const WINDUP_SCALE := [1.0, 0.85, 0.75]
const RECOVERY := [1.0, 0.95, 0.9]
const THINK := [0.6, 0.45, 0.35]

# --- Los ataques: (aviso base, aviso mínimo) en segundos ----------------------------
const SWING_WINDUP := [0.75, 0.40]
const SPIN_WINDUP := [0.90, 0.70]
const STEP_WINDUP := [0.55, 0.40]
const THROW_WINDUP := [0.60, 0.40]
const SUMMON_WINDUP := [1.00, 0.90]
const TRIPLE_WINDUP := [0.90, 0.90]
## Alcance (px) del barrido y del paso, y tamaño del barrido a ras (alto).
const SWING_REACH := 124.0
const SWING_HEIGHT := 36.0
const STEP_DISTANCE := 48.0
const STEP_REACH := 104.0
const STEP_HEIGHT := 44.0
## La vuelta: radio, hueco seguro pegado a él (< 45 px), duración y daño. La tercera: radio y daño.
const SPIN_RADIUS := 130.0
const SPIN_INNER := 45.0
const SPIN_TIME := 0.5
const SPIN_DAMAGE := 2
const THIRD_RADIUS := 160.0
const THIRD_WARNING := 0.6
const TRIPLE_GAP_A := 0.35
## La hoz lanzada: ida (s) y distancia máxima; manos vacías como mucho esto.
const THROW_OUT_TIME := 0.7
const THROW_EMPTY_TIME := 2.2
## El picado: altura del agarre sobre el suelo, subida, espera amarilla, radio y daño.
const CLIMB_HEIGHT := 130.0
const CLIMB_TIME := 0.5
const HOLD_TIME := 0.5
const DIVE_RADIUS := 60.0
const DIVE_DAMAGE := 2
const DIVE_MIN_FLIGHT := 0.5
## Segundos sin acercarse a menos de 4 baldosas para que la Trepa pueda salir.
const FLEE_TIME := 6.0
const CLOSE_DISTANCE := 64.0
## Fotogramas de la animación en los que la hoja toca el suelo (swing_low, step_slash).
## Ver tools/rig_jacinto.js: si se redibuja, hay que mover estas constantes.
const SWING_IMPACT_FRAME := 2
const SWING_FPS := 26.0
const STEP_IMPACT_FRAME := 3
const STEP_FPS := 24.0
## Marcas del suelo de las vueltas y rangos a los que sale cada ataque cuerpo a cuerpo.
const RANGE_MELEE := 150.0
const RANGE_STEP := 250.0
const WALK_SPEED := 120.0
const CLIMB_RUN_SPEED := 300.0
const WAKE_TIME := 1.6
const TRANSITION_TIME := 2.0
const STAGGER_TIME := 1.6
const SUMMON_TIME := 0.45
const DEATH_STAGE_TIMES := [1.0, 0.0, 2.2, 0.6]

@export var display_name: String = "Jacinto, el Último Segador"
@export var ecos_reward: int = 60
@export var gravity: float = 2250.0

## Límites de la sala (coordenadas globales): los fija quien lo coloca.
var arena_left: float = -INF
var arena_right: float = INF
var arena_ceiling: float = -INF
## Mitad de su altura (lo lee boss_room.gd para apoyarlo en el suelo).
var half_height: float = HALF_HEIGHT

var state: State = State.DORMANT
## Si el golpe que viene se puede parar (lo lee la guardia del jugador, ver ParryComponent).
var parryable: bool = true
var phases := PhaseTracker.new()
var picker := AttackPicker.new()
var spawner := Spawner.new()

var _timer: float = 0.0
var _facing: int = -1
var _flash_left: float = 0.0
var _attack: StringName = &""
var _pending: StringName = &""
var _walk_goal: float = 0.0
var _forced_next: StringName = &""
var _attack_hit: bool = false
var _since_close: float = 0.0
var _zones: Array[TelegraphZone] = []
var _hoz: Projectile
var _has_scythe: bool = true
var _spin_left: float = 0.0
var _spin_done: bool = false
var _triple_step: int = 0
var _step_dx: float = 0.0
var _floor_y: float = 0.0
var _dive_from: Vector2
var _dive_to: Vector2
var _dive_time: float = 0.5
var _dive_t: float = 0.0
var _death_stage: int = 0
var _walk_to_wall_x: float = 0.0
var _final_camera: Camera2D
var _state_clock: float = 0.0
## Para la prueba de "ningún estado dura de más": el estado en el que está y desde cuándo.
var _clock_state: State = State.DORMANT

@onready var visual: Sprite2D = $Visual
@onready var animator: SheetAnimator = $SheetAnimator


func _ready() -> void:
	add_to_group("enemy")
	add_to_group(&"pogoable")
	phases.setup(HEALTH, PHASE_FLOORS)
	phases.floor_reached.connect(_on_floor_reached)
	_set_attacks(0)
	picker.limit(&"spin", 2, 5)
	picker.limit(&"triple", 1, 4)
	picker.limit(&"dive", 1, 3)
	spawner.scene = EspantapajarosScene
	spawner.max_alive = 2
	add_child(spawner)
	_set_facing(_facing)
	animator.frame_changed.connect(_on_animation_frame)


func _exit_tree() -> void:
	super._exit_tree()
	_final_camera_off()
	if is_instance_valid(spawner):
		spawner.clear()


## Vida que ve la barra (sin armadura: `armor_max()` es 0 y la barra la oculta).
var armor_hp: int = 0
var core_hp: int:
	get:
		return phases.health
var core_health: int:
	get:
		return phases.max_health


func armor_max() -> int:
	return 0


func is_fighting() -> bool:
	return state != State.DORMANT and state != State.DYING


func _physics_process(delta: float) -> void:
	_timer -= delta
	_flash_left = maxf(_flash_left - delta, 0.0)
	_track_state(delta)
	if _distance_to_player() > CLOSE_DISTANCE and state != State.DORMANT:
		_since_close += delta
	else:
		_since_close = 0.0
	if _uses_gravity():
		if is_on_floor():
			velocity.y = 0.0
		else:
			velocity.y += gravity * delta

	match state:
		State.WAKING:
			velocity.x = 0.0
			if _timer <= 0.0:
				_to_idle(0.5)
		State.IDLE:
			velocity.x = 0.0
			_face_player()
			if _timer <= 0.0:
				_decide()
		State.WALK:
			_face_player()
			velocity.x = _facing * WALK_SPEED
			if _distance_to_player() <= _walk_goal or _timer <= 0.0 or _blocked_ahead():
				_launch(_pending)
		State.SWING_WINDUP:
			velocity.x = 0.0
			if _timer <= 0.0:
				_swing_strike()
		State.SWING_STRIKE:
			velocity.x = 0.0
			if _timer <= 0.0:
				_recover()
		State.SPIN_WINDUP:
			velocity.x = 0.0
			if _timer <= 0.0:
				_spin_start()
		State.SPIN:
			velocity.x = 0.0
			_spin_left -= delta
			_ring_check()
			# (un parry en el golpe del anillo lo ha aturdido ya: no se vuelve a decidir su estado)
			if state == State.SPIN and _spin_left <= 0.0:
				_spin_end()
		State.TRIPLE_GAP:
			velocity.x = 0.0
			if _timer <= 0.0:
				_triple_gap_end()
		State.STEP_WINDUP:
			velocity.x = 0.0
			if _timer <= 0.0:
				_step_strike()
		State.STEP_STRIKE:
			velocity.x = _facing * _step_dx / 0.12 if _timer > 0.16 else 0.0
			if _timer <= 0.0:
				_recover()
		State.THROW_WINDUP:
			velocity.x = 0.0
			if _timer <= 0.0:
				_throw_release()
		State.THROW_EMPTY:
			velocity.x = 0.0
			if _timer <= 0.0:
				_throw_end()
		State.CLIMB_RUN:
			_climb_run()
		State.CLIMB:
			velocity = Vector2(_facing * 40.0, -CLIMB_HEIGHT / CLIMB_TIME)
			if _timer <= 0.0:
				_wall_hold()
		State.WALL_HOLD:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				_dive_start()
		State.DIVE:
			_dive_step(delta)
		State.SUMMON_WINDUP:
			velocity.x = 0.0
			if _timer <= 0.0:
				_summon_release()
		State.SUMMON_END:
			velocity.x = 0.0
			if _timer <= 0.0:
				_recover()
		State.RECOVER:
			velocity.x = 0.0
			if _timer <= 0.0:
				_to_idle(THINK[phases.phase])
		State.STAGGER:
			velocity.x = 0.0
			if _timer <= 0.0:
				_to_idle(0.3)
		State.TRANSITION:
			velocity.x = 0.0
			if _timer <= 0.0:
				_transition_end()
		State.DYING:
			_dying_step(delta)
		_:
			velocity.x = 0.0

	if state != State.DIVE and state != State.WALL_HOLD:
		_resolve_overlap_with_player()
		move_and_slide()
	global_position.x = clampf(global_position.x, arena_left + HALF_WIDTH, arena_right - HALF_WIDTH)
	if state != State.DYING:
		visual.modulate = FLASH_COLOR if _flash_left > 0.0 else _tint()
	if state == State.IDLE or state == State.DORMANT:
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
	animator.play_action("summon", true, 1.2)
	Sfx.play(&"jacinto_alert", global_position, -3.0)
	_shake(5.0, 0.5)
	var player := _player()
	if player:
		player.read_text("Ya vienen. Hay que terminar la era antes de que lleguen.")
		if not player.health.damaged.is_connected(_on_player_damaged):
			player.health.damaged.connect(_on_player_damaged)
	status_changed.emit()


## Contrato "golpeable" (ver docs/arquitectura.md). Dormido, en la transición y muriendo
## no recibe daño. Con las manos vacías o aturdido recibe el doble; una hoz devuelta, otro doble.
func take_hit(damage: int, _from_direction: int, attacker: Node = null) -> void:
	if state == State.DORMANT or state == State.WAKING or state == State.TRANSITION or state == State.DYING:
		return
	if phases.at_floor():
		return
	var dealt := damage
	if attacker is Projectile:
		dealt *= 2
	var exposed := is_exposed()
	if exposed:
		dealt *= 2
	var applied := phases.damage(dealt)
	if applied <= 0:
		return
	_flash_left = FLASH_TIME
	Sfx.play(&"jacinto_hurt", global_position, -7.0)
	HitSpark.spawn(get_parent(), global_position + Vector2(0.0, -4.0), SPARK_COLOR, 1.0)
	DamageNumber.spawn(get_parent(), global_position + Vector2(0.0, -half_height - 14.0), applied, EXPOSED_NUMBER_COLOR if exposed else Color(1.0, 0.97, 0.9))
	if state != State.DYING:
		status_changed.emit()


## Le han desviado el golpe (la guardia lo avisa tanto si fue su barrido como una zona suya).
func on_parried(extra_stun: float = 0.0) -> void:
	match state:
		State.SWING_WINDUP, State.SWING_STRIKE, State.STEP_WINDUP, State.STEP_STRIKE, State.SPIN, State.SPIN_WINDUP, State.TRIPLE_GAP:
			if parryable:
				_enter_stagger(STAGGER_TIME + extra_stun)


## ¿Recibe el doble de daño ahora? Aturdido, o con las manos vacías mientras la hoz anda fuera.
func is_exposed() -> bool:
	return state == State.STAGGER or (state == State.THROW_EMPTY and not _has_scythe)


## Para las pruebas: lanza un ataque ahora mismo sin esperar a que lo elija.
func debug_force_attack(id: StringName) -> void:
	if state == State.DYING or state == State.DORMANT:
		return
	_cancel_attack()
	_launch(id)


## Lo que dura (en segundos) el aviso del ataque `id` en la fase actual.
func windup_time(id: StringName) -> float:
	var data: Array = {
		&"swing": SWING_WINDUP, &"spin": SPIN_WINDUP, &"step": STEP_WINDUP, &"throw": THROW_WINDUP,
		&"summon": SUMMON_WINDUP, &"triple": TRIPLE_WINDUP,
	}.get(id, SWING_WINDUP)
	return maxf(float(data[0]) * float(WINDUP_SCALE[phases.phase]), float(data[1]))


# --- Fases ------------------------------------------------------------------------

func _on_floor_reached(phase: int) -> void:
	if phases.is_last_phase():
		_die()
	else:
		_start_transition(phase)


func _set_attacks(phase: int) -> void:
	match phase:
		0:
			picker.set_attacks({ &"swing": 2, &"spin": 2, &"step": 2 })
		1:
			picker.set_attacks({ &"swing": 2, &"spin": 2, &"step": 2, &"throw": 2, &"dive": 1, &"summon": 1 })
		_:
			picker.set_attacks({ &"swing": 1, &"spin": 2, &"step": 2, &"throw": 1, &"dive": 1, &"summon": 1, &"triple": 1 })


## Pausa de 2 s entre fases: no ataca, no recibe daño y el jugador puede curarse.
func _start_transition(_phase: int) -> void:
	_cancel_attack()
	_attack = &""
	state = State.TRANSITION
	_timer = TRANSITION_TIME
	velocity = Vector2.ZERO
	animator.release_action()
	animator.play_action("summon", true, 1.2)
	Sfx.play(&"jacinto_alert", global_position, -3.0)
	Sfx.play(&"straw_rise", global_position, -6.0)
	_shake(6.0, 0.5)
	status_changed.emit()


func _transition_end() -> void:
	phases.advance()
	_set_attacks(phases.phase)
	picker.reset()
	# Demostración del ataque nuevo: la hoz en la fase 2, la Llamada en la 3.
	_forced_next = &"throw" if phases.phase == 1 else &"summon"
	animator.release_action()
	_to_idle(0.5)
	status_changed.emit()


# --- Decisiones -------------------------------------------------------------------

func _decide() -> void:
	var id := _forced_next
	_forced_next = &""
	if id == &"":
		id = picker.pick(_bias())
	if id == &"":
		_to_idle(0.5)
		return
	_attack = id
	_attack_hit = false
	# Los ataques cuerpo a cuerpo salen a su alcance: si está lejos, primero se acerca.
	var reach := _range_of(id)
	if reach > 0.0 and _distance_to_player() > reach:
		_pending = id
		_walk_goal = reach - 20.0
		state = State.WALK
		_timer = 1.6
		return
	_launch(id)


## Lo que pesa cada ataque según la distancia (de forma gradual, sin umbrales rígidos).
func _bias() -> Dictionary:
	var t := clampf(_distance_to_player() / 320.0, 0.0, 1.0)
	return {
		&"swing": lerpf(2.0, 0.2, t),
		&"spin": lerpf(2.0, 0.25, t),
		&"triple": lerpf(2.0, 0.3, t),
		&"step": lerpf(0.6, 2.4, t),
		&"throw": lerpf(0.3, 2.0, t),
		&"dive": 4.0 if _since_close >= FLEE_TIME else 0.0,
		&"summon": (1.0 if spawner.alive_count() == 0 else 0.4) if spawner.can_spawn() else 0.0,
	}


func _range_of(id: StringName) -> float:
	match id:
		&"swing", &"spin", &"triple":
			return RANGE_MELEE
		&"step":
			return RANGE_STEP
	return 0.0


func _launch(id: StringName) -> void:
	_attack = id
	_pending = &""
	_attack_hit = false
	match id:
		&"swing":
			_swing_windup()
		&"spin":
			_spin_windup()
		&"step":
			_step_windup()
		&"throw":
			_throw_windup()
		&"dive":
			_climb_start()
		&"summon":
			_summon_windup()
		&"triple":
			_triple_start()
		_:
			_to_idle(0.5)


func _blocked_ahead() -> bool:
	return is_on_wall() or not _has_ground(global_position.x + _facing * 40.0, feet_y())


# --- Siega baja ---------------------------------------------------------------------

func _swing_windup() -> void:
	parryable = true
	state = State.SWING_WINDUP
	_timer = windup_time(&"swing")
	animator.release_action()
	animator.play_action("windup_swing", true, _timer)
	Sfx.play(&"jacinto_attack", global_position, -5.0)
	var center := Vector2(global_position.x + _facing * (8.0 + SWING_REACH / 2.0), feet_y() - SWING_HEIGHT / 2.0)
	var zone := _add_zone(TelegraphZone.Shape.RECT, Vector2(SWING_REACH, SWING_HEIGHT), center, _timer + SWING_IMPACT_FRAME / SWING_FPS, 1, true)
	zone.blow_direction = _facing


func _swing_strike() -> void:
	state = State.SWING_STRIKE
	_timer = 0.28
	animator.play_action("swing_low")
	Sfx.play(&"hoz_swing", global_position, -4.0)


# --- Vuelta amplia y tres vueltas --------------------------------------------------

func _spin_windup() -> void:
	parryable = true
	state = State.SPIN_WINDUP
	_timer = windup_time(&"spin")
	animator.release_action()
	animator.play_action("windup_spin", true, _timer)
	Sfx.play(&"jacinto_attack", global_position, -5.0)
	_ring_warning(_timer, false)


## La marca del arco: la banda peligrosa (entre `SPIN_INNER` y `SPIN_RADIUS`) con el hueco
## seguro en el centro. Solo avisa: el daño lo da `_ring_check()` mientras gira.
func _ring_warning(duration: float, red: bool) -> void:
	var zone := _add_zone(TelegraphZone.Shape.CIRCLE, Vector2(SPIN_RADIUS, 0.0), _hip(), duration, 0, not red)
	zone.inner_radius = SPIN_INNER
	zone.target_group = &"nadie"
	zone.flash_time = SPIN_TIME


func _spin_start() -> void:
	state = State.SPIN
	_spin_left = SPIN_TIME
	_spin_done = false
	animator.release_action()
	animator.play_action("spin", true)
	Sfx.play(&"hoz_spin", global_position, -4.0)
	_shake(3.0, 0.2)


## Mientras gira: el jugador que esté en el anillo (ni demasiado pegado ni más lejos del radio) recibe el golpe, una vez.
func _ring_check() -> void:
	if _spin_done:
		return
	var player := _player()
	if player == null:
		return
	var distance := player.global_position.distance_to(_hip())
	if distance < SPIN_INNER or distance > SPIN_RADIUS:
		return
	if player.health.is_invulnerable():
		return
	_spin_done = true
	var side := 1 if player.global_position.x >= global_position.x else -1
	player.take_hit(SPIN_DAMAGE, side, self)


func _spin_end() -> void:
	if _attack == &"triple":
		_triple_spin_ended()
		return
	if _attack_hit:
		picker.ban(&"spin", 2)
	_recover(1.1)


func _triple_start() -> void:
	parryable = true
	_triple_step = 0
	state = State.SPIN_WINDUP
	_timer = windup_time(&"triple")
	animator.release_action()
	animator.play_action("windup_spin", true, _timer)
	Sfx.play(&"jacinto_attack", global_position, -4.0)
	_ring_warning(_timer, false)


## Termina cada vuelta de las tres: tras la primera, un respiro corto con el aviso de la segunda
## (amarilla); tras la segunda, la marca roja a ras de suelo de la tercera (que se salta); tras
## la tercera, la recuperación larga.
func _triple_spin_ended() -> void:
	_triple_step += 1
	if _triple_step == 1:
		_triple_gap(TRIPLE_GAP_A, true)
	elif _triple_step == 2:
		_triple_gap(THIRD_WARNING, false)
		var center := Vector2(global_position.x, feet_y() - 12.0)
		var zone := _add_zone(TelegraphZone.Shape.RECT, Vector2(THIRD_RADIUS * 2.0, 24.0), center, THIRD_WARNING, SPIN_DAMAGE, false)
		zone.flash_time = SPIN_TIME
	else:
		_recover(1.4)


func _triple_gap(duration: float, can_parry: bool) -> void:
	parryable = can_parry
	state = State.TRIPLE_GAP
	_timer = duration
	animator.release_action()
	animator.play_action("windup_spin", true, duration)
	if can_parry:
		_ring_warning(duration, false)


## Acaba el respiro: gira la segunda vuelta (con el anillo que hiere) o la tercera (la hiere ya la marca roja).
func _triple_gap_end() -> void:
	if _triple_step == 1:
		_spin_start()
		return
	state = State.SPIN
	_spin_left = SPIN_TIME
	_spin_done = true
	animator.release_action()
	animator.play_action("spin", true)
	Sfx.play(&"hoz_spin", global_position, -3.0)
	_shake(5.0, 0.3)


# --- Paso de segador ---------------------------------------------------------------

func _step_windup() -> void:
	parryable = true
	# Avanza 3 baldosas si hay suelo delante; si no, se queda donde está.
	var room := (arena_right - HALF_WIDTH - global_position.x) if _facing > 0 else (global_position.x - arena_left - HALF_WIDTH)
	_step_dx = minf(STEP_DISTANCE, maxf(room, 0.0))
	if not _has_ground(global_position.x + _facing * _step_dx, feet_y()):
		_step_dx = 0.0
	state = State.STEP_WINDUP
	_timer = windup_time(&"step")
	animator.release_action()
	animator.play_action("windup_swing", true, _timer)
	Sfx.play(&"jacinto_attack", global_position, -5.0)
	var length := _step_dx + STEP_REACH
	var center := Vector2(global_position.x + _facing * (8.0 + length / 2.0), feet_y() - STEP_HEIGHT / 2.0)
	var zone := _add_zone(TelegraphZone.Shape.RECT, Vector2(length, STEP_HEIGHT), center, _timer + STEP_IMPACT_FRAME / STEP_FPS, 1, true)
	zone.blow_direction = _facing


func _step_strike() -> void:
	state = State.STEP_STRIKE
	_timer = 0.28
	animator.play_action("step_slash")
	Sfx.play(&"hoz_swing", global_position, -4.0)


# --- Hoz lanzada -------------------------------------------------------------------

func _throw_windup() -> void:
	parryable = true
	state = State.THROW_WINDUP
	_timer = windup_time(&"throw")
	animator.release_action()
	animator.play_action("windup_throw", true, _timer)
	Sfx.play(&"jacinto_attack", global_position, -5.0)


func _throw_release() -> void:
	state = State.THROW_EMPTY
	_timer = THROW_EMPTY_TIME
	_has_scythe = false
	animator.release_action()
	animator.play_action("throw", true)
	Sfx.play(&"hoz_swing", global_position, -2.0)
	var distance := clampf(_distance_to_player() + 40.0, 100.0, 260.0)
	_hoz = HozScene.instantiate() as Projectile
	_hoz.speed = distance / THROW_OUT_TIME
	_hoz.outbound_time = THROW_OUT_TIME
	_hoz.return_to = self
	get_parent().add_child(_hoz)
	_hoz.global_position = global_position + Vector2(_facing * 30.0, 4.0)
	_hoz.launch(Vector2(_facing, 0.0))
	_hoz.returned.connect(_on_hoz_returned)


func _on_hoz_returned() -> void:
	_has_scythe = true
	if state == State.THROW_EMPTY:
		_timer = minf(_timer, 0.35)
		animator.release_action()
		animator.play_action("catch")
		Sfx.play(&"hoz_ground", global_position, -9.0)
		status_changed.emit()


func _throw_end() -> void:
	if is_instance_valid(_hoz):
		_hoz.queue_free()
	_hoz = null
	_has_scythe = true
	_recover(0.5)


# --- Trepa y picado ----------------------------------------------------------------

func _climb_start() -> void:
	parryable = false
	state = State.CLIMB_RUN
	_timer = 3.0
	animator.release_action()
	Sfx.play(&"jacinto_attack", global_position, -4.0)


## Corre hacia el muro de la derecha (el único liso de la sala) y, al llegar, lo trepa.
func _climb_run() -> void:
	var wall_x := arena_right - HALF_WIDTH - 1.0
	_facing = 1
	_set_facing(1)
	velocity.x = CLIMB_RUN_SPEED if global_position.x < wall_x - 6.0 else 0.0
	animator.play("walk")
	if global_position.x >= wall_x - 6.0 or _timer <= 0.0 or is_on_wall():
		_floor_y = feet_y()
		state = State.CLIMB
		_timer = CLIMB_TIME
		animator.release_action()
		animator.play_action("climb", true, 0.0)
		Sfx.play(&"jump", global_position, -6.0)


func _wall_hold() -> void:
	state = State.WALL_HOLD
	_timer = HOLD_TIME
	velocity = Vector2.ZERO
	animator.release_action()
	animator.play_action("wall_hold", true)
	Sfx.play(&"wall_jump", global_position, -3.0)


func _dive_start() -> void:
	var player := _player()
	var target_x := global_position.x - 120.0
	var target_floor := _floor_y
	if player:
		target_x = clampf(player.global_position.x, arena_left + HALF_WIDTH + 30.0, arena_right - HALF_WIDTH - 40.0)
		target_floor = _floor_below(target_x, player.global_position.y - 8.0, _floor_y)
	_dive_from = global_position
	_dive_to = Vector2(target_x, target_floor - half_height)
	_dive_time = maxf(DIVE_MIN_FLIGHT, absf(target_x - global_position.x) / 900.0)
	_dive_t = 0.0
	state = State.DIVE
	_timer = _dive_time
	_set_facing(1 if target_x >= global_position.x else -1)
	_facing = 1 if target_x >= global_position.x else -1
	animator.release_action()
	animator.play_action("dive", true, _dive_time)
	Sfx.play(&"boss_leap", global_position, -6.0)
	# La sombra roja: marca en el suelo, no se puede parar.
	_add_zone(TelegraphZone.Shape.CIRCLE, Vector2(DIVE_RADIUS, 0.0), Vector2(target_x, target_floor - 10.0), _dive_time, DIVE_DAMAGE, false)


func _dive_step(delta: float) -> void:
	_dive_t = minf(_dive_t + delta / _dive_time, 1.0)
	var t := _dive_t
	global_position = Vector2(lerpf(_dive_from.x, _dive_to.x, t), lerpf(_dive_from.y, _dive_to.y, t * t))
	velocity = Vector2.ZERO
	if _dive_t >= 1.0:
		_dive_land()


func _dive_land() -> void:
	global_position = _dive_to
	velocity = Vector2.ZERO
	Sfx.play(&"boss_land", global_position, -5.0)
	_shake(6.0, 0.25)
	ImpactDust.spawn(get_parent(), global_position.x, feet_y(), 70.0)
	var player := _player()
	if player:
		_ghost(player)
	_recover()


# --- Llamada -----------------------------------------------------------------------

func _summon_windup() -> void:
	parryable = false
	state = State.SUMMON_WINDUP
	_timer = windup_time(&"summon")
	animator.release_action()
	animator.play_action("summon", true, _timer)
	Sfx.play(&"jacinto_alert", global_position, -5.0)
	Sfx.play(&"straw_rise", global_position, -5.0)


func _summon_release() -> void:
	state = State.SUMMON_END
	_timer = SUMMON_TIME
	_shake(4.0, 0.25)
	var count := 2 if phases.phase < 2 else 3
	var player := _player()
	var base_x := player.global_position.x if player else global_position.x
	var offsets := [-150.0, 150.0, 0.0]
	for i in count:
		var x := clampf(base_x + offsets[i], arena_left + 50.0, arena_right - 50.0)
		if absf(x - global_position.x) < 70.0:
			x = clampf(global_position.x - _facing * 140.0, arena_left + 50.0, arena_right - 50.0)
		var floor_y := _floor_below(x, feet_y() - 30.0, feet_y())
		var scarecrow := spawner.spawn(get_parent(), Vector2(x, floor_y - 24.0), _setup_scarecrow)
		if scarecrow == null:
			break
		scarecrow.ai.wake(1 if x < base_x else -1)


## Espantapájaros invocado: vida 3, sin Ecos, y se borra con los restos de la pelea.
func _setup_scarecrow(scarecrow: Node) -> void:
	scarecrow.ecos_reward = 0
	scarecrow.get_node("HealthComponent").max_health = 3
	scarecrow.add_to_group(&"boss_debris")


# --- Estados comunes ---------------------------------------------------------------

func _recover(time: float = -1.0) -> void:
	state = State.RECOVER
	_timer = RECOVERY[phases.phase] if time < 0.0 else time
	animator.release_action()
	# El resultado del ataque (si dañó o no) alimenta la equidad del selector.
	if _attack != &"":
		picker.report(_attack, _attack_hit)
		_attack = &""


func _to_idle(think_time: float) -> void:
	state = State.IDLE
	_timer = think_time
	parryable = true
	animator.release_action()


func _enter_stagger(duration: float) -> void:
	_cancel_attack()
	state = State.STAGGER
	_timer = duration
	velocity.x = 0.0
	animator.release_action()
	animator.play("stagger")
	if _attack != &"":
		picker.report(_attack, false)
	_attack = &""
	status_changed.emit()


## Anula lo que quedaba del ataque en curso: marcas de aviso, la hoz y las invocaciones no
## (esas siguen: son parte de la pelea).
func _cancel_attack() -> void:
	for zone in _zones:
		if is_instance_valid(zone):
			zone.cancel()
	_zones.clear()
	if is_instance_valid(_hoz):
		_hoz.queue_free()
	_hoz = null
	_has_scythe = true
	_spin_left = 0.0
	_pending = &""
	velocity.x = 0.0


func _add_zone(shape: TelegraphZone.Shape, size: Vector2, center: Vector2, duration: float, damage: int, can_parry: bool) -> TelegraphZone:
	var alive: Array[TelegraphZone] = []
	for old in _zones:
		if is_instance_valid(old) and not old.is_resolved:
			alive.append(old)
	_zones = alive
	var zone := TelegraphZone.new()
	zone.shape_kind = shape
	zone.size = size
	zone.duration = duration
	zone.damage = damage
	zone.parryable = can_parry
	zone.z_index = 1
	zone.add_to_group(&"boss_debris")
	get_parent().add_child(zone)
	zone.global_position = center
	zone.parried.connect(_on_zone_parried)
	zone.resolved.connect(_on_zone_resolved)
	_zones.append(zone)
	return zone


func _on_zone_parried() -> void:
	on_parried(0.0)


func _on_zone_resolved(hit_bodies: Array) -> void:
	if not hit_bodies.is_empty():
		_attack_hit = true


func _on_player_damaged(_amount: int) -> void:
	if state != State.IDLE and state != State.RECOVER and state != State.DORMANT and state != State.WAKING:
		_attack_hit = true


## El golpe llega con el fotograma de impacto: al tocar la hoja el suelo suena y salta el polvo.
func _on_animation_frame(animation: String, frame: int) -> void:
	if animation == "swing_low" and frame == SWING_IMPACT_FRAME or animation == "step_slash" and frame == STEP_IMPACT_FRAME:
		Sfx.play(&"hoz_ground", global_position + Vector2(_facing * 100.0, 0.0), -3.0)
		_shake(3.0, 0.12)


# --- Muerte -------------------------------------------------------------------------

func _die() -> void:
	_cancel_attack()
	_final_camera_on()
	spawner.clear()
	for debris in get_tree().get_nodes_in_group(&"boss_debris"):
		debris.queue_free()
	state = State.DYING
	_death_stage = 0
	_timer = DEATH_STAGE_TIMES[0]
	velocity = Vector2.ZERO
	visual.modulate = Color.WHITE
	animator.release_action()
	animator.play_action("death", true, DEATH_STAGE_TIMES[0])
	Sfx.play(&"jacinto_die", global_position, -2.0)
	_shake(6.0, 0.6)
	status_changed.emit()


## Mientras muere, la cámara se queda con él (el jugador puede estar al otro lado de la arena)
## y al terminar vuelve a la del jugador.
func _final_camera_on() -> void:
	var player := _player()
	var view := player.get_node_or_null("Camera2D") as Camera2D if player else null
	if view == null:
		return
	_final_camera = Camera2D.new()
	_final_camera.limit_left = view.limit_left
	_final_camera.limit_right = view.limit_right
	_final_camera.limit_top = view.limit_top
	_final_camera.limit_bottom = view.limit_bottom
	_final_camera.limit_smoothed = true
	_final_camera.position_smoothing_enabled = true
	_final_camera.position_smoothing_speed = 3.0
	add_child(_final_camera)
	_final_camera.global_position = view.get_screen_center_position()
	_final_camera.make_current()
	_final_camera.reset_smoothing()
	_final_camera.position = Vector2(0.0, -30.0)


func _final_camera_off() -> void:
	if not is_instance_valid(_final_camera):
		return
	var player := _player()
	var view := player.get_node_or_null("Camera2D") as Camera2D if player else null
	if view != null:
		view.make_current()
	_final_camera.queue_free()
	_final_camera = null


## Cae y baja la hoz, camina al muro de bancal, apoya la mano y el campo vuelve a tener trigo
## un instante; después se desvanece. Cuatro etapas con tiempos en DEATH_STAGE_TIMES.
func _dying_step(delta: float) -> void:
	match _death_stage:
		0:
			velocity.x = 0.0
			if _timer <= 0.0:
				_death_stage = 1
				animator.release_action()
				_walk_to_wall_x = arena_right - HALF_WIDTH - 24.0
				_set_facing(1 if _walk_to_wall_x >= global_position.x else -1)
				_timer = 6.0
		1:
			animator.play("walk")
			var direction := signf(_walk_to_wall_x - global_position.x)
			velocity.x = direction * clampf(absf(_walk_to_wall_x - global_position.x) / 1.6, 70.0, 330.0)
			velocity.y = 0.0
			if absf(_walk_to_wall_x - global_position.x) < 4.0 or _timer <= 0.0 or is_on_wall():
				velocity.x = 0.0
				_set_facing(1)
				_death_stage = 2
				_timer = DEATH_STAGE_TIMES[2]
				animator.release_action()
				animator.play_action("release", true, DEATH_STAGE_TIMES[2])
				Sfx.play(&"wheat_bloom", global_position, -4.0)
				var player := _player()
				if player:
					player.read_text("Qué tarde se ha hecho. ¿Habéis comido?")
		2:
			velocity.x = 0.0
			if _timer <= 0.0:
				_death_stage = 3
				_timer = DEATH_STAGE_TIMES[3]
				var tween := create_tween()
				tween.tween_property(visual, "modulate:a", 0.0, DEATH_STAGE_TIMES[3])
				tween.tween_callback(_finish_death)
		_:
			velocity.x = 0.0
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y += gravity * delta


func _finish_death() -> void:
	_final_camera_off()
	var player := _player()
	if player:
		player.add_ecos(ecos_reward)
	defeated.emit()
	queue_free()


# --- Utilidades ---------------------------------------------------------------------

## Color del cuerpo según el estado: apagado dormido, amarillo mientras avisa de un golpe que
## se puede parar, rojo mientras avisa de uno que no, azulado aturdido.
func _tint() -> Color:
	match state:
		State.DORMANT:
			return DORMANT_COLOR
		State.SWING_WINDUP, State.SPIN_WINDUP, State.STEP_WINDUP, State.THROW_WINDUP, State.WALL_HOLD:
			return TELEGRAPH_COLOR
		State.TRIPLE_GAP:
			return TELEGRAPH_COLOR if parryable else TELEGRAPH_RED
		State.DIVE:
			return TELEGRAPH_RED
		State.STAGGER:
			return STUN_COLOR
	return Color.WHITE


func feet_y() -> float:
	return global_position.y + half_height


## Centro del arco de las vueltas (la cadera, un poco bajo el centro del cuerpo).
func _hip() -> Vector2:
	return global_position + Vector2(0.0, 10.0)


func _uses_gravity() -> bool:
	return state != State.CLIMB and state != State.WALL_HOLD and state != State.DIVE and state != State.DYING


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


func _resolve_overlap_with_player() -> void:
	if _ghosted == null:
		return
	var away := _ghost_push(HALF_WIDTH, half_height, SEPARATION, -_facing)
	if away != 0:
		velocity.x = away * 260.0


## Vigilante de la prueba: cuánto lleva en el estado actual.
func _track_state(delta: float) -> void:
	if state != _clock_state:
		_clock_state = state
		_state_clock = 0.0
	_state_clock += delta
