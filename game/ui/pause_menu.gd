extends ModalLayer
## Menú de pausa: continuar, ver el mapa del mundo, ver al personaje (vida,
## Ecos, Filo y habilidades recordadas), ver los controles, volver al menú
## principal (avisa con `title_requested`) y salir del juego. No conoce al
## jugador: recibe los datos con `show_character()` y `set_map()` (los datos
## bajan; ver docs/arquitectura.md).
##
## Quien lo abre (el jugador, al pulsar Esc o Start) llama a `open()`: una capa que solo
## funciona en pausa no puede escuchar la tecla mientras se juega.

enum Page { MAIN, MAP, CHARACTER, CONTROLS }

## Se ha elegido volver al menú principal (lo atiende el mundo, que guarda antes).
signal title_requested

const OPTION_CONTINUE := 0
const OPTION_MAP := 1
const OPTION_CHARACTER := 2
const OPTION_CONTROLS := 3
const OPTION_TITLE := 4
const OPTION_QUIT := 5

## Los indicadores de botón del pie de cada página (ver InputHintBar): sin texto, solo
## los iconos del dispositivo que se use. El mapa añade su leyenda de colores (tú,
## Ancla, tu Eco).
const HINTS_MAIN := [
	{ hint = InputGlyphs.Hint.UP_DOWN },
	{ action = &"ui_accept", hint = InputGlyphs.Hint.CHECK },
	{ action = &"ui_cancel", hint = InputGlyphs.Hint.BACK },
]
const HINTS_CONTROLS := [
	{ hint = InputGlyphs.Hint.LEFT_RIGHT },
	{ action = &"ui_cancel", hint = InputGlyphs.Hint.BACK },
]
const HINTS_SUBPAGE := [{ action = &"ui_cancel", hint = InputGlyphs.Hint.BACK }]
const HINTS_MAP := [
	{ color = Color(0.953, 0.769, 0.416) },
	{ color = Color(0.3, 0.62, 0.95) },
	{ color = Color(0.75, 0.55, 0.95) },
	{ action = &"ui_cancel", hint = InputGlyphs.Hint.BACK },
]
var _page: Page = Page.MAIN
var _character_text: String = ""

@onready var title_label: Label = $Root/Panel/Content/Title
@onready var info: HBoxContainer = $Root/Panel/Content/Info
@onready var info_label: Label = $Root/Panel/Content/Info/Left
@onready var controls_view: Control = $Root/Panel/Content/Controls
@onready var menu: MenuList = $Root/Panel/Content/Options
@onready var hint_bar: InputHintBar = $Root/Panel/Content/Hint
@onready var map_view: MapView = $Root/Panel/Content/Map


func _ready() -> void:
	super()
	menu.set_entries(PackedStringArray(["Continuar", "Mapa", "Personaje", "Controles", "Menú principal", "Salir del juego"]))
	menu.chosen.connect(_on_chosen)
	menu.cancelled.connect(close)


func open() -> void:
	_show_page(Page.MAIN)
	menu.selected = 0
	super()


## `abilities` es nombre -> si está recordada. Las que no lo están salen como ???
## para no desvelar qué queda por encontrar.
func show_character(health: int, max_health: int, flasks: int, max_flasks: int, ecos: int, stats: PackedStringArray, abilities: Dictionary) -> void:
	var lines: PackedStringArray = [
		"Vida: %d / %d  ·  Frascos: %d / %d  ·  Ecos: %d" % [health, max_health, flasks, max_flasks, ecos],
	]
	lines.append_array(stats)
	lines.append_array(["", "Habilidades recordadas"])
	for ability_name in abilities:
		lines.append("   · " + (ability_name if abilities[ability_name] else "???"))
	_character_text = "\n".join(lines)


func set_map(data: MapData) -> void:
	map_view.data = data


func _input(event: InputEvent) -> void:
	if not is_open():
		return
	# En las subpantallas no hay lista de opciones: Esc, Intro o Z vuelven al menú.
	if _page != Page.MAIN and (event.is_action_pressed(&"ui_cancel") \
			or event.is_action_pressed(&"ui_accept") or event.is_action_pressed(&"interact")):
		_show_page(Page.MAIN)
		get_viewport().set_input_as_handled()
	# Start, que abre la pausa, también la cierra desde cualquier pantalla. (Esc es
	# también `ui_cancel`: en el menú principal lo atiende antes la lista de opciones.)
	elif event.is_action_pressed(&"pause"):
		get_viewport().set_input_as_handled()
		close()


func _on_chosen(index: int) -> void:
	match index:
		OPTION_CONTINUE:
			close()
		OPTION_MAP:
			_show_page(Page.MAP)
		OPTION_CHARACTER:
			_show_page(Page.CHARACTER)
		OPTION_CONTROLS:
			_show_page(Page.CONTROLS)
		OPTION_TITLE:
			title_requested.emit()
		OPTION_QUIT:
			# Aviso de cierre antes de salir, para que el mundo guarde (ver world.gd).
			get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
			get_tree().quit()


func _show_page(page: Page) -> void:
	_page = page
	menu.visible = page == Page.MAIN
	info.visible = page == Page.CHARACTER
	controls_view.visible = page == Page.CONTROLS
	map_view.visible = page == Page.MAP
	hint_bar.set_entries(HINTS_MAIN if page == Page.MAIN else (HINTS_MAP if page == Page.MAP else (HINTS_CONTROLS if page == Page.CONTROLS else HINTS_SUBPAGE)))
	match page:
		Page.MAIN:
			title_label.text = "Pausa"
		Page.MAP:
			title_label.text = _map_title()
		Page.CHARACTER:
			title_label.text = "Personaje"
			info_label.text = _character_text
		Page.CONTROLS:
			title_label.text = "Controles"


## "Mapa", y el nombre de la sala donde está el jugador si se sabe.
func _map_title() -> String:
	if map_view.data == null:
		return "Mapa"
	var area := map_view.data.area_at(map_view.data.focus_cell)
	return "Mapa · %s" % area.title if not area.is_empty() else "Mapa"
