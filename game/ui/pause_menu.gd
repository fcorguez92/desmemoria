extends ModalLayer
## Menú de pausa: continuar, ver el mapa del mundo, ver al personaje (vida,
## Ecos, Filo y habilidades recordadas), ver los controles, empezar una partida
## nueva (tras confirmar; avisa con `new_game_requested`) y salir del juego. No
## conoce al jugador: recibe los datos con `show_character()` y `set_map()` (los
## datos bajan; ver docs/arquitectura.md).
##
## Quien lo abre (el jugador, al pulsar Esc) llama a `open()`: una capa que solo
## funciona en pausa no puede escuchar la tecla mientras se juega.

enum Page { MAIN, MAP, CHARACTER, CONTROLS, CONFIRM_NEW_GAME }

## El jugador ha confirmado que quiere borrar la partida y empezar de cero.
signal new_game_requested

const OPTION_CONTINUE := 0
const OPTION_MAP := 1
const OPTION_CHARACTER := 2
const OPTION_CONTROLS := 3
const OPTION_NEW_GAME := 4
const OPTION_QUIT := 5
const MAIN_ENTRIES := ["Continuar", "Mapa", "Personaje", "Controles", "Nueva partida", "Salir del juego"]
## En la pantalla de confirmar una partida nueva, la opción por defecto es no.
const CONFIRM_ENTRIES := ["No, seguir jugando", "Sí, borrar la partida y empezar de cero"]
const CONFIRM_YES := 1

const HINT_MAIN := "↑ ↓ elegir · Intro confirmar · Esc continuar"
const HINT_SUBPAGE := "Esc o Intro para volver"
const HINT_CONFIRM := "↑ ↓ elegir · Intro confirmar · Esc volver"
const HINT_MAP := "Dorado: tú · Azul: Ancla · Violeta: tu Eco · Esc o Intro para volver"
## Tecla y qué hace, una fila por control.
const CONTROLS := [
	["← →", "Moverse"],
	["Espacio", "Saltar (en el aire, otra vez: doble salto)"],
	["↓ + Espacio", "Bajar de un tablón"],
	["X", "Atacar"],
	["V", "Guardia: desvía un golpe justo a tiempo"],
	["Shift", "Dash"],
	["H", "Curarse"],
	["Z", "Ancla de Memoria: descansar y abrir su menú"],
	["↑ ↓", "Mirar arriba o abajo"],
	["Esc", "Pausa"],
]

var _page: Page = Page.MAIN
var _character_text: String = ""

@onready var title_label: Label = $Root/Panel/Content/Title
@onready var info: HBoxContainer = $Root/Panel/Content/Info
@onready var info_label: Label = $Root/Panel/Content/Info/Left
@onready var actions_label: Label = $Root/Panel/Content/Info/Right
@onready var menu: MenuList = $Root/Panel/Content/Options
@onready var hint_label: Label = $Root/Panel/Content/Hint
@onready var map_view: MapView = $Root/Panel/Content/Map


func _ready() -> void:
	super()
	menu.chosen.connect(_on_chosen)
	menu.cancelled.connect(_on_cancelled)


func open() -> void:
	menu.selected = 0
	_show_page(Page.MAIN)
	super()


## `abilities` es nombre -> si está recordada. Las que no lo están salen como ???
## para no desvelar qué queda por encontrar.
func show_character(health: int, max_health: int, ecos: int, weapon_level: int, weapon_damage: int, abilities: Dictionary) -> void:
	var lines: PackedStringArray = [
		"Vida: %d / %d" % [health, max_health],
		"Ecos: %d" % ecos,
		"Filo: nivel %d (daño %d)" % [weapon_level, weapon_damage],
		"",
		"Habilidades recordadas",
	]
	for ability_name in abilities:
		lines.append("   · " + (ability_name if abilities[ability_name] else "???"))
	_character_text = "\n".join(lines)


func _input(event: InputEvent) -> void:
	# En las subpantallas no hay lista de opciones: Esc o Intro vuelven al menú.
	if is_open() and _page != Page.MAIN \
			and (event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"ui_accept")):
		_show_page(Page.MAIN)
		get_viewport().set_input_as_handled()


func _on_chosen(index: int) -> void:
	if _page == Page.CONFIRM_NEW_GAME:
		if index == CONFIRM_YES:
			new_game_requested.emit()
		else:
			_show_page(Page.MAIN)
		return
	match index:
		OPTION_CONTINUE:
			close()
		OPTION_MAP:
			_show_page(Page.MAP)
		OPTION_CHARACTER:
			_show_page(Page.CHARACTER)
		OPTION_CONTROLS:
			_show_page(Page.CONTROLS)
		OPTION_NEW_GAME:
			_show_page(Page.CONFIRM_NEW_GAME)
		OPTION_QUIT:
			# Aviso de cierre antes de salir, para que el mundo guarde (ver world.gd).
			get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
			get_tree().quit()


func _show_page(page: Page) -> void:
	var previous := _page
	_page = page
	menu.visible = page == Page.MAIN or page == Page.CONFIRM_NEW_GAME
	# La confirmación usa la misma lista con otras opciones: al entrar se empieza
	# por "no", y al volver al menú el cursor sigue en "Nueva partida".
	if page == Page.CONFIRM_NEW_GAME:
		menu.selected = 0
	elif previous == Page.CONFIRM_NEW_GAME:
		menu.selected = OPTION_NEW_GAME
	menu.set_entries(PackedStringArray(CONFIRM_ENTRIES if page == Page.CONFIRM_NEW_GAME else MAIN_ENTRIES))
	info.visible = page == Page.CHARACTER or page == Page.CONTROLS or page == Page.CONFIRM_NEW_GAME
	map_view.visible = page == Page.MAP
	actions_label.text = ""
	info_label.custom_minimum_size.x = 0.0
	hint_label.text = {Page.MAIN: HINT_MAIN, Page.MAP: HINT_MAP, Page.CONFIRM_NEW_GAME: HINT_CONFIRM}.get(page, HINT_SUBPAGE)
	match page:
		Page.MAIN:
			title_label.text = "Pausa"
		Page.MAP:
			title_label.text = _map_title()
		Page.CONFIRM_NEW_GAME:
			title_label.text = "Nueva partida"
			info_label.text = "Se borrará todo el progreso guardado: habilidades,\nEcos, mejoras del Filo y mapa. No se puede deshacer."
		Page.CHARACTER:
			title_label.text = "Personaje"
			info_label.text = _character_text
		Page.CONTROLS:
			title_label.text = "Controles"
			# Dos columnas: teclas a la izquierda y qué hace cada una a la derecha.
			var keys := PackedStringArray()
			var actions := PackedStringArray()
			for line in CONTROLS:
				keys.append(line[0])
				actions.append(line[1])
			info_label.text = "
".join(keys)
			actions_label.text = "
".join(actions)
			info_label.custom_minimum_size.x = 150.0


func set_map(data: MapData) -> void:
	map_view.data = data


## "Mapa", y el nombre de la sala donde está el jugador si se sabe.
func _map_title() -> String:
	if map_view.data == null:
		return "Mapa"
	var area := map_view.data.area_at(map_view.data.focus_cell)
	return "Mapa · %s" % area.title if not area.is_empty() else "Mapa"


## Esc en la confirmación vuelve al menú sin borrar nada; en el menú, continúa.
func _on_cancelled() -> void:
	if _page == Page.CONFIRM_NEW_GAME:
		_show_page(Page.MAIN)
	else:
		close()
