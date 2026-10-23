class_name RailPlatform
extends AnimatableBody2D
## Plataforma sobre carril: una plataforma de **un solo sentido** (se pisa por arriba
## y se atraviesa desde abajo) que va y viene en línea recta entre dos extremos. Lleva
## encima a quien la pise: es un cuerpo cinemático con movimiento sincronizado con la
## física (`sync_to_physics`), de modo que un `CharacterBody2D` apoyado en ella la
## acompaña sin patinar con su propio `move_and_slide()`.
##
## El recorrido va del punto de partida (su posición al nacer) a `end_offset` más
## allá. Tres modos:
## - CONTINUOUS: va y viene sin parar y espera `wait_time` en cada extremo.
## - ON_DEMAND: espera en el inicio. Se mueve al final cuando alguien la pisa o
##   cuando está puesta su `activation_flag`; en el final espera mientras haya alguien
##   encima o la marca siga puesta, y `return_delay` segundos después vuelve sola.
## - TRAVEL: un viaje de A a B. Con alguien a bordo, `action_interact` la manda al
##   otro extremo; con `activation_flag`, la marca puesta la lleva al final y borrada,
##   al inicio. Se queda donde llega.
##
## **Nunca aplasta**: si algo la bloquea (un sólido o un cuerpo de `blocker_groups` en
## su camino, o un techo a menos de `rider_height` sobre quien lleva encima) se para y,
## si dura más de `blocked_time`, retrocede (va al otro extremo) y durante `wait_time` no atiende llamadas. Al tener marca, la
## lee del FlagStore (se busca con `FlagStore.find(self)` y se reintenta hasta tenerlo);
## si la marca ya estaba puesta al encontrarlo (partida cargada), nace en el final.
##
## El dibujo es un rectángulo con su carril; los colores son exports.

enum Mode { CONTINUOUS, ON_DEMAND, TRAVEL }

## Llega a un extremo (`at_end`: el final; false: el inicio).
signal arrived(at_end: bool)
## Se ha frenado por un obstáculo y da la vuelta.
signal retreated

@export var mode: Mode = Mode.CONTINUOUS
## Dónde acaba el recorrido, relativo al punto de partida (píxeles).
@export var end_offset: Vector2 = Vector2(0.0, -96.0)
## Tamaño de la plataforma (px); su origen es el centro.
@export var size: Vector2 = Vector2(32.0, 8.0)
## Píxeles por segundo.
@export var speed: float = 80.0
## Espera en cada extremo (CONTINUOUS) y, tras un retroceso, antes de volver a
## hacer caso a quien la llama (así no choca una y otra vez al instante).
@export var wait_time: float = 1.5
## ON_DEMAND: segundos que espera en el final antes de volver sola.
@export var return_delay: float = 8.0
## Segundos de bloqueo antes de retroceder.
@export var blocked_time: float = 0.3
## Hueco que debe quedar sobre quien va encima al subir (altura de un cuerpo).
@export var rider_height: float = 48.0
## Marca de FlagStore que la manda (ON_DEMAND y TRAVEL); vacío = ninguna.
@export var activation_flag: StringName = &""
@export var action_interact: StringName = &"interact"
## Grupos de quien cuenta como pasajero.
@export var rider_groups: Array[StringName] = [&"player"]
## Grupos de cuerpos que la bloquean si están en su camino.
@export var blocker_groups: Array[StringName] = [&"player", &"enemy"]
@export var body_color: Color = Color(0.36, 0.28, 0.2)
@export var edge_color: Color = Color(0.62, 0.5, 0.36)
@export var rail_color: Color = Color(0.2, 0.19, 0.24)

## Si va hacia el final (true) o hacia el inicio (false).
var target_end: bool = false

const PROBE := 3.0

var _start: Vector2
var _end: Vector2
var _pause_left: float = 0.0
var _hold_left: float = 0.0
var _cooldown_left: float = 0.0
var _blocked_for: float = 0.0
var _moving: bool = false
var _snap_pending: bool = false
var _store: FlagStore


func _ready() -> void:
	add_to_group(&"no_checkpoint")  # se mueve: no es suelo seguro al que volver
	sync_to_physics = true
	collision_mask = 0
	_start = position
	target_end = mode == Mode.CONTINUOUS
	_end = _start + end_offset
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	shape.one_way_collision = true
	shape.one_way_collision_margin = 4.0
	add_child(shape)
	queue_redraw()


func _physics_process(delta: float) -> void:
	_ensure_store()
	var rider := has_rider()
	if _pause_left > 0.0:
		_pause_left -= delta
		return
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)
	if _cooldown_left <= 0.0:
		_decide(delta, rider)
	_move(delta, rider)


## TRAVEL: la interacción con alguien a bordo la manda al otro extremo. Se consume
## el evento (como la palanca del jugador) para que no active además otra cosa.
func _unhandled_input(event: InputEvent) -> void:
	if mode == Mode.TRAVEL and not _moving and event.is_action_pressed(action_interact) and has_rider():
		target_end = not target_end
		get_viewport().set_input_as_handled()


## Si hay un pasajero (de `rider_groups`) apoyado encima.
func has_rider() -> bool:
	if not is_inside_tree():
		return false
	var rect := RectangleShape2D.new()
	rect.size = Vector2(size.x - 2.0, 6.0)
	var query := _query(rect, global_position + Vector2(0.0, -size.y / 2.0 - 2.0))
	for hit in get_world_2d().direct_space_state.intersect_shape(query, 8):
		if _in_groups(hit.get("collider") as Node, rider_groups):
			return true
	return false


## Si está en el extremo `at_end` (final o inicio), a menos de un píxel.
func is_at(at_end: bool) -> bool:
	return position.distance_to(_end if at_end else _start) < 1.0


## Si está esperando en un extremo (CONTINUOUS).
func is_waiting() -> bool:
	return _pause_left > 0.0


func _decide(delta: float, rider: bool) -> void:
	match mode:
		Mode.ON_DEMAND:
			var called := rider or _flag_on()
			if called:
				target_end = true
			if is_at(true) and not _moving:
				_hold_left = return_delay if called else _hold_left - delta
				if _hold_left <= 0.0:
					target_end = false
		Mode.TRAVEL:
			pass  # la manda la marca (_on_flag_changed) o la interacción (_unhandled_input)


func _move(delta: float, rider: bool) -> void:
	if _snap_pending:
		_snap_pending = false
		position = _end
		queue_redraw()
		return
	var goal := _end if target_end else _start
	var to_goal := goal - position
	if to_goal.length() < 0.001:
		if _moving:
			_arrive()
		return
	var direction := to_goal.normalized()
	if _is_blocked(direction, rider):
		_moving = false
		_blocked_for += delta
		if _blocked_for >= blocked_time:
			_blocked_for = 0.0
			target_end = not target_end
			_cooldown_left = wait_time
			retreated.emit()
		return
	_blocked_for = 0.0
	_moving = true
	position = position.move_toward(goal, speed * delta)
	queue_redraw()
	if position.is_equal_approx(goal):
		_arrive()


func _arrive() -> void:
	_moving = false
	if mode == Mode.ON_DEMAND and target_end:
		_hold_left = return_delay
	var at_end := target_end
	if mode == Mode.CONTINUOUS:
		target_end = not target_end
		_pause_left = wait_time
	arrived.emit(at_end)


## ¿Hay algo en el camino de la plataforma hacia `direction`? Un sólido o un
## cuerpo de `blocker_groups` (los que van encima no cuentan al subir), o, con un
## pasajero, un techo sin hueco para su altura.
func _is_blocked(direction: Vector2, rider: bool) -> bool:
	var space := get_world_2d().direct_space_state
	var ahead := RectangleShape2D.new()
	ahead.size = size - Vector2(2.0, 2.0)
	for hit in space.intersect_shape(_query(ahead, global_position + direction * PROBE), 8):
		var collider := hit.get("collider") as Node
		if not _in_groups(collider, blocker_groups):
			return true
		if direction.y >= -0.1:
			return true  # un cuerpo en su camino, y no es quien va encima
	if rider and direction.y < -0.1:
		var head := RectangleShape2D.new()
		head.size = Vector2(size.x - 2.0, rider_height)
		var center := global_position + Vector2(0.0, -size.y / 2.0 - rider_height / 2.0 - PROBE)
		for hit in space.intersect_shape(_query(head, center), 8):
			if not _in_groups(hit.get("collider") as Node, blocker_groups):
				return true
	return false


func _query(shape: Shape2D, at: Vector2) -> PhysicsShapeQueryParameters2D:
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, at)
	query.collision_mask = 1
	query.exclude = [get_rid()]
	return query


func _in_groups(node: Node, groups: Array[StringName]) -> bool:
	if node == null:
		return false
	for group in groups:
		if node.is_in_group(group):
			return true
	return false


func _flag_on() -> bool:
	return _store != null and activation_flag != &"" and bool(_store.get_flag(activation_flag, false))


func _ensure_store() -> void:
	if _store != null or activation_flag == &"":
		return
	_store = FlagStore.find(self)
	if _store == null:
		return
	_store.changed.connect(_on_flag_changed)
	if _flag_on() and mode != Mode.CONTINUOUS:
		# Partida cargada con la marca puesta: nace en el final, sin viajar.
		target_end = true
		_snap_pending = true
		_hold_left = return_delay


func _on_flag_changed(id: StringName) -> void:
	if id == activation_flag and mode == Mode.TRAVEL:
		target_end = _flag_on()


func _draw() -> void:
	var rail_from := _start - position
	var rail_to := _end - position
	draw_line(rail_from, rail_to, rail_color, 2.0)
	draw_rect(Rect2(-size / 2.0, size), body_color)
	draw_rect(Rect2(-size / 2.0, Vector2(size.x, 2.0)), edge_color)
