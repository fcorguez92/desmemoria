class_name MenuList
extends VBoxContainer
## Lista vertical de opciones que se maneja con el teclado o el mando: las
## acciones estándar de Godot `ui_up`/`ui_down` mueven la selección, `ui_accept`
## elige y `ui_cancel` cancela. Solo reacciona mientras es visible en el árbol.
##
## No sabe qué hace cada opción: avisa con `chosen(índice)` y `cancelled`, y quien
## la usa decide qué significan. Una opción desactivada se muestra atenuada y no
## se puede elegir, pero sí seleccionar (para poder leer por qué no está disponible).
##
## Para menús que se abren con el juego en pausa, el nodo debe tener
## `process_mode = When Paused` (o Always), o no recibirá las teclas.
##
## Lee las teclas en `_input` (antes que la interfaz de Godot) para que nada se las
## quede: es lo correcto en un menú modal.

signal chosen(index: int)
signal cancelled

@export var normal_color: Color = Color("#a39fa8")
@export var selected_color: Color = Color("#f3c46a")
@export var disabled_color: Color = Color("#6a6670")
## Texto que se antepone a la opción seleccionada.
@export var cursor: String = "› "

var selected: int = 0

var _texts: PackedStringArray = []
var _enabled: Array[bool] = []


## Sustituye las opciones. `enabled` es opcional: sin él, todas están activas.
## Conserva la selección si sigue existiendo esa posición.
func set_entries(texts: PackedStringArray, enabled: Array[bool] = []) -> void:
	_texts = texts
	_enabled = enabled if enabled.size() == texts.size() else _all_true(texts.size())
	selected = clampi(selected, 0, maxi(texts.size() - 1, 0))
	_rebuild()


## Deja la selección en la primera opción activa (o en la primera si no hay ninguna).
func select_first_enabled() -> void:
	selected = 0
	for i in _texts.size():
		if _enabled[i]:
			selected = i
			break
	_rebuild()


func move_selection(step: int) -> void:
	if _texts.is_empty():
		return
	selected = posmod(selected + step, _texts.size())
	_rebuild()


## Elige la opción seleccionada. Devuelve false si estaba desactivada.
func activate() -> bool:
	if _texts.is_empty() or not _enabled[selected]:
		return false
	chosen.emit(selected)
	return true


func cancel() -> void:
	cancelled.emit()


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event.is_action_pressed(&"ui_down"):
		move_selection(1)
	elif event.is_action_pressed(&"ui_up"):
		move_selection(-1)
	elif event.is_action_pressed(&"ui_accept"):
		activate()
	elif event.is_action_pressed(&"ui_cancel"):
		cancel()
	else:
		return
	get_viewport().set_input_as_handled()


func _rebuild() -> void:
	for child in get_children():
		child.queue_free()
	for i in _texts.size():
		var label := Label.new()
		var is_selected := i == selected
		label.text = (cursor if is_selected else " ".repeat(cursor.length())) + _texts[i]
		var color := normal_color
		if not _enabled[i]:
			color = disabled_color
		elif is_selected:
			color = selected_color
		label.add_theme_color_override(&"font_color", color)
		add_child(label)


func _all_true(count: int) -> Array[bool]:
	var all: Array[bool] = []
	all.resize(count)
	all.fill(true)
	return all
