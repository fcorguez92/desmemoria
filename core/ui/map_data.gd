class_name MapData
extends RefCounted
## Lo que sabe el mapa del mundo: qué zonas hay, cuáles se han descubierto, dónde
## está el foco (normalmente el jugador) y qué marcadores mostrar. Todo en
## baldosas, no en píxeles. Lo dibujan uno o varios `MapView` (un minimapa y un
## mapa completo comparten los mismos datos).
##
## No sabe nada del juego: quien lo rellena decide qué es una zona, qué significa
## cada marcador y de qué color se pinta.

## Algo ha cambiado y las vistas deben redibujarse.
signal changed

## Una entrada por zona, en el orden en que se añadieron:
## { id: StringName, title: String, rect: Rect2i, texture: Texture2D, revealed: bool }
var areas: Array[Dictionary] = []
## id -> { cell: Vector2, color: Color }
var markers: Dictionary = {}
## Celda (con decimales) donde está el foco.
var focus_cell: Vector2 = Vector2.ZERO


## Añade una zona sin descubrir. `rect` es su sitio en el mundo, en baldosas;
## `image` es su dibujo, un píxel por baldosa (ver `image_from_layer()`).
func add_area(id: StringName, title: String, rect: Rect2i, image: Image) -> void:
	areas.append({
		id = id,
		title = title,
		rect = rect,
		texture = ImageTexture.create_from_image(image),
		revealed = false,
	})
	changed.emit()


## Descubre la zona. Devuelve true si no lo estaba ya.
func reveal(id: StringName) -> bool:
	for area in areas:
		if area.id == id and not area.revealed:
			area.revealed = true
			changed.emit()
			return true
	return false


func is_revealed(id: StringName) -> bool:
	for area in areas:
		if area.id == id:
			return area.revealed
	return false


## La zona que contiene `cell`, o un diccionario vacío si ninguna.
func area_at(cell: Vector2) -> Dictionary:
	for area in areas:
		if Rect2(area.rect).has_point(cell):
			return area
	return {}


## Los marcadores solo se dibujan dentro de zonas descubiertas.
func set_marker(id: StringName, cell: Vector2, color: Color) -> void:
	var marker: Dictionary = markers.get(id, {})
	if not marker.is_empty() and marker.cell == cell and marker.color == color:
		return
	markers[id] = { cell = cell, color = color }
	changed.emit()


func remove_marker(id: StringName) -> void:
	if markers.erase(id):
		changed.emit()


func set_focus(cell: Vector2) -> void:
	if cell != focus_cell:
		focus_cell = cell
		changed.emit()


## Rectángulo (en baldosas) que abarca todas las zonas descubiertas.
func revealed_bounds() -> Rect2i:
	var bounds := Rect2i()
	for area in areas:
		if area.revealed:
			bounds = area.rect if bounds.size == Vector2i.ZERO else bounds.merge(area.rect)
	return bounds


## Dibujo de una capa de baldosas para el mapa: un píxel de `color` por baldosa
## ocupada en un lienzo de `size` baldosas, transparente en el resto. `colors`
## (coordenadas en el atlas -> Color) pinta algunas baldosas de otro color, p. ej.
## las plataformas de un solo sentido.
static func image_from_layer(layer: TileMapLayer, size: Vector2i, color: Color, colors: Dictionary = {}) -> Image:
	var image := Image.create_empty(maxi(size.x, 1), maxi(size.y, 1), false, Image.FORMAT_RGBA8)
	for cell in layer.get_used_cells():
		if cell.x < 0 or cell.y < 0 or cell.x >= size.x or cell.y >= size.y:
			continue
		image.set_pixelv(cell, colors.get(layer.get_cell_atlas_coords(cell), color))
	return image
