class_name InputPrompt
extends Node2D
## Indicador de botón: dibuja el icono de la acción `action` según el dispositivo
## que se esté usando (ver `InputGlyphs`), centrado en su posición, y un indicador de
## a qué se refiere:
## - POINTER: una flecha que señala hacia abajo, al objeto sobre el que se coloca.
## - MENU / UP_DOWN / CHECK / BACK: un pequeño símbolo a la derecha (menú, elegir
##   arriba/abajo, aceptar, volver).
##
## Es un `CanvasItem` normal: quien quiera mostrarlo u ocultarlo cambia su `visible`
## (p. ej. el `prompt` de Checkpoint y Readable). Solo gasta tiempo mientras se ve.

@export var action: StringName = &"interact"
@export var hint: InputGlyphs.Hint = InputGlyphs.Hint.POINTER

var _time: float = 0.0


func _ready() -> void:
	InputGlyphs.ensure_tracker(get_tree()).kind_changed.connect(_on_kind_changed)
	visibility_changed.connect(_on_visibility_changed)
	_on_visibility_changed()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _on_visibility_changed() -> void:
	# Se anima (la flecha sube y baja) solo mientras se ve.
	set_process(is_visible_in_tree() and hint == InputGlyphs.Hint.POINTER)
	queue_redraw()


func _on_kind_changed(_kind: int) -> void:
	queue_redraw()


func _draw() -> void:
	var glyph_width := InputGlyphs.draw(self, action, Vector2.ZERO)
	var color := Color(0.95, 0.9, 0.7)
	if hint == InputGlyphs.Hint.POINTER:
		var bob := sin(_time * 5.0) * 1.5
		var top := InputGlyphs.RADIUS + 3.0 + bob
		draw_colored_polygon(PackedVector2Array([Vector2(-4, top), Vector2(4, top), Vector2(0, top + 6.0)]), color)
	elif hint != InputGlyphs.Hint.NONE:
		InputGlyphs.draw_hint(self, hint, Vector2(glyph_width / 2.0 + 9.0, 0.0), color)
