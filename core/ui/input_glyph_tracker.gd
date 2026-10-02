class_name InputGlyphTracker
extends Node
## Vigila qué dispositivo se está usando (teclado, mando Xbox, PlayStation o
## Nintendo) mirando la última entrada recibida, y avisa al cambiar para que los
## iconos de botones se adapten. Lo crea `InputGlyphs.ensure_tracker()`; hay uno
## solo, colgado de la raíz del árbol, y sigue funcionando con el juego en pausa.

signal kind_changed(kind: int)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _input(event: InputEvent) -> void:
	var detected := InputGlyphs.kind_from_event(event)
	if detected >= 0 and detected != InputGlyphs.kind:
		InputGlyphs.kind = detected
		kind_changed.emit(detected)
