extends Node2D
## Una sala del mundo (ver docs/mundo.md y docs/vertical-slice.md). El mundo
## (world.gd) las coloca una junto a otra; el jugador pasa de una a otra
## caminando, sin pantallas de carga.
##
## El terreno se dibuja como texto en un .map (lo construye TextTileMap, en el
## nodo Tiles). Este script pone las entidades del juego en los marcadores:
##   A = Ancla de Memoria, E 1 2 3 4 = enemigos (ver ENEMIES), R = objeto rompible decorativo (no
##   reaparece: ver core/objects/breakable_prop.gd), I = inscripción legible
##   (ver core/objects/readable.gd), i = inscripción con el texto `note` de la sala,
##   d / j / w = habilidad (dash, doble salto, salto de pared) que se recuerda al
##   tocarla, ^ v = pinchos fijos (suelo, techo), { } = pinchos fijos pegados a una
##   pared izquierda / derecha y ~ - = pinchos que salen y se
##   retraen (los dos grupos alternan; ver core/objects/hazard.gd), ! = coleccionable
##   con id guardado (fragmento de vida, Bolsa de Rastro u objeto; ver `pickups`).
## El marcador P (inicio del jugador) no lo usa la sala: lo busca el mundo, que
## es quien crea al jugador.
## Cada entidad se coloca con los pies en la parte de abajo de su celda.
##
## Inscripciones: `I` es la de El Último Umbral (su texto está en
## game/environment/inscription.tscn); `i` toma el texto de `note`, uno por sala.
## La leyenda completa de marcadores está en docs/vertical-slice.md.

const EnemyScene := preload("res://game/enemy/enemy.tscn")
const LanceroScene := preload("res://game/enemy/enemy_lancero.tscn")
const ArrojadorScene := preload("res://game/enemy/enemy_arrojador.tscn")
const ColosoScene := preload("res://game/enemy/enemy_coloso.tscn")
const AcechadorScene := preload("res://game/enemy/enemy_acechador.tscn")
const EspantapajarosScene := preload("res://game/enemy/enemy_espantapajaros.tscn")
const CuervoScene := preload("res://game/enemy/enemy_cuervo.tscn")
const AnchorScene := preload("res://game/memory_anchor/memory_anchor.tscn")
const BreakableUrnScene := preload("res://game/environment/breakable_urn.tscn")
const BreakableCrateScene := preload("res://game/environment/breakable_crate.tscn")
const BreakableBarrelScene := preload("res://game/environment/breakable_barrel.tscn")
const InscriptionScene := preload("res://game/environment/inscription.tscn")
const AbilityPickupScene := preload("res://game/ability_pickup/ability_pickup.tscn")
const CollectibleScene := preload("res://game/pickups/collectible.tscn")
const SpikesScene := preload("res://game/environment/spikes.tscn")
const DecorSheet := preload("res://game/environment/decor_sheet.png")
const PuzzleGateScene := preload("res://game/environment/reja.tscn")
const LeverScene := preload("res://game/environment/palanca.tscn")
const PlateScene := preload("res://game/environment/placa.tscn")
const ButtonScene := preload("res://game/environment/boton.tscn")

## Mecánicas de mundo (ver docs/puzles.md). Compuertas: marcador -> nombre del canal
## (la marca por defecto de una compuerta sin enlace es `t:sala.canal_a`).
const GATE_CHANNELS := {
	"=": "canal_a",
	"+": "canal_b",
}
## Disparadores: marcador -> [escena, nombre para el id por defecto].
const TRIGGERS := {
	"z": [LeverScene, "palanca"],
	"_": [PlateScene, "placa"],
	"*": [ButtonScene, "boton"],
}
const CRACKED_WALL := "#"
## Ciclo (`y`) y extremos de carril (`<` inicio, `>` fin) de las plataformas móviles.
const CYCLE_MARKER := "y"
const RAIL_START := "<"
const RAIL_END := ">"

const CELL := 16.0
## Mitad de la altura de cada entidad, para apoyar sus pies en la celda.
## Enemigos: marcador -> [escena, mitad de la altura de su cuerpo]. E = cascarón
## (tajo), 1 = lancero (estocada larga), 2 = arrojador (a distancia), 3 = coloso
## (mazazo lento), 4 = acechador (embestida), 5 = cuervo (volador, picado) y 6 = espantapájaros (emboscada dormida).
const ENEMIES := {
	"E": [EnemyScene, 24.0],
	"1": [LanceroScene, 24.0],
	"2": [ArrojadorScene, 24.0],
	"3": [ColosoScene, 32.0],
	"4": [AcechadorScene, 18.0],
	"5": [CuervoScene, 8.0],
	"6": [EspantapajarosScene, 24.0],
}
const ANCHOR_HALF_HEIGHT := 28.0
const BREAKABLE_HALF_HEIGHT := 11.0
const CRATE_HALF_HEIGHT := 7.0
const BARREL_HALF_HEIGHT := 10.0
const INSCRIPTION_HALF_HEIGHT := 13.0
const PICKUP_HALF_HEIGHT := 16.0
const COLLECTIBLE_HALF_HEIGHT := 10.0
const ABILITY_MARKERS := {
	"d": &"dash",
	"j": &"double_jump",
	"w": &"wall_jump",
}

## Decorado sin función (sin colisión ni lógica): marcador -> [fotograma de
## art/source/decor.sprite, cuelga del techo, z_index]. Lo que está detrás del
## jugador usa z -1 (y así también detrás de enemigos y urnas); la hierba y los
## huesos van delante (z 1) para dar profundidad. Cada pieza mide 48x64 px y se
## apoya en la parte de abajo de su celda (o cuelga de la de arriba).
const DECOR := {
	"Y": [0, false, -1],  # árbol muerto
	"U": [1, false, -1],  # columna rota
	"H": [2, false, 1],  # hierba
	"Z": [3, false, -1],  # zarza seca
	"K": [4, false, 1],  # huesos y escombros
	"F": [5, true, -1],  # estandarte
	"N": [6, true, -1],  # cadenas
	"X": [7, false, -1],  # estatua decapitada
	"V": [8, false, -1],  # mojón de piedras
	"L": [9, false, -1],  # poste de señal
	"M": [10, false, -1],  # farol
	"D": [11, false, -2],  # arco ciego de muro
	"q": [12, true, -1],  # enredaderas
}
const DECOR_FRAMES := 13

## Pinchos: marcador -> [giro en grados, periodo del ciclo (0 = fijos), desfase].
## Los que pulsan están activos el 40 % del ciclo y avisan 0,4 s antes de salir.
const SPIKES := {
	"^": [0.0, 0.0, 0.0],
	"v": [180.0, 0.0, 0.0],
	"~": [0.0, 2.4, 0.0],
	"-": [0.0, 2.4, 0.5],
	# Laterales (T2 de docs/puzles.md): la tira pegada a una pared izquierda apunta a
	# la derecha (`{`) y la de una pared derecha a la izquierda (`}`). El giro lleva la
	# caja de daño de 12x9 a una tira fina de 9 px pegada a la pared de su celda.
	"{": [90.0, 0.0, 0.0],
	"}": [-90.0, 0.0, 0.0],
}
const SPIKES_HALF_HEIGHT := 8.0

## Nombre de la sala: se anuncia al entrar por primera vez y sale en el mapa.
@export var title: String = ""
## Región del mundo a la que pertenece la sala (la misma que `region` en
## tests/world_manifest.json); fija los Ecos de las Bolsas de Rastro de la sala.
@export var region: StringName = &"cinturon"
## Si se ve el cielo con el fondo de colinas (false en salas bajo tierra).
@export var has_sky: bool = true
## Texto de las inscripciones del marcador `i` (cada sala dice lo suyo; la `I`
## mayúscula es la de El Último Umbral, con su texto en la escena).
@export_multiline var note: String = ""
## Nombre (id de game/names.gd) que contienen las inscripciones `i` de la sala; vacío si
## no llevan ninguno. Lo verifica tools/verifica_mundo.js (C18).
@export var note_name_id: StringName = &""
## Tipo de los coleccionables `!` que no son fragmentos de vida, atado a su posición
## y no al orden de lectura: entradas `cCCfFF:tipo` (p. ej. `c37f05:bag`), con tipo
## `fragment`, `bag` o `item`. Sin entrada, el `!` es `fragment`. Mover un `!` en el
## mapa cambia su id, así que su entrada debe moverse con él (C13 lo comprueba).
@export var pickups: PackedStringArray = PackedStringArray()
## Enlaces de las piezas de mecánica (compuertas `= +`, palancas `z`, placas `_`,
## botones `*` y muros frágiles `#`) con las marcas del mundo. La clave es el id de la
## pieza, `carácter@columna,fila` de su primera celda en orden de lectura (p. ej.
## `z@12,30`). El valor es el id de la marca que **escribe** (palanca, placa, botón,
## muro) o la lista de ids que **lee** una compuerta (se abre con todas, "Y"). Sin
## enlace: las compuertas leen `t:sala.canal_a`/`canal_b` y lo demás escribe
## `t:sala.nombre_columna_fila` (temporal). Lo permanente se nombra aquí, a mano.
@export var links: Dictionary = {}
## Ajustes de las piezas con ritmo o recorrido (ciclos `y`, plataformas `<` y disparadores
## `z _ *`, p. ej. el `hold_time` de una placa): la clave
## es el id de la pieza (`y@12,5`; de una plataforma, el de su `<`) y el valor, un
## diccionario de propiedades del nodo, p. ej. `{"phase": 0.5, "period": 4.0}` para
## un ciclo o `{"mode": 1, "activation_flag": "t:sala.palanca"}` para una plataforma
## (modo 0/1/2 o por nombre: "continuous", "on_demand", "travel"; una propiedad que
## no existe se avisa). Sin entrada, valen los de por defecto.
@export var piece_params: Dictionary = {}

@onready var tiles: TextTileMap = $Tiles


func _ready() -> void:
	for at in tiles.markers.get("A", []):
		_place(AnchorScene.instantiate(), at, ANCHOR_HALF_HEIGHT)
	for at in tiles.markers.get("R", []):
		_place(BreakableUrnScene.instantiate(), at, BREAKABLE_HALF_HEIGHT)
	for at in tiles.markers.get("Q", []):
		_place(BreakableCrateScene.instantiate(), at, CRATE_HALF_HEIGHT)
	for at in tiles.markers.get("O", []):
		_place(BreakableBarrelScene.instantiate(), at, BARREL_HALF_HEIGHT)
	for symbol in DECOR:
		for at in tiles.markers.get(symbol, []):
			_place_decor(DECOR[symbol], at)
	for at in tiles.markers.get("I", []):
		_place(InscriptionScene.instantiate(), at, INSCRIPTION_HALF_HEIGHT)
	for at in tiles.markers.get("i", []):
		var note_stone := InscriptionScene.instantiate()
		note_stone.text = note
		note_stone.name_id = note_name_id
		_place(note_stone, at, INSCRIPTION_HALF_HEIGHT)
	for symbol in SPIKES:
		for at in tiles.markers.get(symbol, []):
			var spikes := SpikesScene.instantiate()
			var info: Array = SPIKES[symbol]
			spikes.rotation_degrees = info[0]
			if info[1] > 0.0:
				spikes.period = info[1]
				spikes.phase = info[2]
				spikes.active_fraction = 0.4
				spikes.warning_time = 0.4
			_place(spikes, at, SPIKES_HALF_HEIGHT)
	for symbol in ENEMIES:
		for at in tiles.markers.get(symbol, []):
			var spawner := EntitySpawner.new()
			spawner.scene = ENEMIES[symbol][0]
			_place(spawner, at, ENEMIES[symbol][1])
	for symbol in ABILITY_MARKERS:
		for at in tiles.markers.get(symbol, []):
			var pickup := AbilityPickupScene.instantiate()
			pickup.ability_id = ABILITY_MARKERS[symbol]
			_place(pickup, at, PICKUP_HALF_HEIGHT)
	var cells: Array = tiles.marker_cells.get("!", [])
	for i in cells.size():
		var collectible := CollectibleScene.instantiate()
		collectible.id = StringName(collectible_id(cells[i]))
		collectible.kind = _collectible_kind(cells[i])
		collectible.region = region
		_place(collectible, tiles.markers["!"][i], COLLECTIBLE_HALF_HEIGHT)
	_place_mechanics()


## Id de la sala en las marcas (`prefijo:sala.objeto`): el archivo del mapa sin extensión.
func room_id() -> String:
	return tiles.map_file.get_file().get_basename()


## Id de una pieza de marcadores: `carácter@columna,fila` de su primera celda.
func piece_id(symbol: String, group: Array) -> String:
	var first: Vector2i = group[0]
	return "%s@%d,%d" % [symbol, first.x, first.y]


## Las marcas de una pieza según `links` (texto o lista de textos), o `fallback`.
func piece_flags(symbol: String, group: Array, fallback: StringName) -> Array[StringName]:
	var ids: Array[StringName] = []
	var value: Variant = links.get(piece_id(symbol, group))
	if value is String or value is StringName:
		ids.append(StringName(value))
	elif value is Array:
		for item in value:
			ids.append(StringName(item))
	if ids.is_empty():
		ids.append(fallback)
	return ids


## Compuertas, disparadores y muros frágiles: una entidad por **pieza** de marcadores,
## con la marca de `links`. Nada va a mano por sala: crece con los mapas.
func _place_mechanics() -> void:
	for symbol in GATE_CHANNELS:
		for group in tiles.marker_groups(symbol):
			var gate := PuzzleGateScene.instantiate() as Gate
			gate.cells = _offsets(group)
			gate.requires = piece_flags(symbol, group, StringName("t:%s.%s" % [room_id(), GATE_CHANNELS[symbol]]))
			gate.position = _cell_local(group[0])
			add_child(gate)
	for symbol in TRIGGERS:
		for group in tiles.marker_groups(symbol):
			var trigger := TRIGGERS[symbol][0].instantiate() as Trigger
			var fallback := StringName("t:%s.%s_%d_%d" % [room_id(), TRIGGERS[symbol][1], group[0].x, group[0].y])
			trigger.flag_id = piece_flags(symbol, group, fallback)[0]
			_apply_params(trigger, piece_id(symbol, group))
			trigger.position = _cell_local(group[0])
			if trigger.mode == Trigger.Mode.PLATE:
				# Una placa de varias celdas en fila es una sola, más ancha.
				var width: int = group.size()
				trigger.scale.x = width
				trigger.position.x += (width - 1) * CELL / 2.0
			add_child(trigger)
	for group in tiles.marker_groups(CRACKED_WALL):
		var wall := BreakableWall.new()
		wall.cells = _offsets(group)
		wall.flag_id = piece_flags(CRACKED_WALL, group, StringName("t:%s.muro_%d_%d" % [room_id(), group[0].x, group[0].y]))[0]
		wall.position = _cell_local(group[0])
		add_child(wall)
	for group in tiles.marker_groups(CYCLE_MARKER):
		var cycle := Cycle.new()
		cycle.cells = _offsets(group)
		cycle.position = _cell_local(group[0])
		_apply_params(cycle, piece_id(CYCLE_MARKER, group))
		add_child(cycle)
	for pair in rail_pairs(tiles.marker_groups(RAIL_START), tiles.marker_groups(RAIL_END)):
		var platform := RailPlatform.new()
		var from := _top_center(pair[0])
		platform.size.x = _group_width(pair[0])
		platform.position = from + Vector2(0.0, platform.size.y / 2.0)
		platform.end_offset = _top_center(pair[1]) - from
		_apply_params(platform, piece_id(RAIL_START, pair[0]))
		add_child(platform)


## Empareja los extremos de carril: cada `<` con el `>` compatible más cercano que quede
## libre. Dos extremos son compatibles si miden lo mismo de ancho y están alineados en
## la misma columna (carril vertical) o en la misma fila (horizontal). Se eligen primero
## los pares más próximos y, a igual distancia, el de menor índice (orden de lectura),
## así que el resultado es determinista. Devuelve una lista de `[inicio, fin]`, cada uno
## una pieza (lista de celdas). Los que sobren sin pareja se avisan.
static func rail_pairs(starts: Array, ends: Array) -> Array:
	var candidates: Array = []
	for s in starts.size():
		for e in ends.size():
			var a: Rect2i = _group_box(starts[s])
			var b: Rect2i = _group_box(ends[e])
			if a.size.x == b.size.x and (a.position.x == b.position.x or a.position.y == b.position.y):
				candidates.append([_group_center(starts[s]).distance_to(_group_center(ends[e])), s, e])
	candidates.sort_custom(func(x: Array, y: Array) -> bool:
		if not is_equal_approx(x[0], y[0]):
			return x[0] < y[0]
		return x[1] < y[1] or (x[1] == y[1] and x[2] < y[2]))
	var used_starts := {}
	var used_ends := {}
	var pairs: Array = []
	for c in candidates:
		if used_starts.has(c[1]) or used_ends.has(c[2]):
			continue
		used_starts[c[1]] = true
		used_ends[c[2]] = true
		pairs.append([starts[c[1]], ends[c[2]]])
	if used_starts.size() < starts.size() or used_ends.size() < ends.size():
		push_warning("room.gd: extremos de carril sin pareja (< y > deben ir en pares del mismo ancho y alineados)")
	return pairs


## Centro de una pieza en celdas (media de las celdas).
static func _group_center(group: Array) -> Vector2:
	var sum := Vector2.ZERO
	for cell in group:
		sum += Vector2(cell)
	return sum / group.size()


## Caja envolvente de una pieza, en celdas.
static func _group_box(group: Array) -> Rect2i:
	var low: Vector2i = group[0]
	var high: Vector2i = group[0]
	for cell in group:
		low = Vector2i(mini(low.x, cell.x), mini(low.y, cell.y))
		high = Vector2i(maxi(high.x, cell.x), maxi(high.y, cell.y))
	return Rect2i(low, high - low + Vector2i.ONE)


## Ancho de una pieza en píxeles (su caja envolvente).
func _group_width(group: Array) -> float:
	return float(_group_box(group).size.x) * CELL


## Punto central del borde de arriba de una pieza, en coordenadas de la sala.
func _top_center(group: Array) -> Vector2:
	var low: int = group[0].x
	var high: int = group[0].x
	var top: int = group[0].y
	for cell in group:
		low = mini(low, cell.x)
		high = maxi(high, cell.x)
		top = mini(top, cell.y)
	var x := (float(low + high) / 2.0 + 0.5) * CELL
	var y := float(top) * CELL
	return tiles.to_global(Vector2(x, y)) - global_position


## Aplica a `node` las propiedades de `piece_params[id]`, si las hay. Una propiedad que
## el nodo no tiene se avisa y se ignora (un error de nombre no pasa en silencio); las
## marcas (`flag_id`, `*_flag`) se convierten a StringName y `mode` admite el nombre
## del modo (`"on_demand"`) además del número.
func _apply_params(node: Object, id: String) -> void:
	var params: Variant = piece_params.get(id)
	if not params is Dictionary:
		return
	var known: Array[String] = []
	for property in node.get_property_list():
		known.append(property["name"])
	for key in params:
		if not known.has(key):
			push_warning("room.gd: piece_params[%s] tiene la propiedad desconocida \"%s\"" % [id, key])
			continue
		var value: Variant = params[key]
		if key == "mode" and value is String:
			var modes: Dictionary = node.get_script().get_script_constant_map().get("Mode", {})
			var found: Variant = modes.get(String(value).to_upper(), -1)
			if found == -1:
				push_warning("room.gd: piece_params[%s] tiene un modo desconocido \"%s\"" % [id, value])
				continue
			value = found
		elif value is String and (key == "flag_id" or key.ends_with("_flag")):
			value = StringName(value)
		node.set(key, value)


## Centro de una celda del mapa, en coordenadas de la sala.
func _cell_local(cell: Vector2i) -> Vector2:
	return tiles.to_global(tiles.map_to_local(cell)) - global_position


## Centros de las celdas de una pieza relativos a su primera celda (píxeles).
func _offsets(group: Array) -> PackedVector2Array:
	var offsets := PackedVector2Array()
	for cell in group:
		offsets.append(Vector2(cell - group[0]) * CELL)
	return offsets


## Id estable de un coleccionable en la celda `cell` (columna, fila de esta sala):
## `archivo_del_mapa.cCCfFF`, p. ej. `cisterna.c37f05`. Sale de la posición, así que no
## hay lista que mantener y escala a cualquier número de salas; solo cambia si se
## mueve el `!` en el mapa (entonces cuenta como otro coleccionable).
func collectible_id(cell: Vector2i) -> String:
	return "%s.%s" % [tiles.map_file.get_file().get_basename(), _cell_key(cell)]


func _cell_key(cell: Vector2i) -> String:
	return "c%02df%02d" % [cell.x, cell.y]


func _collectible_kind(cell: Vector2i) -> StringName:
	var prefix := _cell_key(cell) + ":"
	for entry in pickups:
		if entry.begins_with(prefix):
			return StringName(entry.substr(prefix.length()))
	return &"fragment"


## Rectángulo de la sala en el mundo, en píxeles.
func world_rect() -> Rect2:
	return Rect2(global_position, Vector2(tiles.map_size) * CELL)


## Rectángulo de la sala en el mundo, en baldosas.
func cell_rect() -> Rect2i:
	return Rect2i(Vector2i((global_position / CELL).round()), tiles.map_size)


## Posiciones globales donde se apoyan los pies de un cuerpo de media altura
## `half_height` en los marcadores `symbol` (p. ej. "P" para el jugador).
func spawn_points(symbol: String, half_height: float) -> Array[Vector2]:
	var points: Array[Vector2] = []
	for at in tiles.markers.get(symbol, []):
		points.append(at + Vector2(0.0, CELL / 2.0 - half_height))
	return points


## Una pieza de decorado: un Sprite2D de la hoja de decorado. Si cuelga, su borde
## de arriba toca el de la celda; si no, su borde de abajo toca el de la celda. Se
## voltea según la posición para que las repeticiones no se vean idénticas.
func _place_decor(info: Array, cell_center: Vector2) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = DecorSheet
	sprite.hframes = DECOR_FRAMES
	sprite.frame = info[0]
	sprite.z_index = info[2]
	var hangs: bool = info[1]
	sprite.offset = Vector2(0.0, 32.0 if hangs else -32.0)
	sprite.position = cell_center - global_position + Vector2(0.0, -CELL / 2.0 if hangs else CELL / 2.0)
	sprite.flip_h = int(cell_center.x / CELL) % 3 == 0
	add_child(sprite)


## Los marcadores están en coordenadas globales; la sala no gira ni se escala,
## así que basta con restar su posición.
func _place(node: Node2D, cell_center: Vector2, half_height: float) -> void:
	node.position = cell_center - global_position + Vector2(0.0, CELL / 2.0 - half_height)
	add_child(node)
