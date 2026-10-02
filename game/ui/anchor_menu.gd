extends ModalLayer
## Menú del Ancla de Memoria: se abre al descansar, con el juego en pausa.
## Muestra los Ecos y el Filo, y ofrece mejorar el arma o salir. No conoce al
## jugador: recibe los números con `show_state()` y avisa con señales (los datos
## bajan, los eventos suben; ver docs/arquitectura.md). Las entradas nuevas
## (tienda, viaje entre Anclas...) se añadirán aquí cuando existan sus mecánicas.

signal upgrade_requested

const OPTION_UPGRADE := 0

@onready var stats_label: Label = $Root/Panel/Content/Stats
@onready var menu: MenuList = $Root/Panel/Content/Options
@onready var hint_bar: InputHintBar = $Root/Panel/Content/Hint


func _ready() -> void:
	super()
	menu.chosen.connect(_on_chosen)
	menu.cancelled.connect(close)
	hint_bar.set_entries([
		{ hint = InputGlyphs.Hint.UP_DOWN },
		{ action = &"ui_accept", hint = InputGlyphs.Hint.CHECK },
		{ action = &"ui_cancel", hint = InputGlyphs.Hint.BACK },
	])


func open() -> void:
	menu.select_first_enabled()
	super()


## `next_cost` es el coste de la siguiente mejora del Filo, o -1 si ya está al máximo.
func show_state(ecos: int, weapon_level: int, weapon_damage: int, next_cost: int) -> void:
	stats_label.text = "Ecos: %d\nFilo: nivel %d (daño %d)" % [ecos, weapon_level, weapon_damage]
	var upgrade_text := "El Filo está al máximo"
	var can_upgrade := false
	if next_cost >= 0:
		can_upgrade = ecos >= next_cost
		upgrade_text = "Mejorar el Filo (%d Ecos)" % next_cost
		if not can_upgrade:
			upgrade_text = "Mejorar el Filo (%d Ecos, te faltan %d)" % [next_cost, next_cost - ecos]
	menu.set_entries(PackedStringArray([upgrade_text, "Salir"]), [can_upgrade, true])


func _on_chosen(index: int) -> void:
	if index == OPTION_UPGRADE:
		upgrade_requested.emit()
	else:
		close()
