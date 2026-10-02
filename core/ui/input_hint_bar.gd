class_name InputHintBar
extends Control
## Fila de indicadores de botón (sin texto) para los pies de los menús: cada entrada es
## un icono de acción que se adapta al dispositivo (ver `InputGlyphs`) con un símbolo
## que dice qué hace (aceptar, volver, elegir...), o un punto de color para una leyenda.
##
## Se rellena con `set_entries()`; cada entrada es un diccionario:
## - `{ action = &"ui_accept", hint = InputGlyphs.Hint.CHECK }`: icono de la acción y símbolo.
## - `{ hint = InputGlyphs.Hint.UP_DOWN }`: solo el símbolo (p. ej. elegir con arriba/abajo).
## - `{ color = Color(...) }`: un punto de color (leyenda del mapa).

const GAP := 22.0
const HINT_COLOR := Color(0.62, 0.6, 0.67)

## Si es false, la fila se alinea a la izquierda en lugar de centrarse.
@export var centered: bool = true

var entries: Array = []


func _ready() -> void:
	custom_minimum_size.y = maxf(custom_minimum_size.y, 22.0)
	InputGlyphs.ensure_tracker(get_tree()).kind_changed.connect(_on_kind_changed)


func set_entries(new_entries: Array) -> void:
	entries = new_entries
	queue_redraw()


func _on_kind_changed(_kind: int) -> void:
	queue_redraw()


func _entry_width(entry: Dictionary) -> float:
	if entry.has("color"):
		return 10.0
	var action: StringName = entry.get("action", &"")
	var glyph := InputGlyphs.width(action) if action != &"" else 0.0
	var hint: int = entry.get("hint", InputGlyphs.Hint.NONE)
	var symbol := 0.0 if hint == InputGlyphs.Hint.NONE else (18.0 if action != &"" else 10.0)
	return glyph + symbol


func _draw() -> void:
	var total := 0.0
	for entry in entries:
		total += _entry_width(entry)
	total += GAP * maxf(entries.size() - 1, 0)
	var x := (size.x - total) / 2.0 if centered else 0.0
	var cy := size.y / 2.0
	for entry in entries:
		var w := _entry_width(entry)
		if entry.has("color"):
			draw_circle(Vector2(x + 5.0, cy), 4.0, entry.color)
			draw_arc(Vector2(x + 5.0, cy), 4.0, 0.0, TAU, 12, Color(0, 0, 0, 0.6), 1.0)
		else:
			var action: StringName = entry.get("action", &"")
			var hint: int = entry.get("hint", InputGlyphs.Hint.NONE)
			var glyph_w := 0.0
			if action != &"":
				glyph_w = InputGlyphs.width(action)
				InputGlyphs.draw(self, action, Vector2(x + glyph_w / 2.0, cy))
			if hint != InputGlyphs.Hint.NONE:
				var at_x := x + glyph_w + 9.0 if action != &"" else x + 5.0
				InputGlyphs.draw_hint(self, hint, Vector2(at_x, cy), HINT_COLOR)
		x += w + GAP
