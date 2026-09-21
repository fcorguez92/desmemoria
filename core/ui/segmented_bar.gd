class_name SegmentedBar
extends Control
## Barra dividida en segmentos (uno por punto de `max_value`), dibujada con
## rectángulos de píxeles: marco oscuro, fondo y relleno con un filo de luz.
## Sirve para vida, aguante, etc. No sabe de dónde vienen los números: el dueño
## llama a `set_values()`.

## Ancho en píxeles de cada segmento.
@export var segment_width: int = 20
## Alto de la barra (sin contar el marco).
@export var bar_height: int = 10
@export var border_color: Color = Color("#1b1a1f")
@export var back_color: Color = Color("#3a1218")
@export var fill_color: Color = Color("#c2453f")
@export var highlight_color: Color = Color("#f08a6a")
@export var shade_color: Color = Color("#7a2430")

var max_value: int = 1
var value: int = 1


func set_values(new_value: int, new_max: int) -> void:
	value = clampi(new_value, 0, new_max)
	max_value = maxi(new_max, 1)
	custom_minimum_size = Vector2(max_value * segment_width + 2, bar_height + 2)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, 0, max_value * segment_width + 2, bar_height + 2), border_color)
	for i in max_value:
		var x := 1 + i * segment_width
		# Un píxel de separación entre segmentos, en el color del marco.
		var width := segment_width - (1 if i < max_value - 1 else 0)
		draw_rect(Rect2(x, 1, width, bar_height), back_color)
		if i < value:
			draw_rect(Rect2(x, 1, width, bar_height), fill_color)
			draw_rect(Rect2(x, 1, width, 2), highlight_color)
			draw_rect(Rect2(x, bar_height - 1, width, 2), shade_color)
