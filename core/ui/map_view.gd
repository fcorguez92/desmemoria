class_name MapView
extends Control
## Dibuja un `MapData`: las zonas descubiertas (su fondo, sus baldosas y su
## borde), los marcadores y el foco. Dos modos:
## - `follow_focus = true` (minimapa): centrado en el foco, a `cell_pixels`
##   píxeles por baldosa; lo que sale del recuadro se recorta.
## - `follow_focus = false` (mapa completo): encaja todas las zonas descubiertas,
##   con la escala entera más grande que quepa, hasta `cell_pixels`.
## Solo presentación: no descubre zonas ni mueve nada.

## Píxeles por baldosa (en el modo de mapa completo, el máximo). Entero para que
## los píxeles del mapa salgan todos del mismo tamaño.
@export_range(1, 16) var cell_pixels: int = 2
@export var follow_focus: bool = true
## Fondo y marco del recuadro. Un alfa de 0 en el fondo lo deja transparente.
@export var back_color: Color = Color(0.106, 0.102, 0.122, 0.72)
@export var frame_color: Color = Color(0.416, 0.4, 0.44, 0.6)
## Relleno y borde de cada zona descubierta.
@export var area_color: Color = Color(0.2, 0.192, 0.231, 0.9)
@export var area_border_color: Color = Color(0.5, 0.48, 0.53, 1)
@export var focus_color: Color = Color(0.953, 0.769, 0.416, 1)
## Margen entre el borde del recuadro y el mapa en el modo de mapa completo.
@export var padding: int = 8

var data: MapData:
	set(value):
		if data and data.changed.is_connected(queue_redraw):
			data.changed.disconnect(queue_redraw)
		data = value
		if data:
			data.changed.connect(queue_redraw)
		queue_redraw()


func _ready() -> void:
	clip_contents = true


## Escala en uso, en píxeles por baldosa.
func current_scale() -> int:
	if follow_focus or data == null:
		return cell_pixels
	var bounds := data.revealed_bounds()
	if bounds.size == Vector2i.ZERO:
		return cell_pixels
	var room := size - Vector2(padding, padding) * 2.0
	var fit := floori(minf(room.x / bounds.size.x, room.y / bounds.size.y))
	return clampi(fit, 1, cell_pixels)


## Posición en el recuadro (en píxeles) de una celda del mundo.
func cell_to_view(cell: Vector2) -> Vector2:
	var px := current_scale()
	var center := data.focus_cell
	if not follow_focus:
		center = Rect2(data.revealed_bounds()).get_center()
	return (size / 2.0 - center * px).round() + cell * px


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), back_color)
	if data != null:
		_draw_map()
	draw_rect(Rect2(Vector2.ZERO, size), frame_color, false, 1.0)


func _draw_map() -> void:
	var px := current_scale()
	for area in data.areas:
		if not area.revealed:
			continue
		var rect := Rect2(cell_to_view(Vector2(area.rect.position)), Vector2(area.rect.size) * px)
		draw_rect(rect, area_color)
		draw_texture_rect(area.texture, rect, false)
		draw_rect(rect, area_border_color, false, 1.0)
	for id in data.markers:
		var marker: Dictionary = data.markers[id]
		if data.area_at(marker.cell).get("revealed", false):
			_draw_dot(cell_to_view(marker.cell), marker.color, maxi(3, px + 1))
	_draw_dot(cell_to_view(data.focus_cell), focus_color, maxi(4, px + 2))


## Un cuadrado de `side` píxeles centrado en `at`, con un filo oscuro para que se
## distinga sobre cualquier fondo.
func _draw_dot(at: Vector2, color: Color, side: int) -> void:
	var rect := Rect2((at - Vector2(side, side) / 2.0).round(), Vector2(side, side))
	draw_rect(rect.grow(1.0), Color(0.04, 0.04, 0.06, 1))
	draw_rect(rect, color)
