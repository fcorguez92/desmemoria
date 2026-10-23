extends Node2D
## El mundo: las salas (hijas de Rooms, ver room.gd) colocadas una junto a otra
## en sus posiciones, el jugador y el mapa. Ver docs/mundo.md.
##
## Todas las salas están cargadas a la vez y el jugador pasa de una a otra
## caminando. Este script sabe en qué sala está y, al cambiar:
## - limita la cámara a la sala (con deslizamiento suave, no un corte),
## - muestra u oculta el cielo de fondo (no hay cielo bajo tierra),
## - mueve el límite de caída mortal al fondo de la sala,
## - la primera vez, anuncia su nombre.
## Además, cada paso de físicas descubre en el mapa lo que queda cerca del
## jugador (REVEAL_RADIUS): el mapa solo muestra lo que se ha explorado.
##
## El mapa (MapData, de core/ui) se rellena aquí y se lo pasa al jugador, que lo
## reparte entre el minimapa del HUD y el mapa del menú de pausa.
##
## También guarda la partida, sola, como Hollow Knight: al cambiar de sala, al
## descansar en un Ancla, al reaparecer tras morir y al salir del juego. Al
## abrir el juego se carga y se aparece en la última Ancla (ver docs/nucleo-jugable.md).

const PlayerScene := preload("res://game/player/player.tscn")
## Pantalla de inicio, a la que se vuelve desde la pausa. Por ruta y no con
## preload: ella también apunta a este mundo, y dos escenas no pueden
## precargarse la una a la otra.
const TITLE_SCENE := "res://game/ui/title_screen.tscn"
## La partida de quien juega (el menú principal mira si existe).
const SAVE_PATH := "user://partida.json"

const CELL := 16.0
const PLAYER_HALF_HEIGHT := 24.0
## Cuánto puede bajar el jugador del fondo de su sala antes de morir. Da margen
## para que, al bajar a una sala de abajo, se detecte el cambio de sala antes.
const FALL_MARGIN := 96.0
## Para cambiar de sala hay que adentrarse en la nueva este tanto (y menos que
## FALL_MARGIN): así, saltando justo en una frontera, la cámara no va y viene.
const ROOM_HYSTERESIS := 32.0
## Margen alrededor de la sala actual dentro del cual las salas vecinas siguen vivas.
const ACTIVE_ROOM_MARGIN := 64.0
## Lo que tarda el cielo en aparecer o desaparecer al cambiar de sala: la cámara
## se desliza a la sala nueva y un corte seco se notaría a mitad de camino.
const SKY_FADE_SECONDS := 0.5
## Hasta cuántas baldosas alrededor del jugador se descubre el mapa al pasar.
const REVEAL_RADIUS := 12.0
## Colores del mapa.
const MAP_TILE_COLOR := Color(0.62, 0.6, 0.66)
const MAP_PLANK_COLOR := Color(0.54, 0.33, 0.13)
const PLANK_ATLAS := Vector2i(4, 0)
const MAP_ANCHOR_COLOR := Color(0.3, 0.62, 0.95)
const MAP_ECHO_COLOR := Color(0.75, 0.55, 0.95)
## Cuántos fragmentos de vida hacen falta para una vida máxima más (la fórmula que
## la aplica es K10 y aún no existe: de momento solo se cuentan y se notifican).
const FRAGMENTS_PER_LIFE := 4

## Dónde se guarda la partida. Las pruebas usan otro archivo para no tocar la
## partida de quien juega.
@export var save_path: String = SAVE_PATH

var map_data := MapData.new()
## Marcas permanentes del mundo (puzles, secretos, atajos, objetos de trama; ver
## docs/puzles.md). Las temporales (prefijo t:) se reinician al descansar o morir.
var flags := FlagStore.new()
## Coleccionables recogidos: id -> tipo ("fragment" o "bag"). Los de tipo objeto
## van en `flags` con prefijo "i:". Cada id cuenta una sola vez.
var collected := FlagStore.new()
var player: Node2D
## Sala en la que está el jugador (la última en la que estuvo si ahora mismo no
## está dentro de ninguna, p. ej. saltando por encima del techo del mapa).
var current_room: Node2D
## Si el cielo de fondo se está mostrando (o apareciendo).
var sky_shown: bool = true

var _rooms: Array[Node2D] = []
var _room_rects: Array[Rect2] = []
var _camera: Camera2D
## Última baldosa desde la que se descubrió el mapa: quieto, no hay nada nuevo.
var _last_reveal_cell := Vector2i(-99999, -99999)
var _sky_tween: Tween
var _save_slot: SaveSlot
## Donde aparece el jugador en una partida nueva (el marcador P).
var _start_position: Vector2

@onready var background: CanvasLayer = $Background


func _ready() -> void:
	# Antes que el jugador en cada paso de físicas: si reaparece en otra sala, su
	# límite de caída ya debe ser el de la sala nueva cuando él lo compruebe.
	process_physics_priority = -1
	for room in $Rooms.get_children():
		_rooms.append(room)
		if room.has_signal(&"boss_defeated"):
			# Al vencer a un jefe se guarda enseguida: que no se pierda si se cierra el juego.
			room.boss_defeated.connect(save_game, CONNECT_DEFERRED)
		_room_rects.append(room.world_rect())
		var image := MapData.image_from_layer(room.tiles, room.tiles.map_size, MAP_TILE_COLOR, { PLANK_ATLAS: MAP_PLANK_COLOR })
		map_data.add_area(room.name, room.title, room.cell_rect(), image)
		for child in room.get_children():
			if child is Checkpoint:
				map_data.set_marker(StringName("anchor_%d" % child.get_instance_id()), child.global_position / CELL, MAP_ANCHOR_COLOR)
	flags.add_to_group(&"flag_store")
	flags.add_to_group(&"resettable")
	add_child(flags)
	add_child(collected)
	_spawn_player()
	if player == null:
		return
	_save_slot = SaveSlot.new(save_path)
	var saved := _save_slot.read()
	if not saved.is_empty():
		_apply_save(saved)
	_setup_collectibles()
	var room := room_at(player.global_position)
	_enter_room(room if room else _rooms[0], false, false)
	_camera.reset_smoothing()
	_show_sky(current_room.has_sky, true)
	player.save_requested.connect(save_game)
	player.title_requested.connect(return_to_title)


func _physics_process(_delta: float) -> void:
	if player == null:
		return
	var here := _room_rects[_rooms.find(current_room)].grow(ROOM_HYSTERESIS)
	if not here.has_point(player.global_position):
		var room := room_at(player.global_position)
		if room != null and room != current_room:
			_enter_room(room)
	map_data.set_focus(player.global_position / CELL)
	var cell := Vector2i(map_data.focus_cell.floor())
	if cell != _last_reveal_cell:
		_last_reveal_cell = cell
		map_data.reveal_around(map_data.focus_cell, REVEAL_RADIUS)
	if is_instance_valid(player.active_echo):
		map_data.set_marker(&"echo", player.active_echo.global_position / CELL, MAP_ECHO_COLOR)
	else:
		map_data.remove_marker(&"echo")


## La sala que contiene `point` (en píxeles), o null si ninguna.
func room_at(point: Vector2) -> Node2D:
	for i in _rooms.size():
		if _room_rects[i].has_point(point):
			return _rooms[i]
	return null


func _spawn_player() -> void:
	for room in _rooms:
		var points: Array[Vector2] = room.spawn_points("P", PLAYER_HALF_HEIGHT)
		if points.is_empty():
			continue
		player = PlayerScene.instantiate()
		player.position = points[0]
		_start_position = points[0]
		add_child(player)
		_camera = player.get_node("Camera2D")
		_camera.limit_smoothed = true
		player.set_map(map_data)
		return
	push_error("Ninguna sala tiene el marcador P (inicio del jugador).")


func _enter_room(room: Node2D, announce: bool = true, autosave: bool = true) -> void:
	current_room = room
	var rect: Rect2 = _room_rects[_rooms.find(room)]
	_limit_camera(rect)
	_show_sky(room.has_sky)
	player.respawn.fall_limit_y = rect.end.y + FALL_MARGIN
	if map_data.visit(room.name) and announce:
		player.announce_area(room.title)
	_activate_nearby_rooms(rect)
	if autosave:
		# Un fotograma después: que el guardado en disco no coincida con el
		# arranque del deslizamiento de la cámara.
		save_game.call_deferred()


## Solo la sala actual y las que tocan con ella (con un margen) procesan: los
## enemigos de salas lejanas no piensan, no se mueven ni lanzan raycasts. Siguen
## dibujadas y con sus colisiones; solo se les quita el trabajo por fotograma.
func _activate_nearby_rooms(current_rect: Rect2) -> void:
	var zone := current_rect.grow(ACTIVE_ROOM_MARGIN)
	for i in _rooms.size():
		_rooms[i].process_mode = Node.PROCESS_MODE_INHERIT if zone.intersects(_room_rects[i]) else Node.PROCESS_MODE_DISABLED


## Que la cámara no salga de la sala. Si la sala es más baja o más estrecha que
## la pantalla, se enseña lo que hay por encima (pegada al suelo, como en El
## Último Umbral) o a ambos lados.
func _limit_camera(rect: Rect2) -> void:
	var view := get_viewport_rect().size
	var extra_x := maxf(0.0, view.x - rect.size.x) / 2.0
	_camera.limit_left = int(rect.position.x - extra_x)
	_camera.limit_right = int(rect.end.x + extra_x)
	_camera.limit_bottom = int(rect.end.y)
	_camera.limit_top = int(minf(rect.position.y, rect.end.y - view.y))


## Funde las capas del cielo (o las pone de golpe con `instant`).
func _show_sky(show: bool, instant: bool = false) -> void:
	if show == sky_shown and not instant:
		return
	sky_shown = show
	if _sky_tween:
		_sky_tween.kill()
	var alpha := 1.0 if show else 0.0
	if instant:
		for layer in background.get_children():
			layer.modulate.a = alpha
		return
	_sky_tween = create_tween().set_parallel()
	for layer in background.get_children():
		_sky_tween.tween_property(layer, "modulate:a", alpha, SKY_FADE_SECONDS)


## Guarda la partida: lo del jugador, las salas visitadas, los jefes vencidos y
## lo explorado del mapa.
func save_game() -> void:
	if player == null:
		return
	var rooms: Array[String] = []
	for area in map_data.areas:
		if area.visited:
			rooms.append(String(area.id))
	var bosses: Array[String] = []
	for room in _rooms:
		if room.has_method(&"is_defeated") and room.is_defeated():
			bosses.append(String(room.name))
	_save_slot.write({
		player = player.get_save_data(),
		rooms = rooms,
		bosses = bosses,
		seen = map_data.get_seen_data(),
		flags = flags.to_dict(),
		fragments = _collected_ids(&"fragment"),
		bags = _collected_ids(&"bag"),
	})


## Guarda y vuelve al menú principal.
func return_to_title() -> void:
	save_game()
	# El árbol sigue en pausa hasta que cambie la escena (al final del fotograma):
	# si no, el mundo seguiría jugándose ese rato y podría volver a guardar. La
	# pausa la quita el menú principal al abrirse.
	if get_tree().current_scene == self:
		get_tree().change_scene_to_file(TITLE_SCENE)
	else:
		# En las pruebas el mundo no es la escena principal: no se cambia de escena.
		get_tree().paused = false


## Al cerrar la ventana (o al elegir "Salir del juego", que avisa igual) se
## guarda por última vez, para no perder lo conseguido desde el último guardado.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()


func _apply_save(saved: Dictionary) -> void:
	var player_data: Variant = saved.get("player")
	player.load_save_data(player_data if player_data is Dictionary else {})
	# La partida guarda posiciones del mundo. Si desde entonces se ha cambiado un
	# mapa o movido un Ancla, pueden caer en una pared o en el vacío: reaparecer
	# allí mataría al jugador una y otra vez (y cada muerte lo volvería a guardar).
	if not _is_valid_spawn(player.respawn.spawn_position):
		player.respawn.set_checkpoint(_start_position)
		player.global_position = _start_position
	if is_instance_valid(player.active_echo) and room_at(player.active_echo.global_position) == null:
		player.active_echo.queue_free()
		player.active_echo = null
	var rooms: Variant = saved.get("rooms")
	if rooms is Array:
		for id in rooms:
			if id is String:
				map_data.visit(StringName(id))
	var bosses: Variant = saved.get("bosses")
	if bosses is Array:
		for room in _rooms:
			if room.has_method(&"mark_defeated") and String(room.name) in bosses:
				room.mark_defeated()
	var seen: Variant = saved.get("seen")
	if seen is Dictionary:
		map_data.set_seen_data(seen)
	# Claves opcionales: una partida antigua sin ellas carga sin marcas ni coleccionables.
	flags.from_dict(saved.get("flags"))
	collected.from_dict({})
	# Solo cuentan los ids de coleccionables que existen en el mundo (uno que se
	# quitó del mapa, o un id inventado, se ignora).
	var real_ids: Array[String] = []
	for pickup in get_tree().get_nodes_in_group(&"collectible"):
		real_ids.append(String(pickup.id))
	for key in ["fragments", "bags"]:
		var ids: Variant = saved.get(key)
		if ids is Array:
			for id in ids:
				if id is String and id in real_ids:
					collected.set_flag(StringName(id), "fragment" if key == "fragments" else "bag")
	# Los recuerdos de habilidades ya conseguidas no vuelven a aparecer.
	for room in _rooms:
		for child in room.get_children():
			if child is AbilityPickup and player.has_ability(child.ability_id):
				child.queue_free()


## Solo se reaparece en un Ancla que siga existiendo o en el inicio del juego.
func _is_valid_spawn(at: Vector2) -> bool:
	if at.distance_to(_start_position) < 1.0:
		return true
	for room in _rooms:
		for child in room.get_children():
			if child is Checkpoint and at.distance_to(child.global_position) < 1.0:
				return true
	return false


## Cuántos fragmentos de vida se han recogido (los contadores salen de los ids
## guardados, no hay un número aparte que pueda descuadrarse).
func fragment_count() -> int:
	return collected.ids_with_value("fragment").size()


## Cuántas Bolsas de Rastro se han recogido.
func bag_count() -> int:
	return collected.ids_with_value("bag").size()


func _collected_ids(kind: String) -> Array[String]:
	var ids: Array[String] = []
	for id in collected.ids_with_value(kind):
		ids.append(String(id))
	ids.sort()
	return ids


func _is_collected(pickup: Node) -> bool:
	if pickup.kind == &"item":
		return flags.has_flag(StringName("i:" + pickup.id))
	return collected.has_flag(pickup.id)


## Los coleccionables ya recogidos no vuelven a aparecer; el resto avisan al mundo.
func _setup_collectibles() -> void:
	for pickup in get_tree().get_nodes_in_group(&"collectible"):
		if _is_collected(pickup):
			pickup.queue_free()
		else:
			pickup.collected.connect(_on_collectible_collected)


## Cuenta el coleccionable (una sola vez por id), lo guarda y avisa al jugador.
func _on_collectible_collected(pickup: Node) -> void:
	var message := ""
	match pickup.kind:
		&"fragment":
			if not collected.set_flag(pickup.id, "fragment"):
				return
			var count := fragment_count()
			message = "Fragmento de vida %d/%d" % [(count - 1) % FRAGMENTS_PER_LIFE + 1, FRAGMENTS_PER_LIFE]
		&"bag":
			if not collected.set_flag(pickup.id, "bag"):
				return
			message = "Bolsa de Rastro"
		_:
			if not flags.set_flag(StringName("i:" + pickup.id)):
				return
			message = "Objeto recogido"
	Sfx.play(&"echo_collect", null, -7.0)
	player.announce_area(message)
	save_game.call_deferred()
