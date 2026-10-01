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
## Texto que se muestra junto a la opción seleccionada.
@export var cursor: String = "›"
## Acciones que eligen la opción seleccionada. Por defecto solo `ui_accept`; un
## juego puede añadir otras (p. ej. su tecla de interactuar). Ojo: no conviene
## añadir la tecla de interactuar a `ui_accept` en el Mapa de entrada si
## `ui_accept` es también saltar.
@export var accept_actions: Array[StringName] = [&"ui_accept"]
## Ancho fijo (en píxeles) de la columna del cursor.
@export var cursor_width: int = 18

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
	var step := 0
	if event.is_action_pressed(&"ui_down"):
		step = 1
	elif event.is_action_pressed(&"ui_up"):
		step = -1
	elif not _is_accept(event) and not event.is_action_pressed(&"ui_cancel"):
		return
	# La tecla se da por usada ANTES de actuar: elegir una opción puede sacar
	# esta lista del árbol (p. ej. cambiar de escena) y después ya no habría
	# viewport al que avisar.
	get_viewport().set_input_as_handled()
	if step != 0:
		move_selection(step)
	elif _is_accept(event):
		activate()
	else:
		cancel()


func _is_accept(event: InputEvent) -> bool:
	for action in accept_actions:
		if event.is_action_pressed(action):
			return true
	return false


## Las filas se crean una sola vez y después solo se actualizan (texto y color).
## Borrar y recrear con `queue_free` dejaría un frame con filas viejas y nuevas a
## la vez, y el menú "temblaría" al mover la selección.
func _rebuild() -> void:
	while get_child_count() > _texts.size():
		var extra := get_child(get_child_count() - 1)
		remove_child(extra)
		extra.queue_free()
	while get_child_count() < _texts.size():
		add_child(_make_row())
	for i in _texts.size():
		_style_row(get_child(i) as HBoxContainer, i)


## Una fila: el cursor en su propia columna de ancho fijo (así el texto no se
## desplaza ni cambia el ancho del menú) y el texto de la opción.
func _make_row() -> HBoxContainer:
	var cursor_label := Label.new()
	cursor_label.custom_minimum_size.x = cursor_width
	var row := HBoxContainer.new()
	row.add_child(cursor_label)
	row.add_child(Label.new())
	return row


func _style_row(row: HBoxContainer, index: int) -> void:
	var color := normal_color
	if not _enabled[index]:
		color = disabled_color
	elif index == selected:
		color = selected_color
	var cursor_label := row.get_child(0) as Label
	var text_label := row.get_child(1) as Label
	cursor_label.text = cursor if index == selected else ""
	text_label.text = _texts[index]
	cursor_label.add_theme_color_override(&"font_color", color)
	text_label.add_theme_color_override(&"font_color", color)


func _all_true(count: int) -> Array[bool]:
	var all: Array[bool] = []
	all.resize(count)
	all.fill(true)
	return all
