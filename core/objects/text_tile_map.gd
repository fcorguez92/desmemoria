class_name TextTileMap
extends TileMapLayer
## Construye un TileMapLayer a partir de un mapa dibujado como texto: una línea
## por fila y un carácter por baldosa. Sirve para diseñar y revisar niveles como
## cualquier otro archivo de texto.
##
## - Los caracteres definidos en `legend` se colocan como baldosas.
## - El punto (.) y el espacio son vacío.
## - Cualquier otro carácter es un **marcador**: no pone baldosa, pero se anota su
##   posición en `markers` para que el nivel ponga ahí un jugador, un enemigo, etc.
##   Así esta clase no sabe nada de las entidades de ningún juego.
##
## Las filas pueden tener longitudes distintas; lo que falta cuenta como vacío.

## Archivo de texto con el mapa.
@export_file("*.map") var map_file: String
## Carácter -> coordenadas de la baldosa en el atlas (Vector2i).
@export var legend: Dictionary = {}
## Identificador de la fuente de baldosas dentro del TileSet.
@export var source_id: int = 0

## Carácter marcador -> lista de posiciones globales (centro de su celda).
var markers: Dictionary = {}
## Tamaño del mapa en baldosas: la fila más larga por el número de filas (sin
## contar líneas vacías al final). A diferencia de `get_used_rect()`, incluye el
## vacío dibujado con puntos (el cielo, un foso).
var map_size: Vector2i = Vector2i.ZERO
## Carácter marcador -> celdas (Vector2i) en orden de lectura (fila a fila).
var marker_cells: Dictionary = {}


func _ready() -> void:
	if map_file != "":
		build(FileAccess.get_file_as_string(map_file))


## Coloca las baldosas y anota los marcadores del mapa `text`.
func build(text: String) -> void:
	clear()
	markers.clear()
	marker_cells.clear()
	map_size = Vector2i.ZERO
	var rows := text.split("\n")
	for y in rows.size():
		var row := rows[y].strip_edges(false, true)
		if not row.is_empty():
			map_size = Vector2i(maxi(map_size.x, row.length()), y + 1)
		for x in row.length():
			var symbol := row[x]
			if symbol == "." or symbol == " ":
				continue
			var cell := Vector2i(x, y)
			if legend.has(symbol):
				set_cell(cell, source_id, legend[symbol])
			else:
				if not markers.has(symbol):
					markers[symbol] = []
					marker_cells[symbol] = []
				markers[symbol].append(to_global(map_to_local(cell)))
				marker_cells[symbol].append(cell)


## Agrupa los marcadores `symbol` en piezas: conjuntos conexos por lados (4 vecinos;
## las diagonales no unen). Un muro de 2x3 marcadores es una sola pieza. Devuelve una
## lista de piezas y cada pieza es una lista de celdas (Vector2i) en orden de lectura;
## las piezas van ordenadas por su primera celda. Así el identificador de una pieza
## puede ser `carácter@columna,fila` de su primera celda (ver docs/puzles.md).
func marker_groups(symbol: String) -> Array:
	var groups: Array = []
	var cells: Array = marker_cells.get(symbol, [])
	var pending := {}
	for cell in cells:
		pending[cell] = true
	for first in cells:  # ya en orden de lectura
		if not pending.has(first):
			continue
		var group: Array = []
		var queue: Array = [first]
		pending.erase(first)
		while not queue.is_empty():
			var cell: Vector2i = queue.pop_back()
			group.append(cell)
			for step in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var next: Vector2i = cell + step
				if pending.has(next):
					pending.erase(next)
					queue.append(next)
		group.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y or (a.y == b.y and a.x < b.x))
		groups.append(group)
	return groups
