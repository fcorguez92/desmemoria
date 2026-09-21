extends ModalLayer
## Menú de pausa: continuar, ver al personaje (vida, Ecos, Filo y habilidades
## recordadas), ver los controles y salir del juego. No conoce al jugador: recibe
## los datos con `show_character()` (los datos bajan; ver docs/arquitectura.md).
##
## Quien lo abre (el jugador, al pulsar Esc) llama a `open()`: una capa que solo
## funciona en pausa no puede escuchar la tecla mientras se juega.

enum Page { MAIN, CHARACTER, CONTROLS }

const OPTION_CONTINUE := 0
const OPTION_CHARACTER := 1
const OPTION_CONTROLS := 2
const OPTION_QUIT := 3

const HINT_MAIN := "↑ ↓ elegir · Intro confirmar · Esc continuar"
const HINT_SUBPAGE := "Esc o Intro para volver"
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


func _ready() -> void:
	super()
	menu.set_entries(PackedStringArray(["Continuar", "Personaje", "Controles", "Salir del juego"]))
	menu.chosen.connect(_on_chosen)
	menu.cancelled.connect(close)


func open() -> void:
	_show_page(Page.MAIN)
	menu.selected = 0
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
	match index:
		OPTION_CONTINUE:
			close()
		OPTION_CHARACTER:
			_show_page(Page.CHARACTER)
		OPTION_CONTROLS:
			_show_page(Page.CONTROLS)
		OPTION_QUIT:
			get_tree().quit()


func _show_page(page: Page) -> void:
	_page = page
	menu.visible = page == Page.MAIN
	info.visible = page != Page.MAIN
	actions_label.text = ""
	info_label.custom_minimum_size.x = 0.0
	hint_label.text = HINT_MAIN if page == Page.MAIN else HINT_SUBPAGE
	match page:
		Page.MAIN:
			title_label.text = "Pausa"
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
