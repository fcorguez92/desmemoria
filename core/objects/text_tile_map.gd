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


func _ready() -> void:
	if map_file != "":
		build(FileAccess.get_file_as_string(map_file))


## Coloca las baldosas y anota los marcadores del mapa `text`.
func build(text: String) -> void:
	clear()
	markers.clear()
	var rows := text.split("\n")
	for y in rows.size():
		var row := rows[y].strip_edges(false, true)
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
				markers[symbol].append(to_global(map_to_local(cell)))
