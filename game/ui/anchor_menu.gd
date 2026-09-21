extends CanvasLayer
## Menú del Ancla de Memoria: se abre al descansar, con el juego en pausa.
## Muestra los Ecos y el Filo, y ofrece mejorar el arma o salir. No conoce al
## jugador: recibe los números con `show_state()` y avisa con señales (los datos
## bajan, los eventos suben; ver docs/arquitectura.md). Las entradas nuevas
## (tienda, viaje entre Anclas...) se añadirán aquí cuando existan sus mecánicas.

signal upgrade_requested
signal closed

const OPTION_UPGRADE := 0

@onready var root: Control = $Root
@onready var stats_label: Label = $Root/Panel/Content/Stats
@onready var menu: MenuList = $Root/Panel/Content/Options


func _ready() -> void:
	root.visible = false
	menu.chosen.connect(_on_chosen)
	menu.cancelled.connect(close)


func is_open() -> bool:
	return root.visible


func open() -> void:
	menu.selected = 0
	root.visible = true
	get_tree().paused = true


func close() -> void:
	if not root.visible:
		return
	root.visible = false
	get_tree().paused = false
	closed.emit()


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


func _unhandled_input(event: InputEvent) -> void:
	# Volver a pulsar la tecla del Ancla también cierra el menú.
	if root.visible and event.is_action_pressed(&"interact"):
		close()
		get_viewport().set_input_as_handled()


func _on_chosen(index: int) -> void:
	if index == OPTION_UPGRADE:
		upgrade_requested.emit()
	else:
		close()
