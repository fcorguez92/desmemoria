class_name IconRow
extends Control
## Fila de iconos iguales sacados de una hoja de sprites: `count` con el aspecto
## "lleno" y el resto hasta `max_count` con el aspecto "vacío". Sirve para cargas
## de curación, llaves, munición... El dueño llama a `set_values()`.

## Hoja de sprites con los iconos en una fila.
@export var sheet: Texture2D
## Tamaño en píxeles de cada icono en la hoja.
@export var icon_size: Vector2i = Vector2i(16, 16)
## Posición (columna) del icono lleno y del vacío en la hoja.
@export var full_frame: int = 0
@export var empty_frame: int = 1
## Píxeles entre iconos.
@export var spacing: int = 2

var count: int = 0
var max_count: int = 0


func set_values(new_count: int, new_max: int) -> void:
	count = clampi(new_count, 0, new_max)
	max_count = new_max
	custom_minimum_size = Vector2(max_count * (icon_size.x + spacing) - spacing, icon_size.y)
	queue_redraw()


func _draw() -> void:
	if sheet == null:
		return
	for i in max_count:
		var frame := full_frame if i < count else empty_frame
		var source := Rect2(frame * icon_size.x, 0, icon_size.x, icon_size.y)
		draw_texture_rect_region(sheet, Rect2(i * (icon_size.x + spacing), 0, icon_size.x, icon_size.y), source)
