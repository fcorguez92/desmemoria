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

const PlayerScene := preload("res://game/player/player.tscn")

const CELL := 16.0
const PLAYER_HALF_HEIGHT := 24.0
## Cuánto puede bajar el jugador del fondo de su sala antes de morir. Da margen
## para que, al bajar a una sala de abajo, se detecte el cambio de sala antes.
const FALL_MARGIN := 96.0
## Para cambiar de sala hay que adentrarse en la nueva este tanto (y menos que
## FALL_MARGIN): así, saltando justo en una frontera, la cámara no va y viene.
const ROOM_HYSTERESIS := 32.0
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

var map_data := MapData.new()
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

@onready var background: CanvasLayer = $Background


func _ready() -> void:
	# Antes que el jugador en cada paso de físicas: si reaparece en otra sala, su
	# límite de caída ya debe ser el de la sala nueva cuando él lo compruebe.
	process_physics_priority = -1
	for room in $Rooms.get_children():
		_rooms.append(room)
		_room_rects.append(room.world_rect())
		var image := MapData.image_from_layer(room.tiles, room.tiles.map_size, MAP_TILE_COLOR, { PLANK_ATLAS: MAP_PLANK_COLOR })
		map_data.add_area(room.name, room.title, room.cell_rect(), image)
		for child in room.get_children():
			if child is Checkpoint:
				map_data.set_marker(StringName("anchor_%d" % child.get_instance_id()), child.global_position / CELL, MAP_ANCHOR_COLOR)
	_spawn_player()


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
		add_child(player)
		_camera = player.get_node("Camera2D")
		_camera.limit_smoothed = true
		player.set_map(map_data)
		_enter_room(room, false)
		_camera.reset_smoothing()
		_show_sky(room.has_sky, true)
		return
	push_error("Ninguna sala tiene el marcador P (inicio del jugador).")


func _enter_room(room: Node2D, announce: bool = true) -> void:
	current_room = room
	var rect: Rect2 = _room_rects[_rooms.find(room)]
	_limit_camera(rect)
	_show_sky(room.has_sky)
	player.respawn.fall_limit_y = rect.end.y + FALL_MARGIN
	if map_data.visit(room.name) and announce:
		player.announce_area(room.title)


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
