extends Control
## Menú principal: la primera pantalla del juego (escena principal del proyecto).
##
## - Continuar: carga la partida guardada (solo si la hay).
## - Nuevo juego: empieza de cero; si ya hay partida, pide confirmación antes
##   de borrarla.
## - Opciones: hoy solo pantalla completa; se guarda en su propio archivo.
## - Controles: el esquema del teclado y de los mandos.
## - Salir.
##
## El fondo (cielo, luna, ruinas, niebla, brasas), el Caminante, el Ancla y el logotipo
## están animados y son solo presentación.
##
## El guardado en sí lo hace el mundo (game/levels/world.gd); aquí solo se mira si
## hay partida y, para un juego nuevo, se borra.

## Se va a empezar a jugar (`new_game`: desde cero). Lo usan las pruebas, en las
## que este menú no es la escena principal y no se cambia de escena.
signal game_started(new_game: bool)

enum Page { MAIN, CONFIRM_NEW_GAME, OPTIONS, CONTROLS }

const World := preload("res://game/levels/world.gd")
const WORLD_SCENE := "res://game/levels/world.tscn"
const GameAudio := preload("res://game/audio/game_audio.gd")

const MAIN_CONTINUE := 0
const MAIN_NEW_GAME := 1
const MAIN_OPTIONS := 2
const MAIN_CONTROLS := 3
const MAIN_QUIT := 4
const CONFIRM_YES := 1
const OPTION_FULLSCREEN := 0
const OPTION_BACK := 1

## Indicadores de botón del pie (ver InputHintBar): elegir, aceptar y, en las subpáginas, volver.
const HINTS_MAIN := [
	{ hint = InputGlyphs.Hint.UP_DOWN },
	{ action = &"ui_accept", hint = InputGlyphs.Hint.CHECK },
]
const HINTS_CONTROLS := [
	{ hint = InputGlyphs.Hint.LEFT_RIGHT },
	{ action = &"ui_cancel", hint = InputGlyphs.Hint.BACK },
]
const HINTS_SUBPAGE := [
	{ hint = InputGlyphs.Hint.UP_DOWN },
	{ action = &"ui_accept", hint = InputGlyphs.Hint.CHECK },
	{ action = &"ui_cancel", hint = InputGlyphs.Hint.BACK },
]

## Las pruebas cambian estas rutas para no tocar la partida ni las opciones reales.
@export var save_path: String = World.SAVE_PATH
@export var options_path: String = "user://opciones.cfg"

var fullscreen: bool = false

var _page: Page = Page.MAIN

@onready var menu: MenuList = $Center/Panel/Content/Options
@onready var info_label: Label = $Center/Panel/Content/Info
@onready var hint_bar: InputHintBar = $Hint
@onready var controls_view: Control = $Controls
@onready var menu_panel: Control = $Center
## Lo que se oculta al mirar los controles, para que el esquema se vea limpio.
@onready var scenery: Array[CanvasItem] = [$Hero, $Anchor, $Logo]
@onready var dim: CanvasItem = $Dim


func _ready() -> void:
	GameAudio.setup(get_tree())
	# Al volver desde la pausa, el mundo deja el árbol en pausa hasta el cambio de
	# escena (para que no siga jugándose ni guardándose a medias): se quita aquí.
	get_tree().paused = false
	# Desde aquí se sabe con qué se juega (teclado o mando) para los iconos de botones.
	InputGlyphs.ensure_tracker(get_tree())
	_load_options()
	menu.chosen.connect(_on_chosen)
	menu.cancelled.connect(_on_cancelled)
	_show_page(Page.MAIN)
	# Con partida, el cursor empieza en Continuar; sin ella, en Nuevo juego.
	menu.select_first_enabled()


## Solo cuenta una partida que se puede leer: una rota o de otra versión no se
## puede continuar (el mundo empezaría de cero sin avisar).
func has_save() -> bool:
	return not SaveSlot.new(save_path).read().is_empty()


func _on_chosen(index: int) -> void:
	match _page:
		Page.MAIN:
			match index:
				MAIN_CONTINUE:
					_start(false)
				MAIN_NEW_GAME:
					if has_save():
						_show_page(Page.CONFIRM_NEW_GAME, 0)
					else:
						_start(true)
				MAIN_OPTIONS:
					_show_page(Page.OPTIONS, 0)
				MAIN_CONTROLS:
					_show_page(Page.CONTROLS)
				MAIN_QUIT:
					get_tree().quit()
		Page.CONFIRM_NEW_GAME:
			if index == CONFIRM_YES:
				_start(true)
			else:
				_show_page(Page.MAIN, MAIN_NEW_GAME)
		Page.OPTIONS:
			if index == OPTION_FULLSCREEN:
				fullscreen = not fullscreen
				_apply_options()
				_save_options()
				_show_page(Page.OPTIONS, OPTION_FULLSCREEN)
			else:
				_show_page(Page.MAIN, MAIN_OPTIONS)


func _on_cancelled() -> void:
	match _page:
		Page.CONFIRM_NEW_GAME:
			_show_page(Page.MAIN, MAIN_NEW_GAME)
		Page.OPTIONS:
			_show_page(Page.MAIN, MAIN_OPTIONS)
		Page.CONTROLS:
			_show_page(Page.MAIN, MAIN_CONTROLS)


## El esquema de controles no tiene lista que lo cierre: Esc, Intro o Z vuelven al menú.
func _input(event: InputEvent) -> void:
	if _page != Page.CONTROLS:
		return
	if event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"ui_accept") or event.is_action_pressed(&"interact"):
		get_viewport().set_input_as_handled()
		_on_cancelled()


## Muestra una página con el cursor en `selected` (o donde estuviera, con -1).
func _show_page(page: Page, selected: int = -1) -> void:
	_page = page
	if selected >= 0:
		menu.selected = selected
	info_label.visible = page == Page.CONFIRM_NEW_GAME
	var showing_controls := page == Page.CONTROLS
	controls_view.visible = showing_controls
	menu_panel.visible = not showing_controls
	dim.visible = showing_controls
	for item in scenery:
		item.visible = not showing_controls
	if showing_controls:
		hint_bar.set_entries(HINTS_CONTROLS)
	else:
		hint_bar.set_entries(HINTS_MAIN if page == Page.MAIN else HINTS_SUBPAGE)
	match page:
		Page.MAIN:
			var saved := has_save()
			menu.set_entries(PackedStringArray(["Continuar", "Nuevo juego", "Opciones", "Controles", "Salir"]), [saved, true, true, true, true])
		Page.CONFIRM_NEW_GAME:
			info_label.text = "Ya hay una partida guardada. Empezar de nuevo la borrará:\nhabilidades, Ecos, mejoras y mapa."
			menu.set_entries(PackedStringArray(["No, volver", "Sí, borrarla y empezar de cero"]))
		Page.OPTIONS:
			menu.set_entries(PackedStringArray(["Pantalla completa: %s" % ("sí" if fullscreen else "no"), "Volver"]))
		Page.CONTROLS:
			pass


func _start(new_game: bool) -> void:
	Sfx.play(&"begin", null, -4.0)
	if new_game:
		SaveSlot.new(save_path).erase()
	game_started.emit(new_game)
	if get_tree().current_scene != self:
		return
	# Se espera a que pasen dos pasos de físicas: la tecla que elige la opción
	# (Intro o Espacio, que también es saltar) seguiría contando como recién
	# pulsada en el mundo y el personaje saltaría nada más aparecer.
	menu.set_process_input(false)
	await get_tree().physics_frame
	await get_tree().physics_frame
	get_tree().change_scene_to_file(WORLD_SCENE)


func _load_options() -> void:
	var config := ConfigFile.new()
	if config.load(options_path) == OK:
		fullscreen = config.get_value("pantalla", "completa", false) == true
	_apply_options()


func _save_options() -> void:
	var config := ConfigFile.new()
	config.set_value("pantalla", "completa", fullscreen)
	config.save(options_path)


func _apply_options() -> void:
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)
