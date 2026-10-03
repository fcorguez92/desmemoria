extends ModalLayer
## Menú del Ancla de Memoria: se abre al descansar, con el juego en pausa. Muestra
## los Ecos y ofrece el árbol de habilidades (donde se gastan en mejorar al
## personaje) o salir. No conoce al jugador: recibe los datos con `show_state()` y
## avisa con señales (los datos bajan, los eventos suben; ver docs/arquitectura.md).
## Las entradas nuevas (tienda, viaje entre Anclas...) se añadirán aquí cuando
## existan sus mecánicas.

## Se ha elegido comprar el siguiente nivel de una mejora del árbol.
signal skill_requested(id: StringName)

const OPTION_TREE := 0
const HINTS_MAIN := [
	{ hint = InputGlyphs.Hint.UP_DOWN },
	{ action = &"ui_accept", hint = InputGlyphs.Hint.CHECK },
	{ action = &"ui_cancel", hint = InputGlyphs.Hint.BACK },
]
const HINTS_TREE := [
	{ hint = InputGlyphs.Hint.UP_DOWN },
	{ hint = InputGlyphs.Hint.LEFT_RIGHT },
	{ action = &"ui_accept", hint = InputGlyphs.Hint.CHECK },
	{ action = &"ui_cancel", hint = InputGlyphs.Hint.BACK },
]
## Direcciones del árbol: acción -> [dx, dy].
const DIRECTIONS := {
	&"ui_left": Vector2i(-1, 0),
	&"ui_right": Vector2i(1, 0),
	&"ui_up": Vector2i(0, -1),
	&"ui_down": Vector2i(0, 1),
}

@onready var stats_label: Label = $Root/Panel/Content/Stats
@onready var menu: MenuList = $Root/Panel/Content/Options
@onready var tree_view: Control = $Root/Panel/Content/SkillTree
@onready var hint_bar: InputHintBar = $Root/Panel/Content/Hint

var _in_tree: bool = false
## Dirección -> si estaba inclinada la palanca (para contar solo la primera inclinación).
var _held: Dictionary = {}


func _ready() -> void:
	super()
	menu.chosen.connect(_on_chosen)
	menu.cancelled.connect(close)
	menu.set_entries(PackedStringArray(["Árbol de habilidades", "Salir"]))
	_show_tree(false)


func open() -> void:
	_show_tree(false)
	menu.select_first_enabled()
	super()


## `skills` son los datos del árbol (ver SkillTreeView); `branches`, los nombres de sus ramas.
func show_state(ecos: int, skills: Array, branches: PackedStringArray) -> void:
	stats_label.text = "Ecos: %d" % ecos
	tree_view.set_skills(skills, branches)


func is_tree_open() -> bool:
	return _in_tree


func _show_tree(on: bool) -> void:
	_in_tree = on
	menu.visible = not on
	tree_view.visible = on
	hint_bar.set_entries(HINTS_TREE if on else HINTS_MAIN)


func _on_chosen(index: int) -> void:
	if index == OPTION_TREE:
		_show_tree(true)
	else:
		close()


## En el árbol se navega con las flechas (o la cruceta/palanca) y se compra con aceptar.
func _input(event: InputEvent) -> void:
	if not (is_open() and _in_tree):
		return
	for action in DIRECTIONS:
		if not event.is_action(action):
			continue
		var pressed := event.is_action_pressed(action)
		var was_held: bool = _held.get(action, false)
		# La palanca manda un evento por cada pequeño movimiento: cuenta solo el primero.
		if event is InputEventJoypadMotion:
			_held[action] = pressed
			pressed = pressed and not was_held
		elif event.is_echo():
			pressed = false
		if pressed:
			get_viewport().set_input_as_handled()
			var step: Vector2i = DIRECTIONS[action]
			tree_view.move(step.x, step.y)
		return
	if event.is_action_pressed(&"ui_accept") or event.is_action_pressed(&"interact"):
		get_viewport().set_input_as_handled()
		var skill: Dictionary = tree_view.selected()
		if not skill.is_empty():
			skill_requested.emit(skill.id)
	elif event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		_show_tree(false)
